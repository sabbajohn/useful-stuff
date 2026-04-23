#!/bin/zsh

set -euo pipefail

PHP_CONFIG_FILE="$HOME/.php_versions"

find_brew() {
    if command -v brew >/dev/null 2>&1; then
        command -v brew
        return 0
    fi

    local candidate
    for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        if [[ -x "$candidate" ]]; then
            echo "$candidate"
            return 0
        fi
    done

    return 1
}

if [[ "${OSTYPE:-}" == darwin* ]] && [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
        user_home=$(dscl . -read "/Users/${SUDO_USER}" NFSHomeDirectory 2>/dev/null | awk '{print $2}')
        if [[ -n "$user_home" ]]; then
            export HOME="$user_home"
        fi
        exec sudo -u "$SUDO_USER" HOME="$HOME" USER="$SUDO_USER" "$0" "$@"
    fi

    echo "Homebrew cannot run as root on macOS."
    echo "Run the PHP switcher as your normal user, without sudo."
    exit 1
fi

if ! BREW_BIN=$(find_brew); then
    echo "Homebrew is not installed. Please install it first."
    exit 1
fi

brew_cmd() {
    "$BREW_BIN" "$@"
}

write_php_config() {
    local php_prefix="$1"

    cat > "$PHP_CONFIG_FILE" <<EOF
# PHP version configuration
export PATH="$php_prefix/bin:$php_prefix/sbin:\$PATH"
EOF
}

if ! command -v fzf >/dev/null 2>&1; then
    echo "fzf is not installed. Please install it with 'brew install fzf'."
    exit 1
fi

if [[ ! -f "$PHP_CONFIG_FILE" ]]; then
    touch "$PHP_CONFIG_FILE"
fi

INSTALLED_PHP_VERSIONS=$(brew_cmd list --formula --versions 2>/dev/null | awk '{print $1}' | grep '^php@' | sort -V || true)

echo "PHP Version Manager"
echo "-------------------"

if [[ -n "$INSTALLED_PHP_VERSIONS" ]]; then
    MENU=(
        "Switch to an installed PHP version"
        "Install a new PHP version (including keg-only versions)"
        "Cancel and exit"
    )
else
    echo "No PHP versions are currently installed via Homebrew."
    MENU=(
        "Install a new PHP version (including keg-only versions)"
        "Cancel and exit"
    )
fi

CHOICE=$(printf "%s\n" "${MENU[@]}" | fzf --prompt="Select an option: ")

case "$CHOICE" in
"Switch to an installed PHP version")
    PHP_VERSION=$(printf "%s\n" "$INSTALLED_PHP_VERSIONS" | fzf --prompt="Select an installed PHP version: ")
    if [[ -z "$PHP_VERSION" ]]; then
        echo "No selection made. Exiting..."
        exit 0
    fi
    echo "Switching to $PHP_VERSION..."
    ;;
"Install a new PHP version (including keg-only versions)")
    echo "Searching for available PHP versions..."
    AVAILABLE_PHP_VERSIONS=$(brew_cmd search "^php@" 2>/dev/null | grep '^php@' | sort -V || true)
    if [[ -z "$AVAILABLE_PHP_VERSIONS" ]]; then
        echo "No PHP versions available for installation. Exiting..."
        exit 1
    fi
    PHP_VERSION=$(printf "%s\n" "$AVAILABLE_PHP_VERSIONS" | fzf --prompt="Select a PHP version to install: ")
    if [[ -z "$PHP_VERSION" ]]; then
        echo "No selection made. Exiting..."
        exit 0
    fi
    echo "Installing $PHP_VERSION..."
    brew_cmd install "$PHP_VERSION"
    ;;
"Cancel and exit")
    echo "Exiting..."
    exit 0
    ;;
*)
    echo "Invalid option. Exiting..."
    exit 1
    ;;
esac

echo "Unlinking current PHP..."
while IFS= read -r installed_php; do
    [[ -z "$installed_php" ]] && continue
    brew_cmd unlink "$installed_php" >/dev/null 2>&1 || true
done <<< "$INSTALLED_PHP_VERSIONS"

PHP_PREFIX=$(brew_cmd --prefix "$PHP_VERSION")
write_php_config "$PHP_PREFIX"
export PATH="$PHP_PREFIX/bin:$PHP_PREFIX/sbin:$PATH"
hash -r 2>/dev/null || true

if brew_cmd info "$PHP_VERSION" 2>/dev/null | grep -q "keg-only"; then
    echo "$PHP_VERSION is keg-only. Updating PATH..."
    echo "Run: source \"$PHP_CONFIG_FILE\""
else
    echo "Linking $PHP_VERSION..."
    brew_cmd link --force --overwrite "$PHP_VERSION"
fi

echo "PHP version switched to:"
echo "Using: $(command -v php)"
php -v

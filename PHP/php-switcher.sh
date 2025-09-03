#!/bin/zsh

# Define your PHP configuration file
PHP_CONFIG_FILE="$HOME/.php_versions"

# Ensure Homebrew is available
if ! command -v brew &> /dev/null; then
    echo "Homebrew is not installed. Please install it first."
    exit 1
fi

# Ensure fzf is available
if ! command -v fzf &> /dev/null; then
    echo "fzf is not installed. Please install it with 'brew install fzf'."
    exit 1
fi

# Ensure the PHP config file exists
if [ ! -f "$PHP_CONFIG_FILE" ]; then
    touch "$PHP_CONFIG_FILE"
fi

# Fetch installed PHP versions
INSTALLED_PHP_VERSIONS=$(brew list --versions | grep -o 'php@[0-9]\+\.[0-9]\+')

# Main menu
echo "PHP Version Manager"
echo "-------------------"
MENU=("Switch to an installed PHP version" "Install a new PHP version (including keg-only versions)" "Cancel and exit")
CHOICE=$(printf "%s\n" "${MENU[@]}" | fzf --prompt="Select an option: ")

case "$CHOICE" in
"Switch to an installed PHP version")
    if [ -n "$INSTALLED_PHP_VERSIONS" ]; then
        PHP_VERSION=$(printf "%s\n" "$INSTALLED_PHP_VERSIONS" | fzf --prompt="Select an installed PHP version: ")
        if [ -z "$PHP_VERSION" ]; then
            echo "No selection made. Exiting..."
            exit 0
        fi
        echo "Switching to $PHP_VERSION..."
    else
        echo "No PHP versions are installed. Exiting..."
        exit 1
    fi
    ;;
"Install a new PHP version (including keg-only versions)")
    echo "Searching for available PHP versions..."
    AVAILABLE_PHP_VERSIONS=$(brew search "^php@" | grep "php@" | sed 's/ .*//' | sort)
    if [ -z "$AVAILABLE_PHP_VERSIONS" ]; then
        echo "No PHP versions available for installation. Exiting..."
        exit 1
    fi
    PHP_VERSION=$(printf "%s\n" "$AVAILABLE_PHP_VERSIONS" | fzf --prompt="Select a PHP version to install: ")
    if [ -z "$PHP_VERSION" ]; then
        echo "No selection made. Exiting..."
        exit 0
    fi
    echo "Installing $PHP_VERSION..."
    brew install "$PHP_VERSION"
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

# Safely unlink currently linked PHP (ignore errors if none is linked)
echo "Unlinking current PHP..."
brew list --versions | grep -o 'php@[0-9]\+\.[0-9]\+' | xargs -I {} brew unlink {} &>/dev/null || true

# Check if the selected PHP version is keg-only
if brew info "$PHP_VERSION" | grep "keg-only"; then
    echo "$PHP_VERSION is keg-only. Updating PATH..."
    # Update PATH to include keg-only PHP version
    echo "export PATH=\"$(brew --prefix $PHP_VERSION)/bin:\$PATH\"" >> "$PHP_CONFIG_FILE"
    echo "export PATH=\"$(brew --prefix $PHP_VERSION)/sbin:\$PATH\"" >> "$PHP_CONFIG_FILE"
else
    echo "Linking $PHP_VERSION..."
    brew link --force --overwrite "$PHP_VERSION"
fi

# Suggest sourcing the configuration
#if ! grep -q "source $PHP_CONFIG_FILE" "$HOME/.zshrc"; then
#    echo "Adding source command to .zshrc..."
#    echo "source $PHP_CONFIG_FILE" >> "$HOME/.zshrc"
#fi
#
source "$HOME/.zshrc"

# Confirm the switch
echo "PHP version switched to:"
php -v

# Reload the shell configuration in Zsh
echo "Reloading shell configuration..."
exec zsh



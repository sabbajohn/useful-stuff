#!/usr/bin/env bash
#
# Shared helpers for DevOps Toolkit scripts.
# Goals:
# - gum is optional (fallback to basic shell prompts)
# - consistent --help, --no-ui behavior
# - light OS detection

set -u

dtk_os() {
  local os
  os="$(uname -s 2>/dev/null || echo "")"
  case "$os" in
    Darwin) echo "macOS" ;;
    Linux) echo "Linux" ;;
    *) echo "UNKNOWN" ;;
  esac
}

dtk_has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

dtk_is_tty() {
  [[ -t 0 && -t 1 ]]
}

dtk_ui_available() {
  local no_ui="${1:-0}"
  if [[ "$no_ui" = "1" ]]; then
    return 1
  fi
  dtk_is_tty && dtk_has_cmd gum
}

dtk_die() {
  echo "❌ $*" >&2
  exit 1
}

dtk_warn() {
  echo "⚠️  $*" >&2
}

dtk_info() {
  echo "ℹ️  $*"
}

dtk_confirm() {
  # Usage: dtk_confirm "Question?"
  local prompt="$1"
  local resp=""
  read -r -p "$prompt [y/N] " resp
  case "$resp" in
    [yY]|[yY][eE][sS]) return 0 ;;
    *) return 1 ;;
  esac
}

dtk_ui_confirm() {
  local no_ui="${1:-0}"
  local prompt="$2"
  if dtk_ui_available "$no_ui"; then
    gum confirm "$prompt"
    return $?
  fi
  dtk_confirm "$prompt"
}

dtk_ui_input() {
  # Usage: dtk_ui_input <no_ui> <placeholder> [default]
  local no_ui="${1:-0}"
  local placeholder="$2"
  local default="${3:-}"
  if dtk_ui_available "$no_ui"; then
    if [[ -n "$default" ]]; then
      gum input --placeholder "$placeholder" --value "$default"
    else
      gum input --placeholder "$placeholder"
    fi
    return 0
  fi

  local resp=""
  if [[ -n "$default" ]]; then
    read -r -p "$placeholder (default: $default): " resp
    echo "${resp:-$default}"
  else
    read -r -p "$placeholder: " resp
    echo "$resp"
  fi
}

dtk_ui_choose() {
  # Usage: dtk_ui_choose <no_ui> <prompt> <options...>
  # In non-UI mode, prints numbered list and returns chosen value.
  local no_ui="${1:-0}"
  local prompt="$2"
  shift 2

  if dtk_ui_available "$no_ui"; then
    gum choose --header "$prompt" "$@"
    return 0
  fi

  local options=("$@")
  local i=1
  echo "$prompt"
  for opt in "${options[@]}"; do
    echo "  $i) $opt"
    i=$((i + 1))
  done

  local choice=""
  read -r -p "Choose [1-${#options[@]}]: " choice
  if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
    echo "${options[$((choice - 1))]}"
  else
    echo ""
  fi
}

dtk_atomic_write() {
  # Usage: dtk_atomic_write <path> <content>
  local path="$1"
  local content="$2"
  local dir tmp
  dir="$(dirname "$path")"
  tmp="${path}.tmp.$$"
  mkdir -p "$dir" 2>/dev/null || true
  printf "%s" "$content" > "$tmp"
  mv -f "$tmp" "$path"
}

dtk_assert_no_pipe() {
  # Blocks '|' because config storage uses it as delimiter.
  local field_name="$1"
  local value="$2"
  if [[ "$value" == *"|"* ]]; then
    dtk_die "Campo '$field_name' não pode conter '|'"
  fi
}


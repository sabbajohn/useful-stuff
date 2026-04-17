#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../common/cli.sh
source "$SCRIPT_DIR/../common/cli.sh"

OS="$(dtk_os)"

if [[ "$OS" = "macOS" ]]; then
  exec "$SCRIPT_DIR/mac-storage-manager.sh" "$@"
fi

exec "$SCRIPT_DIR/linux-storage-manager.sh" "$@"


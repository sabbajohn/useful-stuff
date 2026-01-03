#!/usr/bin/env bash
# Simple installer for devops-toolkit
set -euo pipefail

DEST_DIR="${1:-$HOME/.devops-toolkit}"
BIN_LINK_DIR="/usr/local/bin"

echo "Installing devops-toolkit to ${DEST_DIR}"
mkdir -p "$DEST_DIR"

# If install.sh is run from a remote curl, try to detect script directory
SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -d "$SRC_DIR" ]; then
  cp -a "$SRC_DIR/"* "$DEST_DIR/"
else
  echo "Installer could not locate source files. If running via curl, use 'git clone' or download the archive." >&2
fi

if [ -w "$BIN_LINK_DIR" ]; then
  ln -sf "$DEST_DIR/bin/devops.sh" "$BIN_LINK_DIR/devops"
  echo "Installed symlink: $BIN_LINK_DIR/devops"
else
  echo "Cannot write to $BIN_LINK_DIR. Add $DEST_DIR/bin to your PATH to use 'devops' command." >&2
fi

echo "Installation complete. Run: devops or $DEST_DIR/bin/devops.sh" 

#!/usr/bin/env bash

# Minimal launcher for the legacy devops-toolkit subfolder.
# The main hub launcher for this repository is at repo root: devops-toolkit.sh

set -euo pipefail
IFS=$'\n\t'

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="$ROOT_DIR/bin/scripts"

if [[ ! -d "$SCRIPTS_DIR" ]]; then
  echo "❌ Scripts directory not found: $SCRIPTS_DIR" >&2
  exit 1
fi

pick_with_gum() {
  local selection
  selection="$(ls -1 "$SCRIPTS_DIR"/*.sh 2>/dev/null | xargs -n1 basename | gum choose --header="devops-toolkit (legacy) - Select a script")"
  [[ -z "$selection" ]] && exit 0
  exec "$SCRIPTS_DIR/$selection" "$@"
}

pick_with_fzf() {
  local selection
  selection="$(ls -1 "$SCRIPTS_DIR"/*.sh 2>/dev/null | xargs -n1 basename | fzf --prompt="devops> " --height=40% --reverse)"
  [[ -z "$selection" ]] && exit 0
  exec "$SCRIPTS_DIR/$selection" "$@"
}

if command -v gum >/dev/null 2>&1 && [[ -t 0 && -t 1 ]]; then
  pick_with_gum "$@"
elif command -v fzf >/dev/null 2>&1 && [[ -t 0 && -t 1 ]]; then
  pick_with_fzf "$@"
else
  echo "Available scripts:"
  ls -1 "$SCRIPTS_DIR"/*.sh 2>/dev/null | xargs -n1 basename
  echo
  echo "Run one directly, e.g.:"
  echo "  $SCRIPTS_DIR/mac-storage-manager.sh --help"
fi


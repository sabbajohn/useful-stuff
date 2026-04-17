#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../common/cli.sh
source "$SCRIPT_DIR/../common/cli.sh"

NO_UI=0
OS="$(dtk_os)"

usage() {
  cat <<EOF
Linux Storage Manager (Ubuntu/Debian)

Uso:
  $0                         # modo interativo (gum opcional)
  $0 --disk-usage [--no-ui]
  $0 --analyze <path> [--no-ui]
  $0 --mounts [--no-ui]
  $0 --open-ncdu [path]      # se instalado
  $0 --open-duf              # se instalado

Flags:
  --no-ui
  -h, --help
EOF
}

assert_linux() {
  [[ "$OS" = "Linux" ]] || dtk_die "Este script é para Linux. Use Storage/storage-manager.sh."
}

show_disk_usage() {
  assert_linux
  echo "=== Disk Usage (df -hT) ==="
  if dtk_has_cmd df; then
    df -hT || true
  else
    dtk_warn "df não encontrado."
  fi
  echo

  echo "=== Block Devices (lsblk) ==="
  if dtk_has_cmd lsblk; then
    lsblk -f || true
  else
    dtk_warn "lsblk não encontrado."
  fi
}

analyze_path() {
  assert_linux
  local path="$1"
  [[ -n "$path" ]] || path="/"
  [[ -d "$path" ]] || dtk_die "Diretório inválido: $path"

  echo "=== Top Level Usage: $path ==="
  if dtk_has_cmd du; then
    du -xh --max-depth=1 "$path" 2>/dev/null | sort -h || true
  else
    dtk_warn "du não encontrado."
  fi
}

list_mounts() {
  assert_linux
  if dtk_has_cmd findmnt; then
    findmnt || true
  else
    mount || true
  fi
}

open_ncdu() {
  assert_linux
  local path="${1:-/}"
  if ! dtk_has_cmd ncdu; then
    dtk_die "ncdu não encontrado. Instale: sudo apt install ncdu"
  fi
  ncdu "$path"
}

open_duf() {
  assert_linux
  if ! dtk_has_cmd duf; then
    dtk_die "duf não encontrado. Instale: sudo apt install duf"
  fi
  duf
}

interactive() {
  if ! dtk_ui_available "$NO_UI"; then
    usage
    exit 1
  fi

  while true; do
    choice="$(gum choose --header="Linux Storage Manager" \
      "📊 Disk usage (df/lsblk)" \
      "📁 Analyze path (du)" \
      "🧷 List mounts" \
      "🧭 Open ncdu (if installed)" \
      "📈 Open duf (if installed)" \
      "🚪 Sair")"
    case "$choice" in
      "📊 Disk usage"*) show_disk_usage; gum confirm "Voltar ao menu?" || exit 0 ;;
      "📁 Analyze path"*)
        path="$(gum input --placeholder "Path" --value "/")"
        analyze_path "${path:-/}"
        gum confirm "Voltar ao menu?" || exit 0
        ;;
      "🧷 List mounts"*) list_mounts | less; ;;
      "🧭 Open ncdu"*)
        path="$(gum input --placeholder "Path" --value "/")"
        open_ncdu "${path:-/}"
        ;;
      "📈 Open duf"*) open_duf ;;
      *) exit 0 ;;
    esac
  done
}

DISK_USAGE=0
ANALYZE_PATH=""
MOUNTS=0
OPEN_NCDU=0
NCDU_PATH=""
OPEN_DUF=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-ui) NO_UI=1; shift ;;
    --disk-usage) DISK_USAGE=1; shift ;;
    --analyze) ANALYZE_PATH="${2:-}"; shift 2 ;;
    --mounts) MOUNTS=1; shift ;;
    --open-ncdu) OPEN_NCDU=1; shift; NCDU_PATH="${1:-/}"; [[ $# -gt 0 ]] && shift || true ;;
    --open-duf) OPEN_DUF=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) dtk_die "Argumento desconhecido: $1" ;;
  esac
done

if [[ "$DISK_USAGE" = "1" ]]; then
  show_disk_usage
  exit 0
fi

if [[ -n "$ANALYZE_PATH" ]]; then
  analyze_path "$ANALYZE_PATH"
  exit 0
fi

if [[ "$MOUNTS" = "1" ]]; then
  list_mounts
  exit 0
fi

if [[ "$OPEN_NCDU" = "1" ]]; then
  open_ncdu "${NCDU_PATH:-/}"
  exit 0
fi

if [[ "$OPEN_DUF" = "1" ]]; then
  open_duf
  exit 0
fi

interactive


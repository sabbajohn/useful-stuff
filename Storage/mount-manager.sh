#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../common/cli.sh
source "$SCRIPT_DIR/../common/cli.sh"

OS="$(dtk_os)"
NO_UI=0
YES=0

usage() {
  cat <<EOF
Mount Manager (SMB/NFS)

Uso:
  $0                          # modo interativo (gum opcional)
  $0 --list [--no-ui]
  $0 --mount --type <smb|nfs> --remote <remote> --mountpoint <path> [--user <u>] [--no-ui]
  $0 --unmount --mountpoint <path> [--no-ui]
  $0 --fstab-line --type <smb|nfs> --remote <remote> --mountpoint <path> [--user <u>]

Exemplos:
  Linux SMB:  --remote //server/share --mountpoint /mnt/share --user john
  macOS SMB:  --remote //server/share --mountpoint /Volumes/share --user john
  NFS:        --remote server:/export/path --mountpoint /mnt/nfs

Flags:
  --yes                       Sem confirmação
  --no-ui
  -h, --help
EOF
}

list_mounts() {
  if [[ "$OS" = "Linux" ]]; then
    if dtk_has_cmd findmnt; then
      findmnt -t nfs,cifs 2>/dev/null || findmnt 2>/dev/null || true
    else
      mount | grep -E ' type (nfs|cifs) ' || true
    fi
    return 0
  fi

  mount | grep -E '(smbfs|nfs)' || true
}

prompt_password() {
  local pw=""
  if dtk_ui_available "$NO_UI"; then
    pw="$(gum input --password --placeholder "Password")"
    echo "$pw"
    return 0
  fi
  read -r -s -p "Password: " pw
  echo
  echo "$pw"
}

do_mount_smb_linux() {
  local remote="$1"
  local mountpoint="$2"
  local user="$3"
  local password="$4"

  dtk_has_cmd mount || dtk_die "mount não encontrado."
  mkdir -p "$mountpoint" 2>/dev/null || true

  # Best-effort options; user can edit fstab output if needed.
  sudo mount -t cifs "$remote" "$mountpoint" \
    -o "username=${user},password=${password},uid=$(id -u),gid=$(id -g),iocharset=utf8,vers=3.0"
}

do_mount_smb_macos() {
  local remote="$1"       # //server/share
  local mountpoint="$2"
  local user="$3"
  local password="$4"

  dtk_has_cmd mount_smbfs || dtk_die "mount_smbfs não encontrado."
  mkdir -p "$mountpoint" 2>/dev/null || true

  # mount_smbfs expects //user:pass@server/share
  local with_creds
  with_creds="$(echo "$remote" | sed "s#^//#//${user}:${password}@#")"
  sudo mount_smbfs "$with_creds" "$mountpoint"
}

do_mount_nfs() {
  local remote="$1"       # server:/export
  local mountpoint="$2"
  mkdir -p "$mountpoint" 2>/dev/null || true

  if [[ "$OS" = "macOS" ]] && dtk_has_cmd mount_nfs; then
    sudo mount_nfs "$remote" "$mountpoint"
    return 0
  fi
  sudo mount -t nfs "$remote" "$mountpoint"
}

do_unmount() {
  local mountpoint="$1"
  if [[ "$OS" = "macOS" ]]; then
    # diskutil is nicer but not always desired; umount works.
    sudo umount "$mountpoint"
    return 0
  fi
  sudo umount "$mountpoint"
}

fstab_line() {
  local type="$1"
  local remote="$2"
  local mountpoint="$3"
  local user="${4:-}"

  case "$type" in
    smb)
      echo "${remote} ${mountpoint} cifs username=${user},password=***,uid=1000,gid=1000,iocharset=utf8,vers=3.0 0 0"
      ;;
    nfs)
      echo "${remote} ${mountpoint} nfs defaults,_netdev 0 0"
      ;;
    *)
      dtk_die "Tipo inválido: $type"
      ;;
  esac
}

mount_action() {
  local type="$1"
  local remote="$2"
  local mountpoint="$3"
  local user="${4:-}"

  [[ -n "$type" ]] || dtk_die "--type é obrigatório"
  [[ -n "$remote" ]] || dtk_die "--remote é obrigatório"
  [[ -n "$mountpoint" ]] || dtk_die "--mountpoint é obrigatório"

  if [[ "$YES" != "1" ]] && ! dtk_ui_confirm "$NO_UI" "Montar '$remote' em '$mountpoint'?" ; then
    exit 1
  fi

  case "$type" in
    smb)
      [[ -n "$user" ]] || user="$(dtk_ui_input "$NO_UI" "Username" "$(whoami)")"
      password="$(prompt_password)"
      if [[ "$OS" = "Linux" ]]; then
        do_mount_smb_linux "$remote" "$mountpoint" "$user" "$password"
      else
        do_mount_smb_macos "$remote" "$mountpoint" "$user" "$password"
      fi
      ;;
    nfs)
      do_mount_nfs "$remote" "$mountpoint"
      ;;
    *)
      dtk_die "Tipo inválido: $type"
      ;;
  esac
}

interactive() {
  if ! dtk_ui_available "$NO_UI"; then
    usage
    exit 1
  fi

  while true; do
    choice="$(gum choose --header="Mount Manager ($OS)" \
      "📋 List mounts" \
      "🔗 Mount SMB" \
      "🔗 Mount NFS" \
      "⏏️  Unmount" \
      "🧾 Generate fstab line" \
      "🚪 Sair")"
    case "$choice" in
      "📋 List mounts") list_mounts | less ;;
      "🔗 Mount SMB")
        remote="$(gum input --placeholder "Remote (//server/share)")"
        mountpoint="$(gum input --placeholder "Mountpoint" --value "/mnt/share")"
        user="$(gum input --placeholder "Username" --value "$(whoami)")"
        mount_action "smb" "$remote" "$mountpoint" "$user"
        gum confirm "Voltar ao menu?" || exit 0
        ;;
      "🔗 Mount NFS")
        remote="$(gum input --placeholder "Remote (server:/export)")"
        mountpoint="$(gum input --placeholder "Mountpoint" --value "/mnt/nfs")"
        mount_action "nfs" "$remote" "$mountpoint" ""
        gum confirm "Voltar ao menu?" || exit 0
        ;;
      "⏏️  Unmount")
        mountpoint="$(gum input --placeholder "Mountpoint")"
        [[ -n "$mountpoint" ]] && do_unmount "$mountpoint"
        ;;
      "🧾 Generate fstab line")
        type="$(gum choose "smb" "nfs")"
        remote="$(gum input --placeholder "Remote")"
        mountpoint="$(gum input --placeholder "Mountpoint")"
        user=""
        [[ "$type" = "smb" ]] && user="$(gum input --placeholder "Username" --value "$(whoami)")"
        fstab_line "$type" "$remote" "$mountpoint" "$user"
        gum confirm "Voltar ao menu?" || exit 0
        ;;
      *) exit 0 ;;
    esac
  done
}

LIST=0
DO_MOUNT=0
DO_UNMOUNT=0
DO_FSTAB=0
TYPE=""
REMOTE=""
MOUNTPOINT=""
USER_ARG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-ui) NO_UI=1; shift ;;
    --yes) YES=1; shift ;;
    --list) LIST=1; shift ;;
    --mount) DO_MOUNT=1; shift ;;
    --unmount) DO_UNMOUNT=1; shift ;;
    --fstab-line) DO_FSTAB=1; shift ;;
    --type) TYPE="${2:-}"; shift 2 ;;
    --remote) REMOTE="${2:-}"; shift 2 ;;
    --mountpoint) MOUNTPOINT="${2:-}"; shift 2 ;;
    --user) USER_ARG="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) dtk_die "Argumento desconhecido: $1" ;;
  esac
done

if [[ "$LIST" = "1" ]]; then
  list_mounts
  exit 0
fi

if [[ "$DO_FSTAB" = "1" ]]; then
  fstab_line "$TYPE" "$REMOTE" "$MOUNTPOINT" "$USER_ARG"
  exit 0
fi

if [[ "$DO_UNMOUNT" = "1" ]]; then
  [[ -n "$MOUNTPOINT" ]] || dtk_die "--mountpoint é obrigatório"
  if [[ "$YES" = "1" ]] || dtk_ui_confirm "$NO_UI" "Desmontar '$MOUNTPOINT'?" ; then
    do_unmount "$MOUNTPOINT"
    exit $?
  fi
  exit 1
fi

if [[ "$DO_MOUNT" = "1" ]]; then
  mount_action "$TYPE" "$REMOTE" "$MOUNTPOINT" "$USER_ARG"
  exit $?
fi

interactive


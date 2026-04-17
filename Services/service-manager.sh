#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../common/cli.sh
source "$SCRIPT_DIR/../common/cli.sh"

OS="$(dtk_os)"
NO_UI=0

usage() {
  cat <<EOF
Service Manager (systemd/launchd)

Uso:
  $0                         # modo interativo (gum opcional)
  $0 --list [--no-ui]
  $0 --service <name> --action <status|start|stop|restart|enable|disable> [--no-ui]

macOS extra:
  $0 --service <label> --action <enable|disable> --domain <domain>

Flags:
  --list
  --service <unit/label>
  --action <status|start|stop|restart|enable|disable>
  --domain <domain>          (macOS enable/disable)
  --no-ui
  -h, --help

Notas:
  - Ubuntu/Debian: usa systemd (systemctl).
  - macOS: suporte limitado via launchctl; enable/disable precisa de domain.
EOF
}

list_services_linux() {
  systemctl list-units --type=service --all --no-pager
}

service_action_linux() {
  local service="$1"
  local action="$2"
  case "$action" in
    status) systemctl status "$service" --no-pager ;;
    start|stop|restart|enable|disable) sudo systemctl "$action" "$service" ;;
    *) dtk_die "Ação inválida: $action" ;;
  esac
}

list_services_macos() {
  launchctl list
}

service_action_macos() {
  local label="$1"
  local action="$2"
  local domain="${3:-}"
  case "$action" in
    status)
      launchctl list | grep -F " $label" || true
      ;;
    start|stop)
      # Best-effort; launchctl will error if not applicable.
      launchctl "$action" "$label"
      ;;
    enable|disable)
      if [[ -z "$domain" ]]; then
        dtk_die "No macOS, enable/disable exige --domain (ex.: gui/$UID ou system)."
      fi
      launchctl "$action" "${domain}/${label}"
      ;;
    *)
      dtk_die "Ação inválida: $action"
      ;;
  esac
}

interactive() {
  if ! dtk_ui_available "$NO_UI"; then
    usage
    exit 1
  fi

  while true; do
    choice="$(gum choose --header="Service Manager ($OS)" \
      "📋 Listar serviços" \
      "⚙️  Ação em serviço" \
      "🚪 Sair")"
    case "$choice" in
      "📋 Listar serviços")
        if [[ "$OS" = "Linux" && $(dtk_has_cmd systemctl; echo $?) -eq 0 ]]; then
          list_services_linux | less
        elif [[ "$OS" = "macOS" && $(dtk_has_cmd launchctl; echo $?) -eq 0 ]]; then
          list_services_macos | less
        else
          dtk_warn "Nenhum backend disponível (systemctl/launchctl)."
        fi
        ;;
      "⚙️  Ação em serviço")
        svc="$(gum input --placeholder "Service unit (Linux) ou label (macOS)")"
        [[ -z "$svc" ]] && continue
        act="$(gum choose "status" "start" "stop" "restart" "enable" "disable")"
        domain=""
        if [[ "$OS" = "macOS" && ( "$act" = "enable" || "$act" = "disable" ) ]]; then
          domain="$(gum input --placeholder "Domain (ex.: gui/$UID ou system)")"
        fi
        if [[ "$OS" = "Linux" ]]; then
          service_action_linux "$svc" "$act" || true
        else
          service_action_macos "$svc" "$act" "$domain" || true
        fi
        gum confirm "Voltar ao menu?" || exit 0
        ;;
      *)
        exit 0
        ;;
    esac
  done
}

LIST=0
SERVICE=""
ACTION=""
DOMAIN=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-ui) NO_UI=1; shift ;;
    --list) LIST=1; shift ;;
    --service) SERVICE="${2:-}"; shift 2 ;;
    --action) ACTION="${2:-}"; shift 2 ;;
    --domain) DOMAIN="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) dtk_die "Argumento desconhecido: $1" ;;
  esac
done

if [[ "$LIST" = "1" ]]; then
  if [[ "$OS" = "Linux" ]]; then
    dtk_has_cmd systemctl || dtk_die "systemctl não encontrado."
    list_services_linux
    exit 0
  fi
  dtk_has_cmd launchctl || dtk_die "launchctl não encontrado."
  list_services_macos
  exit 0
fi

if [[ -n "$SERVICE" || -n "$ACTION" ]]; then
  [[ -n "$SERVICE" ]] || dtk_die "--service é obrigatório"
  [[ -n "$ACTION" ]] || dtk_die "--action é obrigatório"
  if [[ "$OS" = "Linux" ]]; then
    dtk_has_cmd systemctl || dtk_die "systemctl não encontrado."
    service_action_linux "$SERVICE" "$ACTION"
  else
    dtk_has_cmd launchctl || dtk_die "launchctl não encontrado."
    service_action_macos "$SERVICE" "$ACTION" "$DOMAIN"
  fi
  exit $?
fi

interactive


#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../common/cli.sh
source "$SCRIPT_DIR/../common/cli.sh"

MACHINE="$(dtk_os)"

NO_UI=0
YES=0

usage() {
    cat <<EOF
Port Checker

Uso:
  $0                          # modo interativo (gum opcional)
  $0 --list [--no-ui]
  $0 --port <p> [--no-ui]
  $0 --stop-port <p> [--yes] [--no-ui]
  $0 --kill-pid <pid> [--yes] [--no-ui]

Flags:
  --list                      Lista listeners
  --port <p>                  Mostra status de uma porta
  --stop-port <p>             Para o serviço/container/processo que está usando a porta
  --kill-pid <pid>            Encerra um PID (SIGTERM -> SIGKILL)
  --yes                       Não perguntar confirmação (cuidado)
  --no-ui                     Força modo texto
  -h, --help                  Ajuda
EOF
}

require_lsof_or_die() {
    if ! dtk_has_cmd lsof; then
        dtk_die "lsof não encontrado. Instale: macOS: brew install lsof | Ubuntu: sudo apt install lsof"
    fi
}

# Verifica se Docker está disponível (opcional)
DOCKER_AVAILABLE=false
if command -v docker &>/dev/null && docker info &>/dev/null 2>&1; then
    DOCKER_AVAILABLE=true
fi

# Função para formatar tabela compatível com ambos os sistemas
format_table() {
    if command -v column &>/dev/null; then
        column -t
    else
        # Fallback para sistemas sem column
        cat
    fi
}

# Função para obter informações do processo compatível com macOS/Linux
get_process_info() {
    local pid=$1
    if [[ "$MACHINE" == "macOS" ]]; then
        ps -p "$pid" -o pid,etime,user,comm,args 2>/dev/null | tail -n +2
    else
        ps -p "$pid" -o pid,etime,user,comm,cmd --no-headers 2>/dev/null
    fi
}

# Função para usar sudo apenas quando necessário
run_lsof() {
    # No macOS, tenta primeiro sem sudo
    if [[ "$MACHINE" == "macOS" ]]; then
        lsof "$@" 2>/dev/null || sudo lsof "$@" 2>/dev/null
    else
        sudo lsof "$@"
    fi
}

service_name_for() {
    local port="$1"
    local proto="$2"
    if dtk_has_cmd getent; then
        getent services "${port}/${proto}" 2>/dev/null | awk '{print $1}' | head -n 1
        return 0
    fi
    if [[ -f /etc/services ]]; then
        awk -v p="${port}/${proto}" '$2==p {print $1; exit}' /etc/services 2>/dev/null || true
    fi
}

systemd_unit_for_pid() {
    local pid="$1"
    [[ "$MACHINE" != "Linux" ]] && return 1
    ! dtk_has_cmd systemctl && return 1

    local status
    status="$(systemctl status "$pid" --no-pager 2>/dev/null || true)"
    [[ -z "$status" ]] && return 1

    local unit=""
    unit="$(echo "$status" | sed -n '1s/^●[[:space:]]\\{1,\\}\\([^[:space:]]\\+\\.service\\).*/\\1/p' | head -n 1)"
    if [[ -n "$unit" ]]; then
        echo "$unit"
        return 0
    fi
    unit="$(echo "$status" | sed -n 's/^[[:space:]]*CGroup: .*\\/\\([^/]*\\.service\\).*/\\1/p' | head -n 1)"
    [[ -n "$unit" ]] && echo "$unit"
}

docker_container_for_pid() {
    local pid="$1"
    [[ "$MACHINE" != "Linux" ]] && return 1
    [[ ! -r "/proc/$pid/cgroup" ]] && return 1
    ! dtk_has_cmd docker && return 1

    local id
    id="$(grep -Eo '[0-9a-f]{64}' "/proc/$pid/cgroup" 2>/dev/null | head -n 1 || true)"
    [[ -z "$id" ]] && return 1
    echo "$id"
}

kill_pid_gracefully() {
    local pid="$1"
    local ask="${2:-1}"
    if [[ "$ask" = "1" && "$YES" != "1" ]]; then
        if ! dtk_ui_confirm "$NO_UI" "Encerrar PID $pid (SIGTERM -> SIGKILL se necessário)?"; then
            return 1
        fi
    fi

    if kill -TERM "$pid" 2>/dev/null; then
        sleep 2
        if kill -0 "$pid" 2>/dev/null; then
            kill -KILL "$pid" 2>/dev/null || true
        fi
        return 0
    fi

    dtk_warn "Falhou em encerrar PID $pid (permite? tente com sudo)."
    return 1
}
# Função para pegar nome do container Docker
get_docker_container_name() {
    local pid=$1
    
    # Verifica se Docker está disponível
    if [[ "$DOCKER_AVAILABLE" != "true" ]]; then
        return 1
    fi
    
    for container in $(docker ps -q 2>/dev/null); do
        cpid=$(docker inspect --format '{{.State.Pid}}' "$container" 2>/dev/null)
        if [ "$cpid" = "$pid" ]; then
            cname=$(docker inspect --format '{{.Name}}' "$container" 2>/dev/null | sed 's#/##')
            echo "$cname"
            return 0
        fi
    done
    return 1
}

# Função para listar processos/portas
list_ports() {
    require_lsof_or_die
    run_lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | awk '
        NR==1 { next }
        {
            cmd=$1; pid=$2; user=$3; name=$NF;
            gsub("\\(LISTEN\\)","",name);
            port=name;
            sub(/^.*:/,"",port);
            if (port ~ /^[0-9]+$/) {
                printf "tcp\t%s\t%s\t%s\t%s\n", port, pid, user, cmd
            }
        }
    ' | sort -u
}

format_listeners_table() {
    local lines="$1"
    if [[ -z "$lines" ]]; then
        echo ""
        return
    fi
    echo "$lines" | awk -F'\t' '
        BEGIN { printf "%-5s %-6s %-8s %-12s %-18s %-14s\n", "PROTO", "PORT", "PID", "USER", "CMD", "SERVICE" }
        {
            proto=$1; port=$2; pid=$3; user=$4; cmd=$5;
            printf "%-5s %-6s %-8s %-12s %-18s %-14s\n", proto, port, pid, user, cmd, ""
        }
    '
}

enrich_listener_line() {
    # Input: proto\tport\tpid\tuser\tcmd
    local line="$1"
    local proto port pid user cmd
    IFS=$'\t' read -r proto port pid user cmd <<<"$line"
    local svc=""
    svc="$(service_name_for "$port" "$proto" || true)"
    local unit=""
    unit="$(systemd_unit_for_pid "$pid" || true)"
    local container=""
    container="$(docker_container_for_pid "$pid" || true)"
    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "$proto" "$port" "$pid" "$user" "$cmd" "${svc:-}" "${unit:-}" "${container:-}"
}

show_port_status() {
    local port="$1"
    local lines
    lines="$(list_ports | awk -F'\t' -v p="$port" '$2==p {print}')"
    if [[ -z "$lines" ]]; then
        echo "✅ Porta $port está LIVRE"
        return 0
    fi
    echo "❌ Porta $port está OCUPADA:"
    while IFS= read -r line; do
        local enriched
        enriched="$(enrich_listener_line "$line")"
        echo "$enriched" | awk -F'\t' '{
            printf "  proto=%s port=%s pid=%s user=%s cmd=%s\n", $1,$2,$3,$4,$5
            if ($6!="") printf "  service=%s\n",$6
            if ($7!="") printf "  systemd=%s\n",$7
            if ($8!="") printf "  docker=%s\n",$8
        }'
    done <<<"$lines"
}

stop_port() {
    local port="$1"
    local line
    line="$(list_ports | awk -F'\t' -v p="$port" '$2==p {print; exit}')"
    if [[ -z "$line" ]]; then
        echo "✅ Porta $port já está livre."
        return 0
    fi
    local enriched proto pid unit container cmd user svc
    enriched="$(enrich_listener_line "$line")"
    IFS=$'\t' read -r proto _port pid user cmd svc unit container <<<"$enriched"

    if [[ -n "$unit" && "$MACHINE" == "Linux" && -n "${unit:-}" && $(dtk_has_cmd systemctl; echo $?) -eq 0 ]]; then
        if [[ "$YES" = "1" ]] || dtk_ui_confirm "$NO_UI" "Parar serviço systemd '$unit' (porta $port)?" ; then
            sudo systemctl stop "$unit"
            return $?
        fi
        return 1
    fi

    if [[ -n "$container" && "$MACHINE" == "Linux" && $(dtk_has_cmd docker; echo $?) -eq 0 ]]; then
        local name
        name="$(docker inspect --format '{{.Name}}' "$container" 2>/dev/null | sed 's#^/##' || true)"
        local target="${name:-$container}"
        if [[ "$YES" = "1" ]] || dtk_ui_confirm "$NO_UI" "Parar container Docker '$target' (porta $port)?" ; then
            docker stop "$target"
            return $?
        fi
        return 1
    fi

    kill_pid_gracefully "$pid" 1
}

# Monitoramento amigável
monitor_port() {
    local porta="$1"
    echo "🖥️  Sistema: $MACHINE"
    echo "🐳 Docker: $([ "$DOCKER_AVAILABLE" == "true" ] && echo "Disponível" || echo "Não disponível")"
    echo
    
    while true; do
        clear
        echo "🖥️  Sistema: $MACHINE | 🐳 Docker: $([ "$DOCKER_AVAILABLE" == "true" ] && echo "✅" || echo "❌")"
        echo "⏳ Monitorando porta $porta"
        
        ocupado=$(run_lsof -i :$porta -P -n 2>/dev/null)
        if [ -z "$ocupado" ]; then
            echo "✅ Porta $porta está LIVRE"
        else
            echo "❌ Porta $porta está OCUPADA:"
            echo "$ocupado" | awk '{print $1, $2, $3, $9, $NF}' | format_table
        fi
        echo
        echo "🔄 Atualizando a cada 2 segundos... (Pressione [q] para sair)"
        
        # Tratamento diferente para macOS e Linux no read com timeout
        if [[ "$MACHINE" == "macOS" ]]; then
            read -t 2 -n 1 key 2>/dev/null || true
        else
            read -t 2 -n 1 key
        fi
        
        if [[ $key == "q" ]]; then
            break
        fi
    done
}

# Verificar se porta está livre
check_ports() {
    local porta=$(gum input --placeholder "Digite a(s) porta(s) separadas por espaço")
    [[ -z "$porta" ]] && return 0

    for p in $porta; do
        ocupado=$(run_lsof -i :$p -P -n 2>/dev/null)
        if [ -z "$ocupado" ]; then
            echo "✅ Porta $p está LIVRE"
        else
            echo "❌ Porta $p está OCUPADA:"
            echo "$ocupado" | awk '{print $1, $2, $3, $9, $NF}' | format_table
        fi
    done

    if gum confirm "Deseja monitorar alguma dessas portas?"; then
        local p=$(gum input --placeholder "Digite a porta para monitorar")
        [[ -n "$p" ]] && monitor_port "$p"
    fi
}

# Função interativa usando gum
interactive_list() {
    local linhas
    linhas="$(list_ports)"

    if [[ -z "$linhas" ]]; then
        echo "❌ Nenhuma porta LISTEN encontrada."
        return
    fi

    if ! dtk_ui_available "$NO_UI"; then
        echo "$linhas" | awk -F'\t' '{printf "%s/%s pid=%s user=%s cmd=%s\n",$1,$2,$3,$4,$5}'
        return
    fi

    local menu
    menu="$(echo "$linhas" | awk -F'\t' '{printf "%s/%s\tpid=%s\tuser=%s\tcmd=%s\n",$1,$2,$3,$4,$5}')"
    local selection
    selection="$(echo "$menu" | gum choose --header="🖥️ $MACHINE | Selecione uma porta")"
    [[ -z "$selection" ]] && return

    local port
    port="$(echo "$selection" | awk '{print $1}' | awk -F'/' '{print $2}')"
    show_port_status "$port"

    local action
    action="$(gum choose "⛔ Parar (systemd/docker/kill)" "ℹ️  Status" "↩️  Voltar")"
    case "$action" in
        "⛔ Parar"*) stop_port "$port" ;;
        "ℹ️  Status"*) show_port_status "$port" ;;
        *) return ;;
    esac
}

LIST=0
SHOW_PORT=""
STOP_PORT=""
KILL_PID=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-ui) NO_UI=1; shift ;;
        --yes) YES=1; shift ;;
        --list) LIST=1; shift ;;
        --port) SHOW_PORT="${2:-}"; shift 2 ;;
        --stop-port) STOP_PORT="${2:-}"; shift 2 ;;
        --kill-pid) KILL_PID="${2:-}"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) dtk_die "Argumento desconhecido: $1" ;;
    esac
done

if [[ "$LIST" = "1" ]]; then
    list_ports | while IFS= read -r line; do enrich_listener_line "$line"; done | awk -F'\t' 'BEGIN{
        printf "%-5s %-6s %-8s %-12s %-18s %-14s %-22s %-14s\n","PROTO","PORT","PID","USER","CMD","SERVICE","SYSTEMD","DOCKER"
    }{
        printf "%-5s %-6s %-8s %-12s %-18s %-14s %-22s %-14s\n",$1,$2,$3,$4,$5,($6==""?"-":$6),($7==""?"-":$7),($8==""?"-":substr($8,1,12))
    }'
    exit 0
fi

if [[ -n "$SHOW_PORT" ]]; then
    show_port_status "$SHOW_PORT"
    exit 0
fi

if [[ -n "$STOP_PORT" ]]; then
    stop_port "$STOP_PORT"
    exit $?
fi

if [[ -n "$KILL_PID" ]]; then
    kill_pid_gracefully "$KILL_PID" 1
    exit $?
fi

echo "🖥️  Port Checker - Sistema: $MACHINE"
echo

if dtk_ui_available "$NO_UI"; then
    while true; do
        opcao=$(gum choose "📜 Listar/Selecionar porta" "🔍 Verificar porta(s)" "🚦 Monitorar porta" "🚪 Sair")
        case "$opcao" in
            "📜 Listar/Selecionar porta") interactive_list ;;
            "🔍 Verificar porta(s)")
                if dtk_has_cmd gum; then
                    check_ports
                else
                    p="$(dtk_ui_input "$NO_UI" "Digite a(s) porta(s) separadas por espaço" "")"
                    [[ -n "$p" ]] && for x in $p; do show_port_status "$x"; done
                fi
                ;;
            "🚦 Monitorar porta")
                porta=$(gum input --placeholder "Digite a porta para monitorar")
                [[ -n "$porta" ]] && monitor_port "$porta"
                ;;
            "🚪 Sair") exit 0 ;;
        esac
    done
else
    usage
fi

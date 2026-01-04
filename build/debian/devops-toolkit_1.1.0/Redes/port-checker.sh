#!/bin/bash

# Detecta o sistema operacional
OS="$(uname -s)"
case "${OS}" in
    Linux*)     MACHINE=Linux;;
    Darwin*)    MACHINE=macOS;;
    *)          MACHINE="UNKNOWN:${OS}"
esac

# Verifica se os comandos essenciais estão instalados
for cmd in lsof gum; do
    if ! command -v $cmd &>/dev/null; then
        echo "Erro: '$cmd' não está instalado."
        if [[ "$MACHINE" == "macOS" ]]; then
            echo "Para instalar no macOS: brew install $cmd"
        fi
        exit 1
    fi
done

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
    run_lsof -i -P -n | grep LISTEN | \
    awk '{printf "%-8s %-10s %-10s %-6s %-20s\n", $1, $2, $3, $9, $NF}' | \
    sort -u
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
    local linhas=$(list_ports)

    if [[ -z "$linhas" ]]; then
        gum style --foreground 1 "❌ Nenhuma porta LISTEN encontrada."
        sleep 2
        return
    fi

    local selection=$(echo "$linhas" | gum choose --no-limit --header="🖥️ $MACHINE | 🐳 Docker: $([ "$DOCKER_AVAILABLE" == "true" ] && echo "✅" || echo "❌") | Selecione uma ou mais portas para detalhes")
    [[ -z "$selection" ]] && return

    IFS=$'\n'
    for linha in $selection; do
        local pid=$(echo "$linha" | awk '{print $2}')
        [[ -z "$pid" ]] && continue

        local info=$(get_process_info "$pid")
        local cname=""
        
        if [[ "$DOCKER_AVAILABLE" == "true" ]]; then
            cname=$(get_docker_container_name "$pid")
        fi

        echo "=========================="
        echo "🆔 Processo: $info"
        if [ -n "$cname" ]; then
            echo "🐳 Container Docker: $cname"
        fi
        echo "=========================="
        echo
    done

    unset IFS

    gum confirm "Deseja retornar ao menu?" || exit 0
}

# Loop principal
echo "🖥️  Port Checker - Sistema: $MACHINE"
echo "🐳 Docker: $([ "$DOCKER_AVAILABLE" == "true" ] && echo "Disponível" || echo "Não disponível")"
echo

while true; do
    opcao=$(gum choose "📜 Listar portas e processos" "🔍 Verificar se porta(s) estão livres" "🚦 Monitorar porta" "🚪 Sair")

    case "$opcao" in
    "📜 Listar portas e processos")
        interactive_list
        ;;
    "🔍 Verificar se porta(s) estão livres")
        check_ports
        ;;
    "🚦 Monitorar porta")
        porta=$(gum input --placeholder "Digite a porta para monitorar")
        [[ -n "$porta" ]] && monitor_port "$porta"
        ;;
    "🚪 Sair")
        echo "👋 Obrigado por usar o Port Checker!"
        exit 0
        ;;
    esac
done

#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../common/cli.sh
source "$SCRIPT_DIR/../common/cli.sh"

# SSH is mandatory; gum is optional (UI only).
if ! dtk_has_cmd ssh; then
    dtk_die "Erro: 'ssh' não está instalado."
fi

# Verifica disponibilidade de comandos opcionais
HAS_SSHFS=false
HAS_SCP=true
HAS_RSYNC=false

if command -v sshfs &>/dev/null; then
    HAS_SSHFS=true
fi

if command -v rsync &>/dev/null; then
    HAS_RSYNC=true
fi

# Arquivo de configuração para salvar conexões
CONFIG_FILE="$HOME/.ssh_manager_config"
# Arquivo de histórico de dispositivos de rede (compartilhado com network-config-checker)
DEVICE_HISTORY="$HOME/.network_devices_history"
# Arquivo de histórico de conexões recentes
RECENT_CONNECTIONS="$HOME/.ssh_recent_connections"

# Função para listar dispositivos descobertos na rede
list_network_devices() {
    echo "🌐 Dispositivos Descobertos na Rede"
    echo "=================================="
    
    if [[ ! -f "$DEVICE_HISTORY" ]] || [[ ! -s "$DEVICE_HISTORY" ]]; then
        echo "❌ Nenhum dispositivo descoberto no histórico"
        echo "💡 Execute o Network Config Checker para escanear a rede"
        echo "💡 Comando: ./network-config-checker.sh"
        return 0
    fi
    
    echo "📋 Dispositivos encontrados recentemente:"
    echo "------------------------------------------"
    printf "%-15s %-18s %-20s %s\n" "IP" "MAC Address" "Fabricante" "Última Vista"
    echo "------------------------------------------"
    
    # Lista os últimos 15 dispositivos descobertos
    sort -t'|' -k4 -r "$DEVICE_HISTORY" | head -15 | while IFS='|' read -r ip mac vendor timestamp; do
        printf "%-15s %-18s %-20s %s\n" "$ip" "$mac" "$vendor" "$timestamp"
    done
    
    echo "------------------------------------------"
    echo "📊 Total de dispositivos únicos: $(cut -d'|' -f1 "$DEVICE_HISTORY" | sort | uniq | wc -l)"
    echo
}

# Função para sugerir hosts baseado no histórico
suggest_hosts() {
    local suggestions=()
    
    # Adiciona dispositivos da rede local
    if [[ -f "$DEVICE_HISTORY" ]]; then
        while IFS='|' read -r ip mac vendor timestamp; do
            # Filtra dispositivos que podem ser servidores (excluindo roteadores comuns)
            if [[ "$vendor" != *"Router"* ]] && [[ "$vendor" != *"Gateway"* ]]; then
                suggestions+=("$ip ($vendor)")
            fi
        done < <(sort -t'|' -k4 -r "$DEVICE_HISTORY" | head -10)
    fi
    
    # Adiciona conexões recentes
    if [[ -f "$RECENT_CONNECTIONS" ]]; then
        while IFS='|' read -r timestamp ip user port; do
            suggestions+=("$ip [Recente: $user@$ip:$port]")
        done < <(head -5 "$RECENT_CONNECTIONS")
    fi
    
    # Adiciona conexões salvas
    if [[ -f "$CONFIG_FILE" ]]; then
        while IFS='|' read -r name user host port key_path; do
            suggestions+=("$host [Salvo: $name]")
        done < "$CONFIG_FILE"
    fi
    
    # IPs comuns para desenvolvimento
    suggestions+=(
        "127.0.0.1 (localhost)"
        "192.168.1.1 (Gateway comum)"
        "192.168.0.1 (Gateway alternativo)"
        "10.0.0.1 (Gateway privado)"
    )
    
    printf '%s\n' "${suggestions[@]}" | sort | uniq
}

# Função para registrar conexão recente
register_recent_connection() {
    local ip="$1"
    local user="$2"
    local port="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    dtk_assert_no_pipe "host" "$ip"
    dtk_assert_no_pipe "user" "$user"
    dtk_assert_no_pipe "port" "$port"

    local existing=""
    if [[ -f "$RECENT_CONNECTIONS" ]]; then
        existing="$(cat "$RECENT_CONNECTIONS" 2>/dev/null || true)"
    fi

    # Remove entradas antigas do mesmo IP+user+port, adiciona nova e mantém só as últimas 20.
    local updated
    updated="$(printf "%s\n" "$existing" | grep -v "^.*|${ip//\//\\/}|${user//\//\\/}|${port//\//\\/}$" 2>/dev/null || true)"
    updated="$(printf "%s\n%s|%s|%s|%s\n" "$updated" "$timestamp" "$ip" "$user" "$port" | sed '/^$/d' | tail -n 20)"
    dtk_atomic_write "$RECENT_CONNECTIONS" "$updated"$'\n'
}

ssh_build_cmd() {
    # Outputs a shell-escaped printable representation on stdout; command array via global SSH_CMD.
    local host="$1"
    local user="$2"
    local port="$3"
    local key_path="${4:-}"

    local connect_timeout="${DTK_SSH_CONNECT_TIMEOUT:-10}"
    local alive_interval="${DTK_SSH_SERVER_ALIVE_INTERVAL:-30}"
    local alive_count="${DTK_SSH_SERVER_ALIVE_COUNT_MAX:-3}"

    SSH_CMD=(ssh
        -o "ConnectTimeout=${connect_timeout}"
        -o "ServerAliveInterval=${alive_interval}"
        -o "ServerAliveCountMax=${alive_count}"
    )

    if [[ -n "$key_path" ]]; then
        SSH_CMD+=(-i "$key_path")
    fi
    if [[ -n "$port" && "$port" != "22" ]]; then
        SSH_CMD+=(-p "$port")
    fi
    SSH_CMD+=("${user}@${host}")
}

ssh_run() {
    local host="$1"
    local user="$2"
    local port="$3"
    local key_path="${4:-}"
    local dry_run="${5:-0}"

    ssh_build_cmd "$host" "$user" "$port" "$key_path"

    echo "🚀 Executando:"
    printf '   '
    printf '%q ' "${SSH_CMD[@]}"
    echo

    if [[ "$dry_run" = "1" ]]; then
        return 0
    fi

    "${SSH_CMD[@]}"
}

# Função para listar chaves SSH disponíveis (busca recursiva)
list_ssh_keys() {
    echo "🔑 Chaves SSH disponíveis:"
    echo "========================="
    
    if [ ! -d "$HOME/.ssh" ]; then
        echo "❌ Diretório ~/.ssh não encontrado"
        return 1
    fi
    
    keys_found=false
    
    # Busca recursiva por chaves públicas
    while IFS= read -r -d '' key; do
        if [ -f "$key" ]; then
            keys_found=true
            private_key="${key%.pub}"
            
            # Calcula o caminho relativo para exibição mais limpa
            relative_path="${key#$HOME/.ssh/}"
            relative_private="${private_key#$HOME/.ssh/}"
            
            key_type=$(ssh-keygen -l -f "$key" 2>/dev/null | awk '{print $4}' | tr -d '()')
            key_bits=$(ssh-keygen -l -f "$key" 2>/dev/null | awk '{print $1}')
            
            # Identifica se está em subdiretório
            if [[ "$relative_path" == *"/"* ]]; then
                subdir=$(dirname "$relative_path")
                echo "🗂️  Pasta: $subdir"
                echo "🔐 Chave: $(basename "$relative_private")"
            else
                echo "🔐 Chave: $(basename "$relative_private")"
            fi
            
            echo "   Tipo: $key_type"
            echo "   Bits: $key_bits"
            echo "   Pública: ~/.ssh/$relative_path"
            echo "   Privada: ~/.ssh/$relative_private"
            echo
        fi
    done < <(find "$HOME/.ssh" -name "*.pub" -type f -print0)
    
    if [ "$keys_found" = false ]; then
        echo "❌ Nenhuma chave SSH encontrada em ~/.ssh/"
        echo "💡 Para gerar uma nova chave: ssh-keygen -t rsa -b 4096 -C \"seu@email.com\""
        echo "💡 Para organizar em subdiretórios: mkdir ~/.ssh/projeto && ssh-keygen -f ~/.ssh/projeto/id_rsa"
    fi
}

# Função para conectar via SSH
ssh_connect() {
    echo "🔗 Conectar via SSH"
    echo "=================="
    
    # Mostra sugestões de hosts
    local suggestions=()
    while IFS= read -r line; do
        suggestions+=("$line")
    done < <(suggest_hosts)
    
    if [[ ${#suggestions[@]} -gt 0 ]]; then
        echo "💭 Sugestões baseadas no histórico:"
        use_suggestion=$(gum confirm "Ver sugestões de hosts?" && echo "yes" || echo "no")
        
        if [[ "$use_suggestion" == "yes" ]]; then
            suggestions+=("📝 Digitar manualmente")
            selected_host=$(printf '%s\n' "${suggestions[@]}" | gum choose --header="Selecione um host ou digite manualmente")
            
            if [[ "$selected_host" == "📝 Digitar manualmente" ]] || [[ -z "$selected_host" ]]; then
                host=$(gum input --placeholder "Digite o host/IP (ex: 192.168.1.100)")
            else
                # Extrai o IP da sugestão
                host=$(echo "$selected_host" | awk '{print $1}')
                echo "🎥 Host selecionado: $host"
            fi
        else
            host=$(gum input --placeholder "Digite o host/IP (ex: 192.168.1.100)")
        fi
    else
        host=$(gum input --placeholder "Digite o host/IP (ex: 192.168.1.100)")
    fi
    
    [[ -z "$host" ]] && return 0
    
    user=$(gum input --placeholder "Digite o usuário (padrão: $(whoami))" --value "$(whoami)")
    port=$(gum input --placeholder "Digite a porta (padrão: 22)" --value "22")
    
    # Pergunta sobre chave específica
    use_key=$(gum confirm "Usar chave SSH específica?" && echo "yes" || echo "no")
    
    key_path=""
    if [ "$use_key" = "yes" ]; then
        # Lista chaves disponíveis para seleção (busca recursiva)
        if [ -d "$HOME/.ssh" ]; then
            keys=()
            key_paths=()
            
            # Busca recursiva por chaves privadas
            while IFS= read -r key; do
                if [ -f "$key" ] && [ -f "${key}.pub" ]; then
                    relative_path="${key#$HOME/.ssh/}"
                    if [[ "$relative_path" == *"/"* ]]; then
                        subdir=$(dirname "$relative_path")
                        display_name="$subdir/$(basename "$key")"
                    else
                        display_name="$(basename "$key")"
                    fi
                    keys+=("$display_name")
                    key_paths+=("$key")
                fi
            done < <(find "$HOME/.ssh" -type f ! -name "*.pub" ! -name "known_hosts*" ! -name "config*" ! -name "authorized_keys*")
            
            if [ ${#keys[@]} -gt 0 ]; then
                echo "🔑 Chaves disponíveis:"
                selected_key=$(gum choose "${keys[@]}")
                
                # Encontra o caminho completo da chave selecionada
                for i in "${!keys[@]}"; do
                    if [[ "${keys[$i]}" = "$selected_key" ]]; then
                        key_path="${key_paths[$i]}"
                        break
                    fi
                done
            else
                key_path=$(gum input --placeholder "Digite o caminho da chave privada")
            fi
        else
            key_path=$(gum input --placeholder "Digite o caminho da chave privada")
        fi
    fi
    
    # Salva a configuração se solicitado (bloqueia pipes pois usamos '|' como delimitador).
    dtk_assert_no_pipe "connection_name" "${connection_name:-}"
    dtk_assert_no_pipe "user" "$user"
    dtk_assert_no_pipe "host" "$host"
    dtk_assert_no_pipe "port" "$port"
    dtk_assert_no_pipe "key_path" "$key_path"
    
    # Salva a configuração se solicitado
    if gum confirm "Salvar esta configuração para uso futuro?"; then
        connection_name=$(gum input --placeholder "Nome para esta conexão")
        if [ -n "$connection_name" ]; then
            dtk_assert_no_pipe "connection_name" "$connection_name"
            # Append de forma atômica.
            local existing=""
            [[ -f "$CONFIG_FILE" ]] && existing="$(cat "$CONFIG_FILE" 2>/dev/null || true)"
            local updated
            updated="$(printf "%s\n%s|%s|%s|%s|%s\n" "$existing" "$connection_name" "$user" "$host" "$port" "$key_path" | sed '/^$/d')"
            dtk_atomic_write "$CONFIG_FILE" "$updated"$'\n'
            echo "✅ Configuração salva como: $connection_name"
        fi
    fi
    
    # Registra conexão no histórico
    register_recent_connection "$host" "$user" "$port"
    
    # Executa a conexão SSH interativa
    ssh_run "$host" "$user" "$port" "$key_path" 0
    ssh_exit_code=$?
    
    if [ $ssh_exit_code -eq 0 ]; then
        echo "\n✅ Conexão SSH finalizada com sucesso"
    else
        echo "\n❌ Conexão SSH finalizada com erro (código: $ssh_exit_code)"
    fi
}

# Função para usar conexão salva
use_saved_connection() {
    if [ ! -f "$CONFIG_FILE" ] || [ ! -s "$CONFIG_FILE" ]; then
        echo "❌ Nenhuma conexão salva encontrada"
        echo "💡 Use 'Conectar via SSH' para criar uma nova conexão"
        return 1
    fi
    
    echo "📋 Conexões salvas:"
    echo "=================="
    
    # Prepara lista para gum
    connections=()
    while IFS='|' read -r name user host port key_path; do
        # Pula linhas vazias
        [[ -z "$name" ]] && continue
        
        display_text="$name ($user@$host:$port)"
        if [ -n "$key_path" ] && [ "$key_path" != "" ]; then
            display_text="$display_text [🔑 $(basename "$key_path")]"
        fi
        connections+=("$display_text")
    done < "$CONFIG_FILE"
    
    if [ ${#connections[@]} -eq 0 ]; then
        echo "❌ Nenhuma conexão válida encontrada no arquivo"
        echo "💡 Verifique o arquivo: $CONFIG_FILE"
        return 1
    fi
    
    echo "🔗 Selecione uma conexão:"
    selected=$(gum choose "${connections[@]}")
    [[ -z "$selected" ]] && return 1
    
    # Extrai o nome da conexão selecionada (antes do primeiro parênteses)
    connection_name=$(echo "$selected" | sed 's/ (.*$//' | xargs)
    
    echo "🔍 Procurando configuração para: '$connection_name'"
    
    # Busca a configuração correspondente
    found=false
    found_user=""
    found_host=""
    found_port=""
    found_key_path=""
    found_name=""
    
    while IFS='|' read -r name user host port key_path; do
        # Pula linhas vazias
        [[ -z "$name" ]] && continue
        
        if [ "$name" = "$connection_name" ]; then
            found=true
            found_name="$name"
            found_user="$user"
            found_host="$host"
            found_port="$port"
            found_key_path="$key_path"
            break
        fi
    done < "$CONFIG_FILE"
    
    if [ "$found" = false ]; then
        echo "❌ Configuração não encontrada para: '$connection_name'"
        echo "💡 Verifique se o nome está correto no arquivo: $CONFIG_FILE"
        return 1
    fi
    
    # Agora que encontramos a configuração, processamos fora do loop
    echo "✅ Configuração encontrada!"
    echo "   Nome: $found_name"
    echo "   Usuário: $found_user"
    echo "   Host: $found_host"
    echo "   Porta: $found_port"
    if [ -n "$found_key_path" ] && [ "$found_key_path" != "" ]; then
        echo "   Chave: $found_key_path"
    fi
    echo
    
    # Valida se a chave existe
    if [ -n "$found_key_path" ] && [ "$found_key_path" != "" ] && [ ! -f "$found_key_path" ]; then
        echo "⚠️  Chave SSH não encontrada: $found_key_path"
        echo "🔍 Chaves disponíveis em ~/.ssh/:"
        find "$HOME/.ssh" -name "*.pem" -o -name "id_*" ! -name "*.pub" 2>/dev/null | head -5
        echo "💭 Conectando sem chave específica..."
        found_key_path=""
    fi
    
    # Executa a conexão SSH interativa (FORA DO LOOP)
    ssh_run "$found_host" "$found_user" "$found_port" "$found_key_path" 0
    ssh_exit_code=$?
    
    if [ $ssh_exit_code -eq 0 ]; then
        echo "✅ Conexão SSH finalizada com sucesso"
    else
        echo "❌ Conexão SSH finalizada com erro (código: $ssh_exit_code)"
    fi
}

# Função para copiar arquivos via SCP/RSYNC
copy_files() {
    echo "📁 Copiar arquivos via SSH"
    echo "=========================="
    
    # Escolhe método de cópia
    copy_methods=("scp")
    if [ "$HAS_RSYNC" = true ]; then
        copy_methods+=("rsync")
    fi
    
    method=$(gum choose "${copy_methods[@]}")
    [[ -z "$method" ]] && return 0
    
    # Escolhe direção
    direction=$(gum choose "Local → Remoto" "Remoto → Local")
    [[ -z "$direction" ]] && return 0
    
    # Coleta informações de conexão
    host=$(gum input --placeholder "Digite o host/IP")
    [[ -z "$host" ]] && return 0
    
    user=$(gum input --placeholder "Digite o usuário (padrão: $(whoami))" --value "$(whoami)")
    port=$(gum input --placeholder "Digite a porta (padrão: 22)" --value "22")
    
    # Chave SSH
    use_key=$(gum confirm "Usar chave SSH específica?" && echo "yes" || echo "no")
    key_path=""
    if [ "$use_key" = "yes" ]; then
        key_path=$(gum input --placeholder "Digite o caminho da chave privada")
    fi
    
    if [ "$direction" = "Local → Remoto" ]; then
        source_path=$(gum input --placeholder "Caminho local do arquivo/pasta")
        dest_path=$(gum input --placeholder "Caminho remoto de destino")
        
        if [ "$method" = "scp" ]; then
            cmd="scp -r"
            if [ "$port" != "22" ]; then
                cmd="$cmd -P $port"
            fi
            if [ -n "$key_path" ]; then
                cmd="$cmd -i $key_path"
            fi
            cmd="$cmd \"$source_path\" $user@$host:\"$dest_path\""
        else
            cmd="rsync -avz"
            if [ "$port" != "22" ]; then
                cmd="$cmd -e 'ssh -p $port'"
            fi
            if [ -n "$key_path" ]; then
                cmd="$cmd -e 'ssh -i $key_path'"
            fi
            cmd="$cmd \"$source_path\" $user@$host:\"$dest_path\""
        fi
    else
        source_path=$(gum input --placeholder "Caminho remoto do arquivo/pasta")
        dest_path=$(gum input --placeholder "Caminho local de destino")
        
        if [ "$method" = "scp" ]; then
            cmd="scp -r"
            if [ "$port" != "22" ]; then
                cmd="$cmd -P $port"
            fi
            if [ -n "$key_path" ]; then
                cmd="$cmd -i $key_path"
            fi
            cmd="$cmd $user@$host:\"$source_path\" \"$dest_path\""
        else
            cmd="rsync -avz"
            if [ "$port" != "22" ]; then
                cmd="$cmd -e 'ssh -p $port'"
            fi
            if [ -n "$key_path" ]; then
                cmd="$cmd -e 'ssh -i $key_path'"
            fi
            cmd="$cmd $user@$host:\"$source_path\" \"$dest_path\""
        fi
    fi
    
    echo "🚀 Executando: $cmd"
    echo "=================="
    
    if gum confirm "Executar este comando?"; then
        eval "$cmd"
    fi
}

# Função para montar diretório via SSHFS
mount_sshfs() {
    if [ "$HAS_SSHFS" = false ]; then
        echo "❌ SSHFS não está instalado"
        echo "Para instalar:"
        echo "  macOS: brew install macfuse && brew install gromgit/fuse/sshfs-mac"
        echo "  Linux: sudo apt install sshfs  # ou sudo yum install fuse-sshfs"
        return 1
    fi
    
    echo "🗂️  Montar diretório via SSHFS"
    echo "=============================="
    
    action=$(gum choose "Montar diretório" "Desmontar diretório" "Listar montagens")
    
    case "$action" in
    "Montar diretório")
        # Coleta informações
        host=$(gum input --placeholder "Digite o host/IP")
        [[ -z "$host" ]] && return 0
        
        user=$(gum input --placeholder "Digite o usuário (padrão: $(whoami))" --value "$(whoami)")
        port=$(gum input --placeholder "Digite a porta (padrão: 22)" --value "22")
        remote_path=$(gum input --placeholder "Caminho remoto (padrão: /)" --value "/")
        local_mount=$(gum input --placeholder "Ponto de montagem local")
        [[ -z "$local_mount" ]] && return 0
        
        # Chave SSH
        use_key=$(gum confirm "Usar chave SSH específica?" && echo "yes" || echo "no")
        key_path=""
        if [ "$use_key" = "yes" ]; then
            key_path=$(gum input --placeholder "Digite o caminho da chave privada")
        fi
        
        # Cria diretório de montagem se não existir
        if [ ! -d "$local_mount" ]; then
            echo "📁 Criando diretório: $local_mount"
            mkdir -p "$local_mount"
        fi
        
        # Monta comando SSHFS
        sshfs_cmd=(sshfs "${user}@${host}:${remote_path}" "$local_mount")
        
        if [ "$port" != "22" ]; then
            sshfs_cmd+=(-p "$port")
        fi
        
        if [ -n "$key_path" ]; then
            sshfs_cmd+=(-o "IdentityFile=$key_path")
        fi
        
        # Opções adicionais baseadas no sistema operacional
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS - usa macFUSE
            sshfs_cmd+=(-o "allow_other,defer_permissions")
        else
            # Linux - usa FUSE
            sshfs_cmd+=(-o "allow_other,reconnect")
        fi
        
        echo "🚀 Executando:"
        printf '   '
        printf '%q ' "${sshfs_cmd[@]}"
        echo
        "${sshfs_cmd[@]}"
        
        if [ $? -eq 0 ]; then
            echo "✅ Diretório montado com sucesso em: $local_mount"
            echo "💡 Para desmontar: fusermount -u $local_mount (Linux) ou umount $local_mount (macOS)"
        else
            echo "❌ Erro ao montar diretório"
            echo ""
            echo "💡 Possíveis soluções:"
            if [[ "$OSTYPE" == "darwin"* ]]; then
                echo "   • Instale macFUSE: brew install --cask macfuse"
                echo "   • Instale sshfs: brew install gromgit/fuse/sshfs-mac"
            else
                echo "   • Instale sshfs: sudo apt install sshfs (Ubuntu/Debian)"
                echo "   • Verifique se o usuário está no grupo 'fuse': sudo usermod -a -G fuse $USER"
                echo "   • Tente sem allow_other: remova a opção -o allow_other"
            fi
            echo "   • Verifique se o servidor SSH está acessível: ssh $user@$host"
            echo "   • Crie o diretório local se necessário: mkdir -p $local_mount"
        fi
        ;;
        
    "Desmontar diretório")
        mount_point=$(gum input --placeholder "Caminho do ponto de montagem")
        [[ -z "$mount_point" ]] && return 0
        
        if [[ "$OSTYPE" == "darwin"* ]]; then
            umount_cmd="umount $mount_point"
        else
            umount_cmd="fusermount -u $mount_point"
        fi
        
        echo "🚀 Executando: $umount_cmd"
        eval "$umount_cmd"
        
        if [ $? -eq 0 ]; then
            echo "✅ Diretório desmontado com sucesso"
        else
            echo "❌ Erro ao desmontar diretório"
        fi
        ;;
        
    "Listar montagens")
        echo "📋 Montagens SSHFS ativas:"
        echo "========================="
        
        if [[ "$OSTYPE" == "darwin"* ]]; then
            mount | grep sshfs
        else
            mount -t fuse.sshfs
        fi
        ;;
    esac
}

# -------- CLI flags (non-interactive) --------
show_help() {
    cat <<EOF
SSH Manager

Uso:
  $0                    # modo interativo (requer gum)
  $0 --list-saved
  $0 --saved <nome>
  $0 --connect --host <ip/host> [--user <u>] [--port <p>] [--key <path>] [--dry-run] [--no-ui]

Flags:
  --connect             Conecta usando parâmetros informados
  --host <host>         Host/IP
  --user <user>         Usuário (default: \$(whoami))
  --port <port>         Porta (default: 22)
  --key <path>          Caminho da chave privada (opcional)
  --list-saved          Lista conexões salvas
  --saved <nome>        Conecta usando uma conexão salva pelo nome
  --dry-run             Não executa, apenas mostra o comando
  --no-ui               Força modo texto (não usa gum)
  -h, --help            Ajuda

Env:
  DTK_SSH_CONNECT_TIMEOUT=10
  DTK_SSH_SERVER_ALIVE_INTERVAL=30
  DTK_SSH_SERVER_ALIVE_COUNT_MAX=3
EOF
}

list_saved_cli() {
    if [[ ! -f "$CONFIG_FILE" || ! -s "$CONFIG_FILE" ]]; then
        echo "Nenhuma conexão salva."
        return 0
    fi
    cat "$CONFIG_FILE"
}

connect_saved_by_name() {
    local name="$1"
    if [[ ! -f "$CONFIG_FILE" || ! -s "$CONFIG_FILE" ]]; then
        dtk_die "Nenhuma conexão salva em $CONFIG_FILE"
    fi
    local line
    line="$(grep -F "^${name}|" "$CONFIG_FILE" | tail -n 1 || true)"
    if [[ -z "$line" ]]; then
        dtk_die "Conexão não encontrada: $name"
    fi
    local found_name found_user found_host found_port found_key
    IFS='|' read -r found_name found_user found_host found_port found_key <<<"$line"
    ssh_run "$found_host" "$found_user" "${found_port:-22}" "${found_key:-}" 0
}

connect_cli() {
    local host="$1"
    local user="$2"
    local port="$3"
    local key="$4"
    local dry_run="$5"
    [[ -z "$host" ]] && dtk_die "--host é obrigatório"
    ssh_run "$host" "${user:-$(whoami)}" "${port:-22}" "$key" "$dry_run"
}

NO_UI=0
DRY_RUN=0
DO_CONNECT=0
HOST=""
USER_ARG=""
PORT="22"
KEY_PATH=""
LIST_SAVED=0
SAVED_NAME=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-ui) NO_UI=1; shift ;;
        --dry-run) DRY_RUN=1; shift ;;
        --connect) DO_CONNECT=1; shift ;;
        --host) HOST="${2:-}"; shift 2 ;;
        --user) USER_ARG="${2:-}"; shift 2 ;;
        --port) PORT="${2:-}"; shift 2 ;;
        --key) KEY_PATH="${2:-}"; shift 2 ;;
        --list-saved) LIST_SAVED=1; shift ;;
        --saved) SAVED_NAME="${2:-}"; shift 2 ;;
        -h|--help) show_help; exit 0 ;;
        *) dtk_die "Argumento desconhecido: $1" ;;
    esac
done

if [[ "$LIST_SAVED" = "1" ]]; then
    list_saved_cli
    exit 0
fi

if [[ -n "$SAVED_NAME" ]]; then
    connect_saved_by_name "$SAVED_NAME"
    exit 0
fi

if [[ "$DO_CONNECT" = "1" ]]; then
    connect_cli "$HOST" "$USER_ARG" "$PORT" "$KEY_PATH" "$DRY_RUN"
    exit $?
fi

# Default: interactive UI
if ! dtk_ui_available "$NO_UI"; then
    show_help
    dtk_warn "Para modo interativo, instale 'gum' ou use flags (ex.: --connect ...)."
    exit 1
fi

# Função para gerenciar chaves SSH
manage_ssh_keys() {
    echo "🔑 Gerenciar chaves SSH"
    echo "======================"
    
    action=$(gum choose "Listar chaves" "Gerar nova chave" "Copiar chave pública" "Testar chave")
    
    case "$action" in
    "Listar chaves")
        list_ssh_keys
        ;;
        
    "Gerar nova chave")
        # Pergunta sobre organização em subdiretório
        use_subdir=$(gum confirm "Criar em subdiretório? (recomendado para organização)" && echo "yes" || echo "no")
        
        subdir_path=""
        if [ "$use_subdir" = "yes" ]; then
            subdir_name=$(gum input --placeholder "Nome do subdiretório (ex: projeto, servidor)")
            if [ -n "$subdir_name" ]; then
                subdir_path="$HOME/.ssh/$subdir_name"
                mkdir -p "$subdir_path"
                echo "📁 Criando diretório: $subdir_path"
            fi
        fi
        
        key_name=$(gum input --placeholder "Nome da chave (ex: id_rsa, github_key)")
        [[ -z "$key_name" ]] && return 0
        
        key_type=$(gum choose "rsa" "ed25519" "ecdsa")
        email=$(gum input --placeholder "Seu email (opcional)")
        
        # Define o caminho completo da chave
        if [ -n "$subdir_path" ]; then
            full_key_path="$subdir_path/$key_name"
        else
            full_key_path="$HOME/.ssh/$key_name"
        fi
        
        ssh_keygen_cmd="ssh-keygen -t $key_type"
        
        if [ "$key_type" = "rsa" ]; then
            ssh_keygen_cmd="$ssh_keygen_cmd -b 4096"
        fi
        
        ssh_keygen_cmd="$ssh_keygen_cmd -f $full_key_path"
        
        if [ -n "$email" ]; then
            ssh_keygen_cmd="$ssh_keygen_cmd -C \"$email\""
        fi
        
        echo "🚀 Executando: $ssh_keygen_cmd"
        eval "$ssh_keygen_cmd"
        
        if [ $? -eq 0 ]; then
            echo "✅ Chave criada com sucesso!"
            echo "🔐 Privada: $full_key_path"
            echo "🔓 Pública: $full_key_path.pub"
        fi
        ;;
        
    "Copiar chave pública")
        if [ ! -d "$HOME/.ssh" ]; then
            echo "❌ Diretório ~/.ssh não encontrado"
            return 1
        fi
        
        keys=()
        key_paths=()
        
        # Busca recursiva por chaves públicas
        while IFS= read -r key; do
            if [ -f "$key" ]; then
                relative_path="${key#$HOME/.ssh/}"
                if [[ "$relative_path" == *"/"* ]]; then
                    subdir=$(dirname "$relative_path")
                    display_name="$subdir/$(basename "$key")"
                else
                    display_name="$(basename "$key")"
                fi
                keys+=("$display_name")
                key_paths+=("$key")
            fi
        done < <(find "$HOME/.ssh" -name "*.pub" -type f)
        
        if [ ${#keys[@]} -eq 0 ]; then
            echo "❌ Nenhuma chave pública encontrada"
            return 1
        fi
        
        selected_key=$(gum choose "${keys[@]}")
        [[ -z "$selected_key" ]] && return 0
        
        # Encontra o caminho completo da chave selecionada
        selected_key_path=""
        for i in "${!keys[@]}"; do
            if [[ "${keys[$i]}" = "$selected_key" ]]; then
                selected_key_path="${key_paths[$i]}"
                break
            fi
        done
        
        key_content=$(cat "$selected_key_path")
        echo "📋 Conteúdo da chave $selected_key copiado:"
        echo "=========================================="
        echo "$key_content"
        
        if command -v pbcopy &>/dev/null; then
            echo "$key_content" | pbcopy
            echo "✅ Chave copiada para a área de transferência (macOS)"
        elif command -v xclip &>/dev/null; then
            echo "$key_content" | xclip -selection clipboard
            echo "✅ Chave copiada para a área de transferência (Linux)"
        fi
        ;;
        
    "Testar chave")
        host=$(gum input --placeholder "Host para testar (ex: github.com)")
        [[ -z "$host" ]] && return 0
        
        key_path=$(gum input --placeholder "Caminho da chave privada")
        [[ -z "$key_path" ]] && return 0
        
        echo "🔍 Testando conexão..."
        ssh -T -i "$key_path" "$host"
        ;;
    esac
}

# Função principal de resumo
ssh_summary() {
    clear
    echo "📋 RESUMO DO SSH MANAGER"
    echo "========================"
    
    # Mostra informações do sistema
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "💻 Sistema: macOS"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "💻 Sistema: Linux"
    else
        echo "💻 Sistema: $OSTYPE"
    fi
    
    echo "🔧 Ferramentas disponíveis:"
    echo "   ✅ ssh"
    echo "   ✅ scp"
    
    if [ "$HAS_RSYNC" = true ]; then
        echo "   ✅ rsync"
    else
        echo "   ❌ rsync"
    fi
    
    if [ "$HAS_SSHFS" = true ]; then
        echo "   ✅ sshfs"
    else
        echo "   ❌ sshfs"
    fi
    
    echo
    
    # Lista chaves disponíveis
    list_ssh_keys
    
    # Mostra conexões salvas
    if [ -f "$CONFIG_FILE" ] && [ -s "$CONFIG_FILE" ]; then
        echo "💾 Conexões salvas:"
        echo "=================="
        while IFS='|' read -r name user host port key_path; do
            echo "🔗 $name: $user@$host:$port"
            if [ -n "$key_path" ]; then
                echo "   🔑 Chave: $(basename "$key_path")"
            fi
        done < "$CONFIG_FILE"
        echo
    fi
    
    gum confirm "Deseja retornar ao menu?" || exit 0
}

# Loop principal
while true; do
    opcao=$(gum choose \
        "📋 Resumo completo" \
        "🔗 Conectar via SSH" \
        "💾 Usar conexão salva" \
        "📁 Copiar arquivos (SCP/RSYNC)" \
        "🗂️  Montar/Desmontar SSHFS" \
        "🔑 Gerenciar chaves SSH" \
        "🚪 Sair")

    case "$opcao" in
    "📋 Resumo completo")
        ssh_summary
        ;;
    "🔗 Conectar via SSH")
        ssh_connect
        gum confirm "Deseja retornar ao menu?" || exit 0
        ;;
    "💾 Usar conexão salva")
        use_saved_connection
        gum confirm "Deseja retornar ao menu?" || exit 0
        ;;
    "📁 Copiar arquivos (SCP/RSYNC)")
        copy_files
        gum confirm "Deseja retornar ao menu?" || exit 0
        ;;
    "🗂️  Montar/Desmontar SSHFS")
        mount_sshfs
        gum confirm "Deseja retornar ao menu?" || exit 0
        ;;
    "🔑 Gerenciar chaves SSH")
        manage_ssh_keys
        gum confirm "Deseja retornar ao menu?" || exit 0
        ;;
    "🚪 Sair")
        exit 0
        ;;
    esac
done

#!/bin/bash

# Verifica se os comandos essenciais estão instalados
for cmd in gum ssh; do
    if ! command -v $cmd &>/dev/null; then
        echo "Erro: '$cmd' não está instalado."
        if [ "$cmd" = "gum" ]; then
            echo "Para instalar o gum:"
            echo "  macOS: brew install gum"
            echo "  Linux: https://github.com/charmbracelet/gum#installation"
        fi
        exit 1
    fi
done

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
    
    # Coleta informações
    host=$(gum input --placeholder "Digite o host/IP (ex: 192.168.1.100)")
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
            while IFS= read -r -d '' key; do
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
            done < <(find "$HOME/.ssh" -type f ! -name "*.pub" ! -name "known_hosts*" ! -name "config*" ! -name "authorized_keys*" -print0)
            
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
    
    # Monta o comando SSH
    ssh_cmd="ssh"
    
    if [ -n "$key_path" ]; then
        ssh_cmd="$ssh_cmd -i $key_path"
    fi
    
    if [ "$port" != "22" ]; then
        ssh_cmd="$ssh_cmd -p $port"
    fi
    
    ssh_cmd="$ssh_cmd $user@$host"
    
    echo "🚀 Executando: $ssh_cmd"
    echo "========================"
    
    # Salva a configuração se solicitado
    if gum confirm "Salvar esta configuração para uso futuro?"; then
        connection_name=$(gum input --placeholder "Nome para esta conexão")
        if [ -n "$connection_name" ]; then
            echo "$connection_name|$user|$host|$port|$key_path" >> "$CONFIG_FILE"
            echo "✅ Configuração salva!"
        fi
    fi
    
    # Executa a conexão
    eval "$ssh_cmd"
}

# Função para usar conexão salva
use_saved_connection() {
    if [ ! -f "$CONFIG_FILE" ] || [ ! -s "$CONFIG_FILE" ]; then
        echo "❌ Nenhuma conexão salva encontrada"
        return 0
    fi
    
    echo "📋 Conexões salvas:"
    echo "=================="
    
    # Prepara lista para gum
    connections=()
    while IFS='|' read -r name user host port key_path; do
        display_text="$name ($user@$host:$port)"
        if [ -n "$key_path" ]; then
            display_text="$display_text [🔑 $(basename "$key_path")]"
        fi
        connections+=("$display_text")
    done < "$CONFIG_FILE"
    
    if [ ${#connections[@]} -eq 0 ]; then
        echo "❌ Nenhuma conexão válida encontrada"
        return 0
    fi
    
    selected=$(gum choose "${connections[@]}")
    [[ -z "$selected" ]] && return 0
    
    # Extrai o nome da conexão selecionada
    connection_name=$(echo "$selected" | cut -d'(' -f1 | xargs)
    
    # Busca a configuração correspondente
    while IFS='|' read -r name user host port key_path; do
        if [ "$name" = "$connection_name" ]; then
            ssh_cmd="ssh"
            
            if [ -n "$key_path" ]; then
                ssh_cmd="$ssh_cmd -i $key_path"
            fi
            
            if [ "$port" != "22" ]; then
                ssh_cmd="$ssh_cmd -p $port"
            fi
            
            ssh_cmd="$ssh_cmd $user@$host"
            
            echo "🚀 Conectando: $ssh_cmd"
            eval "$ssh_cmd"
            return 0
        fi
    done < "$CONFIG_FILE"
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
        sshfs_cmd="sshfs $user@$host:$remote_path $local_mount"
        
        if [ "$port" != "22" ]; then
            sshfs_cmd="$sshfs_cmd -p $port"
        fi
        
        if [ -n "$key_path" ]; then
            sshfs_cmd="$sshfs_cmd -o IdentityFile=$key_path"
        fi
        
        # Opções adicionais
        sshfs_cmd="$sshfs_cmd -o allow_other,defer_permissions"
        
        echo "🚀 Executando: $sshfs_cmd"
        eval "$sshfs_cmd"
        
        if [ $? -eq 0 ]; then
            echo "✅ Diretório montado com sucesso em: $local_mount"
        else
            echo "❌ Erro ao montar diretório"
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
        while IFS= read -r -d '' key; do
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
        done < <(find "$HOME/.ssh" -name "*.pub" -type f -print0)
        
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

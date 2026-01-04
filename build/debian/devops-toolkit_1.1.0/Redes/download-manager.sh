#!/bin/bash

# Detecta o sistema operacional
OS="$(uname -s)"
case "${OS}" in
    Linux*)     MACHINE=Linux;;
    Darwin*)    MACHINE=macOS;;
    *)          MACHINE="UNKNOWN:${OS}"
esac

# Verifica se os comandos essenciais estão instalados
for cmd in gum; do
    if ! command -v $cmd &>/dev/null; then
        echo "Erro: '$cmd' não está instalado."
        if [[ "$MACHINE" == "macOS" ]]; then
            echo "Para instalar no macOS: brew install gum"
        else
            echo "Para instalar no Linux: https://github.com/charmbracelet/gum#installation"
        fi
        exit 1
    fi
done

# Verifica disponibilidade de ferramentas de download
HAS_CURL=false
HAS_WGET=false
HAS_ARIA2=false
HAS_YOUTUBE_DL=false
HAS_YT_DLP=false

if command -v curl &>/dev/null; then
    HAS_CURL=true
fi

if command -v wget &>/dev/null; then
    HAS_WGET=true
fi

if command -v aria2c &>/dev/null; then
    HAS_ARIA2=true
fi

if command -v youtube-dl &>/dev/null; then
    HAS_YOUTUBE_DL=true
fi

if command -v yt-dlp &>/dev/null; then
    HAS_YT_DLP=true
fi

# Verifica se pelo menos uma ferramenta de download está disponível
if [[ "$HAS_CURL" == false && "$HAS_WGET" == false && "$HAS_ARIA2" == false ]]; then
    echo "Erro: Nenhuma ferramenta de download disponível."
    echo "Instale pelo menos uma: curl, wget ou aria2"
    if [[ "$MACHINE" == "macOS" ]]; then
        echo "  brew install curl wget aria2"
    else
        echo "  sudo apt install curl wget aria2  # Ubuntu/Debian"
        echo "  sudo yum install curl wget aria2  # RHEL/CentOS"
    fi
    exit 1
fi

# Arquivo de configuração
CONFIG_FILE="$HOME/.download_manager_config"
DOWNLOADS_DIR="$HOME/Downloads"

# Função para verificar se URL é válida
validate_url() {
    local url="$1"
    if [[ "$url" =~ ^https?:// ]]; then
        return 0
    else
        return 1
    fi
}

# Função para obter tamanho do arquivo
get_file_size() {
    local url="$1"
    
    if [[ "$HAS_CURL" == true ]]; then
        size=$(curl -sI "$url" | grep -i content-length | awk '{print $2}' | tr -d '\r')
        if [[ -n "$size" ]]; then
            echo "$size"
            return 0
        fi
    fi
    
    if [[ "$HAS_WGET" == true ]]; then
        size=$(wget --spider --server-response "$url" 2>&1 | grep -i content-length | awk '{print $2}' | tr -d '\r')
        if [[ -n "$size" ]]; then
            echo "$size"
            return 0
        fi
    fi
    
    echo "Desconhecido"
}

# Função para formatar tamanho em bytes
format_size() {
    local size="$1"
    if [[ "$size" == "Desconhecido" ]]; then
        echo "$size"
        return
    fi
    
    if (( size < 1024 )); then
        echo "${size} B"
    elif (( size < 1048576 )); then
        echo "$(( size / 1024 )) KB"
    elif (( size < 1073741824 )); then
        echo "$(( size / 1048576 )) MB"
    else
        echo "$(( size / 1073741824 )) GB"
    fi
}

# Função para download simples
simple_download() {
    echo "📥 Download Simples"
    echo "=================="
    
    url=$(gum input --placeholder "Digite a URL para download")
    [[ -z "$url" ]] && return 0
    
    if ! validate_url "$url"; then
        echo "❌ URL inválida. Use formato: http:// ou https://"
        return 1
    fi
    
    # Pergunta sobre diretório de destino
    use_custom_dir=$(gum confirm "Usar diretório personalizado?" && echo "yes" || echo "no")
    
    dest_dir="$DOWNLOADS_DIR"
    if [[ "$use_custom_dir" == "yes" ]]; then
        dest_dir=$(gum input --placeholder "Caminho do diretório de destino" --value "$DOWNLOADS_DIR")
        mkdir -p "$dest_dir"
    fi
    
    # Pergunta sobre nome do arquivo
    filename=$(basename "$url" | cut -d'?' -f1)
    custom_name=$(gum input --placeholder "Nome do arquivo (deixe vazio para usar padrão)" --value "$filename")
    if [[ -n "$custom_name" ]]; then
        filename="$custom_name"
    fi
    
    # Mostra informações do arquivo
    echo "🔍 Analisando arquivo..."
    file_size=$(get_file_size "$url")
    formatted_size=$(format_size "$file_size")
    
    echo "📋 Informações do download:"
    echo "   URL: $url"
    echo "   Destino: $dest_dir/$filename"
    echo "   Tamanho: $formatted_size"
    echo
    
    # Escolhe ferramenta de download
    tools=()
    if [[ "$HAS_ARIA2" == true ]]; then
        tools+=("aria2c (recomendado)")
    fi
    if [[ "$HAS_CURL" == true ]]; then
        tools+=("curl")
    fi
    if [[ "$HAS_WGET" == true ]]; then
        tools+=("wget")
    fi
    
    selected_tool=$(gum choose "${tools[@]}")
    tool=$(echo "$selected_tool" | awk '{print $1}')
    
    # Executa download
    case "$tool" in
    "aria2c")
        cmd="aria2c --dir=\"$dest_dir\" --out=\"$filename\" --continue=true --max-connection-per-server=4 \"$url\""
        ;;
    "curl")
        cmd="curl -L --progress-bar -o \"$dest_dir/$filename\" \"$url\""
        ;;
    "wget")
        cmd="wget --progress=bar --show-progress -O \"$dest_dir/$filename\" \"$url\""
        ;;
    esac
    
    echo "🚀 Executando: $cmd"
    echo "=================="
    
    if gum confirm "Iniciar download?"; then
        eval "$cmd"
        if [[ $? -eq 0 ]]; then
            echo "✅ Download concluído com sucesso!"
            echo "📁 Arquivo salvo em: $dest_dir/$filename"
        else
            echo "❌ Erro durante o download"
        fi
    fi
}

# Função para download em lote
batch_download() {
    echo "📦 Download em Lote"
    echo "=================="
    
    method=$(gum choose "Inserir URLs manualmente" "Carregar de arquivo")
    
    urls=()
    case "$method" in
    "Inserir URLs manualmente")
        echo "Digite as URLs (uma por linha). Digite 'FIM' para terminar:"
        while true; do
            url=$(gum input --placeholder "URL ${#urls[@]}+1 (ou 'FIM' para terminar)")
            if [[ "$url" == "FIM" || "$url" == "fim" ]]; then
                break
            fi
            if validate_url "$url"; then
                urls+=("$url")
                echo "✅ Adicionada: $url"
            else
                echo "❌ URL inválida ignorada: $url"
            fi
        done
        ;;
    "Carregar de arquivo")
        urls_file=$(gum input --placeholder "Caminho do arquivo com URLs")
        if [[ -f "$urls_file" ]]; then
            while IFS= read -r url; do
                url=$(echo "$url" | xargs)  # Remove espaços
                if [[ -n "$url" ]] && validate_url "$url"; then
                    urls+=("$url")
                fi
            done < "$urls_file"
            echo "✅ Carregadas ${#urls[@]} URLs válidas do arquivo"
        else
            echo "❌ Arquivo não encontrado: $urls_file"
            return 1
        fi
        ;;
    esac
    
    if [[ ${#urls[@]} -eq 0 ]]; then
        echo "❌ Nenhuma URL válida encontrada"
        return 1
    fi
    
    # Configurações do lote
    dest_dir=$(gum input --placeholder "Diretório de destino" --value "$DOWNLOADS_DIR")
    mkdir -p "$dest_dir"
    
    # Pergunta sobre downloads simultâneos
    if [[ "$HAS_ARIA2" == true ]]; then
        concurrent=$(gum input --placeholder "Downloads simultâneos (1-5)" --value "2")
        if ! [[ "$concurrent" =~ ^[1-5]$ ]]; then
            concurrent=2
        fi
    else
        concurrent=1
    fi
    
    echo "📋 Configuração do lote:"
    echo "   URLs: ${#urls[@]}"
    echo "   Destino: $dest_dir"
    echo "   Simultâneos: $concurrent"
    echo
    
    if ! gum confirm "Iniciar downloads em lote?"; then
        return 0
    fi
    
    # Executa downloads
    if [[ "$HAS_ARIA2" == true ]]; then
        # Cria arquivo temporário com URLs
        temp_file="/tmp/download_urls_$$"
        printf '%s\n' "${urls[@]}" > "$temp_file"
        
        cmd="aria2c --dir=\"$dest_dir\" --continue=true --max-concurrent-downloads=$concurrent --max-connection-per-server=4 --input-file=\"$temp_file\""
        echo "🚀 Executando: $cmd"
        eval "$cmd"
        rm -f "$temp_file"
    else
        # Download sequencial com curl/wget
        for i in "${!urls[@]}"; do
            url="${urls[$i]}"
            filename=$(basename "$url" | cut -d'?' -f1)
            echo "📥 Baixando $((i+1))/${#urls[@]}: $filename"
            
            if [[ "$HAS_CURL" == true ]]; then
                curl -L --progress-bar -o "$dest_dir/$filename" "$url"
            elif [[ "$HAS_WGET" == true ]]; then
                wget --progress=bar -O "$dest_dir/$filename" "$url"
            fi
        done
    fi
    
    echo "✅ Downloads em lote concluídos!"
}

# Função para download de vídeos
video_download() {
    if [[ "$HAS_YT_DLP" == false && "$HAS_YOUTUBE_DL" == false ]]; then
        echo "❌ yt-dlp ou youtube-dl não estão instalados"
        echo "Para instalar:"
        if [[ "$MACHINE" == "macOS" ]]; then
            echo "  brew install yt-dlp"
        else
            echo "  pip install yt-dlp"
            echo "  # ou"
            echo "  sudo apt install yt-dlp  # Ubuntu 22.04+"
        fi
        return 1
    fi
    
    echo "🎥 Download de Vídeos"
    echo "===================="
    
    url=$(gum input --placeholder "URL do vídeo (YouTube, Vimeo, etc.)")
    [[ -z "$url" ]] && return 0
    
    # Escolhe ferramenta
    video_tool=""
    if [[ "$HAS_YT_DLP" == true ]]; then
        video_tool="yt-dlp"
    elif [[ "$HAS_YOUTUBE_DL" == true ]]; then
        video_tool="youtube-dl"
    fi
    
    # Pergunta sobre qualidade
    quality=$(gum choose "Melhor qualidade" "720p" "480p" "Áudio apenas (MP3)")
    
    dest_dir=$(gum input --placeholder "Diretório de destino" --value "$DOWNLOADS_DIR")
    mkdir -p "$dest_dir"
    
    # Monta comando baseado na qualidade
    case "$quality" in
    "Melhor qualidade")
        cmd="$video_tool -o \"$dest_dir/%(title)s.%(ext)s\" \"$url\""
        ;;
    "720p")
        cmd="$video_tool -f 'best[height<=720]' -o \"$dest_dir/%(title)s.%(ext)s\" \"$url\""
        ;;
    "480p")
        cmd="$video_tool -f 'best[height<=480]' -o \"$dest_dir/%(title)s.%(ext)s\" \"$url\""
        ;;
    "Áudio apenas (MP3)")
        cmd="$video_tool -x --audio-format mp3 -o \"$dest_dir/%(title)s.%(ext)s\" \"$url\""
        ;;
    esac
    
    echo "🚀 Executando: $cmd"
    echo "=================="
    
    if gum confirm "Iniciar download?"; then
        eval "$cmd"
        if [[ $? -eq 0 ]]; then
            echo "✅ Download concluído!"
        else
            echo "❌ Erro durante o download"
        fi
    fi
}

# Função para retomar downloads
resume_download() {
    echo "🔄 Retomar Downloads"
    echo "==================="
    
    if [[ "$HAS_ARIA2" == false ]]; then
        echo "❌ aria2c não está disponível"
        echo "A retomada de downloads requer aria2c"
        if [[ "$MACHINE" == "macOS" ]]; then
            echo "Para instalar: brew install aria2"
        else
            echo "Para instalar: sudo apt install aria2"
        fi
        return 1
    fi
    
    # Procura por arquivos .aria2 (downloads incompletos)
    incomplete_files=()
    if [[ -d "$DOWNLOADS_DIR" ]]; then
        while IFS= read -r -d '' file; do
            incomplete_files+=("$file")
        done < <(find "$DOWNLOADS_DIR" -name "*.aria2" -print0)
    fi
    
    if [[ ${#incomplete_files[@]} -eq 0 ]]; then
        echo "✅ Nenhum download incompleto encontrado"
        return 0
    fi
    
    echo "📋 Downloads incompletos encontrados:"
    for file in "${incomplete_files[@]}"; do
        original_file="${file%.aria2}"
        echo "   📁 $(basename "$original_file")"
    done
    echo
    
    if gum confirm "Retomar todos os downloads incompletos?"; then
        for file in "${incomplete_files[@]}"; do
            original_file="${file%.aria2}"
            dir=$(dirname "$original_file")
            filename=$(basename "$original_file")
            
            echo "🔄 Retomando: $filename"
            aria2c --dir="$dir" --out="$filename" --continue=true --max-connection-per-server=4
        done
        echo "✅ Tentativa de retomada concluída!"
    fi
}

# Função para gerenciar downloads
manage_downloads() {
    echo "📊 Gerenciar Downloads"
    echo "====================="
    
    action=$(gum choose "Listar arquivos baixados" "Limpar downloads incompletos" "Configurar diretório padrão" "Verificar espaço em disco")
    
    case "$action" in
    "Listar arquivos baixados")
        if [[ -d "$DOWNLOADS_DIR" ]]; then
            echo "📁 Arquivos em $DOWNLOADS_DIR:"
            echo "=============================="
            ls -lh "$DOWNLOADS_DIR" | grep -v "^total" | while read -r line; do
                if [[ "$line" == d* ]]; then
                    echo "📁 $(echo "$line" | awk '{print $9}')"
                else
                    size=$(echo "$line" | awk '{print $5}')
                    name=$(echo "$line" | awk '{print $9}')
                    echo "📄 $name ($size)"
                fi
            done
        else
            echo "❌ Diretório de downloads não encontrado: $DOWNLOADS_DIR"
        fi
        ;;
    "Limpar downloads incompletos")
        if [[ -d "$DOWNLOADS_DIR" ]]; then
            incomplete_count=$(find "$DOWNLOADS_DIR" -name "*.aria2" | wc -l)
            if [[ $incomplete_count -gt 0 ]]; then
                echo "🗑️  Encontrados $incomplete_count arquivos incompletos"
                if gum confirm "Remover arquivos .aria2 (downloads incompletos)?"; then
                    find "$DOWNLOADS_DIR" -name "*.aria2" -delete
                    echo "✅ Arquivos incompletos removidos"
                fi
            else
                echo "✅ Nenhum arquivo incompleto encontrado"
            fi
        fi
        ;;
    "Configurar diretório padrão")
        new_dir=$(gum input --placeholder "Novo diretório padrão" --value "$DOWNLOADS_DIR")
        if [[ -n "$new_dir" ]]; then
            mkdir -p "$new_dir"
            echo "DOWNLOADS_DIR=\"$new_dir\"" > "$CONFIG_FILE"
            DOWNLOADS_DIR="$new_dir"
            echo "✅ Diretório padrão alterado para: $new_dir"
        fi
        ;;
    "Verificar espaço em disco")
        if [[ "$MACHINE" == "macOS" ]]; then
            df -h "$DOWNLOADS_DIR"
        else
            df -h "$DOWNLOADS_DIR"
        fi
        ;;
    esac
}

# Função principal de resumo
download_summary() {
    clear
    echo "📋 RESUMO DO DOWNLOAD MANAGER"
    echo "============================="
    
    # Mostra informações do sistema
    echo "💻 Sistema: $MACHINE"
    echo "📁 Diretório padrão: $DOWNLOADS_DIR"
    echo
    
    echo "🔧 Ferramentas disponíveis:"
    if [[ "$HAS_CURL" == true ]]; then
        echo "   ✅ curl"
    else
        echo "   ❌ curl"
    fi
    
    if [[ "$HAS_WGET" == true ]]; then
        echo "   ✅ wget"
    else
        echo "   ❌ wget"
    fi
    
    if [[ "$HAS_ARIA2" == true ]]; then
        echo "   ✅ aria2c (recomendado)"
    else
        echo "   ❌ aria2c"
    fi
    
    if [[ "$HAS_YT_DLP" == true ]]; then
        echo "   ✅ yt-dlp"
    elif [[ "$HAS_YOUTUBE_DL" == true ]]; then
        echo "   ✅ youtube-dl"
    else
        echo "   ❌ yt-dlp/youtube-dl"
    fi
    
    echo
    
    # Mostra estatísticas do diretório
    if [[ -d "$DOWNLOADS_DIR" ]]; then
        file_count=$(find "$DOWNLOADS_DIR" -type f ! -name "*.aria2" | wc -l)
        incomplete_count=$(find "$DOWNLOADS_DIR" -name "*.aria2" | wc -l)
        
        echo "📊 Estatísticas:"
        echo "   📄 Arquivos baixados: $file_count"
        if [[ $incomplete_count -gt 0 ]]; then
            echo "   ⏳ Downloads incompletos: $incomplete_count"
        fi
        
        # Mostra espaço em disco
        echo "   💾 Espaço disponível:"
        if [[ "$MACHINE" == "macOS" ]]; then
            df -h "$DOWNLOADS_DIR" | tail -1 | awk '{print "      " $4 " livres de " $2}'
        else
            df -h "$DOWNLOADS_DIR" | tail -1 | awk '{print "      " $4 " livres de " $2}'
        fi
    fi
    
    echo
    gum confirm "Deseja retornar ao menu?" || exit 0
}

# Carrega configurações se existirem
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

# Loop principal
echo "📥 Download Manager - Sistema: $MACHINE"
echo "📁 Diretório: $DOWNLOADS_DIR"
echo

while true; do
    opcao=$(gum choose \
        "📋 Resumo completo" \
        "📥 Download simples" \
        "📦 Download em lote" \
        "🎥 Download de vídeos" \
        "🔄 Retomar downloads" \
        "📊 Gerenciar downloads" \
        "🚪 Sair")

    case "$opcao" in
    "📋 Resumo completo")
        download_summary
        ;;
    "📥 Download simples")
        simple_download
        gum confirm "Deseja retornar ao menu?" || exit 0
        ;;
    "📦 Download em lote")
        batch_download
        gum confirm "Deseja retornar ao menu?" || exit 0
        ;;
    "🎥 Download de vídeos")
        video_download
        gum confirm "Deseja retornar ao menu?" || exit 0
        ;;
    "🔄 Retomar downloads")
        resume_download
        gum confirm "Deseja retornar ao menu?" || exit 0
        ;;
    "📊 Gerenciar downloads")
        manage_downloads
        gum confirm "Deseja retornar ao menu?" || exit 0
        ;;
    "🚪 Sair")
        echo "👋 Obrigado por usar o Download Manager!"
        exit 0
        ;;
    esac
done

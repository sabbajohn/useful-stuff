#!/bin/bash

# DevOps Toolkit - Painel Principal
# Hub central para todos os scripts organizados por categoria

set -e

# Verifica se gum está instalado
if ! command -v gum &>/dev/null; then
    echo "❌ gum não está instalado. Instale primeiro:"
    echo ""
    echo "📦 Ubuntu/Debian:"
    echo "   sudo mkdir -p /etc/apt/keyrings"
    echo "   curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg"
    echo "   echo \"deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *\" | sudo tee /etc/apt/sources.list.d/charm.list"
    echo "   sudo apt update && sudo apt install gum"
    echo ""
    echo "📦 macOS:"
    echo "   brew install gum"
    echo ""
    echo "📦 Manual (Linux):"
    echo "   wget https://github.com/charmbracelet/gum/releases/download/v0.14.1/gum_0.14.1_amd64.deb"
    echo "   sudo dpkg -i gum_0.14.1_amd64.deb"
    echo ""
    echo "💡 Ou use o script de instalação: ./dev-install.sh"
    exit 1
fi

# Detecta o diretório base dos scripts
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Debug mode (uncomment for troubleshooting)
# set -x

# Verifica se os diretórios principais existem
check_directories() {
    local missing_dirs=()
    for dir in "Redes" "Storage" "Django" "Services" "common"; do
        if [[ ! -d "$SCRIPT_DIR/$dir" ]]; then
            missing_dirs+=("$dir")
        fi
    done
    
    if [[ ${#missing_dirs[@]} -gt 0 ]]; then
        echo "⚠️  Diretórios em falta: ${missing_dirs[*]}"
        echo "📍 Localização atual: $SCRIPT_DIR"
        echo "💡 Certifique-se de estar executando do diretório correto"
        return 1
    fi
    return 0
}

# Cores e estilos
export GUM_CHOOSE_CURSOR_FOREGROUND="212"
export GUM_CHOOSE_SELECTED_FOREGROUND="212" 

# Função para mostrar header
show_header() {
    clear
    echo "🚀 DevOps Toolkit v1.1.0"
    echo "========================"
    echo "Professional Development & System Administration Suite"
    echo ""
}

# Menu de Network & SSH
network_menu() {
    show_header
    echo "🌐 Network & SSH Management"
    echo "============================"
    echo ""
    
    local option=$(gum choose \
        "🔗 SSH Manager - Conexões e gerenciamento SSH" \
        "📡 Network Config Checker - Análise e diagnóstico de rede" \
        "🔍 Port Checker - Monitor de portas e processos" \
        "🌍 DNS Troubleshoot - Resolução de problemas DNS" \
        "⬅️  Voltar ao menu principal")
    
    case "$option" in
    *"SSH Manager"*)
        echo "🚀 Iniciando SSH Manager..."
        "$SCRIPT_DIR/Redes/ssh-manager.sh"
        ;;
    *"Network Config"*)
        echo "🚀 Iniciando Network Config Checker..."
        "$SCRIPT_DIR/Redes/network-config-checker.sh"
        ;;
    *"Port Checker"*)
        echo "🚀 Iniciando Port Checker..."
        "$SCRIPT_DIR/Redes/port-checker.sh"
        ;;
    *"DNS Troubleshoot"*)
        echo "🚀 Iniciando DNS Troubleshoot..."
        "$SCRIPT_DIR/Redes/dns-troubleshoot.sh"
        ;;
    *"Voltar"*)
        return
        ;;
    esac
}

# Menu de Storage Management
storage_menu() {
    show_header
    echo "💾 Storage Management"
    echo "====================="
    echo ""
    
    local option=$(gum choose \
        "🧰 Storage Manager - Gerenciador (macOS/Linux)" \
        "🔗 Symlink Manager - Gerenciamento de links simbólicos" \
        "📊 Disk Usage - Visão rápida do disco" \
        "🧾 Mount Manager - Montar SMB/NFS" \
        "⬅️  Voltar ao menu principal")
    
    case "$option" in
    *"Storage Manager"*)
        echo "🚀 Iniciando Storage Manager..."
        "$SCRIPT_DIR/Storage/storage-manager.sh"
        ;;
    *"Symlink Manager"*)
        echo "🚀 Iniciando Symlink Manager..."
        "$SCRIPT_DIR/Storage/symlink-manager.sh"
        ;;
    *"Disk Usage"*)
        echo "🚀 Analisando uso do disco..."
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            "$SCRIPT_DIR/Storage/linux-storage-manager.sh" --disk-usage --no-ui
        else
            "$SCRIPT_DIR/Storage/mac-storage-manager.sh" disk-usage
        fi
        gum confirm "Pressione Enter para continuar..." || true
        ;;
    *"Mount Manager"*)
        echo "🚀 Iniciando Mount Manager..."
        "$SCRIPT_DIR/Storage/mount-manager.sh"
        ;;
    *"Voltar"*)
        return
        ;;
    esac
}

# Menu de Services
services_menu() {
    show_header
    echo "🧩 Services"
    echo "==========="
    echo ""

    "$SCRIPT_DIR/Services/service-manager.sh"
}

# Menu de Django Development
django_menu() {
    show_header
    echo "🐍 Django Development"
    echo "====================="
    echo ""
    
    local option=$(gum choose \
        "🏗️  Django Project Creator v3 - Criar novo projeto Django" \
        "📋 Listar templates disponíveis" \
        "🧪 Testar Django Creator" \
        "📚 Ver documentação Django" \
        "⬅️  Voltar ao menu principal")
    
    case "$option" in
    *"Project Creator"*)
        echo "🚀 Iniciando Django Project Creator..."
        "$SCRIPT_DIR/django-project-creator-v3.sh"
        ;;
    *"templates"*)
        echo "📋 Templates Django disponíveis:"
        echo "================================"
        if [[ -d "$SCRIPT_DIR/Django/django-templates-v3" ]]; then
            ls -la "$SCRIPT_DIR/Django/django-templates-v3" | grep "^d" | awk '{print "   📁 " $9}'
        fi
        echo ""
        gum confirm "Pressione Enter para continuar..."
        ;;
    *"Testar"*)
        echo "🧪 Executando testes..."
        if [[ -f "$SCRIPT_DIR/tests/test-scripts.sh" ]]; then
            "$SCRIPT_DIR/tests/test-scripts.sh"
        else
            echo "❌ Script de teste não encontrado"
        fi
        gum confirm "Pressione Enter para continuar..."
        ;;
    *"documentação"*)
        echo "📚 Abrindo documentação..."
        if [[ -f "$SCRIPT_DIR/README_django_v3.md" ]]; then
            if command -v bat &>/dev/null; then
                bat "$SCRIPT_DIR/README_django_v3.md"
            else
                less "$SCRIPT_DIR/README_django_v3.md"
            fi
        else
            echo "❌ Documentação não encontrada"
        fi
        ;;
    *"Voltar"*)
        return
        ;;
    esac
}

# Menu de System Utilities
system_menu() {
    show_header
    echo "🔧 System Utilities"
    echo "==================="
    echo ""
    
    local option=$(gum choose \
        "🐘 PHP Switcher - Alternar versões do PHP" \
        "📥 Download Manager - Gerenciador de downloads" \
        "🚀 Laravel Starter - Iniciar projetos Laravel" \
        "🐍 Python Project Manager - Gerenciar projetos Python" \
        "📦 Package Manager - Instalar/atualizar toolkit" \
        "⬅️  Voltar ao menu principal")
    
    case "$option" in
    *"PHP Switcher"*)
        echo "🚀 Iniciando PHP Switcher..."
        "$SCRIPT_DIR/PHP/php-switcher.sh"
        ;;
    *"Download Manager"*)
        echo "🚀 Iniciando Download Manager..."
        "$SCRIPT_DIR/Redes/download-manager.sh"
        ;;
    *"Laravel"*)
        echo "🚀 Iniciando Laravel Starter..."
        "$SCRIPT_DIR/laravel-start.sh"
        ;;
    *"Python Project"*)
        echo "🚀 Iniciando Python Project Manager..."
        "$SCRIPT_DIR/Python/python-project-manager.sh"
        ;;
    *"Package Manager"*)
        echo "🚀 Abrindo Package Manager..."
        if [[ -f "$SCRIPT_DIR/dev-install.sh" ]]; then
            "$SCRIPT_DIR/dev-install.sh"
        else
            echo "❌ Package manager não encontrado"
            gum confirm "Pressione Enter para continuar..."
        fi
        ;;
    *"Voltar"*)
        return
        ;;
    esac
}

# Menu de informações e status
info_menu() {
    show_header
    echo "ℹ️  Informações do Sistema"
    echo "=========================="
    echo ""
    
    # Detecção do sistema
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "💻 Sistema: macOS $(sw_vers -productVersion)"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "💻 Sistema: Linux $(lsb_release -ds 2>/dev/null || echo 'Unknown')"
    else
        echo "💻 Sistema: $OSTYPE"
    fi
    
    echo "📍 Localização dos scripts: $SCRIPT_DIR"
    echo ""
    
    # Verifica dependências principais
    echo "🔧 Dependências:"
    echo "================"
    for cmd in gum ssh arp-scan docker php python3 rsync; do
        if command -v $cmd &>/dev/null; then
            local version=$(command $cmd --version 2>/dev/null | head -1 | awk '{print $NF}' || echo "instalado")
            echo "   ✅ $cmd ($version)"
        else
            echo "   ❌ $cmd (não instalado)"
        fi
    done
    
    echo ""
    
    # Estatísticas dos scripts
    echo "📊 Estatísticas:"
    echo "==============="
    local script_count=$(find "$SCRIPT_DIR" -name "*.sh" -type f | wc -l)
    echo "   📜 Scripts disponíveis: $script_count"
    echo "   📁 Diretórios principais: Network, Storage, Services, Django, System"
    
    local size=$(du -sh "$SCRIPT_DIR" 2>/dev/null | awk '{print $1}')
    echo "   💽 Tamanho total: $size"
    
    echo ""
    gum confirm "Pressione Enter para voltar..."
}

# Menu principal
main_menu() {
    while true; do
        show_header
        
        local option=$(gum choose \
            "🌐 Network & SSH - Gerenciamento de rede e conexões SSH" \
            "💾 Storage Management - Limpeza e otimização de storage" \
            "🧩 Services - Listar/gerenciar serviços (systemd/launchd)" \
            "🐍 Django Development - Criação e gestão de projetos Django" \
            "🔧 System Utilities - Ferramentas do sistema e utilitários" \
            "ℹ️  Informações - Status do sistema e dependências" \
            "🚪 Sair")
        
        case "$option" in
        *"Network & SSH"*)
            network_menu
            ;;
        *"Storage Management"*)
            storage_menu
            ;;
        *"Services"*)
            services_menu
            ;;
        *"Django Development"*)
            django_menu
            ;;
        *"System Utilities"*)
            system_menu
            ;;
        *"Informações"*)
            info_menu
            ;;
        *"Sair"*)
            echo "👋 Até logo!"
            exit 0
            ;;
        esac
    done
}

# Execução principal
echo "🔧 Iniciando DevOps Toolkit..."
check_directories || exit 1
main_menu

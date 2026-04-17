#!/bin/bash

# DevOps Toolkit - Development Installation Script
# Instala o toolkit em modo desenvolvimento para testes

set -e

echo "🔧 DevOps Toolkit - Instalação para Desenvolvimento"
echo "=================================================="

# Verifica se está sendo executado como sudo quando necessário
check_sudo() {
    if [[ $EUID -ne 0 ]] && [[ "$1" == "system" ]]; then
        echo "❌ Este script precisa ser executado com sudo para instalação do sistema"
        echo "💡 Use: sudo ./dev-install.sh"
        exit 1
    fi
}

# Verifica dependências
check_dependencies() {
    echo "🔍 Verificando dependências..."
    
    local missing_deps=()
    
    # Dependências obrigatórias
    for cmd in bash curl git python3; do
        if ! command -v $cmd &>/dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    # Dependências recomendadas
    echo "📋 Dependências recomendadas:"
    for cmd in gum arp-scan docker php rsync sshfs; do
        if command -v $cmd &>/dev/null; then
            echo "   ✅ $cmd"
        else
            echo "   ❌ $cmd (recomendado)"
            missing_deps+=("$cmd")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo "⚠️  Dependências em falta: ${missing_deps[*]}"
        echo "💡 Para macOS:"
        echo "   brew install gum arp-scan docker php rsync"
        echo "   brew install --cask macfuse && brew install gromgit/fuse/sshfs-mac"
        echo ""
        
        if ! gum confirm "Continuar mesmo assim?"; then
            exit 1
        fi
    fi
}

# Instalação local (usuário)
install_user() {
    echo "👤 Instalando para usuário atual..."
    
    local install_dir="$HOME/.local/bin/devops-toolkit"
    
    # Cria diretórios
    mkdir -p "$install_dir/bin/scripts/network"
    mkdir -p "$install_dir/bin/scripts/storage"
    mkdir -p "$install_dir/bin/scripts/services"
    mkdir -p "$install_dir/templates"
    
    # Copia arquivos
    echo "📁 Copiando scripts principais..."
    echo "📁 Copiando painel principal..."
    cp devops-toolkit.sh "$install_dir/"
    chmod +x "$install_dir/devops-toolkit.sh"
    
    echo "📁 Copiando scripts auxiliares..."
    cp -r devops-toolkit/* "$install_dir/" 2>/dev/null || true
    
    echo "📁 Copiando scripts de rede..."
    cp Redes/*.sh "$install_dir/bin/scripts/network/"
    
    echo "📁 Copiando scripts de storage..."
    cp Storage/*.sh "$install_dir/bin/scripts/storage/"

    echo "📁 Copiando scripts de services..."
    if [[ -d Services ]]; then
        cp Services/*.sh "$install_dir/bin/scripts/services/"
    fi

    echo "📁 Copiando libs comuns..."
    if [[ -d common ]]; then
        cp -r common "$install_dir/"
    fi
    
    echo "📁 Copiando templates Django..."
    cp -r Django "$install_dir/templates/"
    
    # Define permissões
    chmod +x "$install_dir/bin/scripts/network"/*.sh
    chmod +x "$install_dir/bin/scripts/storage"/*.sh
    chmod +x "$install_dir/bin/scripts/services"/*.sh 2>/dev/null || true
    
    # Symlinks para facilitar uso direto (ssh-manager, port-checker, etc.)
    for script in "$install_dir/bin/scripts/network"/*.sh "$install_dir/bin/scripts/storage"/*.sh "$install_dir/bin/scripts/services"/*.sh; do
        [[ -f "$script" ]] || continue
        script_name=$(basename "$script" .sh)
        ln -sf "$script" "$install_dir/bin/scripts/$script_name"
    done

    # Adiciona alias para o painel principal
    local bashrc="$HOME/.bashrc"
    local zshrc="$HOME/.zshrc"
    local path_line='export PATH="$HOME/.local/bin/devops-toolkit/bin/scripts:$HOME/.local/bin/devops-toolkit/bin/scripts/network:$HOME/.local/bin/devops-toolkit/bin/scripts/storage:$HOME/.local/bin/devops-toolkit/bin/scripts/services:$PATH"'
    local alias_line='alias devops="$HOME/.local/bin/devops-toolkit/devops-toolkit.sh"'
    
    for rc_file in "$bashrc" "$zshrc"; do
        if [[ -f "$rc_file" ]] && ! grep -q "devops-toolkit" "$rc_file"; then
            echo "🔧 Adicionando ao PATH em $rc_file"
            echo "" >> "$rc_file"
            echo "# DevOps Toolkit" >> "$rc_file"
            echo "$path_line" >> "$rc_file"
            echo "$alias_line" >> "$rc_file"
        fi
    done
    
    echo "✅ Instalação local concluída em: $install_dir"
    echo "🎯 Execute: devops (ou $install_dir/devops-toolkit.sh)"
    echo "💡 Reinicie o terminal ou execute: source ~/.zshrc"
}

# Instalação sistema (global)
install_system() {
    echo "🌐 Instalando para todo o sistema..."
    
    local install_dir="/opt/devops-toolkit"
    
    # Remove instalação anterior
    if [[ -d "$install_dir" ]]; then
        echo "🗑️  Removendo instalação anterior..."
        rm -rf "$install_dir"
    fi
    
    # Cria diretórios
    mkdir -p "$install_dir/bin/scripts/network"
    mkdir -p "$install_dir/bin/scripts/storage"
    mkdir -p "$install_dir/bin/scripts/services"
    mkdir -p "$install_dir/templates"
    
    # Copia arquivos
    echo "📁 Copiando scripts principais..."
    echo "📁 Copiando painel principal..."
    cp devops-toolkit.sh "$install_dir/"
    chmod +x "$install_dir/devops-toolkit.sh"
    
    echo "📁 Copiando scripts principais..."
    cp -r devops-toolkit/* "$install_dir/" 2>/dev/null || true
    
    echo "📁 Copiando scripts de rede..."
    cp Redes/*.sh "$install_dir/bin/scripts/network/"
    
    echo "📁 Copiando scripts de storage..."
    cp Storage/*.sh "$install_dir/bin/scripts/storage/"

    echo "📁 Copiando scripts de services..."
    if [[ -d Services ]]; then
        cp Services/*.sh "$install_dir/bin/scripts/services/"
    fi

    echo "📁 Copiando libs comuns..."
    if [[ -d common ]]; then
        cp -r common "$install_dir/"
    fi
    
    echo "📁 Copiando templates Django..."
    cp -r Django "$install_dir/templates/"
    
    # Define permissões
    chmod +x "$install_dir/bin/scripts/network"/*.sh
    chmod +x "$install_dir/bin/scripts/storage"/*.sh
    chmod +x "$install_dir/bin/scripts/services"/*.sh 2>/dev/null || true

    # Symlinks para facilitar uso direto (ssh-manager, port-checker, etc.)
    for script in "$install_dir/bin/scripts/network"/*.sh "$install_dir/bin/scripts/storage"/*.sh "$install_dir/bin/scripts/services"/*.sh; do
        [[ -f "$script" ]] || continue
        script_name=$(basename "$script" .sh)
        ln -sf "$script" "$install_dir/bin/scripts/$script_name"
    done
    
    # Cria symlinks no sistema
    echo "🔗 Criando links simbólicos..."
    local bin_dir="/usr/local/bin"
    
    # Link principal para o painel
    ln -sf "$install_dir/devops-toolkit.sh" "$bin_dir/devops"
    
    # Scripts principais
    for script in "$install_dir/bin/scripts/network"/*.sh; do
        local script_name=$(basename "$script" .sh)
        ln -sf "$script" "$bin_dir/$script_name"
    done
    
    for script in "$install_dir/bin/scripts/storage"/*.sh; do
        local script_name=$(basename "$script" .sh)
        ln -sf "$script" "$bin_dir/$script_name"
    done

    for script in "$install_dir/bin/scripts/services"/*.sh; do
        [[ -f "$script" ]] || continue
        local script_name=$(basename "$script" .sh)
        ln -sf "$script" "$bin_dir/$script_name"
    done
    
    echo "✅ Instalação do sistema concluída em: $install_dir"
    echo "🎯 Execute: devops (painel principal)"
    echo "✅ Scripts individuais também disponíveis: ssh-manager, network-config-checker, etc."
}

# Menu principal
main() {
    echo "Selecione o tipo de instalação:"
    
    local install_type=$(gum choose \
        "👤 Usuário (instala em ~/.local/bin)" \
        "🌐 Sistema (instala em /opt, requer sudo)" \
        "🧹 Remover instalação" \
        "🚪 Sair")
    
    case "$install_type" in
    "👤 Usuário"*)
        check_dependencies
        install_user
        ;;
    "🌐 Sistema"*)
        check_sudo "system"
        check_dependencies
        install_system
        ;;
    "🧹 Remover"*)
        if gum confirm "Remover todas as instalações?"; then
            echo "🗑️  Removendo instalações..."
            rm -rf "$HOME/.local/bin/devops-toolkit" 2>/dev/null || true
            if [[ $EUID -eq 0 ]]; then
                rm -rf "/opt/devops-toolkit" 2>/dev/null || true
                rm -f /usr/local/bin/ssh-manager 2>/dev/null || true
                rm -f /usr/local/bin/network-config-checker 2>/dev/null || true
                rm -f /usr/local/bin/mac-storage-manager 2>/dev/null || true
                rm -f /usr/local/bin/port-checker 2>/dev/null || true
                rm -f /usr/local/bin/storage-manager 2>/dev/null || true
                rm -f /usr/local/bin/linux-storage-manager 2>/dev/null || true
                rm -f /usr/local/bin/mount-manager 2>/dev/null || true
                rm -f /usr/local/bin/service-manager 2>/dev/null || true
            fi
            echo "✅ Remoção concluída"
        fi
        ;;
    "🚪 Sair")
        exit 0
        ;;
    esac
}

# Execução principal
if command -v gum &>/dev/null; then
    main
else
    echo "❌ gum não está instalado. Instale primeiro:"
    echo "   macOS: brew install gum"
    echo "   Linux: https://github.com/charmbracelet/gum#installation"
    exit 1
fi

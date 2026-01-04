#!/bin/bash

# DevOps Toolkit - Quick Ubuntu Setup
# Instalação rápida de dependências para Ubuntu/Debian

echo "🐧 DevOps Toolkit - Instalação Ubuntu/Debian"
echo "============================================="

# Verifica se é Ubuntu/Debian
if ! command -v apt &>/dev/null; then
    echo "❌ Este script é específico para Ubuntu/Debian (sistemas com apt)"
    exit 1
fi

# Atualiza repositórios
echo "📦 Atualizando repositórios..."
sudo apt update

# Instala dependências básicas
echo "📦 Instalando dependências básicas..."
sudo apt install -y curl wget git python3 python3-pip rsync openssh-client arp-scan

# Instala gum (interface interativa)
echo "📦 Instalando gum..."
if ! command -v gum &>/dev/null; then
    echo "   Adicionando repositório Charm..."
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
    sudo apt update
    sudo apt install -y gum
else
    echo "   ✅ gum já está instalado"
fi

# Instala Docker (opcional)
if ! command -v docker &>/dev/null; then
    echo "🐳 Deseja instalar Docker? (recomendado)"
    read -p "   [y/N]: " install_docker
    if [[ "$install_docker" =~ ^[Yy] ]]; then
        echo "   Instalando Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        rm get-docker.sh
        echo "   ⚠️  Faça logout/login para usar Docker sem sudo"
    fi
fi

# Instala PHP (opcional)
if ! command -v php &>/dev/null; then
    echo "🐘 Deseja instalar PHP? (para scripts PHP)"
    read -p "   [y/N]: " install_php
    if [[ "$install_php" =~ ^[Yy] ]]; then
        sudo apt install -y php-cli php-curl php-zip
    fi
fi

echo ""
echo "✅ Instalação concluída!"
echo ""
echo "🚀 Para testar, execute:"
echo "   ./devops-toolkit.sh"
echo ""
echo "📝 Dependências instaladas:"
command -v gum && echo "   ✅ gum"
command -v git && echo "   ✅ git" 
command -v python3 && echo "   ✅ python3"
command -v arp-scan && echo "   ✅ arp-scan"
command -v docker && echo "   ✅ docker"
command -v php && echo "   ✅ php"
#!/bin/bash

# Script de Correção Rápida de DNS para Ubuntu
# Autor: Quick DNS Fix
# Data: $(date)

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "================================================================"
echo "             CORREÇÃO RÁPIDA DE DNS - UBUNTU"
echo "================================================================"

# Verificar privilégios
if [ "$EUID" -ne 0 ]; then
    if ! sudo -n true 2>/dev/null; then
        log_error "Este script precisa de privilégios sudo"
        exit 1
    fi
fi

# Backup do resolv.conf atual
log_info "Fazendo backup da configuração atual..."
sudo cp /etc/resolv.conf /etc/resolv.conf.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

# Método 1: Correção via systemd-resolved (Ubuntu 18.04+)
log_info "Aplicando correção via systemd-resolved..."

# Configurar systemd-resolved
sudo tee /etc/systemd/resolved.conf > /dev/null << 'EOF'
[Resolve]
DNS=8.8.8.8 8.8.4.4 1.1.1.1 1.0.0.1
FallbackDNS=208.67.222.222 208.67.220.220
Domains=~.
DNSSEC=no
DNSOverTLS=no
Cache=yes
DNSStubListener=yes
EOF

# Restart systemd-resolved
sudo systemctl restart systemd-resolved
sudo systemctl enable systemd-resolved

# Reconfigurar resolv.conf
sudo rm -f /etc/resolv.conf
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

log_success "systemd-resolved configurado"

# Flush DNS cache
log_info "Limpando cache DNS..."
sudo systemctl restart systemd-resolved
sudo resolvectl flush-caches 2>/dev/null || true

# Método 2: Configuração direta (fallback)
log_info "Aplicando configuração direta como fallback..."

sudo tee /etc/resolv.conf > /dev/null << 'EOF'
# Configuração DNS de emergência
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 1.1.1.1
nameserver 1.0.0.1
nameserver 208.67.222.222
EOF

# Testar resolução
log_info "Testando resolução DNS..."
sleep 2

if nslookup google.com >/dev/null 2>&1; then
    log_success "✓ Resolução DNS funcionando!"
else
    log_warning "Resolução DNS ainda com problemas"
fi

# Testar ping
log_info "Testando conectividade..."
if ping -c 2 google.com >/dev/null 2>&1; then
    log_success "✓ Ping para google.com funcionando!"
else
    log_warning "Ping ainda com problemas"
fi

# Testar apt update
log_info "Testando apt update..."
if timeout 30 sudo apt update >/dev/null 2>&1; then
    log_success "✓ apt update funcionando!"
    
    echo ""
    log_info "Executando apt update completo..."
    sudo apt update
    
else
    log_warning "apt update ainda com problemas"
fi

echo ""
echo "================================================================"
log_success "CORREÇÃO APLICADA!"
echo "================================================================"

echo ""
echo "Para verificar o status:"
echo "• ping google.com"
echo "• nslookup google.com"
echo "• sudo apt update"
echo ""

echo "Configurações aplicadas:"
echo "• DNS primário: 8.8.8.8 (Google)"
echo "• DNS secundário: 8.8.4.4 (Google)"
echo "• DNS backup: 1.1.1.1 (Cloudflare)"
echo "• systemd-resolved reiniciado"
echo ""

# Mostrar status atual
echo "Status atual do DNS:"
cat /etc/resolv.conf
echo ""

echo "Para mais opções, execute: ./dns-troubleshoot.sh"

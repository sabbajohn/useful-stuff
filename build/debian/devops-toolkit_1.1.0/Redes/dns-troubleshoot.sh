#!/bin/bash

# Script para diagnosticar e resolver problemas de DNS no Ubuntu/Linux
# Autor: Script de Diagnóstico de Rede
# Data: $(date)

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Função para verificar se o comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Função para testar conectividade básica
test_connectivity() {
    log_info "=== TESTE DE CONECTIVIDADE ==="
    
    # Teste ping para IP direto (Google DNS)
    log_info "Testando conectividade direta com IP (8.8.8.8)..."
    if ping -c 3 8.8.8.8 >/dev/null 2>&1; then
        log_success "Conectividade IP funciona - problema é DNS"
        return 0
    else
        log_error "Sem conectividade IP - problema de rede física"
        return 1
    fi
}

# Função para diagnosticar DNS
diagnose_dns() {
    log_info "=== DIAGNÓSTICO DNS ==="
    
    # Verificar arquivo resolv.conf
    log_info "Verificando /etc/resolv.conf..."
    if [ -f /etc/resolv.conf ]; then
        echo "Conteúdo atual do /etc/resolv.conf:"
        cat /etc/resolv.conf
        echo ""
    else
        log_error "/etc/resolv.conf não encontrado"
    fi
    
    # Verificar status do systemd-resolved
    log_info "Verificando status do systemd-resolved..."
    if command_exists systemctl; then
        systemctl status systemd-resolved --no-pager || true
    fi
    
    # Verificar configuração do NetworkManager
    log_info "Verificando configuração do NetworkManager..."
    if command_exists nmcli; then
        nmcli dev show | grep DNS || true
    fi
}

# Função para backup da configuração atual
backup_config() {
    log_info "=== BACKUP DA CONFIGURAÇÃO ==="
    
    BACKUP_DIR="/tmp/dns_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Backup do resolv.conf
    if [ -f /etc/resolv.conf ]; then
        cp /etc/resolv.conf "$BACKUP_DIR/"
        log_success "Backup do resolv.conf salvo em $BACKUP_DIR"
    fi
    
    # Backup da configuração do NetworkManager
    if [ -d /etc/NetworkManager ]; then
        cp -r /etc/NetworkManager "$BACKUP_DIR/" 2>/dev/null || true
    fi
    
    echo "BACKUP_DIR=$BACKUP_DIR"
}

# Função para corrigir DNS
fix_dns() {
    log_info "=== CORREÇÃO DNS ==="
    
    # Método 1: Configurar DNS temporariamente
    log_info "Método 1: Configurando DNS temporário..."
    
    # Backup do resolv.conf atual
    sudo cp /etc/resolv.conf /etc/resolv.conf.backup.$(date +%Y%m%d_%H%M%S)
    
    # Configurar DNS temporário
    sudo tee /etc/resolv.conf > /dev/null << EOF
# DNS temporário configurado pelo script de diagnóstico
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 1.1.1.1
nameserver 1.0.0.1
EOF
    
    log_success "DNS temporário configurado"
    
    # Testar resolução
    log_info "Testando resolução DNS..."
    if nslookup google.com >/dev/null 2>&1; then
        log_success "Resolução DNS funcionando!"
        
        # Testar ping
        if ping -c 2 google.com >/dev/null 2>&1; then
            log_success "Ping para google.com funcionando!"
        fi
    else
        log_warning "Resolução DNS ainda não funciona"
    fi
}

# Função para configuração permanente
permanent_fix() {
    log_info "=== CONFIGURAÇÃO PERMANENTE ==="
    
    log_warning "Para tornar a configuração permanente, escolha uma opção:"
    echo "1. Usar systemd-resolved (recomendado para Ubuntu 18.04+)"
    echo "2. Usar NetworkManager"
    echo "3. Configuração manual no /etc/resolv.conf"
    echo ""
    
    read -p "Digite sua escolha (1-3): " choice
    
    case $choice in
        1)
            configure_systemd_resolved
            ;;
        2)
            configure_networkmanager
            ;;
        3)
            configure_manual_dns
            ;;
        *)
            log_warning "Opção inválida"
            ;;
    esac
}

# Configurar systemd-resolved
configure_systemd_resolved() {
    log_info "Configurando systemd-resolved..."
    
    # Criar/editar configuração
    sudo tee /etc/systemd/resolved.conf > /dev/null << EOF
[Resolve]
DNS=8.8.8.8 8.8.4.4 1.1.1.1
FallbackDNS=1.0.0.1
Domains=~.
DNSSEC=no
DNSOverTLS=no
Cache=yes
DNSStubListener=yes
EOF
    
    # Restart do serviço
    sudo systemctl restart systemd-resolved
    sudo systemctl enable systemd-resolved
    
    # Reconfigurar link simbólico
    sudo rm -f /etc/resolv.conf
    sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
    
    log_success "systemd-resolved configurado"
}

# Configurar NetworkManager
configure_networkmanager() {
    log_info "Configurando NetworkManager..."
    
    if command_exists nmcli; then
        # Configurar DNS via NetworkManager
        connection=$(nmcli -t -f NAME connection show --active | head -n1)
        if [ -n "$connection" ]; then
            sudo nmcli connection modify "$connection" ipv4.dns "8.8.8.8,8.8.4.4,1.1.1.1"
            sudo nmcli connection modify "$connection" ipv4.ignore-auto-dns yes
            sudo nmcli connection up "$connection"
            log_success "NetworkManager configurado para conexão: $connection"
        else
            log_error "Nenhuma conexão ativa encontrada"
        fi
    else
        log_error "NetworkManager não encontrado"
    fi
}

# Configuração manual
configure_manual_dns() {
    log_info "Configurando DNS manual..."
    
    # Tornar imutável
    sudo chattr -i /etc/resolv.conf 2>/dev/null || true
    
    sudo tee /etc/resolv.conf > /dev/null << EOF
# Configuração DNS manual
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 1.1.1.1
nameserver 1.0.0.1
EOF
    
    # Tornar imutável para evitar sobrescrita
    sudo chattr +i /etc/resolv.conf
    
    log_success "DNS manual configurado e protegido"
}

# Função para testar após correção
test_after_fix() {
    log_info "=== TESTE FINAL ==="
    
    # Teste de resolução DNS
    log_info "Testando resolução DNS..."
    if nslookup google.com; then
        log_success "Resolução DNS: OK"
    else
        log_error "Resolução DNS: FALHOU"
        return 1
    fi
    
    # Teste de ping
    log_info "Testando ping..."
    if ping -c 3 google.com; then
        log_success "Ping: OK"
    else
        log_error "Ping: FALHOU"
        return 1
    fi
    
    # Teste de atualização do sistema
    log_info "Testando atualização do sistema..."
    if sudo apt update >/dev/null 2>&1; then
        log_success "Atualização do sistema: OK"
    else
        log_error "Atualização do sistema: FALHOU"
        return 1
    fi
    
    log_success "Todos os testes passaram! DNS corrigido com sucesso."
}

# Função para mostrar informações adicionais
show_additional_info() {
    log_info "=== INFORMAÇÕES ADICIONAIS ==="
    
    echo "Comandos úteis para diagnóstico:"
    echo "• nslookup google.com - Testar resolução DNS"
    echo "• dig google.com - Diagnóstico DNS detalhado"
    echo "• systemd-resolve --status - Status do systemd-resolved"
    echo "• nmcli dev show - Configuração do NetworkManager"
    echo "• cat /etc/resolv.conf - Ver configuração DNS atual"
    echo ""
    
    echo "DNSs públicos recomendados:"
    echo "• Google: 8.8.8.8, 8.8.4.4"
    echo "• Cloudflare: 1.1.1.1, 1.0.0.1"
    echo "• OpenDNS: 208.67.222.222, 208.67.220.220"
    echo ""
}

# Função principal
main() {
    echo "================================================================"
    echo "           SCRIPT DE DIAGNÓSTICO E CORREÇÃO DNS"
    echo "================================================================"
    echo ""
    
    # Verificar se é root ou tem sudo
    if [ "$EUID" -eq 0 ]; then
        log_warning "Executando como root"
    elif sudo -n true 2>/dev/null; then
        log_info "Sudo disponível"
    else
        log_error "Este script precisa de privilégios sudo"
        exit 1
    fi
    
    # Diagnóstico inicial
    test_connectivity
    connectivity_result=$?
    
    diagnose_dns
    
    if [ $connectivity_result -eq 0 ]; then
        echo ""
        log_info "Problema identificado: DNS não funciona, mas conectividade IP sim"
        echo ""
        
        read -p "Deseja tentar corrigir o DNS? (s/n): " fix_choice
        if [[ $fix_choice =~ ^[Ss]$ ]]; then
            backup_config
            fix_dns
            
            echo ""
            read -p "Deseja configurar DNS permanentemente? (s/n): " perm_choice
            if [[ $perm_choice =~ ^[Ss]$ ]]; then
                permanent_fix
            fi
            
            echo ""
            test_after_fix
        fi
    else
        log_error "Problema de conectividade básica - verifique cabo/wifi"
    fi
    
    echo ""
    show_additional_info
}

# Verificar argumentos
case "${1:-}" in
    --test-only)
        test_connectivity
        diagnose_dns
        ;;
    --fix-only)
        fix_dns
        test_after_fix
        ;;
    --help|-h)
        echo "Uso: $0 [opção]"
        echo ""
        echo "Opções:"
        echo "  --test-only    Apenas diagnosticar, não corrigir"
        echo "  --fix-only     Apenas aplicar correção rápida"
        echo "  --help, -h     Mostrar esta ajuda"
        echo ""
        echo "Sem argumentos: Diagnóstico completo e correção interativa"
        ;;
    *)
        main
        ;;
esac

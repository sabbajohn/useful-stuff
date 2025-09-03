#!/bin/bash

# Verifica se os comandos essenciais estão instalados
for cmd in curl gum; do
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

# Verifica disponibilidade de comandos de rede
HAS_IFCONFIG=false
HAS_IP=false

if command -v ifconfig &>/dev/null; then
    HAS_IFCONFIG=true
fi

if command -v ip &>/dev/null; then
    HAS_IP=true
fi

if [[ "$HAS_IFCONFIG" == false && "$HAS_IP" == false ]]; then
    echo "Erro: Nenhum comando de rede disponível (ifconfig ou ip)."
    echo "Instale net-tools (ifconfig) ou iproute2 (ip)."
    exit 1
fi

# Função para obter IP público
get_public_ip() {
    echo "🌐 Buscando IP público..."
    
    # Tenta vários serviços para obter o IP público
    services=(
        "https://ipinfo.io/ip"
        "https://icanhazip.com"
        "https://ifconfig.me"
        "https://api.ipify.org"
    )
    
    for service in "${services[@]}"; do
        ip=$(curl -s --connect-timeout 5 "$service" 2>/dev/null | tr -d '\n')
        if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            echo "✅ IP público: $ip"
            echo "🌍 Serviço usado: $service"
            return 0
        fi
    done
    
    echo "❌ Não foi possível obter o IP público"
    return 1
}

# Função para listar interfaces físicas conectadas
list_physical_interfaces() {
    echo "🔌 Interfaces físicas conectadas:"
    echo "================================"
    
    # Para macOS ou sistemas com ifconfig
    if [[ "$HAS_IFCONFIG" == true ]]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS - usa ifconfig -l para listar interfaces
            interfaces=$(ifconfig -l)
        else
            # Linux com ifconfig - lista interfaces de forma diferente
            interfaces=$(ifconfig -s | tail -n +2 | awk '{print $1}')
        fi
        
        for interface in $interfaces; do
            # Verifica se a interface está ativa
            is_active=false
            if [[ "$OSTYPE" == "darwin"* ]]; then
                status=$(ifconfig "$interface" | grep "status:" | awk '{print $2}')
                if [[ "$status" == "active" ]]; then
                    is_active=true
                fi
            else
                # Linux - verifica se interface está UP
                if ifconfig "$interface" | grep -q "UP"; then
                    is_active=true
                    status="UP"
                fi
            fi
            
            inet=$(ifconfig "$interface" | grep "inet " | head -1 | awk '{print $2}')
            
            # Remove prefixo addr: se existir (algumas versões do Linux)
            inet=$(echo "$inet" | sed 's/addr://')
            
            if [[ "$is_active" == true && -n "$inet" && "$inet" != "127.0.0.1" ]]; then
                echo "📡 Interface: $interface"
                echo "   IP: $inet"
                
                # Obtém informações adicionais
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    netmask=$(ifconfig "$interface" | grep "inet " | head -1 | awk '{print $4}')
                else
                    netmask=$(ifconfig "$interface" | grep "inet " | head -1 | awk '{print $4}' | sed 's/Mask://')
                fi
                echo "   Netmask: $netmask"
                
                # Identifica tipo de interface
                if [[ "$interface" == en0* ]]; then
                    echo "   Tipo: Wi-Fi/Ethernet Principal"
                elif [[ "$interface" == en* ]]; then
                    echo "   Tipo: Ethernet"
                elif [[ "$interface" == eth* ]]; then
                    echo "   Tipo: Ethernet"
                elif [[ "$interface" == wlan* ]] || [[ "$interface" == wlp* ]]; then
                    echo "   Tipo: Wi-Fi"
                elif [[ "$interface" == utun* ]] || [[ "$interface" == tun* ]]; then
                    echo "   Tipo: VPN/Tunnel"
                fi
                
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    echo "   Status: $status"
                else
                    echo "   Status: $status"
                fi
                echo
            fi
        done
    fi
    
    # Para Linux com comando ip (se ifconfig não estiver disponível)
    if [[ "$HAS_IP" == true && "$HAS_IFCONFIG" == false ]]; then
        echo "📋 Usando comando 'ip' (ifconfig não disponível)"
        ip -4 addr show | grep -E "^[0-9]+:|inet " | while read line; do
            if [[ $line =~ ^[0-9]+: ]]; then
                interface=$(echo "$line" | awk -F': ' '{print $2}' | awk '{print $1}')
                echo "📡 Interface: $interface"
            elif [[ $line =~ inet ]]; then
                ip_addr=$(echo "$line" | awk '{print $2}' | cut -d'/' -f1)
                if [[ "$ip_addr" != "127.0.0.1" ]]; then
                    echo "   IP: $ip_addr"
                    echo "   Status: UP"
                    echo
                fi
            fi
        done
    fi
}

# Função para mostrar gateway padrão
show_default_gateway() {
    echo "🚪 Gateway padrão:"
    echo "=================="
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - usa route
        if command -v route &>/dev/null; then
            gateway=$(route -n get default 2>/dev/null | grep gateway | awk '{print $2}')
            interface=$(route -n get default 2>/dev/null | grep interface | awk '{print $2}')
            
            if [[ -n "$gateway" ]]; then
                echo "🛣️  Gateway: $gateway"
                echo "📡 Interface: $interface"
            else
                echo "❌ Gateway padrão não encontrado"
            fi
        else
            echo "❌ Comando 'route' não disponível"
        fi
    else
        # Linux - tenta ip route primeiro, depois route
        if [[ "$HAS_IP" == true ]]; then
            gateway=$(ip route 2>/dev/null | grep default | awk '{print $3}' | head -1)
            interface=$(ip route 2>/dev/null | grep default | awk '{print $5}' | head -1)
        elif command -v route &>/dev/null; then
            gateway=$(route -n 2>/dev/null | grep "^0.0.0.0" | awk '{print $2}' | head -1)
            interface=$(route -n 2>/dev/null | grep "^0.0.0.0" | awk '{print $8}' | head -1)
        fi
        
        if [[ -n "$gateway" ]]; then
            echo "🛣️  Gateway: $gateway"
            echo "📡 Interface: $interface"
        else
            echo "❌ Gateway padrão não encontrado"
        fi
    fi
    echo
}

# Função para mostrar servidores DNS
show_dns_servers() {
    echo "🌐 Servidores DNS:"
    echo "=================="
    
    if [[ -f /etc/resolv.conf ]]; then
        dns_servers=$(grep "^nameserver" /etc/resolv.conf | awk '{print $2}')
        if [[ -n "$dns_servers" ]]; then
            echo "$dns_servers" | while read dns; do
                echo "🔍 DNS: $dns"
            done
        else
            echo "❌ Nenhum servidor DNS encontrado em /etc/resolv.conf"
        fi
    else
        echo "❌ Arquivo /etc/resolv.conf não encontrado"
    fi
    echo
}

# Função para teste de conectividade
test_connectivity() {
    echo "🔍 Testando conectividade..."
    echo "============================"
    
    hosts=("8.8.8.8" "1.1.1.1" "google.com")
    
    for host in "${hosts[@]}"; do
        if ping -c 1 -W 3000 "$host" &>/dev/null; then
            echo "✅ $host - Conectado"
        else
            echo "❌ $host - Falha na conexão"
        fi
    done
    echo
}

# Função para mostrar estatísticas da interface
show_interface_stats() {
    interface=$(gum input --placeholder "Digite o nome da interface (ex: en0, eth0)")
    [[ -z "$interface" ]] && return 0
    
    echo "📊 Estatísticas da interface $interface:"
    echo "========================================"
    
    if [[ "$HAS_IFCONFIG" == true ]]; then
        stats=$(ifconfig "$interface" 2>/dev/null)
        if [[ -n "$stats" ]]; then
            echo "$stats" | grep -E "(RX|TX) packets"
            echo "$stats" | grep -E "(RX|TX) bytes"
            echo "$stats" | grep -E "collisions|errors"
        else
            echo "❌ Interface '$interface' não encontrada"
        fi
    elif [[ "$HAS_IP" == true ]]; then
        stats=$(ip -s link show "$interface" 2>/dev/null)
        if [[ -n "$stats" ]]; then
            echo "📈 Estatísticas disponíveis via 'ip':"
            echo "$stats"
        else
            echo "❌ Interface '$interface' não encontrada"
        fi
    else
        echo "❌ Nenhum comando disponível para mostrar estatísticas"
    fi
    echo
}

# Função para scan de rede local
scan_local_network() {
    echo "🔍 Escaneando rede local..."
    
    # Obtém a rede local usando método mais compatível
    local_ip=""
    
    if [[ "$HAS_IFCONFIG" == true ]]; then
        local_ip=$(ifconfig 2>/dev/null | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}' | sed 's/addr://')
    elif [[ "$HAS_IP" == true ]]; then
        local_ip=$(ip route get 8.8.8.8 2>/dev/null | grep src | awk '{print $7}' | head -1)
    fi
    
    if [[ -z "$local_ip" ]]; then
        echo "❌ Não foi possível determinar o IP local"
        return 1
    fi
    
    network=$(echo "$local_ip" | cut -d'.' -f1-3).0/24
    echo "🌐 Escaneando rede: $network"
    echo "🏠 Seu IP: $local_ip"
    echo "============================"
    
    # Ping sweep otimizado
    base_ip=$(echo "$local_ip" | cut -d'.' -f1-3)
    echo "🔍 Dispositivos encontrados:"
    
    # Função para fazer ping em paralelo (mais eficiente)
    ping_host() {
        local ip="$1"
        if ping -c 1 -W 1000 "$ip" &>/dev/null; then
            echo "✅ $ip está ativo"
        fi
    }
    
    # Exporta a função para usar com parallel/xargs se disponível
    export -f ping_host
    
    # Cria lista de IPs e testa em lotes para ser mais eficiente
    echo "⏳ Escaneando... (isso pode levar alguns minutos)"
    
    for i in {1..254}; do
        ip="$base_ip.$i"
        ping_host "$ip" &
        
        # Limita o número de processos paralelos
        if (( i % 20 == 0 )); then
            wait
        fi
    done
    
    wait  # Espera todos os processos terminarem
    echo "✅ Scan concluído!"
    echo
}

# Função principal de resumo da rede
network_summary() {
    clear
    echo "📋 RESUMO DA CONFIGURAÇÃO DE REDE"
    echo "=================================="
    
    # Mostra informações do sistema
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "💻 Sistema: macOS"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "💻 Sistema: Linux"
    else
        echo "💻 Sistema: $OSTYPE"
    fi
    
    echo "🔧 Comandos disponíveis:"
    if [[ "$HAS_IFCONFIG" == true ]]; then
        echo "   ✅ ifconfig"
    else
        echo "   ❌ ifconfig"
    fi
    
    if [[ "$HAS_IP" == true ]]; then
        echo "   ✅ ip"
    else
        echo "   ❌ ip"
    fi
    echo
    
    list_physical_interfaces
    show_default_gateway
    show_dns_servers
    get_public_ip
    echo
    
    gum confirm "Deseja retornar ao menu?" || exit 0
}

# Loop principal
while true; do
    opcao=$(gum choose \
        "📋 Resumo completo da rede" \
        "🔌 Listar interfaces físicas" \
        "🌐 Verificar IP público" \
        "🚪 Mostrar gateway padrão" \
        "🔍 Mostrar servidores DNS" \
        "📊 Estatísticas de interface" \
        "🌍 Testar conectividade" \
        "🔍 Escanear rede local" \
        "🚪 Sair")

    case "$opcao" in
    "📋 Resumo completo da rede")
        network_summary
        ;;
    "🔌 Listar interfaces físicas")
        list_physical_interfaces
        gum confirm "Deseja retornar ao menu?" || exit 0
        ;;
    "🌐 Verificar IP público")
        get_public_ip
        echo
        gum confirm "Deseja retornar ao menu?" || exit 0
        ;;
    "🚪 Mostrar gateway padrão")
        show_default_gateway
        gum confirm "Deseja retornar ao menu?" || exit 0
        ;;
    "🔍 Mostrar servidores DNS")
        show_dns_servers
        gum confirm "Deseja retornar ao menu?" || exit 0
        ;;
    "📊 Estatísticas de interface")
        show_interface_stats
        gum confirm "Deseja retornar ao menu?" || exit 0
        ;;
    "🌍 Testar conectividade")
        test_connectivity
        gum confirm "Deseja retornar ao menu?" || exit 0
        ;;
    "🔍 Escanear rede local")
        scan_local_network
        gum confirm "Deseja retornar ao menu?" || exit 0
        ;;
    "🚪 Sair")
        exit 0
        ;;
    esac
done

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

# Arquivo para salvar histórico de dispositivos descobertos
DEVICE_HISTORY="$HOME/.network_devices_history"
OUI_DATABASE="/tmp/oui_database.txt"

# Função para baixar/atualizar base de dados OUI (fabricantes)
update_oui_database() {
    if [[ ! -f "$OUI_DATABASE" ]] || [[ $(find "$OUI_DATABASE" -mtime +7 2>/dev/null) ]]; then
        echo "📡 Atualizando base de dados de fabricantes..."
        # Base de dados simplificada dos principais fabricantes
        cat > "$OUI_DATABASE" << 'EOF'
00:00:5e:Xerox
00:01:42:Cisco
00:03:93:Apple
00:50:56:VMware
00:0c:29:VMware
00:05:69:VMware
00:1c:42:Parallels
08:00:27:Oracle VirtualBox
00:15:5d:Microsoft
00:17:fa:Cisco
00:1b:21:Intel
00:1f:3c:Apple
00:23:df:Apple
00:25:00:Apple
3c:15:c2:Apple
40:6c:8f:Apple
78:4f:43:Apple
7c:d1:c3:Apple
88:e9:fe:Apple
a4:83:e7:Apple
bc:ec:5d:Apple
f0:18:98:Apple
f4:37:b7:Apple
fc:25:3f:Apple
00:04:ac:IBM
00:06:29:IBM
00:11:25:IBM
00:14:5e:IBM
00:16:35:IBM
00:21:5a:IBM
00:04:75:Linksys
00:06:25:Linksys
00:12:17:Linksys
00:13:10:Linksys
00:14:bf:Linksys
00:18:39:Linksys
00:1a:70:Linksys
00:1d:7e:Linksys
00:21:29:Linksys
00:22:6b:Linksys
00:25:9c:Linksys
EOF
    fi
}

# Função para identificar fabricante pelo MAC
identify_vendor() {
    local mac="$1"
    if [[ -z "$mac" ]]; then
        echo "Desconhecido"
        return
    fi
    
    # Normaliza o MAC para formato padrão (primeiros 6 chars)
    mac_prefix=$(echo "$mac" | tr '[:upper:]' '[:lower:]' | sed 's/[:-]//g' | cut -c1-6)
    
    # Busca na base de dados OUI
    vendor=$(grep -i "^${mac_prefix:0:2}:${mac_prefix:2:2}:${mac_prefix:4:2}:" "$OUI_DATABASE" 2>/dev/null | cut -d':' -f4)
    
    if [[ -n "$vendor" ]]; then
        echo "$vendor"
    else
        echo "Desconhecido"
    fi
}

# Função para obter MAC address de um IP
get_mac_address() {
    local ip="$1"
    local mac=""
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - usa arp
        mac=$(arp -n "$ip" 2>/dev/null | awk '{print $4}' | grep -E '^([0-9a-fA-F]{2}[:-]){5}[0-9a-fA-F]{2}$')
    else
        # Linux - tenta ip neigh primeiro, depois arp
        if [[ "$HAS_IP" == true ]]; then
            mac=$(ip neigh show "$ip" 2>/dev/null | awk '{print $5}' | grep -E '^([0-9a-fA-F]{2}[:-]){5}[0-9a-fA-F]{2}$')
        elif command -v arp &>/dev/null; then
            mac=$(arp -n "$ip" 2>/dev/null | awk '{print $3}' | grep -E '^([0-9a-fA-F]{2}[:-]){5}[0-9a-fA-F]{2}$')
        fi
    fi
    
    echo "$mac"
}

# Função para salvar dispositivo descoberto no histórico
save_discovered_device() {
    local ip="$1"
    local mac="$2"
    local vendor="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Remove entradas antigas do mesmo IP
    if [[ -f "$DEVICE_HISTORY" ]]; then
        grep -v "^$ip|" "$DEVICE_HISTORY" > "${DEVICE_HISTORY}.tmp" 2>/dev/null || true
        mv "${DEVICE_HISTORY}.tmp" "$DEVICE_HISTORY" 2>/dev/null || true
    fi
    
    # Adiciona nova entrada
    echo "$ip|$mac|$vendor|$timestamp" >> "$DEVICE_HISTORY"
}

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

# Função para scan de rede local avançado
scan_local_network() {
    echo "🔍 Escaneando rede local avançado..."
    
    # Atualiza base de dados OUI
    update_oui_database
    
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
    echo "===================================================="
    
    # Ping sweep otimizado
    base_ip=$(echo "$local_ip" | cut -d'.' -f1-3)
    echo "🔍 Dispositivos encontrados:"
    echo "===================================================="
    printf "%-15s %-18s %-20s %s\n" "IP" "MAC Address" "Fabricante" "Status"
    echo "---------------------------------------------------"
    
    discovered_devices=()
    
    # Função para fazer ping e obter informações
    scan_host() {
        local ip="$1"
        if ping -c 1 -W 1000 "$ip" &>/dev/null; then
            # Aguarda um pouco para a entrada ARP ser populada
            sleep 0.1
            
            local mac=$(get_mac_address "$ip")
            local vendor="Desconhecido"
            
            if [[ -n "$mac" && "$mac" != "(incomplete)" ]]; then
                vendor=$(identify_vendor "$mac")
            else
                mac="N/A"
            fi
            
            printf "✅ %-12s %-18s %-20s %s\n" "$ip" "$mac" "$vendor" "Ativo"
            
            # Salva no histórico
            save_discovered_device "$ip" "$mac" "$vendor"
            
            # Adiciona à lista de dispositivos descobertos
            discovered_devices+=("$ip|$mac|$vendor")
        fi
    }
    
    # Exporta a função para usar com parallel/xargs se disponível
    export -f scan_host
    export -f get_mac_address
    export -f identify_vendor
    export -f save_discovered_device
    export OUI_DATABASE
    export DEVICE_HISTORY
    export OSTYPE
    export HAS_IP
    
    echo "⏳ Escaneando... (isso pode levar alguns minutos)"
    
    # Primeiro força a descoberta ARP fazendo ping broadcast
    if [[ "$OSTYPE" == "darwin"* ]]; then
        ping -c 1 -t 1 "${base_ip}.255" &>/dev/null || true
    else
        ping -c 1 -W 1 "${base_ip}.255" &>/dev/null || true
    fi
    
    for i in {1..254}; do
        ip="$base_ip.$i"
        scan_host "$ip" &
        
        # Limita o número de processos paralelos
        if (( i % 20 == 0 )); then
            wait
        fi
    done
    
    wait  # Espera todos os processos terminarem
    
    echo "---------------------------------------------------"
    echo "✅ Scan concluído! Encontrados ${#discovered_devices[@]} dispositivos ativos"
    
    if [[ ${#discovered_devices[@]} -gt 0 ]]; then
        echo "\n📋 Resumo dos dispositivos encontrados:"
        for device in "${discovered_devices[@]}"; do
            ip=$(echo "$device" | cut -d'|' -f1)
            mac=$(echo "$device" | cut -d'|' -f2)
            vendor=$(echo "$device" | cut -d'|' -f3)
            echo "🔹 $ip ($vendor)"
        done
        
        # Pergunta se quer salvar para uso futuro
        if gum confirm "Salvar dispositivos para sugestões futuras?"; then
            echo "💾 Dispositivos salvos para uso em outros scripts!"
        fi
    fi
    
    echo
}

# Função para utilitários netcat
netcat_utilities() {
    if ! command -v nc &>/dev/null && ! command -v netcat &>/dev/null; then
        echo "❌ Netcat não está instalado"
        echo "Para instalar:"
        echo "  macOS: brew install netcat"
        echo "  Linux: sudo apt install netcat  # ou sudo yum install nc"
        return 1
    fi
    
    echo "🔧 Utilitários Netcat"
    echo "===================="
    
    nc_cmd="nc"
    if command -v netcat &>/dev/null && ! command -v nc &>/dev/null; then
        nc_cmd="netcat"
    fi
    
    action=$(gum choose \
        "🔍 Verificar porta específica" \
        "📡 Escutar em porta (servidor)" \
        "📤 Enviar arquivo via rede" \
        "📥 Receber arquivo via rede" \
        "💬 Chat simples" \
        "⚡ Teste de velocidade de rede" \
        "🔙 Voltar")
    
    case "$action" in
    "🔍 Verificar porta específica")
        host=$(gum input --placeholder "Digite o host/IP")
        port=$(gum input --placeholder "Digite a porta")
        [[ -z "$host" || -z "$port" ]] && return 0
        
        echo "🔍 Testando $host:$port..."
        if timeout 5 $nc_cmd -z "$host" "$port" 2>/dev/null; then
            echo "✅ Porta $port está aberta em $host"
        else
            echo "❌ Porta $port está fechada ou filtrada em $host"
        fi
        ;;
        
    "📡 Escutar em porta (servidor)")
        port=$(gum input --placeholder "Digite a porta para escutar")
        [[ -z "$port" ]] && return 0
        
        echo "📡 Escutando na porta $port..."
        echo "💡 Para conectar: nc $(hostname) $port"
        echo "🛑 Para parar: Ctrl+C"
        $nc_cmd -l "$port"
        ;;
        
    "📤 Enviar arquivo via rede")
        file_path=$(gum input --placeholder "Caminho do arquivo")
        host=$(gum input --placeholder "IP de destino")
        port=$(gum input --placeholder "Porta" --value "9999")
        
        [[ -z "$file_path" || -z "$host" || -z "$port" ]] && return 0
        
        if [[ ! -f "$file_path" ]]; then
            echo "❌ Arquivo não encontrado: $file_path"
            return 1
        fi
        
        echo "📤 Enviando $file_path para $host:$port..."
        echo "💡 No destino execute: nc -l $port > nome_arquivo"
        $nc_cmd "$host" "$port" < "$file_path"
        echo "✅ Arquivo enviado!"
        ;;
        
    "📥 Receber arquivo via rede")
        port=$(gum input --placeholder "Porta para escutar" --value "9999")
        output_file=$(gum input --placeholder "Nome do arquivo de saída")
        
        [[ -z "$port" || -z "$output_file" ]] && return 0
        
        echo "📥 Aguardando arquivo na porta $port..."
        echo "💡 Para enviar: nc $(hostname) $port < arquivo"
        $nc_cmd -l "$port" > "$output_file"
        echo "✅ Arquivo recebido: $output_file"
        ;;
        
    "💬 Chat simples")
        mode=$(gum choose "Servidor (escutar)" "Cliente (conectar)")
        
        if [[ "$mode" == "Servidor (escutar)" ]]; then
            port=$(gum input --placeholder "Porta para chat" --value "12345")
            echo "💬 Chat servidor na porta $port"
            echo "💡 Para conectar: nc $(hostname) $port"
            $nc_cmd -l "$port"
        else
            host=$(gum input --placeholder "IP do servidor")
            port=$(gum input --placeholder "Porta" --value "12345")
            [[ -z "$host" || -z "$port" ]] && return 0
            
            echo "💬 Conectando ao chat $host:$port"
            $nc_cmd "$host" "$port"
        fi
        ;;
        
    "⚡ Teste de velocidade de rede")
        host=$(gum input --placeholder "IP de destino")
        port=$(gum input --placeholder "Porta" --value "5001")
        
        [[ -z "$host" || -z "$port" ]] && return 0
        
        echo "⚡ Teste de velocidade para $host:$port"
        echo "💡 No destino execute: nc -l $port > /dev/null"
        dd if=/dev/zero bs=1M count=100 2>/dev/null | pv | $nc_cmd "$host" "$port"
        ;;
    esac
    
    echo
}

# Função para utilitários telnet
telnet_utilities() {
    if ! command -v telnet &>/dev/null; then
        echo "❌ Telnet não está instalado"
        echo "Para instalar:"
        echo "  macOS: brew install telnet"
        echo "  Linux: sudo apt install telnet  # ou sudo yum install telnet"
        return 1
    fi
    
    echo "📞 Utilitários Telnet"
    echo "==================="
    
    action=$(gum choose \
        "🔍 Testar conectividade de porta" \
        "📧 Testar servidor SMTP" \
        "🌐 Testar servidor HTTP" \
        "💬 Conectar via Telnet" \
        "🔙 Voltar")
    
    case "$action" in
    "🔍 Testar conectividade de porta")
        host=$(gum input --placeholder "Digite o host/IP")
        port=$(gum input --placeholder "Digite a porta")
        [[ -z "$host" || -z "$port" ]] && return 0
        
        echo "🔍 Testando conectividade $host:$port..."
        timeout 10 telnet "$host" "$port" << EOF
quit
EOF
        ;;
        
    "📧 Testar servidor SMTP")
        host=$(gum input --placeholder "Servidor SMTP (ex: smtp.gmail.com)")
        port=$(gum input --placeholder "Porta SMTP" --value "587")
        
        [[ -z "$host" || -z "$port" ]] && return 0
        
        echo "📧 Testando SMTP $host:$port..."
        echo "💡 Comandos úteis: EHLO, MAIL FROM, RCPT TO, QUIT"
        telnet "$host" "$port"
        ;;
        
    "🌐 Testar servidor HTTP")
        host=$(gum input --placeholder "Servidor web (ex: google.com)")
        port=$(gum input --placeholder "Porta HTTP" --value "80")
        
        [[ -z "$host" || -z "$port" ]] && return 0
        
        echo "🌐 Testando HTTP $host:$port..."
        echo "💡 Exemplo: GET / HTTP/1.1 + Enter + Host: $host + Enter + Enter"
        telnet "$host" "$port"
        ;;
        
    "💬 Conectar via Telnet")
        host=$(gum input --placeholder "Host/IP")
        port=$(gum input --placeholder "Porta")
        
        [[ -z "$host" || -z "$port" ]] && return 0
        
        echo "💬 Conectando via Telnet $host:$port..."
        telnet "$host" "$port"
        ;;
    esac
    
    echo
}

# Função para utilitários nmap
nmap_utilities() {
    if ! command -v nmap &>/dev/null; then
        echo "❌ Nmap não está instalado"
        echo "Para instalar:"
        echo "  macOS: brew install nmap"
        echo "  Linux: sudo apt install nmap  # ou sudo yum install nmap"
        return 1
    fi
    
    echo "🗺️  Utilitários Nmap"
    echo "=================="
    
    action=$(gum choose \
        "🔍 Scan básico de host" \
        "🚪 Scan de portas específicas" \
        "🌐 Scan de rede completo" \
        "🔍 Detecção de OS e serviços" \
        "⚡ Scan rápido (top ports)" \
        "🕵️  Scan stealth (SYN)" \
        "📋 Scan de vulnerabilidades" \
        "🔙 Voltar")
    
    case "$action" in
    "🔍 Scan básico de host")
        host=$(gum input --placeholder "Digite o host/IP")
        [[ -z "$host" ]] && return 0
        
        echo "🔍 Scan básico de $host..."
        nmap "$host"
        ;;
        
    "🚪 Scan de portas específicas")
        host=$(gum input --placeholder "Digite o host/IP")
        ports=$(gum input --placeholder "Portas (ex: 22,80,443 ou 1-1000)")
        
        [[ -z "$host" || -z "$ports" ]] && return 0
        
        echo "🚪 Scanning portas $ports em $host..."
        nmap -p "$ports" "$host"
        ;;
        
    "🌐 Scan de rede completo")
        network=$(gum input --placeholder "Rede (ex: 192.168.1.0/24)")
        [[ -z "$network" ]] && return 0
        
        echo "🌐 Scan completo da rede $network..."
        nmap -sn "$network"
        ;;
        
    "🔍 Detecção de OS e serviços")
        host=$(gum input --placeholder "Digite o host/IP")
        [[ -z "$host" ]] && return 0
        
        echo "🔍 Detectando OS e serviços em $host..."
        nmap -A "$host"
        ;;
        
    "⚡ Scan rápido (top ports)")
        host=$(gum input --placeholder "Digite o host/IP")
        [[ -z "$host" ]] && return 0
        
        echo "⚡ Scan rápido de $host..."
        nmap --top-ports 1000 "$host"
        ;;
        
    "🕵️  Scan stealth (SYN)")
        host=$(gum input --placeholder "Digite o host/IP")
        [[ -z "$host" ]] && return 0
        
        echo "🕵️  Scan stealth de $host..."
        echo "⚠️  Requer privilégios de root em alguns sistemas"
        nmap -sS "$host"
        ;;
        
    "📋 Scan de vulnerabilidades")
        host=$(gum input --placeholder "Digite o host/IP")
        [[ -z "$host" ]] && return 0
        
        echo "📋 Scan de vulnerabilidades em $host..."
        nmap --script vuln "$host"
        ;;
    esac
    
    echo
}

# Função para listar dispositivos descobertos recentemente
list_discovered_devices() {
    echo "📋 Dispositivos Descobertos Recentemente"
    echo "======================================="
    
    if [[ ! -f "$DEVICE_HISTORY" ]] || [[ ! -s "$DEVICE_HISTORY" ]]; then
        echo "❌ Nenhum dispositivo no histórico"
        echo "💡 Execute um scan de rede para descobrir dispositivos"
        return 0
    fi
    
    echo "📅 Dispositivos encontrados nos últimos scans:"
    echo "----------------------------------------------"
    printf "%-15s %-18s %-20s %s\n" "IP" "MAC Address" "Fabricante" "Última Vista"
    echo "----------------------------------------------"
    
    # Ordena por timestamp (mais recente primeiro)
    sort -t'|' -k4 -r "$DEVICE_HISTORY" | head -20 | while IFS='|' read -r ip mac vendor timestamp; do
        printf "%-15s %-18s %-20s %s\n" "$ip" "$mac" "$vendor" "$timestamp"
    done
    
    echo "----------------------------------------------"
    echo "📊 Total de dispositivos únicos: $(cut -d'|' -f1 "$DEVICE_HISTORY" | sort | uniq | wc -l)"
    echo
}
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
        "🔍 Escanear rede local (avançado)" \
        "📋 Dispositivos descobertos" \
        "🔧 Utilitários Netcat" \
        "📞 Utilitários Telnet" \
        "🗺️  Utilitários Nmap" \
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
    "🔍 Escanear rede local (avançado)")
        scan_local_network
        gum confirm "Deseja retornar ao menu?" || exit 0
        ;;
    "📋 Dispositivos descobertos")
        list_discovered_devices
        gum confirm "Deseja retornar ao menu?" || exit 0
        ;;
    "🔧 Utilitários Netcat")
        netcat_utilities
        gum confirm "Deseja retornar ao menu?" || exit 0
        ;;
    "📞 Utilitários Telnet")
        telnet_utilities
        gum confirm "Deseja retornar ao menu?" || exit 0
        ;;
    "🗺️  Utilitários Nmap")
        nmap_utilities
        gum confirm "Deseja retornar ao menu?" || exit 0
        ;;
    "🚪 Sair")
        exit 0
        ;;
    esac
done

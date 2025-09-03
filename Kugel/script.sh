#!/bin/bash

REMOTE_USER="kugel"
REMOTE_HOST="192.168.4.57"
REMOTE_DIR="/home/$REMOTE_USER/Kugel"  
LOCAL_MOUNT_DIR="$HOME/Projects/Kugel/Remote"

if ! command -v fzf &> /dev/null; then
    echo "fzf não está instalado. Instale-o primeiro (exemplo: 'sudo apt install fzf' no Linux ou 'brew install fzf' no macOS)."
    exit 1
fi

function menu() {
    while true; do
        OPTION=$(echo -e "Iniciar SSH\nMontar SSHFS\nDesmontar SSHFS\nExecutar compilar.sh\nExecutar rodar.sh\nExecutar atualizarweb.sh\nSair" | fzf --prompt="Selecione uma opção: " --height=10 --border --reverse)

        case $OPTION in
            "Iniciar SSH") init_ssh ;;
	    "Montar SSHFS") montar_sshfs ;;
            "Desmontar SSHFS") desmontar_sshfs ;;
            "Executar compilar.sh") executar_script "compilar.sh" ;;
            "Executar rodar.sh") executar_script "rodar.sh" ;;
            "Executar atualizarweb.sh") executar_script "atualizarweb.sh" ;;
            "Sair") exit 0 ;;
            *) echo "Opção inválida!" ;;
        esac
    done
}

function montar_sshfs() {
    if [ ! -d "$LOCAL_MOUNT_DIR" ]; then
        mkdir -p "$LOCAL_MOUNT_DIR"
    fi
    sshfs "${REMOTE_USER}@${REMOTE_HOST}:$REMOTE_DIR" "$LOCAL_MOUNT_DIR"
    if [ $? -eq 0 ]; then
        echo "Montagem concluída com sucesso!"
    else
        echo "Erro ao montar o diretório. Verifique sua conexão com a VPN."
    fi
}

function desmontar_sshfs() {
    if command -v fusermount &> /dev/null; then
        fusermount -u "$LOCAL_MOUNT_DIR"
    else
        umount "$LOCAL_MOUNT_DIR"
    fi
    if [ $? -eq 0 ]; then
        echo "Desmontagem concluída com sucesso!"
    else
        echo "Erro ao desmontar o diretório."
    fi
}

function init_ssh(){
	echo "Iniciando SSH com $REMOTE_HOST"
	ssh  ${REMOTE_USER}@${REMOTE_HOST}
}

function executar_script() {
    script_name=$1
    echo "Executando script: $script_name..."

    # Captura o sinal SIGINT (Ctrl+C) e define uma função para lidar com ele
    trap 'echo "Execução interrompida pelo usuário."; exit 1' SIGINT

    #ssh -t ${REMOTE_USER}@${REMOTE_HOST} "source ~/.zshrc && cd $REMOTE_DIR && ./$script_name" 2>&1 | tee /dev/tty
    ssh -t ${REMOTE_USER}@${REMOTE_HOST} "source ~/.zshrc && cd $REMOTE_DIR/ErpWeb && ./$script_name"

    if [ $? -eq 0 ]; then
        echo "Script ${script_name} executado com sucesso!"
    else
        echo "Erro ao executar ${script_name}. Verifique sua conexão com a VPN."
    fi

    # Remove o trap após a execução
    trap - SIGINT
}

menu

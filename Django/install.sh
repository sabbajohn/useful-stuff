#!/bin/bash

# Django Project Creator - Instalador
# Instala o django-project-creator para uso global

set -euo pipefail

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_PATH="$SCRIPT_DIR/django-project-creator.sh"
INSTALL_PATH="/usr/local/bin/django-project-creator"

echo -e "${BLUE}Django Project Creator - Instalador${NC}"
echo ""

# Verifica se o script existe
if [[ ! -f "$SCRIPT_PATH" ]]; then
    echo -e "${RED}❌ Erro: django-project-creator.sh não encontrado em $SCRIPT_DIR${NC}"
    exit 1
fi

# Verifica se tem permissão para instalar
if [[ ! -w "/usr/local/bin" ]]; then
    echo -e "${YELLOW}⚠️  Será necessário sudo para instalar em /usr/local/bin${NC}"
    echo ""
fi

echo -e "${BLUE}📦 Instalando django-project-creator...${NC}"

# Remove instalação anterior se existir
if [[ -L "$INSTALL_PATH" || -f "$INSTALL_PATH" ]]; then
    echo "Removendo instalação anterior..."
    sudo rm -f "$INSTALL_PATH"
fi

# Cria link simbólico
if sudo ln -sf "$SCRIPT_PATH" "$INSTALL_PATH"; then
    echo -e "${GREEN}✅ django-project-creator instalado com sucesso!${NC}"
    echo ""
    echo -e "${BLUE}🚀 Uso:${NC}"
    echo "  django-project-creator --help"
    echo "  django-project-creator meu_projeto"
    echo "  django-project-creator -n -t 'API (DRF)' minha_api"
    echo ""
    echo -e "${GREEN}🎉 Agora você pode usar django-project-creator de qualquer diretório!${NC}"
else
    echo -e "${RED}❌ Erro na instalação${NC}"
    exit 1
fi

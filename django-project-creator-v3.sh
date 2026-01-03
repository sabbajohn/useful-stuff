#!/bin/bash

# Django Project Creator v3.0 - Template Based (Simplified)
# Cria projetos Django usando templates especializados sem reescrita de arquivos

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Variáveis globais
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/Django/django-templates-v3"
CURRENT_DIR="$(pwd)"
PROJECT_NAME=""
PROJECT_TYPE=""

# Templates disponíveis (sem Celery - muito específico)
TEMPLATE_1="api-drf|Django REST Framework API|API REST pura com PostgreSQL + Redis"
TEMPLATE_2="web-fullstack|Django Web Fullstack|Django templates + API + PostgreSQL + Redis"
TEMPLATE_3="decoupled|Django + Vue/Quasar|Backend DRF + Frontend Vue.js/Quasar + PostgreSQL + Redis"

# Função para log com timestamp
log() {
    echo -e "${CYAN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

# Função para erro
error() {
    echo -e "${RED}❌ Erro: $1${NC}" >&2
    exit 1
}

# Função para sucesso
success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Função para warning
warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Função para mostrar ajuda
show_help() {
    cat << EOF
${BLUE}Django Project Creator v3.0 - Template Based${NC}

${CYAN}Uso:${NC}
  django-project-creator-v3.sh [nome_do_projeto] [tipo]

${CYAN}Descrição:${NC}
  Cria projetos Django usando templates pré-configurados.
  Cada template é uma estrutura completa e testada, sem modificações dinâmicas.

${CYAN}Templates Disponíveis:${NC}
  1) ${GREEN}api-drf${NC}        : Django REST Framework puro (PostgreSQL + Redis)
  2) ${GREEN}web-fullstack${NC}  : Django templates + API (PostgreSQL + Redis)
  3) ${GREEN}decoupled${NC}      : Backend DRF + Frontend Vue.js/Quasar (PostgreSQL + Redis)

${CYAN}Características dos Templates:${NC}
  📦 ${GREEN}api-drf${NC}:
     - Django REST Framework
     - Autenticação JWT
     - Documentação Swagger/ReDoc
     - PostgreSQL + Redis configurados
     - Docker Compose pronto
     - Estrutura API pura

  🌐 ${GREEN}web-fullstack${NC}:
     - Django tradicional com templates
     - Django REST Framework integrado
     - Frontend e Backend no mesmo projeto
     - PostgreSQL + Redis configurados
     - Docker Compose pronto

  🔄 ${GREEN}decoupled${NC}:
     - Backend: Django REST Framework puro
     - Frontend: Vue.js 3 + Quasar Framework
     - Totalmente separados
     - PostgreSQL + Redis configurados
     - Docker Compose com serviços separados

${CYAN}Exemplos:${NC}
  django-project-creator-v3.sh minha_api 1           # API REST Framework
  django-project-creator-v3.sh meu_site 2            # Web Fullstack  
  django-project-creator-v3.sh meu_app 3             # Decoupled (Django + Vue/Quasar)
  django-project-creator-v3.sh                       # Modo interativo

${CYAN}Instalação Global:${NC}
  sudo ln -sf $(realpath "$0") /usr/local/bin/django-creator
EOF
}

# Função para verificar se diretório de templates existe
check_templates_dir() {
    if [[ ! -d "$TEMPLATES_DIR" ]]; then
        error "Diretório de templates não encontrado: $TEMPLATES_DIR"
    fi
}

# Função para listar templates disponíveis
list_templates() {
    echo -e "${CYAN}📋 Templates Disponíveis:${NC}"
    echo ""
    
    IFS='|' read -r template_name title description <<< "$TEMPLATE_1"
    echo -e "  1) ${GREEN}${title}${NC}"
    echo -e "     ${description}"
    echo ""
    
    IFS='|' read -r template_name title description <<< "$TEMPLATE_2"
    echo -e "  2) ${GREEN}${title}${NC}"
    echo -e "     ${description}"
    echo ""
    
    IFS='|' read -r template_name title description <<< "$TEMPLATE_3"
    echo -e "  3) ${GREEN}${title}${NC}"
    echo -e "     ${description}"
    echo ""
}

# Função para escolher template interativo
choose_template_interactive() {
    list_templates
    
    while true; do
        read -p "Escolha o template (1-3): " choice
        case $choice in
            1)
                IFS='|' read -r template_name title description <<< "$TEMPLATE_1"
                PROJECT_TYPE="$template_name"
                echo -e "${GREEN}✅ Selecionado: ${title}${NC}"
                break
                ;;
            2)
                IFS='|' read -r template_name title description <<< "$TEMPLATE_2"
                PROJECT_TYPE="$template_name"
                echo -e "${GREEN}✅ Selecionado: ${title}${NC}"
                break
                ;;
            3)
                IFS='|' read -r template_name title description <<< "$TEMPLATE_3"
                PROJECT_TYPE="$template_name"
                echo -e "${GREEN}✅ Selecionado: ${title}${NC}"
                break
                ;;
            *)
                warning "Opção inválida. Escolha 1, 2 ou 3."
                ;;
        esac
    done
}

# Função para obter nome do projeto interativo  
get_project_name_interactive() {
    while [[ -z "$PROJECT_NAME" ]]; do
        read -p "📝 Nome do projeto: " PROJECT_NAME
        if [[ -z "$PROJECT_NAME" ]]; then
            warning "Nome do projeto é obrigatório"
        elif [[ -d "$CURRENT_DIR/$PROJECT_NAME" ]]; then
            warning "Diretório '$PROJECT_NAME' já existe"
            PROJECT_NAME=""
        fi
    done
}

# Função para copiar template
copy_template() {
    local template_path="$TEMPLATES_DIR/$PROJECT_TYPE"
    local target_path="$CURRENT_DIR/$PROJECT_NAME"
    
    if [[ ! -d "$template_path" ]]; then
        error "Template não encontrado: $template_path"
    fi
    
    log "📁 Copiando template '$PROJECT_TYPE'..."
    
    # Copia o template completo
    cp -r "$template_path" "$target_path"
    
    success "Template copiado com sucesso"
}

# Função para personalizar nomes no projeto
customize_project_names() {
    log "🔧 Personalizando nomes do projeto..."
    
    local project_path="$CURRENT_DIR/$PROJECT_NAME"
    cd "$project_path"
    
    # Substitui apenas nomes de projeto nos arquivos principais
    # (mantém a lógica simples, apenas troca nomes)
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS
        find . -type f \( -name "*.py" -o -name "*.yml" -o -name "*.yaml" -o -name "*.md" -o -name "*.json" \) \
            -exec sed -i '' "s/ProjTest/$PROJECT_NAME/g" {} + 2>/dev/null || true
        find . -type f \( -name "*.py" -o -name "*.yml" -o -name "*.yaml" -o -name "*.md" -o -name "*.json" \) \
            -exec sed -i '' "s/projtest/$PROJECT_NAME/g" {} + 2>/dev/null || true
    else
        # Linux
        find . -type f \( -name "*.py" -o -name "*.yml" -o -name "*.yaml" -o -name "*.md" -o -name "*.json" \) \
            -exec sed -i "s/ProjTest/$PROJECT_NAME/g" {} + 2>/dev/null || true
        find . -type f \( -name "*.py" -o -name "*.yml" -o -name "*.yaml" -o -name "*.md" -o -name "*.json" \) \
            -exec sed -i "s/projtest/$PROJECT_NAME/g" {} + 2>/dev/null || true
    fi
    
    success "Nomes personalizados"
}

# Função para criar ambiente virtual
create_virtual_environment() {
    log "🐍 Criando ambiente virtual..."
    
    if command -v python3 &> /dev/null; then
        python3 -m venv venv
        success "Ambiente virtual criado"
    else
        warning "Python3 não encontrado. Pule esta etapa se usar Docker"
    fi
}

# Função para mostrar próximos passos
show_next_steps() {
    echo ""
    echo -e "${GREEN}🎉 Projeto '$PROJECT_NAME' criado com sucesso!${NC}"
    echo ""
    echo -e "${CYAN}📋 Próximos passos:${NC}"
    echo ""
    echo "   1. Entre no diretório:"
    echo -e "      ${YELLOW}cd $PROJECT_NAME${NC}"
    echo ""
    
    case "$PROJECT_TYPE" in
        "api-drf")
            echo -e "   2. ${BLUE}Opção A: Usar Docker (Recomendado)${NC}"
            echo -e "      ${YELLOW}docker-compose up --build${NC}"
            echo ""
            echo -e "   3. ${BLUE}Opção B: Ambiente local${NC}"
            echo -e "      ${YELLOW}source venv/bin/activate${NC}"
            echo -e "      ${YELLOW}pip install -r requirements.txt${NC}"
            echo -e "      ${YELLOW}cd backend && python manage.py migrate${NC}"
            echo -e "      ${YELLOW}python manage.py runserver${NC}"
            echo ""
            echo -e "   📖 ${GREEN}API Documentation:${NC}"
            echo -e "      ${BLUE}http://localhost:8000/api/docs/${NC} (Swagger)"
            echo -e "      ${BLUE}http://localhost:8000/api/redoc/${NC} (ReDoc)"
            ;;
            
        "web-fullstack")
            echo -e "   2. ${BLUE}Opção A: Usar Docker (Recomendado)${NC}"
            echo -e "      ${YELLOW}docker-compose up --build${NC}"
            echo ""
            echo -e "   3. ${BLUE}Opção B: Ambiente local${NC}"
            echo -e "      ${YELLOW}source venv/bin/activate${NC}"
            echo -e "      ${YELLOW}pip install -r requirements.txt${NC}"
            echo -e "      ${YELLOW}cd backend && python manage.py migrate${NC}"
            echo -e "      ${YELLOW}python manage.py runserver${NC}"
            echo ""
            echo -e "   🌐 ${GREEN}Acesso:${NC}"
            echo -e "      ${BLUE}http://localhost:8000/${NC} (Site principal)"
            echo -e "      ${BLUE}http://localhost:8000/api/docs/${NC} (API Docs)"
            ;;
            
        "decoupled")
            echo -e "   2. ${BLUE}Iniciar Backend${NC}"
            echo -e "      ${YELLOW}docker-compose up backend postgres redis --build${NC}"
            echo ""
            echo -e "   3. ${BLUE}Iniciar Frontend (terminal separado)${NC}"
            echo -e "      ${YELLOW}cd frontend${NC}"
            echo -e "      ${YELLOW}npm install${NC}"
            echo -e "      ${YELLOW}npm run dev${NC}"
            echo ""
            echo -e "   🔄 ${GREEN}Acesso:${NC}"
            echo -e "      ${BLUE}http://localhost:3000/${NC} (Frontend Vue/Quasar)"
            echo -e "      ${BLUE}http://localhost:8000/api/docs/${NC} (Backend API)"
            echo ""
            echo -e "   📖 ${PURPLE}Consulte README_DECOUPLED.md para mais detalhes${NC}"
            ;;
    esac
    
    echo ""
    echo -e "${GREEN}✨ Feliz codificação!${NC}"
}

# Função principal
main() {
    echo -e "${BLUE}🚀 Django Project Creator v3.0${NC}"
    echo -e "${CYAN}📁 Diretório: $(pwd)${NC}"
    echo ""
    
    # Verifica se diretório de templates existe
    check_templates_dir
    
    # Parse argumentos simples
    if [[ $# -eq 0 ]]; then
        # Modo interativo
        get_project_name_interactive
        choose_template_interactive
    elif [[ $# -eq 1 ]]; then
        if [[ "$1" == "-h" || "$1" == "--help" ]]; then
            show_help
            exit 0
        fi
        # Só nome do projeto
        PROJECT_NAME="$1"
        if [[ -d "$CURRENT_DIR/$PROJECT_NAME" ]]; then
            error "Diretório '$PROJECT_NAME' já existe"
        fi
        choose_template_interactive
    elif [[ $# -eq 2 ]]; then
        # Nome e tipo
        PROJECT_NAME="$1"
        local template_choice="$2"
        
        if [[ -d "$CURRENT_DIR/$PROJECT_NAME" ]]; then
            error "Diretório '$PROJECT_NAME' já existe"
        fi
        
        case $template_choice in
            1)
                IFS='|' read -r template_name title description <<< "$TEMPLATE_1"
                PROJECT_TYPE="$template_name"
                echo -e "${GREEN}✅ Template: ${title}${NC}"
                ;;
            2)
                IFS='|' read -r template_name title description <<< "$TEMPLATE_2"
                PROJECT_TYPE="$template_name"
                echo -e "${GREEN}✅ Template: ${title}${NC}"
                ;;
            3)
                IFS='|' read -r template_name title description <<< "$TEMPLATE_3"
                PROJECT_TYPE="$template_name"
                echo -e "${GREEN}✅ Template: ${title}${NC}"
                ;;
            *)
                error "Template inválido: $template_choice. Use 1, 2 ou 3"
                ;;
        esac
    else
        error "Muitos argumentos. Use: $0 [nome] [tipo] ou $0 --help"
    fi
    
    echo ""
    log "🚀 Criando projeto Django '$PROJECT_NAME' com template '$PROJECT_TYPE'"
    echo ""
    
    # Executa criação do projeto
    copy_template
    customize_project_names
    create_virtual_environment
    
    # Volta ao diretório original
    cd "$CURRENT_DIR"
    
    show_next_steps
}

# Executa o script
main "$@"

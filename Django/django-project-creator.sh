#!/bin/bash

# Django Project Creator v2.0 (Production Ready)
# Cria projetos Django usando templates especializados
# Pode ser executado de qualquer diretório

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
TEMPLATES_DIR="$SCRIPT_DIR/django-templates"
CURRENT_DIR="$(pwd)"
PROJECT_NAME=""
PROJECT_TYPE=""
USE_POSTGRES=true
USE_REDIS=true
USE_CELERY=true
USE_DOCKER=true
NON_INTERACTIVE=false

# Função para detectar diretório dos templates
detect_templates_dir() {
    # Primeiro tenta o diretório do script
    if [[ -d "$SCRIPT_DIR/django-templates" ]]; then
        TEMPLATES_DIR="$SCRIPT_DIR/django-templates"
        return 0
    fi
    
    # Tenta diretório padrão na pasta Django
    local django_dir="/Users/johnsabba/Projects/Scripts/Django/django-templates"
    if [[ -d "$django_dir" ]]; then
        TEMPLATES_DIR="$django_dir"
        return 0
    fi
    
    # Busca no PATH
    local script_location="$(which django-project-creator 2>/dev/null || echo "")"
    if [[ -n "$script_location" ]]; then
        local script_parent="$(dirname "$script_location")"
        if [[ -d "$script_parent/django-templates" ]]; then
            TEMPLATES_DIR="$script_parent/django-templates"
            return 0
        fi
    fi
    
    error "Diretório de templates não encontrado. Certifique-se que 'django-templates' está no mesmo diretório do script."
}

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
${BLUE}Django Project Creator v2.0 (Production Ready)${NC}

${CYAN}Uso:${NC}
  django-project-creator.sh [opções] [nome_do_projeto]

${CYAN}Descrição:${NC}
  Cria projetos Django profissionais usando templates especializados.
  Pode ser executado de qualquer diretório - o projeto será criado no diretório atual.

${CYAN}Tipos de Projeto:${NC}
  - ${GREEN}Web tradicional${NC}  : Django clássico com templates e frontend integrado
  - ${GREEN}API (DRF)${NC}        : API REST pura com Django REST Framework
  - ${GREEN}Fullstack${NC}        : API + Frontend integrado (monolito moderno)
  - ${GREEN}Decoupled${NC}        : Backend API para frontend separado (React, Vue, etc)

${CYAN}Opções:${NC}
  -t, --type TYPE      Tipo do projeto: 'Web tradicional', 'API (DRF)', 'Fullstack', 'Decoupled'
  --no-postgres        Usar SQLite em vez de PostgreSQL
  --no-redis           Não usar Redis (cache local)
  --no-celery          Não usar Celery 
  --no-docker          Não gerar configuração Docker
  -n, --non-interactive Modo não-interativo
  -h, --help           Mostrar esta ajuda

${CYAN}Exemplos:${NC}
  django-project-creator.sh meu_projeto                                          # Modo interativo (stack completa)
  django-project-creator.sh -n -t 'Web tradicional' meu_site                   # Site com PostgreSQL+Redis+Celery+Docker
  django-project-creator.sh -n -t 'API (DRF)' minha_api                        # API completa
  django-project-creator.sh -n -t 'Web tradicional' --no-redis --no-celery meu_site_simples  # Site sem Redis/Celery
  django-project-creator.sh -n -t 'Decoupled' api_backend                      # Backend para SPA

${CYAN}Templates Disponíveis:${NC}
$(ls -1 "$TEMPLATES_DIR" 2>/dev/null | sed 's/^/  - /' || echo "  Templates serão detectados automaticamente")

${CYAN}Instalação Global:${NC}
  Para usar de qualquer diretório, adicione o script ao PATH:
  ${YELLOW}sudo ln -sf $(realpath "$0") /usr/local/bin/django-project-creator${NC}
EOF
}

# Função para verificar dependências
check_dependencies() {
    local deps=("python3" "pip3")
    
    if [[ "$USE_DOCKER" == true ]]; then
        deps+=("docker")
    fi
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            error "Dependência não encontrada: $dep"
        fi
    done
}

# Função para detectar sistema
detect_system() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macOS"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "Linux"
    else
        echo "Unknown"
    fi
}

# Função para verificar se Docker está rodando
check_docker() {
    if [[ "$USE_DOCKER" == true ]]; then
        if ! docker info &> /dev/null; then
            warning "Docker não está rodando ou não está acessível"
            return 1
        fi
        return 0
    fi
    return 1
}

# Função para escolher template baseado no tipo
get_template_name() {
    case "$PROJECT_TYPE" in
        "Web tradicional")
            echo "web-tradicional"
            ;;
        "API (DRF)")
            echo "api-drf"
            ;;
        "Fullstack")
            echo "fullstack"
            ;;
        "Decoupled")
            echo "decoupled"
            ;;
        *)
            error "Tipo de projeto inválido: $PROJECT_TYPE"
            ;;
    esac
}

# Função para copiar template
copy_template() {
    local template_name=$(get_template_name)
    local template_path="$TEMPLATES_DIR/$template_name"
    local target_path="$CURRENT_DIR/$PROJECT_NAME"
    
    if [[ ! -d "$template_path" ]]; then
        error "Template não encontrado: $template_path"
    fi
    
    log "📁 Copiando template '$template_name'..."
    
    if [[ -d "$target_path" ]]; then
        error "Diretório '$PROJECT_NAME' já existe em $(pwd)"
    fi
    
    cp -r "$template_path" "$target_path"
    success "Template copiado com sucesso"
}

# Função para personalizar projeto
customize_project() {
    log "🔧 Personalizando projeto para '$PROJECT_NAME'..."
    
    local project_path="$CURRENT_DIR/$PROJECT_NAME"
    cd "$project_path"
    
    # Substitui nome do projeto nos arquivos
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS
        find . -type f \( -name "*.py" -o -name "*.yml" -o -name "*.yaml" -o -name "*.md" \) -exec sed -i '' "s/ProjTest/$PROJECT_NAME/g" {} +
        find . -type f \( -name "*.py" -o -name "*.yml" -o -name "*.yaml" -o -name "*.md" \) -exec sed -i '' "s/projtest/$PROJECT_NAME/g" {} +
    else
        # Linux
        find . -type f \( -name "*.py" -o -name "*.yml" -o -name "*.yaml" -o -name "*.md" \) -exec sed -i "s/ProjTest/$PROJECT_NAME/g" {} +
        find . -type f \( -name "*.py" -o -name "*.yml" -o -name "*.yaml" -o -name "*.md" \) -exec sed -i "s/projtest/$PROJECT_NAME/g" {} +
    fi
    
    success "Projeto personalizado"
}

# Função para configurar opcionais
configure_options() {
    log "⚙️  Configurando opções do projeto..."
    
    # Remove PostgreSQL se não solicitado
    if [[ "$USE_POSTGRES" == false ]]; then
        log "🗑️  Removendo configuração PostgreSQL (usando SQLite)..."
        remove_postgres_config
    fi
    
    # Remove Redis se não solicitado
    if [[ "$USE_REDIS" == false ]]; then
        log "🗑️  Removendo configuração Redis..."
        remove_redis_config
    fi
    
    # Remove Celery se não solicitado
    if [[ "$USE_CELERY" == false ]]; then
        log "🗑️  Removendo configuração Celery..."
        remove_celery_config
    fi
    
    # Remove Docker se não solicitado
    if [[ "$USE_DOCKER" == false ]]; then
        log "🗑️  Removendo configuração Docker..."
        remove_docker_config
    fi
}

# Função para remover configuração PostgreSQL
remove_postgres_config() {
    if [[ -f requirements.txt ]]; then
        if [[ "$(uname)" == "Darwin" ]]; then
            sed -i '' '/psycopg2-binary/d' requirements.txt
        else
            sed -i '/psycopg2-binary/d' requirements.txt
        fi
    fi
    
    # Remove serviço db do docker-compose se existir
    if [[ -f docker-compose.yml ]] && [[ "$USE_DOCKER" == true ]]; then
        # Remove apenas linhas relacionadas ao PostgreSQL
        if [[ "$(uname)" == "Darwin" ]]; then
            sed -i '' '/db:/,/^$/d' docker-compose.yml
            sed -i '' '/postgres_data:/d' docker-compose.yml
            sed -i '' '/depends_on:/,/- db/d' docker-compose.yml
        else
            sed -i '/db:/,/^$/d' docker-compose.yml
            sed -i '/postgres_data:/d' docker-compose.yml
            sed -i '/depends_on:/,/- db/d' docker-compose.yml
        fi
    fi
}

# Função para remover configuração Redis
remove_redis_config() {
    if [[ -f requirements.txt ]]; then
        if [[ "$(uname)" == "Darwin" ]]; then
            sed -i '' '/redis/d' requirements.txt
            sed -i '' '/django-redis/d' requirements.txt
        else
            sed -i '/redis/d' requirements.txt
            sed -i '/django-redis/d' requirements.txt
        fi
    fi
    
    # Remove do docker-compose
    if [[ -f docker-compose.yml ]] && [[ "$USE_DOCKER" == true ]]; then
        if [[ "$(uname)" == "Darwin" ]]; then
            sed -i '' '/redis:/,/^$/d' docker-compose.yml
        else
            sed -i '/redis:/,/^$/d' docker-compose.yml
        fi
    fi
}

# Função para remover configuração Celery
remove_celery_config() {
    if [[ -f requirements.txt ]]; then
        if [[ "$(uname)" == "Darwin" ]]; then
            sed -i '' '/celery/d' requirements.txt
            sed -i '' '/django-celery-beat/d' requirements.txt
        else
            sed -i '/celery/d' requirements.txt
            sed -i '/django-celery-beat/d' requirements.txt
        fi
    fi
    
    # Remove do docker-compose
    if [[ -f docker-compose.yml ]] && [[ "$USE_DOCKER" == true ]]; then
        if [[ "$(uname)" == "Darwin" ]]; then
            sed -i '' '/celery:/,/^$/d' docker-compose.yml
            sed -i '' '/celery-beat:/,/^$/d' docker-compose.yml
        else
            sed -i '/celery:/,/^$/d' docker-compose.yml
            sed -i '/celery-beat:/,/^$/d' docker-compose.yml
        fi
    fi
}

# Função para remover configuração Docker
remove_docker_config() {
    rm -rf docker/
    rm -f docker-compose.yml docker-compose.prod.yml
}

# Função para criar ambiente virtual
create_venv() {
    log "🐍 Criando ambiente virtual..."
    
    if [[ ! -d "venv" ]]; then
        python3 -m venv venv
    fi
    
    success "Ambiente virtual criado"
}

# Função para instalar dependências
install_dependencies() {
    log "📦 Instalando dependências..."
    
    # Ativa o ambiente virtual e instala dependências
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    
    success "Dependências instaladas"
}

# Função interativa para coletar informações
interactive_mode() {
    echo -e "${BLUE}🚀 Django Project Creator v2.0${NC}"
    echo -e "${CYAN}Sistema: $(detect_system)${NC}"
    
    if check_docker; then
        echo -e "${GREEN}🐳 Docker: Disponível${NC}"
    else
        echo -e "${YELLOW}🐳 Docker: Não disponível${NC}"
    fi
    
    echo ""
    
    # Nome do projeto
    while [[ -z "$PROJECT_NAME" ]]; do
        read -p "📝 Nome do projeto: " PROJECT_NAME
        if [[ -z "$PROJECT_NAME" ]]; then
            warning "Nome do projeto é obrigatório"
        fi
    done
    
    # Tipo do projeto
    echo ""
    echo "🎯 Escolha o tipo de projeto:"
    echo "1) Web tradicional - Django com templates e frontend integrado"
    echo "2) API (DRF) - API REST pura com Django REST Framework"
    echo "3) Fullstack - API + Frontend integrado"
    echo "4) Decoupled - Backend API para frontend separado"
    
    while [[ -z "$PROJECT_TYPE" ]]; do
        read -p "Escolha (1-4): " choice
        case $choice in
            1) PROJECT_TYPE="Web tradicional" ;;
            2) PROJECT_TYPE="API (DRF)" ;;
            3) PROJECT_TYPE="Fullstack" ;;
            4) PROJECT_TYPE="Decoupled" ;;
            *) warning "Opção inválida" ;;
        esac
    done
    
    # Opções adicionais
    echo ""
    echo "⚙️  Configurações adicionais:"
    
    read -p "Usar PostgreSQL? (Y/n): " use_pg
    if [[ "$use_pg" =~ ^[Nn]$ ]]; then
        USE_POSTGRES=false
    else
        USE_POSTGRES=true
    fi
    
    read -p "Usar Redis? (Y/n): " use_redis  
    if [[ "$use_redis" =~ ^[Nn]$ ]]; then
        USE_REDIS=false
    else
        USE_REDIS=true
    fi
    
    if [[ "$USE_REDIS" == true ]]; then
        read -p "Usar Celery? (Y/n): " use_celery
        if [[ "$use_celery" =~ ^[Nn]$ ]]; then
            USE_CELERY=false
        else
            USE_CELERY=true
        fi
    fi
    
    if command -v docker &> /dev/null; then
        read -p "Usar Docker? (Y/n): " use_docker
        if [[ "$use_docker" =~ ^[Nn]$ ]]; then
            USE_DOCKER=false
        else
            USE_DOCKER=true
        fi
    fi
}

# Função para mostrar próximos passos
show_next_steps() {
    echo ""
    echo -e "${GREEN}🎉 Projeto criado com sucesso!${NC}"
    echo ""
    echo -e "${CYAN}📋 Próximos passos:${NC}"
    echo ""
    echo "   1. Entre no diretório:"
    echo "      ${YELLOW}cd $PROJECT_NAME${NC}"
    echo ""
    echo "   2. Ative o ambiente virtual:"
    echo "      ${YELLOW}source venv/bin/activate${NC}"
    echo ""
    
    if [[ "$USE_DOCKER" == true ]]; then
        echo "   3. Inicie com Docker:"
        echo "      ${YELLOW}docker-compose up --build${NC}"
        echo ""
        echo "   4. Acesse em:"
        echo "      ${BLUE}http://localhost:8000${NC}"
        
        if [[ "$PROJECT_TYPE" == "API (DRF)" || "$PROJECT_TYPE" == "Fullstack" || "$PROJECT_TYPE" == "Decoupled" ]]; then
            echo ""
            echo "   📖 Documentação da API:"
            echo "      ${BLUE}http://localhost:8000/api/docs/${NC} (Swagger)"
            echo "      ${BLUE}http://localhost:8000/api/redoc/${NC} (ReDoc)"
        fi
    else
        echo "   3. Execute as migrações:"
        echo "      ${YELLOW}cd backend && python manage.py migrate${NC}"
        echo ""
        echo "   4. Inicie o servidor:"
        echo "      ${YELLOW}python manage.py runserver${NC}"
        echo ""
        echo "   5. Acesse em:"
        echo "      ${BLUE}http://localhost:8000${NC}"
    fi
    
    if [[ "$PROJECT_TYPE" == "Decoupled" ]]; then
        echo ""
        echo -e "${PURPLE}💡 Dica para projeto Decoupled:${NC}"
        echo "   Consulte README_DECOUPLED.md para instruções de frontend"
    fi
    
    echo ""
    echo -e "${GREEN}✨ Feliz codificação!${NC}"
}

# Parse de argumentos
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--type)
                PROJECT_TYPE="$2"
                shift 2
                ;;
            --no-postgres)
                USE_POSTGRES=false
                shift
                ;;
            --no-redis)
                USE_REDIS=false
                USE_CELERY=false  # Celery requer Redis
                shift
                ;;
            --no-celery)
                USE_CELERY=false
                shift
                ;;
            --no-docker)
                USE_DOCKER=false
                shift
                ;;
            -n|--non-interactive)
                NON_INTERACTIVE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -*)
                error "Opção desconhecida: $1"
                ;;
            *)
                if [[ -z "$PROJECT_NAME" ]]; then
                    PROJECT_NAME="$1"
                else
                    error "Argumento extra: $1"
                fi
                shift
                ;;
        esac
    done
}

# Função principal
main() {
    # Detecta diretório dos templates
    detect_templates_dir
    
    # Parse argumentos
    parse_args "$@"
    
    # Verifica se templates existem
    if [[ ! -d "$TEMPLATES_DIR" ]]; then
        error "Diretório de templates não encontrado: $TEMPLATES_DIR"
    fi
    
    # Modo interativo ou não-interativo
    if [[ "$NON_INTERACTIVE" == false ]]; then
        interactive_mode
    else
        if [[ -z "$PROJECT_NAME" ]]; then
            error "Nome do projeto é obrigatório no modo não-interativo"
        fi
        if [[ -z "$PROJECT_TYPE" ]]; then
            error "Tipo do projeto é obrigatório no modo não-interativo (-t)"
        fi
        
        echo -e "${BLUE}🚀 Django Project Creator v2.0${NC}"
        echo -e "${CYAN}🖥️  Sistema: $(detect_system)${NC}"
        
        if check_docker; then
            echo -e "${GREEN}🐳 Docker: Disponível${NC}"
        else
            echo -e "${YELLOW}🐳 Docker: Não disponível${NC}"
        fi
        echo ""
    fi
    
    # Verifica dependências
    check_dependencies
    
    # Executa criação do projeto
    log "🚀 Iniciando criação do projeto Django..."
    
    copy_template
    customize_project
    configure_options
    create_venv
    install_dependencies
    
    cd ..
    
    success "Projeto '$PROJECT_NAME' criado com sucesso!"
    show_next_steps
}

# Executa o script
main "$@"

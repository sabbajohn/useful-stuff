#!/bin/bash

# Detecta o sistema operacional
OS="$(uname -s)"
case "${OS}" in
    Linux*)     MACHINE=Linux;;
    Darwin*)    MACHINE=macOS;;
    *)          MACHINE="UNKNOWN:${OS}"
esac

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Função para log colorido
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Verifica dependências
check_dependencies() {
    local missing_deps=()
    
    # Dependências essenciais
    for cmd in php composer; do
        if ! command -v $cmd &>/dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    # Verifica se gum está disponível para interface interativa
    if ! command -v gum &>/dev/null; then
        missing_deps+=("gum")
    fi
    
    # Docker (obrigatório para este script)
    DOCKER_AVAILABLE=false
    if command -v docker &>/dev/null && docker info &>/dev/null 2>&1; then
        DOCKER_AVAILABLE=true
    else
        missing_deps+=("docker")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        error "Dependências não encontradas: ${missing_deps[*]}"
        if [[ "$MACHINE" == "macOS" ]]; then
            echo "Para instalar no macOS:"
            echo "  brew install php composer gum"
            echo "  brew install --cask docker"
        else
            echo "Para instalar no Linux:"
            echo "  sudo apt-get install php-cli composer"
            echo "  # Para gum: https://github.com/charmbracelet/gum#installation"
            echo "  # Para Docker: https://docs.docker.com/engine/install/"
        fi
        exit 1
    fi
}

# Função para obter entrada do usuário
get_input() {
    local prompt="$1"
    local default="$2"
    local result
    
    if command -v gum &>/dev/null; then
        result=$(gum input --placeholder "$prompt" --value "$default")
    else
        echo -n "$prompt: "
        read result
        [[ -z "$result" ]] && result="$default"
    fi
    
    echo "$result"
}

# Função para seleção de opções
select_option() {
    local prompt="$1"
    shift
    local options=("$@")
    
    if command -v gum &>/dev/null; then
        printf '%s\n' "${options[@]}" | gum choose --header "$prompt"
    else
        echo "$prompt"
        select opt in "${options[@]}"; do
            [[ -n "$opt" ]] && echo "$opt" && break
        done
    fi
}

# Função para confirmação
confirm() {
    local prompt="$1"
    
    if command -v gum &>/dev/null; then
        gum confirm "$prompt"
    else
        echo -n "$prompt (y/n): "
        read -r response
        [[ "$response" =~ ^[Yy]$ ]]
    fi
}

# Função para criar projeto Laravel
create_laravel_project() {
    log "🚀 Iniciando criação do projeto Laravel..."
    
    # Coleta informações do projeto
    PROJECT_NAME=$(get_input "📦 Nome do projeto" "meu_projeto_laravel")
    if [[ -z "$PROJECT_NAME" ]]; then
        error "Nome do projeto é obrigatório!"
        exit 1
    fi
    
    # Verifica se já existe
    if [[ -d "$PROJECT_NAME" ]]; then
        if ! confirm "📁 Diretório '$PROJECT_NAME' já existe. Deseja sobrescrever?"; then
            error "Operação cancelada."
            exit 1
        fi
        rm -rf "$PROJECT_NAME"
    fi
    
    # Configurações do projeto
    HTTP_PORT=$(select_option "🌐 Porta HTTP (Nginx)" "80" "8080" "8000" "3000")
    HTTPS_PORT=$(select_option "🔒 Porta HTTPS (Nginx)" "443" "8443" "4443")
    APP_PORT=$(select_option "🐘 Porta PHP-FPM" "9000" "9001" "9002")
    
    # Tipo de projeto
    PROJECT_TYPE=$(select_option "📋 Tipo de projeto" "API" "Web Full" "SPA + API")
    
    # Configurações de banco
    DATABASE_TYPE=$(select_option "🗄️ Banco de dados" "MySQL" "PostgreSQL" "SQLite")
    
    # Configurações adicionais
    USE_REDIS=$(confirm "🔴 Usar Redis?" && echo "yes" || echo "no")
    USE_QUEUE=$(confirm "📬 Usar Queue (Laravel Horizon)?" && echo "yes" || echo "no")
    USE_ELASTICSEARCH=$(confirm "🔍 Usar Elasticsearch?" && echo "yes" || echo "no")
    USE_MAILHOG=$(confirm "📧 Usar MailHog (email testing)?" && echo "yes" || echo "no")
    USE_GIT=$(confirm "📦 Inicializar Git?" && echo "yes" || echo "no")
    
    log "📁 Criando estrutura do projeto..."
    create_project_structure
}

# Função para criar estrutura do projeto
create_project_structure() {
    # Cria diretório principal
    mkdir -p "$PROJECT_NAME"
    cd "$PROJECT_NAME" || exit 1
    
    # Estrutura Docker
    mkdir -p {docker/nginx,docker/php,docker/mysql,docker/redis,scripts,storage/logs}
    
    log "🐘 Criando projeto Laravel..."
    create_laravel_app
    
    log "📝 Gerando arquivos de configuração..."
    create_env_files
    create_docker_files
    create_nginx_config
    create_php_config
    
    if [[ "$USE_GIT" == "yes" ]]; then
        log "📦 Inicializando Git..."
        setup_git
    fi
    
    log "📚 Criando documentação..."
    create_documentation
    
    display_final_instructions
}

# Função para criar aplicação Laravel
create_laravel_app() {
    log "🎯 Criando aplicação Laravel..."
    
    # Criar projeto Laravel usando Composer
    if command -v composer &>/dev/null; then
        composer create-project laravel/laravel . --prefer-dist --no-interaction
    else
        # Fallback usando Docker
        docker run --rm -v "$(pwd)":/app composer create-project laravel/laravel . --prefer-dist --no-interaction
    fi
    
    # Instalar pacotes específicos baseado no tipo de projeto
    case "$PROJECT_TYPE" in
        "API")
            install_api_packages
            ;;
        "Web Full")
            install_web_packages
            ;;
        "SPA + API")
            install_spa_packages
            ;;
    esac
    
    log "✅ Aplicação Laravel criada"
}

# Função para instalar pacotes da API
install_api_packages() {
    log "📦 Instalando pacotes para API..."
    
    # Usando composer ou Docker
    if command -v composer &>/dev/null; then
        composer require laravel/sanctum spatie/laravel-query-builder
        composer require --dev laravel/telescope
    else
        docker run --rm -v "$(pwd)":/app composer require laravel/sanctum spatie/laravel-query-builder
        docker run --rm -v "$(pwd)":/app composer require --dev laravel/telescope
    fi
}

# Função para instalar pacotes web
install_web_packages() {
    log "📦 Instalando pacotes para Web..."
    
    if command -v composer &>/dev/null; then
        composer require laravel/breeze
        composer require --dev laravel/telescope
    else
        docker run --rm -v "$(pwd)":/app composer require laravel/breeze
        docker run --rm -v "$(pwd)":/app composer require --dev laravel/telescope
    fi
}

# Função para instalar pacotes SPA
install_spa_packages() {
    log "📦 Instalando pacotes para SPA + API..."
    
    if command -v composer &>/dev/null; then
        composer require laravel/sanctum spatie/laravel-query-builder laravel/breeze
        composer require --dev laravel/telescope
    else
        docker run --rm -v "$(pwd)":/app composer require laravel/sanctum spatie/laravel-query-builder laravel/breeze
        docker run --rm -v "$(pwd)":/app composer require --dev laravel/telescope
    fi
}

# Função para criar arquivos .env
create_env_files() {
    log "⚙️ Criando arquivos de ambiente..."
    
    # Backup do .env original se existir
    [[ -f .env ]] && cp .env .env.backup
    
    # Gera APP_KEY se não existir
    APP_KEY=$(openssl rand -base64 32)
    
    cat <<EOF > .env
APP_NAME=$PROJECT_NAME
APP_ENV=local
APP_KEY=base64:$APP_KEY
APP_DEBUG=true
APP_URL=http://localhost:$HTTP_PORT

LOG_CHANNEL=stack
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=debug

EOF

    # Configuração do banco
    case "$DATABASE_TYPE" in
        "MySQL")
            cat <<EOF >> .env
DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=${PROJECT_NAME}_db
DB_USERNAME=${PROJECT_NAME}_user
DB_PASSWORD=$(openssl rand -hex 16)
EOF
            ;;
        "PostgreSQL")
            cat <<EOF >> .env
DB_CONNECTION=pgsql
DB_HOST=postgres
DB_PORT=5432
DB_DATABASE=${PROJECT_NAME}_db
DB_USERNAME=${PROJECT_NAME}_user
DB_PASSWORD=$(openssl rand -hex 16)
EOF
            ;;
        "SQLite")
            cat <<EOF >> .env
DB_CONNECTION=sqlite
DB_DATABASE=/var/www/database/database.sqlite
EOF
            ;;
    esac

    if [[ "$USE_REDIS" == "yes" ]]; then
        cat <<EOF >> .env

BROADCAST_DRIVER=redis
CACHE_DRIVER=redis
FILESYSTEM_DISK=local
QUEUE_CONNECTION=redis
SESSION_DRIVER=redis
SESSION_LIFETIME=120

REDIS_HOST=redis
REDIS_PASSWORD=null
REDIS_PORT=6379
EOF
    else
        cat <<EOF >> .env

BROADCAST_DRIVER=log
CACHE_DRIVER=file
FILESYSTEM_DISK=local
QUEUE_CONNECTION=sync
SESSION_DRIVER=file
SESSION_LIFETIME=120
EOF
    fi

    if [[ "$USE_MAILHOG" == "yes" ]]; then
        cat <<EOF >> .env

MAIL_MAILER=smtp
MAIL_HOST=mailhog
MAIL_PORT=1025
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS="hello@${PROJECT_NAME}.com"
MAIL_FROM_NAME="\${APP_NAME}"
EOF
    fi

    # .env para produção
    cat <<EOF > .env.production
APP_NAME=$PROJECT_NAME
APP_ENV=production
APP_KEY=base64:$APP_KEY
APP_DEBUG=false
APP_URL=https://yourapp.com

LOG_CHANNEL=stderr
LOG_LEVEL=error

# Database - Configure with your production values
DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=${PROJECT_NAME}_prod
DB_USERNAME=${PROJECT_NAME}_prod
DB_PASSWORD=CHANGE_IN_PRODUCTION

# Cache and Sessions
CACHE_DRIVER=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis

# Redis
REDIS_HOST=redis
REDIS_PASSWORD=CHANGE_IN_PRODUCTION
REDIS_PORT=6379

# Mail
MAIL_MAILER=smtp
MAIL_HOST=smtp.mailtrap.io
MAIL_PORT=2525
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=tls
EOF

    log "✅ Arquivos de ambiente criados"
}

# Função para criar arquivos Docker
create_docker_files() {
    log "🐳 Criando arquivos Docker..."
    
    # Dockerfile para PHP
    cat <<EOF > docker/php/Dockerfile
FROM php:8.2-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y \\
    git \\
    curl \\
    libpng-dev \\
    libonig-dev \\
    libxml2-dev \\
    zip \\
    unzip \\
    libzip-dev \\
    libfreetype6-dev \\
    libjpeg62-turbo-dev \\
    libpq-dev \\
    supervisor

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip
RUN docker-php-ext-configure gd --with-freetype --with-jpeg
RUN docker-php-ext-install -j\$(nproc) gd

# Install PostgreSQL extension if needed
RUN docker-php-ext-install pdo_pgsql

# Install Redis extension
RUN pecl install redis && docker-php-ext-enable redis

# Install Xdebug for development
RUN pecl install xdebug && docker-php-ext-enable xdebug

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Create system user to run Composer and Artisan Commands
RUN useradd -G www-data,root -u 1000 -d /home/user user
RUN mkdir -p /home/user/.composer && \\
    chown -R user:user /home/user

# Copy custom configurations
COPY docker/php/custom.ini /usr/local/etc/php/conf.d/custom.ini
COPY docker/php/xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

# Set working directory
WORKDIR /var/www

USER user
EOF

    # Configuração customizada do PHP
    cat <<EOF > docker/php/custom.ini
upload_max_filesize=64M
post_max_size=64M
memory_limit=256M
max_execution_time=300
max_input_vars=3000
date.timezone=America/Sao_Paulo
EOF

    # Configuração do Xdebug
    cat <<EOF > docker/php/xdebug.ini
zend_extension=xdebug.so
xdebug.mode=debug,coverage
xdebug.start_with_request=yes
xdebug.client_host=host.docker.internal
xdebug.client_port=9003
xdebug.log=/var/log/xdebug.log
xdebug.discover_client_host=1
xdebug.remote_handler=dbgp
EOF

    # docker-compose.yml
    cat <<EOF > docker-compose.yml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: docker/php/Dockerfile
    image: ${PROJECT_NAME}_app
    container_name: ${PROJECT_NAME}_app
    restart: unless-stopped
    working_dir: /var/www
    volumes:
      - ./:/var/www
      - ./docker/php/custom.ini:/usr/local/etc/php/conf.d/custom.ini
      - ./docker/php/xdebug.ini:/usr/local/etc/php/conf.d/xdebug.ini
    networks:
      - laravel
    depends_on:
EOF

    case "$DATABASE_TYPE" in
        "MySQL")
            cat <<EOF >> docker-compose.yml
      - mysql
EOF
            ;;
        "PostgreSQL")
            cat <<EOF >> docker-compose.yml
      - postgres
EOF
            ;;
    esac

    cat <<EOF >> docker-compose.yml

  webserver:
    image: nginx:alpine
    container_name: ${PROJECT_NAME}_webserver
    restart: unless-stopped
    ports:
      - "$HTTP_PORT:80"
      - "$HTTPS_PORT:443"
    volumes:
      - ./:/var/www
      - ./docker/nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./docker/nginx/sites-available:/etc/nginx/sites-available
      - ./docker/nginx/sites-enabled:/etc/nginx/sites-enabled
      - ./storage/logs/nginx:/var/log/nginx
    networks:
      - laravel
    depends_on:
      - app

EOF

    # Adicionar MySQL se selecionado
    if [[ "$DATABASE_TYPE" == "MySQL" ]]; then
        cat <<EOF >> docker-compose.yml
  mysql:
    image: mysql:8.0
    container_name: ${PROJECT_NAME}_mysql
    restart: unless-stopped
    tty: true
    ports:
      - "3306:3306"
    environment:
      MYSQL_DATABASE: \${DB_DATABASE}
      MYSQL_USER: \${DB_USERNAME}
      MYSQL_PASSWORD: \${DB_PASSWORD}
      MYSQL_ROOT_PASSWORD: root
      SERVICE_TAGS: dev
      SERVICE_NAME: mysql
    volumes:
      - mysql_data:/var/lib/mysql
      - ./docker/mysql/my.cnf:/etc/mysql/my.cnf
    networks:
      - laravel

EOF
    fi

    # Adicionar PostgreSQL se selecionado
    if [[ "$DATABASE_TYPE" == "PostgreSQL" ]]; then
        cat <<EOF >> docker-compose.yml
  postgres:
    image: postgres:15
    container_name: ${PROJECT_NAME}_postgres
    restart: unless-stopped
    ports:
      - "5432:5432"
    environment:
      POSTGRES_DB: \${DB_DATABASE}
      POSTGRES_USER: \${DB_USERNAME}
      POSTGRES_PASSWORD: \${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - laravel

EOF
    fi

    # Adicionar Redis se selecionado
    if [[ "$USE_REDIS" == "yes" ]]; then
        cat <<EOF >> docker-compose.yml
  redis:
    image: redis:alpine
    container_name: ${PROJECT_NAME}_redis
    restart: unless-stopped
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    networks:
      - laravel

EOF
    fi

    # Adicionar Queue Worker se selecionado
    if [[ "$USE_QUEUE" == "yes" ]]; then
        cat <<EOF >> docker-compose.yml
  queue:
    build:
      context: .
      dockerfile: docker/php/Dockerfile
    container_name: ${PROJECT_NAME}_queue
    restart: unless-stopped
    command: php artisan queue:work --verbose --tries=3 --timeout=90
    volumes:
      - ./:/var/www
    networks:
      - laravel
    depends_on:
      - app
      - redis

EOF
    fi

    # Adicionar Elasticsearch se selecionado
    if [[ "$USE_ELASTICSEARCH" == "yes" ]]; then
        cat <<EOF >> docker-compose.yml
  elasticsearch:
    image: elasticsearch:8.8.0
    container_name: ${PROJECT_NAME}_elasticsearch
    restart: unless-stopped
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
    ports:
      - "9200:9200"
      - "9300:9300"
    volumes:
      - elasticsearch_data:/usr/share/elasticsearch/data
    networks:
      - laravel

EOF
    fi

    # Adicionar MailHog se selecionado
    if [[ "$USE_MAILHOG" == "yes" ]]; then
        cat <<EOF >> docker-compose.yml
  mailhog:
    image: mailhog/mailhog
    container_name: ${PROJECT_NAME}_mailhog
    restart: unless-stopped
    ports:
      - "1025:1025"
      - "8025:8025"
    networks:
      - laravel

EOF
    fi

    # Networks e Volumes
    cat <<EOF >> docker-compose.yml
networks:
  laravel:
    driver: bridge

volumes:
EOF

    case "$DATABASE_TYPE" in
        "MySQL")
            cat <<EOF >> docker-compose.yml
  mysql_data:
    driver: local
EOF
            ;;
        "PostgreSQL")
            cat <<EOF >> docker-compose.yml
  postgres_data:
    driver: local
EOF
            ;;
    esac

    if [[ "$USE_REDIS" == "yes" ]]; then
        cat <<EOF >> docker-compose.yml
  redis_data:
    driver: local
EOF
    fi

    if [[ "$USE_ELASTICSEARCH" == "yes" ]]; then
        cat <<EOF >> docker-compose.yml
  elasticsearch_data:
    driver: local
EOF
    fi

    # Configuração MySQL
    if [[ "$DATABASE_TYPE" == "MySQL" ]]; then
        mkdir -p docker/mysql
        cat <<EOF > docker/mysql/my.cnf
[mysqld]
general_log = 1
general_log_file = /var/lib/mysql/general.log
EOF
    fi

    log "✅ Arquivos Docker criados"
}

# Função para criar configuração do Nginx
create_nginx_config() {
    log "🌐 Criando configuração do Nginx..."
    
    mkdir -p docker/nginx/{sites-available,sites-enabled}
    
    # Configuração principal do Nginx
    cat <<EOF > docker/nginx/nginx.conf
user nginx;
worker_processes auto;

error_log /var/log/nginx/error.log notice;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 64M;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;

    include /etc/nginx/sites-enabled/*;
}
EOF

    # Site configuration
    cat <<EOF > docker/nginx/sites-available/default
server {
    listen 80;
    server_name localhost;
    index index.php index.html;
    error_log /var/log/nginx/error.log;
    access_log /var/log/nginx/access.log;
    root /var/www/public;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \\.php\$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\\.php)(/.+)\$;
        fastcgi_pass app:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
        
        # Increase timeouts for debugging
        fastcgi_read_timeout 300;
        fastcgi_send_timeout 300;
    }

    location ~ /\\.(?!well-known).* {
        deny all;
    }

    # Cache static files
    location ~* \\.(jpg|jpeg|gif|png|css|js|ico|xml)\$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        log_not_found off;
    }
}
EOF

    # Criar link simbólico para sites-enabled
    ln -sf /etc/nginx/sites-available/default docker/nginx/sites-enabled/default

    log "✅ Configuração do Nginx criada"
}

# Função para criar configuração PHP
create_php_config() {
    log "🐘 Criando configurações do PHP..."
    
    # Já criados na função create_docker_files
    # Aqui podemos adicionar configurações adicionais se necessário
    
    log "✅ Configurações do PHP prontas"
}

# Função para configurar Git
setup_git() {
    log "📦 Configurando Git..."
    
    git init
    
    cat <<EOF > .gitignore
/node_modules
/public/hot
/public/storage
/storage/*.key
/vendor
.env
.env.backup
.phpunit.result.cache
docker-compose.override.yml
Homestead.json
Homestead.yaml
npm-debug.log
yarn-error.log
/.idea
/.vscode

# Docker
/storage/logs/nginx/*
!/storage/logs/nginx/.gitkeep

# OS
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db
EOF

    cat <<EOF > README.md
# $PROJECT_NAME

Projeto Laravel criado automaticamente com Docker, Nginx e configurações de debug.

## 🚀 Requisitos

- Docker e Docker Compose
- PHP 8.2+ (opcional, para desenvolvimento local)
- Composer (opcional, para desenvolvimento local)

## 🐳 Executando com Docker

### Desenvolvimento
\`\`\`bash
# Construir e executar containers
docker-compose up --build -d

# Instalar dependências
docker-compose exec app composer install

# Gerar chave da aplicação
docker-compose exec app php artisan key:generate

# Executar migrations
docker-compose exec app php artisan migrate

# Criar usuário admin (se aplicável)
docker-compose exec app php artisan make:filament-user
\`\`\`

### URLs importantes
- **Aplicação:** http://localhost:$HTTP_PORT
- **MailHog:** http://localhost:8025 (se habilitado)
- **Elasticsearch:** http://localhost:9200 (se habilitado)

## 🔧 Comandos úteis

### Laravel Artisan
\`\`\`bash
# Executar comandos artisan
docker-compose exec app php artisan [comando]

# Limpar cache
docker-compose exec app php artisan cache:clear
docker-compose exec app php artisan config:clear
docker-compose exec app php artisan route:clear

# Migrations
docker-compose exec app php artisan make:migration [nome]
docker-compose exec app php artisan migrate
docker-compose exec app php artisan migrate:rollback

# Models
docker-compose exec app php artisan make:model [Nome] -mfc
\`\`\`

### Composer
\`\`\`bash
# Instalar pacotes
docker-compose exec app composer require [pacote]

# Atualizar dependências
docker-compose exec app composer update
\`\`\`

### Logs
\`\`\`bash
# Ver logs da aplicação
docker-compose logs -f app

# Ver logs do Nginx
docker-compose logs -f webserver

# Ver logs do MySQL/PostgreSQL
docker-compose logs -f mysql  # ou postgres
\`\`\`

## 🐛 Debug

### Xdebug
O Xdebug está configurado e pronto para uso:
- **Host:** host.docker.internal
- **Porta:** 9003

### Configuração VS Code
Adicione ao \`.vscode/launch.json\`:
\`\`\`json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Listen for Xdebug",
            "type": "php",
            "request": "launch",
            "port": 9003,
            "pathMappings": {
                "/var/www": "\${workspaceFolder}"
            }
        }
    ]
}
\`\`\`

## 📦 Estrutura

\`\`\`
$PROJECT_NAME/
├── app/                    # Aplicação Laravel
├── docker/                 # Configurações Docker
│   ├── nginx/             # Configurações Nginx
│   ├── php/               # Configurações PHP
│   └── mysql/             # Configurações MySQL
├── public/                # Arquivos públicos
├── resources/             # Views, assets, lang
├── routes/                # Rotas da aplicação
├── storage/               # Storage e logs
├── docker-compose.yml     # Docker Compose
└── README.md              # Esta documentação
\`\`\`

## 🔒 Produção

Para produção, use \`.env.production\` e:

\`\`\`bash
# Build para produção
docker-compose -f docker-compose.prod.yml up --build -d

# Otimizações
docker-compose exec app php artisan config:cache
docker-compose exec app php artisan route:cache
docker-compose exec app php artisan view:cache
\`\`\`

## 📚 Documentação

- [Laravel Documentation](https://laravel.com/docs)
- [Docker Documentation](https://docs.docker.com/)
- [Nginx Documentation](https://nginx.org/en/docs/)
EOF

    log "✅ Git configurado"
}

# Função para criar documentação
create_documentation() {
    log "📚 Criando documentação..."
    
    mkdir -p docs
    
    # Scripts utilitários
    mkdir -p scripts
    
    cat <<EOF > scripts/setup.sh
#!/bin/bash
# Script de configuração inicial

echo "🚀 Configurando projeto $PROJECT_NAME..."

# Build dos containers
docker-compose up --build -d

# Aguardar containers iniciarem
sleep 10

# Instalar dependências
docker-compose exec app composer install

# Gerar chave da aplicação
docker-compose exec app php artisan key:generate

# Executar migrations
docker-compose exec app php artisan migrate

echo "✅ Projeto configurado!"
echo "🌐 Acesse: http://localhost:$HTTP_PORT"
EOF

    chmod +x scripts/setup.sh

    cat <<EOF > scripts/dev.sh
#!/bin/bash
# Script para desenvolvimento

echo "🔧 Iniciando ambiente de desenvolvimento..."

# Iniciar containers
docker-compose up -d

# Mostrar logs
docker-compose logs -f
EOF

    chmod +x scripts/dev.sh

    cat <<EOF > scripts/artisan.sh
#!/bin/bash
# Wrapper para comandos artisan

if [ \$# -eq 0 ]; then
    echo "Uso: ./scripts/artisan.sh [comando artisan]"
    echo "Exemplo: ./scripts/artisan.sh migrate"
    exit 1
fi

docker-compose exec app php artisan "\$@"
EOF

    chmod +x scripts/artisan.sh

    log "✅ Documentação criada"
}

# Função para mostrar instruções finais
display_final_instructions() {
    echo
    echo -e "🎉${GREEN} Projeto Laravel '$PROJECT_NAME' criado com sucesso!${NC}"
    echo
    echo -e "📋 ${CYAN}Próximos passos:${NC}"
    echo
    echo -e "1. ${YELLOW}Entrar no diretório:${NC}"
    echo "   cd $PROJECT_NAME"
    echo
    echo -e "2. ${YELLOW}Executar setup automático:${NC}"
    echo "   ./scripts/setup.sh"
    echo
    echo -e "3. ${YELLOW}OU configurar manualmente:${NC}"
    echo "   docker-compose up --build -d"
    echo "   docker-compose exec app composer install"
    echo "   docker-compose exec app php artisan key:generate"
    echo "   docker-compose exec app php artisan migrate"
    echo

    echo -e "🌐 ${GREEN}URLs importantes:${NC}"
    echo "   • Aplicação: http://localhost:$HTTP_PORT"
    
    if [[ "$USE_MAILHOG" == "yes" ]]; then
        echo "   • MailHog: http://localhost:8025"
    fi
    
    if [[ "$USE_ELASTICSEARCH" == "yes" ]]; then
        echo "   • Elasticsearch: http://localhost:9200"
    fi
    
    echo
    echo -e "🛠️ ${CYAN}Comandos úteis:${NC}"
    echo "   • ./scripts/dev.sh - Ambiente de desenvolvimento"
    echo "   • ./scripts/artisan.sh [comando] - Executar artisan"
    echo "   • docker-compose logs -f - Ver logs"
    echo
    echo -e "🐛 ${PURPLE}Debug (Xdebug):${NC}"
    echo "   • Host: host.docker.internal"
    echo "   • Porta: 9003"
    echo "   • Path mapping: /var/www -> $(pwd)"
    echo
    echo -e "📚 ${CYAN}Documentação:${NC}"
    echo "   • README.md - Informações gerais"
    echo "   • docs/ - Documentação técnica"
    echo
}

# Função principal
main() {
    echo -e "🚀 ${GREEN}Laravel Project Creator${NC}"
    echo "🖥️  Sistema: $MACHINE"
    echo "🐳 Docker: $([ "$DOCKER_AVAILABLE" == "true" ] && echo "Disponível" || echo "Não disponível")"
    echo

    check_dependencies
    create_laravel_project
}

# Executa função principal
main "$@"

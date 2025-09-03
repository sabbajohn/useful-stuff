# Laravel Project Creator

Script automatizado para criar projetos Laravel completos com Docker, Nginx, PHP-FPM, e configurações de debug profissionais.

## 🚀 Características

- ✅ **Docker Completo**: Nginx + PHP-FPM + MySQL/PostgreSQL + Redis
- 🐛 **Debug Ready**: Xdebug configurado para VS Code
- 🌐 **Nginx Otimizado**: Configurações de performance e segurança
- 🔧 **Múltiplos Tipos**: API, Web Full, SPA + API
- 📦 **Pacotes Incluídos**: Laravel Sanctum, Telescope, Breeze
- 📧 **MailHog**: Teste de emails em desenvolvimento
- 🔍 **Elasticsearch**: Busca avançada (opcional)
- 📬 **Queue Ready**: Laravel Horizon configurado
- 🛡️ **Security Headers**: Headers de segurança configurados
- 📚 **Documentação**: README e scripts automáticos

## 📋 Pré-requisitos

### macOS

```bash
# Homebrew (se não tiver)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Dependências
brew install php composer gum

# Docker
brew install --cask docker
```

### Linux (Ubuntu/Debian)

```bash
# PHP e Composer
sudo apt-get update
sudo apt-get install php-cli composer

# gum (interface interativa)
echo 'deb [trusted=yes] https://repo.charm.sh/apt/ /' | sudo tee /etc/apt/sources.list.d/charm.list
sudo apt update && sudo apt install gum

# Docker
sudo apt install docker.io docker-compose-plugin
sudo usermod -aG docker $USER
```

## 🛠️ Instalação

1. **Baixar o script:**

```bash
curl -O https://raw.githubusercontent.com/seu-repo/laravel-start.sh
# ou
wget https://raw.githubusercontent.com/seu-repo/laravel-start.sh
```

2. **Tornar executável:**

```bash
chmod +x laravel-start.sh
```

3. **Executar:**

```bash
./laravel-start.sh
```

## 📱 Tipos de Projeto

### 1. 🌐 API

- Laravel Sanctum (autenticação API)
- Laravel Telescope (debugging)
- Query Builder otimizado
- Estrutura para endpoints REST

**Pacotes incluídos:**

- `laravel/sanctum`
- `spatie/laravel-query-builder`
- `laravel/telescope`

### 2. 📄 Web Full

- Laravel Breeze (autenticação web)
- Blade templates
- Sistema completo de autenticação
- Interface web tradicional

**Pacotes incluídos:**

- `laravel/breeze`
- `laravel/telescope`

### 3. 🔄 SPA + API

- Combinação de API + Frontend
- Laravel Sanctum + Breeze
- Preparado para React/Vue/Angular
- API + Interface administrativa

**Pacotes incluídos:**

- `laravel/sanctum`
- `laravel/breeze`
- `spatie/laravel-query-builder`
- `laravel/telescope`

## 🐳 Stack Docker

### Serviços Incluídos

#### Core (Sempre)

- **PHP 8.2-FPM**: Aplicação Laravel
- **Nginx**: Servidor web otimizado
- **MySQL/PostgreSQL**: Banco de dados

#### Opcionais

- **Redis**: Cache e sessões
- **Queue Worker**: Processamento assíncrono
- **MailHog**: Teste de emails
- **Elasticsearch**: Busca avançada

### Configurações de Debug

#### Xdebug

- ✅ Pré-configurado para VS Code
- 🔧 Host: `host.docker.internal`
- 🔌 Porta: `9003`
- 📁 Path mapping automático

#### Logs

- 📝 Nginx: `storage/logs/nginx/`
- 🐘 PHP: Container logs
- 🗄️ MySQL: Container logs
- 📧 Laravel: `storage/logs/laravel.log`

## ⚙️ Configurações Incluídas

### Nginx

- **Performance**: Gzip, cache de estáticos
- **Security**: Headers de segurança completos
- **PHP-FPM**: Integração otimizada
- **SSL Ready**: Preparado para HTTPS

### PHP

- **Extensions**: MySQL, PostgreSQL, Redis, GD, Zip
- **Xdebug**: Configurado para desenvolvimento
- **Memory**: 256MB limit
- **Upload**: 64MB max file size
- **Timezone**: America/Sao_Paulo

### Laravel

- **Sanctum**: Autenticação API
- **Telescope**: Debug e monitoring
- **Breeze**: Scaffolding de autenticação
- **Horizon**: Queue management (opcional)

## 🔧 Comandos Úteis

### Setup Inicial

```bash
# Setup automático
./scripts/setup.sh

# Setup manual
docker-compose up --build -d
docker-compose exec app composer install
docker-compose exec app php artisan key:generate
docker-compose exec app php artisan migrate
```

### Desenvolvimento

```bash
# Ambiente de desenvolvimento
./scripts/dev.sh

# Comandos artisan
./scripts/artisan.sh migrate
./scripts/artisan.sh make:model Post -mfc

# Logs em tempo real
docker-compose logs -f app
```

### Laravel Artisan

```bash
# Migration
docker-compose exec app php artisan make:migration create_posts_table
docker-compose exec app php artisan migrate

# Models
docker-compose exec app php artisan make:model Post -mfc

# Controllers
docker-compose exec app php artisan make:controller PostController --resource

# Seeder
docker-compose exec app php artisan make:seeder PostSeeder
docker-compose exec app php artisan db:seed
```

### Cache e Otimização

```bash
# Limpar caches
docker-compose exec app php artisan cache:clear
docker-compose exec app php artisan config:clear
docker-compose exec app php artisan route:clear
docker-compose exec app php artisan view:clear

# Otimizar para produção
docker-compose exec app php artisan config:cache
docker-compose exec app php artisan route:cache
docker-compose exec app php artisan view:cache
```

## 🐛 Debug e Desenvolvimento

### VS Code Setup

1. **Instalar extensão PHP Debug**
2. **Criar `.vscode/launch.json`:**

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Listen for Xdebug",
      "type": "php",
      "request": "launch",
      "port": 9003,
      "pathMappings": {
        "/var/www": "${workspaceFolder}"
      }
    }
  ]
}
```

3. **Iniciar debug**: F5 ou "Run and Debug"

### Xdebug

- **Breakpoints**: Funcionam automaticamente
- **Step debugging**: F10, F11, F12
- **Variables**: Painel lateral automático
- **Console**: Avaliação de expressões

### Laravel Telescope

- **URL**: `http://localhost:8080/telescope`
- **Queries**: Monitor de banco de dados
- **Requests**: Todas as requisições HTTP
- **Exceptions**: Erros detalhados
- **Cache**: Operações de cache

## 🌐 URLs de Desenvolvimento

### Aplicação

- **Frontend**: `http://localhost:[porta escolhida]`
- **Admin**: `http://localhost:[porta]/admin` (se Filament)
- **API**: `http://localhost:[porta]/api`

### Ferramentas

- **Telescope**: `http://localhost:[porta]/telescope`
- **MailHog**: `http://localhost:8025`
- **Elasticsearch**: `http://localhost:9200`
- **Horizon**: `http://localhost:[porta]/horizon` (se queue)

## 📁 Estrutura do Projeto

```
meu_projeto_laravel/
├── app/                    # Aplicação Laravel
│   ├── Http/Controllers/   # Controllers
│   ├── Models/            # Models Eloquent
│   └── ...
├── docker/                # Configurações Docker
│   ├── nginx/            # Configurações Nginx
│   │   ├── nginx.conf    # Config principal
│   │   └── sites-available/ # Sites
│   ├── php/              # Configurações PHP
│   │   ├── Dockerfile    # Image PHP custom
│   │   ├── custom.ini    # Configurações PHP
│   │   └── xdebug.ini    # Configurações Xdebug
│   └── mysql/            # Configurações MySQL
├── public/               # Arquivos públicos
├── resources/            # Views, assets, lang
├── routes/               # Rotas da aplicação
├── storage/              # Storage e logs
│   └── logs/nginx/       # Logs do Nginx
├── scripts/              # Scripts utilitários
│   ├── setup.sh         # Setup inicial
│   ├── dev.sh           # Desenvolvimento
│   └── artisan.sh       # Wrapper artisan
├── docker-compose.yml    # Docker Compose
├── .env                  # Ambiente desenvolvimento
├── .env.production       # Ambiente produção
└── README.md             # Documentação
```

## 🔒 Produção

### Deploy Preparado

O projeto já vem configurado para produção:

```bash
# Usar .env.production
cp .env.production .env

# Build para produção
docker-compose -f docker-compose.prod.yml up --build -d

# Otimizações
docker-compose exec app php artisan config:cache
docker-compose exec app php artisan route:cache
docker-compose exec app php artisan view:cache
```

### Security Headers

Nginx já configurado com:

- `X-Frame-Options`
- `X-XSS-Protection`
- `X-Content-Type-Options`
- `Content-Security-Policy`
- `Referrer-Policy`

## 🚨 Solução de Problemas

### Docker não encontrado

```bash
# Verificar Docker
docker --version
docker-compose --version

# Iniciar Docker Desktop (macOS)
open -a Docker

# Linux
sudo systemctl start docker
```

### Erro de permissão PHP

```bash
# Corrigir permissões
docker-compose exec app chown -R www-data:www-data storage bootstrap/cache
docker-compose exec app chmod -R 775 storage bootstrap/cache
```

### Xdebug não conecta

```bash
# Verificar configuração
docker-compose exec app php -m | grep xdebug

# Verificar logs
docker-compose exec app tail -f /var/log/xdebug.log
```

### MySQL Connection refused

```bash
# Verificar se MySQL está rodando
docker-compose ps mysql

# Ver logs do MySQL
docker-compose logs mysql

# Resetar container MySQL
docker-compose down mysql
docker-compose up -d mysql
```

### Composer timeout

```bash
# Aumentar timeout
docker-compose exec app composer config --global process-timeout 2000

# Usar cache
docker-compose exec app composer install --prefer-dist
```

## 📦 Extensões Recomendadas

### VS Code

- **PHP Debug**: Debugging Xdebug
- **PHP Intelephense**: IntelliSense
- **Laravel Extension Pack**: Ferramentas Laravel
- **Docker**: Gerenciamento containers

### PHPStorm

- **Laravel Plugin**: Suporte nativo Laravel
- **Docker Plugin**: Integração Docker
- **Database Tools**: Gerenciamento BD

## 🤝 Contribuições

Contribuições são bem-vindas! Áreas de interesse:

- 🆕 Novos tipos de projeto
- 🔧 Otimizações Docker
- 🛡️ Melhorias de segurança
- 📚 Documentação adicional

## 📄 Licença

MIT License - Livre para usar e modificar.

## 🔗 Links Úteis

- [Laravel Documentation](https://laravel.com/docs)
- [Docker Documentation](https://docs.docker.com/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Xdebug Documentation](https://xdebug.org/docs/)
- [Laravel Telescope](https://laravel.com/docs/telescope)
- [Laravel Sanctum](https://laravel.com/docs/sanctum)

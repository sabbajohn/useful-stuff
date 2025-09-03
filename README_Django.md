# Django Project Creator

Script automatizado para criar projetos Django completos com configurações profissionais, compatível com macOS e Linux.

## 🚀 Características

- ✅ **Interface Interativa**: Menu amigável com `gum`
- 🎯 **Tipos de Projeto**: API (DRF), Web tradicional, ou Fullstack
- 🐳 **Docker Ready**: Configuração completa com Docker Compose
- 🗄️ **Multiple Databases**: SQLite, PostgreSQL
- 🔴 **Redis Integration**: Cache e sessões
- 🌱 **Celery Support**: Tasks assíncronas
- 📦 **Git Integration**: Inicialização automática com .gitignore
- 📚 **Documentação**: README e docs automáticos
- 🛡️ **Security**: Configurações de segurança incluídas
- 🎨 **Code Quality**: Configuração para black, flake8, pytest

## 📋 Pré-requisitos

### macOS
```bash
# Homebrew (se não tiver)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Dependências
brew install python gum

# Docker (opcional)
brew install --cask docker

# PostgreSQL (opcional)
brew install postgresql
```

### Linux (Ubuntu/Debian)
```bash
# Python e pip
sudo apt-get update
sudo apt-get install python3 python3-pip python3-venv

# gum
echo 'deb [trusted=yes] https://repo.charm.sh/apt/ /' | sudo tee /etc/apt/sources.list.d/charm.list
sudo apt update && sudo apt install gum

# Docker (opcional)
sudo apt install docker.io docker-compose

# PostgreSQL (opcional)
sudo apt install postgresql postgresql-contrib
```

## 🛠️ Instalação

1. **Baixar o script:**
```bash
curl -O https://raw.githubusercontent.com/seu-repo/django-start.sh
# ou
wget https://raw.githubusercontent.com/seu-repo/django-start.sh
```

2. **Tornar executável:**
```bash
chmod +x django-start.sh
```

3. **Executar:**
```bash
./django-start.sh
```

## 📱 Tipos de Projeto

### 1. 🌐 API (Django REST Framework)
- Django REST Framework configurado
- JWT Authentication
- API Documentation (Swagger/ReDoc)
- Serializers e ViewSets
- CORS configurado

**Apps criados:**
- `core` - Configurações base
- `api` - Endpoints da API
- `users` - Gestão de usuários

### 2. 📄 Web Tradicional
- Templates Django
- Bootstrap 5 integrado
- Crispy Forms
- Sistema de páginas

**Apps criados:**
- `core` - Configurações base
- `users` - Gestão de usuários
- `pages` - Páginas do site

### 3. 🔄 Fullstack
- API + Frontend em um projeto
- Django REST Framework
- Configuração para SPA (React/Vue/Angular)
- Webpack Loader configurado

**Apps criados:**
- `core` - Configurações base
- `api` - Endpoints da API
- `users` - Gestão de usuários
- `frontend` - Interface do usuário

## 🐳 Configuração Docker

### Desenvolvimento
```bash
# Construir e executar
docker-compose up --build

# Em background
docker-compose up -d

# Ver logs
docker-compose logs -f
```

### Produção
```bash
# Usar arquivo de produção
docker-compose -f docker-compose.prod.yml up --build
```

## 🗄️ Bancos de Dados

### SQLite (Padrão)
- Sem configuração adicional
- Ideal para desenvolvimento
- Arquivo `db.sqlite3`

### PostgreSQL
- Configuração automática via Docker
- Variáveis de ambiente no `.env`
- Backup automático com volumes

## 🔴 Redis (Opcional)

### Funcionalidades
- **Cache**: Aceleração de queries
- **Sessões**: Armazenamento em Redis
- **Celery Broker**: Para tasks assíncronas

### Configuração
```bash
# Via Docker (automático)
docker-compose up

# Local (macOS)
brew install redis
brew services start redis

# Local (Linux)
sudo apt install redis-server
sudo systemctl start redis
```

## 🌱 Celery (Opcional)

### Recursos incluídos
- Worker configuration
- Beat scheduler
- Task monitoring
- Error handling

### Comandos úteis
```bash
# Worker
celery -A config worker -l info

# Beat (agendador)
celery -A config beat -l info

# Flower (monitoring)
pip install flower
celery -A config flower
```

## 📁 Estrutura do Projeto

### API Project
```
meu_projeto/
├── src/                    # Código Django
│   ├── config/            # Configurações
│   ├── core/              # App base
│   ├── api/               # API endpoints
│   ├── users/             # Usuários
│   └── manage.py
├── venv/                  # Ambiente virtual
├── docker/                # Configurações Docker
├── scripts/               # Scripts utilitários
├── docs/                  # Documentação
├── requirements.txt       # Dependências
├── requirements-dev.txt   # Deps de desenvolvimento
├── .env                   # Variáveis de ambiente
├── docker-compose.yml     # Docker desenvolvimento
├── docker-compose.prod.yml # Docker produção
└── README.md
```

### Fullstack Project
```
meu_projeto/
├── backend/               # Django app
├── frontend/              # Frontend app
├── docker/
│   ├── backend/
│   └── frontend/
└── ...
```

## ⚙️ Configurações Incluídas

### Django Settings
- Configuração de produção/desenvolvimento
- Security headers
- CORS configurado
- Static files com WhiteNoise
- Logging configurado
- Internationalization (pt-br)

### Code Quality
- **Black**: Formatação de código
- **Flake8**: Linting
- **isort**: Ordenação de imports
- **mypy**: Type checking
- **pytest**: Testes

### CI/CD Ready
- GitHub Actions templates
- Docker multi-stage builds
- Environment variables
- Health checks

## 🔧 Comandos Úteis

### Desenvolvimento
```bash
# Ativar ambiente virtual
source venv/bin/activate

# Instalar dependências
pip install -r requirements-dev.txt

# Executar testes
python manage.py test
# ou com pytest
pytest

# Formatação de código
black .
isort .
flake8 .

# Migrations
python manage.py makemigrations
python manage.py migrate

# Superusuário
python manage.py createsuperuser

# Servidor de desenvolvimento
python manage.py runserver
```

### Produção
```bash
# Coletar static files
python manage.py collectstatic

# Executar com Gunicorn
gunicorn config.wsgi:application --bind 0.0.0.0:8000
```

## 🔐 Variáveis de Ambiente

### Principais variáveis no `.env`:
```bash
# Django
DEBUG=True
SECRET_KEY=sua-chave-secreta
ALLOWED_HOSTS=localhost,127.0.0.1
DJANGO_PORT=8000

# Database
DATABASE_URL=postgresql://user:pass@localhost:5432/db

# Redis (se habilitado)
REDIS_URL=redis://localhost:6379/0

# Celery (se habilitado)
CELERY_BROKER_URL=redis://localhost:6379/0
```

## 🚨 Solução de Problemas

### Error: 'gum' não encontrado
```bash
# macOS
brew install gum

# Linux
# Seguir instruções em: https://github.com/charmbracelet/gum#installation
```

### Error: PostgreSQL connection
```bash
# Verificar se PostgreSQL está rodando
# Docker
docker-compose logs db

# Local
brew services list | grep postgres  # macOS
sudo systemctl status postgresql    # Linux
```

### Error: Redis connection
```bash
# Verificar Redis
docker-compose logs redis

# Testar conexão
redis-cli ping
```

### Error: Permission denied
```bash
# macOS - dar permissão ao terminal
# System Preferences > Security & Privacy > Privacy > Full Disk Access

# Linux - verificar permissões Docker
sudo usermod -aG docker $USER
```

## 🎯 Exemplos de Uso

### Projeto API simples
```bash
./django-start.sh
# Escolher:
# - Nome: "blog_api"
# - Tipo: "API (DRF)"
# - PostgreSQL: Não
# - Redis: Não
# - Docker: Sim
# - Git: Sim
```

### Projeto Fullstack completo
```bash
./django-start.sh
# Escolher:
# - Nome: "ecommerce"
# - Tipo: "Fullstack"
# - PostgreSQL: Sim
# - Redis: Sim
# - Celery: Sim
# - Docker: Sim
# - Git: Sim
```

## 🤝 Contribuições

Contribuições são bem-vindas! Especialmente para:
- Suporte a outros frameworks frontend
- Templates adicionais
- Integrações com cloud providers
- Melhorias na documentação

## 📄 Licença

MIT License - Livre para usar e modificar.

## 🔗 Links Úteis

- [Django Documentation](https://docs.djangoproject.com/)
- [Django REST Framework](https://www.django-rest-framework.org/)
- [Celery Documentation](https://docs.celeryproject.org/)
- [Docker Documentation](https://docs.docker.com/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

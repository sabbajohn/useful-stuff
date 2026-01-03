# Guia de Instalação - ProjTest

## Pré-requisitos

- Python 3.8+
- pip
- PostgreSQL 12+
- Redis 6+
- Docker e Docker Compose (opcional)

## Instalação Local

1. **Clone o repositório:**
   ```bash
   git clone <repository-url>
   cd ProjTest
   ```

2. **Ative o ambiente virtual:**
   ```bash
   source venv/bin/activate
   ```

3. **Instale as dependências:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Configure as variáveis de ambiente:**
   ```bash
   cp .env.example .env
   # Edite o arquivo .env com suas configurações
   ```

5. **Execute as migrações:**
   ```bash
   python manage.py migrate
   ```

6. **Crie um superusuário:**
   ```bash
   python manage.py createsuperuser
   ```

7. **Execute o servidor:**
   ```bash
   python manage.py runserver
   ```

## Instalação com Docker

1. **Execute com Docker Compose:**
   ```bash
   docker-compose up --build
   ```

2. **Acesse:** http://localhost:8000

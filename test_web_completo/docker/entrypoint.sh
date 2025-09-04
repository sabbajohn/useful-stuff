#!/bin/bash
set -e

# Se argumentos foram passados, execute-os diretamente (para celery, etc)
if [ $# -gt 0 ]; then
    echo "🔧 Executando comando: $@"
    # Para celery, precisamos ir ao diretório correto primeiro
    if [ -f "/code/manage.py" ]; then
        cd "/code"
    elif [ -f "/code/backend/manage.py" ]; then
        cd "/code/backend"
    elif [ -f "/code/src/manage.py" ]; then
        cd "/code/src"
    fi
    exec "$@"
fi

# Determinar o diretório correto do Django
if [ -f "/code/manage.py" ]; then
    DJANGO_DIR="/code"
elif [ -f "/code/backend/manage.py" ]; then
    DJANGO_DIR="/code/backend"
elif [ -f "/code/src/manage.py" ]; then
    DJANGO_DIR="/code/src"
else
    echo "❌ Erro: manage.py não encontrado!"
    exit 1
fi

echo "📁 Usando diretório Django: $DJANGO_DIR"
cd "$DJANGO_DIR"

# Apenas o serviço web executa migrações e setup inicial
echo "🌐 Iniciando serviço web..."

# Wait for database
if [ "$DATABASE_URL" != "sqlite:///db.sqlite3" ]; then
    echo "⏳ Aguardando banco de dados..."
    python manage.py wait_for_db || true
fi

# Run migrations
echo "🔄 Executando migrações..."
python manage.py migrate

# Collect static files
echo "� Coletando arquivos estáticos..."
python manage.py collectstatic --noinput

# Create superuser if needed
echo "👤 Criando superusuário..."
python manage.py shell -c "
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@localhost', 'admin123')
    print('Superusuário criado: admin/admin123')
"

# Start server
if [ "$DJANGO_ENV" = "production" ]; then
    echo "🚀 Iniciando Gunicorn..."
    exec gunicorn config.wsgi:application --bind 0.0.0.0:8000 --workers 3
else
    echo "🚀 Iniciando servidor de desenvolvimento..."
    exec python manage.py runserver 0.0.0.0:8000
fi

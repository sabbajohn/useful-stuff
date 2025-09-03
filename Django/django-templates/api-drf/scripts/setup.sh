#!/bin/bash
# Script de configuração inicial

echo "🚀 Configurando projeto ProjTest..."

# Ativa ambiente virtual
source venv/bin/activate

# Instala dependências
pip install -r requirements.txt

# Executa migrações
python manage.py migrate

# Coleta arquivos estáticos
python manage.py collectstatic --noinput

echo "✅ Projeto configurado!"

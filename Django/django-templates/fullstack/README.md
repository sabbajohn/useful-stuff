# ProjTest

Projeto Django criado automaticamente.

## 🚀 Como executar

### Desenvolvimento local

1. **Ativar ambiente virtual:**
   ```bash
   source venv/bin/activate
   ```

2. **Instalar dependências:**
   ```bash
   pip install -r requirements.txt
   ```

3. **Executar migrações:**
   ```bash
   python manage.py migrate
   ```

4. **Criar superusuário:**
   ```bash
   python manage.py createsuperuser
   ```

5. **Executar servidor:**
   ```bash
   python manage.py runserver
   ```

### Com Docker

1. **Construir e executar:**
   ```bash
   docker-compose up --build
   ```

2. **Acessar:** http://localhost:8000

## 📋 Estrutura do projeto

```
ProjTest/
├── backend/          # Código Django
├── venv/             # Ambiente virtual
├── docker/           # Configurações Docker
├── scripts/          # Scripts utilitários
├── docs/             # Documentação
├── requirements.txt  # Dependências Python
├── .env             # Variáveis de ambiente
└── README.md        # Este arquivo
```

## 🛠️ Comandos úteis

- **Executar testes:** `python manage.py test`
- **Criar migração:** `python manage.py makemigrations`
- **Aplicar migração:** `python manage.py migrate`
- **Shell Django:** `python manage.py shell`
- **Coletar static:** `python manage.py collectstatic`

## 📚 Documentação

- [Django Documentation](https://docs.djangoproject.com/)

# Django Project Creator v3.0 - Template Based

Script simplificado para criação de projetos Django usando templates pré-configurados e testados. Substitui o script anterior que tinha problemas com reescrita dinâmica de arquivos.

## 🚀 Melhorias da v3.0

### ✅ Problemas Resolvidos

- **Sem reescrita de arquivos**: Templates são copiados integralmente, sem modificações dinâmicas
- **Estrutura mais simples**: Apenas 3 templates bem definidos
- **Celery removido**: Era muito específico, não incluído por padrão
- **Menos propenso a erros**: Sem manipulação complexa de arquivos
- **Templates testados**: Cada template funciona independentemente

### 📦 Templates Disponíveis

#### 1. API DRF (Django REST Framework)

- Django REST Framework puro
- PostgreSQL + Redis configurados
- Autenticação JWT
- Documentação Swagger/ReDoc automática
- Docker Compose pronto
- **Ideal para**: APIs REST, microserviços, backends para mobile

#### 2. Web Fullstack

- Django templates + Django REST Framework
- Bootstrap 5 para interface web
- PostgreSQL + Redis configurados
- Autenticação dual (Session + JWT)
- Frontend e backend integrados
- **Ideal para**: Sites web com API integrada, dashboards, aplicações híbridas

#### 3. Decoupled (Django + Vue.js)

- Backend: Django REST Framework puro
- Frontend: Vue.js 3 + Quasar Framework
- Totalmente separados
- PostgreSQL + Redis configurados
- Autenticação JWT com refresh automático
- **Ideal para**: SPAs modernas, aplicações decoupled, frontends ricos

## 📁 Estrutura dos Templates

```
Django/django-templates-v3/
├── api-drf/                    # Template 1: API REST pura
│   ├── backend/                # Django REST Framework
│   ├── docker/                 # Configuração Docker
│   ├── requirements.txt        # Dependências Python
│   ├── docker-compose.yml      # Docker Compose
│   └── README.md               # Documentação específica
│
├── web-fullstack/              # Template 2: Web + API
│   ├── backend/                # Django + DRF
│   │   ├── web/                # App para views web
│   │   └── templates/          # Templates HTML com Bootstrap
│   ├── docker/                 # Configuração Docker
│   ├── requirements.txt        # Dependências Python
│   ├── docker-compose.yml      # Docker Compose
│   └── README.md               # Documentação específica
│
└── decoupled/                  # Template 3: Django + Vue.js
    ├── backend/                # Django REST Framework
    ├── frontend/               # Vue.js 3 + Quasar
    │   ├── src/                # Código fonte Vue
    │   ├── package.json        # Dependências Node.js
    │   └── Dockerfile          # Docker para frontend
    ├── docker/                 # Configuração Docker backend
    ├── requirements.txt        # Dependências Python
    ├── docker-compose.yml      # Docker Compose com 2 serviços
    └── README.md               # Documentação específica
```

## 🎯 Uso

### Modo Interativo

```bash
./django-project-creator-v3.sh
# Seguir prompts para nome e tipo de projeto
```

### Modo Direto

```bash
./django-project-creator-v3.sh minha_api 1        # API DRF
./django-project-creator-v3.sh meu_site 2         # Web Fullstack
./django-project-creator-v3.sh meu_app 3          # Decoupled
```

### Ajuda

```bash
./django-project-creator-v3.sh --help
```

## 🔧 Personalização

O script faz apenas substituições simples de nomes:

- `ProjTest` → nome do seu projeto (CamelCase)
- `projtest` → nome do seu projeto (lowercase)

Mantém toda a estrutura e configuração dos templates intactas.

## 📋 Próximos Passos Após Criação

### Para qualquer template:

1. `cd nome_do_projeto`
2. `docker-compose up --build` (recomendado)

### Para template decoupled:

1. `docker-compose up backend postgres redis --build`
2. Em outro terminal: `cd frontend && npm install && npm run dev`

## 🔄 Migração do Script Anterior

Se você usava o script anterior (`django-project-creator.sh`):

1. **Backup**: Mantenha o script antigo como backup
2. **Use o v3**: Para novos projetos, use apenas o v3.0
3. **Templates**: Os templates antigos ainda funcionam, mas recomendamos usar os novos
4. **Configuração**: O v3 é mais simples e confiável

## 🤝 Contribuição

Para adicionar novos templates:

1. Crie nova pasta em `Django/django-templates-v3/`
2. Adicione template funcional e testado
3. Atualize o script para incluir o novo template
4. Adicione documentação específica (README.md)

## 📝 Changelog v3.0

- ✅ Removida lógica de reescrita dinâmica de arquivos
- ✅ Templates completamente auto-contidos
- ✅ Celery removido (muito específico)
- ✅ Adicionado template Vue.js + Quasar
- ✅ Melhorada documentação de cada template
- ✅ Estrutura mais simples e confiável
- ✅ Docker Compose otimizado para cada caso de uso
- ✅ Frontend moderno para template decoupled

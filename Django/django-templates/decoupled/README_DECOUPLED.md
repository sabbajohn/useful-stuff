# Django Decoupled Template

Este template cria um backend Django puro (API REST) sem frontend integrado, ideal para aplicações decoupled onde o frontend será criado separadamente.

## Características

- ✅ Django REST Framework completo
- ✅ Autenticação JWT
- ✅ Documentação Swagger automática
- ✅ PostgreSQL + Redis + Celery
- ✅ Docker configurado
- ❌ Sem frontend Django (templates/views)
- ❌ Sem webpack_loader

## Frontend Separado

Para o frontend, você pode usar qualquer tecnologia:

### React/Next.js
```bash
npx create-next-app@latest frontend
cd frontend
npm install axios
```

### Vue/Nuxt
```bash
npx nuxi@latest init frontend
cd frontend
npm install axios
```

### Vite + React/Vue
```bash
npm create vite@latest frontend
cd frontend
npm install axios
```

### Flutter
```bash
flutter create frontend
cd frontend
# Adicionar http package no pubspec.yaml
```

## API Endpoints

- `http://localhost:8000/api/` - API root
- `http://localhost:8000/api/docs/` - Documentação Swagger
- `http://localhost:8000/api/redoc/` - Documentação ReDoc
- `http://localhost:8000/admin/` - Django Admin

## Consumindo a API

O backend expõe endpoints REST que podem ser consumidos por qualquer frontend:

```javascript
// Exemplo com axios
import axios from 'axios';

const api = axios.create({
  baseURL: 'http://localhost:8000/api/',
  headers: {
    'Content-Type': 'application/json',
  }
});

// GET request
const response = await api.get('endpoint/');

// POST request
const response = await api.post('endpoint/', data);
```

## CORS

O CORS está configurado para aceitar requisições de qualquer origem durante o desenvolvimento. Para produção, configure adequadamente no settings.py:

```python
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",  # React
    "http://localhost:8080",  # Vue
    "https://meusite.com",
]
```

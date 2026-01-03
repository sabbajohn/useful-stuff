# Python Project Manager

Um script bash completo para gerenciar projetos Python, incluindo criação de projetos, ambientes virtuais, gerenciamento de dependências e ferramentas de desenvolvimento.

## 🚀 Recursos

- ✅ **Criação de Projetos**: Cria estrutura completa de projeto Python
- 🐍 **Detecção de Python**: Verifica e lista versões disponíveis do Python
- 🌐 **Ambientes Virtuais**: Criação, ativação e gerenciamento de virtual envs
- 📦 **Gerenciamento de Pacotes**: Instalar, remover, atualizar dependências
- 📋 **Requirements**: Exportar e importar requirements.txt
- 🛠️ **Ferramentas de Dev**: Black, pytest, flake8, mypy, cobertura
- 🏗️ **Estruturas Avançadas**: Configurações para projetos profissionais
- 📊 **Resumos**: Visão geral dos projetos existentes

## 📋 Pré-requisitos

### macOS

```bash
# Instalar Homebrew (se não tiver)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Instalar dependências
brew install gum python3

# Opcional: instalar pyenv para múltiplas versões do Python
brew install pyenv
```

### Linux (Ubuntu/Debian)

```bash
# Instalar gum
echo 'deb [trusted=yes] https://repo.charm.sh/apt/ /' | sudo tee /etc/apt/sources.list.d/charm.list
sudo apt update && sudo apt install gum

# Python3 (geralmente já vem instalado)
sudo apt install python3 python3-pip python3-venv

# Opcional: pyenv
curl https://pyenv.run | bash
```

## 🛠️ Instalação

1. **Clone ou baixe o script:**

```bash
curl -O https://raw.githubusercontent.com/seu-repo/python-project-manager.sh
```

2. **Torne executável:**

```bash
chmod +x python-project-manager.sh
```

3. **Execute:**

```bash
./python-project-manager.sh
```

## 📱 Funcionalidades Detalhadas

### 1. 🔍 Verificar Instalação do Python

- Lista todas as versões do Python disponíveis no sistema
- Verifica se pip está instalado e funcionando
- Mostra versões e caminhos dos executáveis

### 2. 🆕 Criar Novo Projeto Python

**Cria estrutura completa incluindo:**

```
novo-projeto/
├── src/
│   ├── __init__.py
│   └── main.py
├── tests/
│   ├── __init__.py
│   └── test_main.py
├── docs/
├── scripts/
├── venv/                    # Ambiente virtual
├── requirements.txt
├── requirements-dev.txt
├── setup.py
├── README.md
├── .gitignore
└── Makefile
```

**Recursos:**

- Seleção de versão do Python
- Criação automática de ambiente virtual
- Instalação de dependências básicas opcionais
- Estrutura de testes com pytest
- Configuração de desenvolvimento

### 3. 🌐 Gerenciar Ambiente Virtual

#### Funcionalidades:

- **Status**: Verifica se o ambiente virtual existe e está ativo
- **Criar**: Cria novo ambiente virtual com versão específica do Python
- **Remover**: Remove ambiente virtual existente
- **Gerenciar Pacotes**: Interface interativa para pacotes
- **Requirements**: Exportar/importar dependências

#### Gerenciamento de Pacotes:

- Listar pacotes instalados
- Instalar novos pacotes
- Remover pacotes específicos
- Atualizar pacotes individuais ou todos
- Buscar pacotes no PyPI

### 4. 🛠️ Utilitários de Desenvolvimento

#### 🔍 Análise de Qualidade

- **Flake8**: Verificação de estilo e erros sintáticos
- **MyPy**: Verificação de tipos estáticos
- **Pylint**: Análise abrangente de código

#### 🎨 Formatação

- **Black**: Formatação automática do código
- Configuração consistente para todo o projeto

#### 🧪 Testes

- **pytest**: Execução de testes unitários
- **Coverage**: Análise de cobertura de testes
- Relatórios em HTML e terminal

#### 🏗️ Estrutura Avançada

Cria estrutura para projetos profissionais:

```
projeto-avancado/
├── src/
│   ├── models/
│   ├── views/
│   ├── controllers/
│   ├── utils/
│   └── services/
├── tests/
│   ├── unit/
│   ├── integration/
│   └── fixtures/
├── config/
├── data/
├── logs/
├── notebooks/
├── deployment/
├── docker/
├── pyproject.toml
├── Makefile
├── .pre-commit-config.yaml
├── Dockerfile
└── docker-compose.yml
```

### 5. 📊 Resumo de Projetos

- Lista todos os projetos no diretório base
- Mostra status dos ambientes virtuais
- Verifica presença de arquivos importantes
- Estatísticas gerais dos projetos

## ⚙️ Configuração

### Variáveis Configuráveis

Edite no início do script:

```bash
DEFAULT_PYTHON_VERSION="3.11"           # Versão padrão do Python
PROJECTS_BASE_DIR="$HOME/Projects"      # Diretório base dos projetos
VENV_DIR_NAME="venv"                    # Nome do diretório do virtual env
```

### Estrutura de Arquivos Gerados

#### requirements.txt

```
requests>=2.25.1
python-dotenv>=0.19.0
```

#### requirements-dev.txt

```
pytest>=7.0.0
black>=22.0.0
flake8>=4.0.0
mypy>=0.950
pytest-cov>=3.0.0
```

#### .gitignore

Inclui padrões para:

- Arquivos Python compilados
- Ambientes virtuais
- IDEs (VS Code, PyCharm)
- Arquivos de sistema (macOS, Windows)
- Arquivos de build e distribuição

## 🎯 Exemplos de Uso

### Criar Projeto Completo

```bash
./python-project-manager.sh
# Escolher "🆕 Criar novo projeto Python"
# Seguir as instruções interativas
```

### Adicionar Dependências

```bash
./python-project-manager.sh
# Escolher "🌐 Gerenciar ambiente virtual"
# Selecionar projeto
# Escolher "📦 Ativar e gerenciar pacotes"
# Escolher "📦 Instalar novo pacote"
```

### Executar Análise de Qualidade

```bash
./python-project-manager.sh
# Escolher "🛠️ Utilitários de desenvolvimento"
# Escolher "🔍 Analisar qualidade do código"
```

### Executar Testes com Cobertura

```bash
./python-project-manager.sh
# Escolher "🛠️ Utilitários de desenvolvimento"
# Escolher "📊 Verificar cobertura de testes"
```

## 🔧 Integração com IDEs

### VS Code

O script pode abrir projetos automaticamente no VS Code se disponível.

**Extensões recomendadas:**

- Python
- Pylance
- Black Formatter
- GitLens

### PyCharm

Estrutura compatível com PyCharm Professional e Community.

## 🐳 Docker Support

Para projetos com estrutura avançada, são criados:

### Dockerfile

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY src/ ./src/
CMD ["python", "-m", "src.main"]
```

### docker-compose.yml

```yaml
version: "3.8"
services:
  app:
    build: .
    volumes:
      - .:/app
```

## 🚨 Solução de Problemas

### Python não encontrado

```bash
# macOS
brew install python3

# Linux
sudo apt install python3 python3-pip
```

### gum não encontrado

```bash
# macOS
brew install gum

# Linux
sudo apt install gum
```

### Erro de permissões no virtual env

```bash
# Verificar proprietário do diretório
ls -la
# Se necessário, corrigir permissões
sudo chown -R $USER:$USER projeto/
```

### pip outdated

```bash
# Dentro do virtual env
pip install --upgrade pip
```

## 🔄 Atualizações

Para manter o script atualizado:

```bash
# Backup da versão atual
cp python-project-manager.sh python-project-manager.sh.bak

# Baixar nova versão
curl -O https://raw.githubusercontent.com/seu-repo/python-project-manager.sh
chmod +x python-project-manager.sh
```

## 🤝 Contribuições

Contribuições são bem-vindas! Áreas de interesse:

- Suporte a mais ferramentas de desenvolvimento
- Templates de projeto específicos (FastAPI, Django, etc.)
- Integração com mais IDEs
- Melhorias na interface do usuário
- Testes automatizados do próprio script

## 📄 Licença

MIT License - Sinta-se livre para usar e modificar.

## 🆘 Suporte

Para reportar bugs ou solicitar features:

1. Abra uma issue no repositório
2. Inclua informações sobre o sistema operacional
3. Inclua versão do Python e gum
4. Descreva o comportamento esperado vs atual

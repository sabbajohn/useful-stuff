#!/bin/bash

# Python Project Manager - Gerenciador de Projetos Python
# Compatível com macOS e Linux

# Detecta o sistema operacional
OS="$(uname -s)"
case "${OS}" in
    Linux*)     MACHINE=Linux;;
    Darwin*)    MACHINE=macOS;;
    *)          MACHINE="UNKNOWN:${OS}"
esac

# Verifica se os comandos essenciais estão instalados
for cmd in gum python3; do
    if ! command -v $cmd &>/dev/null; then
        echo "Erro: '$cmd' não está instalado."
        if [[ "$cmd" == "gum" && "$MACHINE" == "macOS" ]]; then
            echo "Para instalar no macOS: brew install gum"
        elif [[ "$cmd" == "python3" && "$MACHINE" == "macOS" ]]; then
            echo "Para instalar no macOS: brew install python"
        fi
        exit 1
    fi
done

# Configurações globais
DEFAULT_PYTHON_VERSION="3.11"
PROJECTS_BASE_DIR="$HOME/Projects"
VENV_DIR_NAME="venv"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para logging colorido
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Função para verificar se Python está disponível
check_python_installation() {
    echo "🐍 Verificando instalação do Python..."
    echo "=================================="
    
    # Lista versões disponíveis do Python
    python_versions=()
    for version in python3 python3.11 python3.12 python3.10 python3.9; do
        if command -v "$version" &>/dev/null; then
            ver_output=$($version --version 2>&1)
            python_versions+=("$version ($ver_output)")
        fi
    done
    
    if [[ ${#python_versions[@]} -eq 0 ]]; then
        log_error "Nenhuma versão do Python encontrada!"
        return 1
    fi
    
    log_success "Versões do Python encontradas:"
    for version in "${python_versions[@]}"; do
        echo "  🐍 $version"
    done
    
    # Verifica pip
    if command -v pip3 &>/dev/null; then
        pip_version=$(pip3 --version)
        log_success "pip disponível: $pip_version"
    else
        log_warning "pip3 não encontrado. Algumas funcionalidades podem não funcionar."
    fi
    
    echo
    return 0
}

# Função para criar novo projeto Python
create_new_project() {
    echo "🆕 Criando novo projeto Python..."
    echo "================================"
    
    # Solicita nome do projeto
    project_name=$(gum input --placeholder "Digite o nome do projeto")
    [[ -z "$project_name" ]] && return 0
    
    # Solicita diretório base (opcional)
    use_default_dir=$(gum confirm "Usar diretório padrão ($PROJECTS_BASE_DIR)?")
    if [[ $? -eq 0 ]]; then
        base_dir="$PROJECTS_BASE_DIR"
    else
        base_dir=$(gum input --placeholder "Digite o caminho do diretório base" --value="$HOME/")
    fi
    
    project_path="$base_dir/$project_name"
    
    # Verifica se o projeto já existe
    if [[ -d "$project_path" ]]; then
        log_error "O projeto '$project_name' já existe em '$project_path'"
        if ! gum confirm "Deseja continuar mesmo assim?"; then
            return 0
        fi
    fi
    
    # Cria estrutura do projeto
    log_info "Criando estrutura do projeto..."
    mkdir -p "$project_path"/{src,tests,docs,scripts}
    
    # Seleciona versão do Python
    python_cmd="python3"
    if gum confirm "Deseja especificar uma versão específica do Python?"; then
        available_pythons=()
        for version in python3.12 python3.11 python3.10 python3.9; do
            if command -v "$version" &>/dev/null; then
                available_pythons+=("$version")
            fi
        done
        
        if [[ ${#available_pythons[@]} -gt 0 ]]; then
            python_cmd=$(gum choose "${available_pythons[@]}")
        fi
    fi
    
    # Cria ambiente virtual
    log_info "Criando ambiente virtual com $python_cmd..."
    cd "$project_path" || exit 1
    
    if ! $python_cmd -m venv "$VENV_DIR_NAME"; then
        log_error "Falha ao criar ambiente virtual"
        return 1
    fi
    
    log_success "Ambiente virtual criado em $project_path/$VENV_DIR_NAME"
    
    # Ativa ambiente virtual
    source "$VENV_DIR_NAME/bin/activate"
    
    # Atualiza pip
    log_info "Atualizando pip..."
    pip install --upgrade pip
    
    # Cria arquivos básicos do projeto
    create_project_files "$project_path" "$project_name"
    
    # Pergunta sobre dependências iniciais
    if gum confirm "Deseja instalar dependências básicas (requests, pytest, etc.)?"; then
        install_basic_dependencies
    fi
    
    # Gera requirements.txt inicial
    log_info "Gerando requirements.txt..."
    pip freeze > requirements.txt
    
    log_success "Projeto '$project_name' criado com sucesso!"
    log_info "Para ativar o ambiente virtual: cd $project_path && source $VENV_DIR_NAME/bin/activate"
    
    echo
    if gum confirm "Deseja abrir o projeto no VS Code?"; then
        if command -v code &>/dev/null; then
            code "$project_path"
        else
            log_warning "VS Code não encontrado"
        fi
    fi
}

# Função para criar arquivos básicos do projeto
create_project_files() {
    local project_path="$1"
    local project_name="$2"
    
    # README.md
    cat > "$project_path/README.md" << EOF
# $project_name

Descrição do projeto.

## Instalação

1. Clone o repositório
2. Crie o ambiente virtual: \`python3 -m venv venv\`
3. Ative o ambiente virtual: \`source venv/bin/activate\`
4. Instale as dependências: \`pip install -r requirements.txt\`

## Uso

\`\`\`python
# Exemplo de uso
\`\`\`

## Desenvolvimento

Para executar os testes:
\`\`\`bash
pytest
\`\`\`

## Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request
EOF

    # .gitignore
    cat > "$project_path/.gitignore" << EOF
# Byte-compiled / optimized / DLL files
__pycache__/
*.py[cod]
*$py.class

# C extensions
*.so

# Distribution / packaging
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST

# PyInstaller
*.manifest
*.spec

# Unit test / coverage reports
htmlcov/
.tox/
.coverage
.coverage.*
.cache
nosetests.xml
coverage.xml
*.cover
.hypothesis/
.pytest_cache/

# Virtual environments
venv/
env/
ENV/

# IDEs
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Environment variables
.env
.env.local
.env.production
EOF

    # main.py
    cat > "$project_path/src/main.py" << EOF
#!/usr/bin/env python3
"""
$project_name - Arquivo principal
"""

def main():
    """Função principal do programa"""
    print("Hello, $project_name!")

if __name__ == "__main__":
    main()
EOF

    # __init__.py
    touch "$project_path/src/__init__.py"
    touch "$project_path/tests/__init__.py"
    
    # test_main.py
    cat > "$project_path/tests/test_main.py" << EOF
"""
Testes para o módulo main
"""
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

from main import main

def test_main():
    """Testa a função main"""
    # Adicione seus testes aqui
    assert True
EOF

    # requirements-dev.txt
    cat > "$project_path/requirements-dev.txt" << EOF
pytest>=7.0.0
black>=22.0.0
flake8>=4.0.0
mypy>=0.950
pytest-cov>=3.0.0
EOF

    # setup.py (opcional)
    cat > "$project_path/setup.py" << EOF
from setuptools import setup, find_packages

setup(
    name="$project_name",
    version="0.1.0",
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    python_requires=">=3.8",
    install_requires=[
        # Adicione suas dependências aqui
    ],
    author="Seu Nome",
    author_email="seu.email@example.com",
    description="Descrição do projeto",
    long_description=open("README.md").read(),
    long_description_content_type="text/markdown",
    url="https://github.com/seuusuario/$project_name",
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
    ],
)
EOF

    log_success "Arquivos do projeto criados"
}

# Função para instalar dependências básicas
install_basic_dependencies() {
    log_info "Instalando dependências básicas..."
    
    basic_packages=(
        "requests"
        "pytest"
        "black"
        "flake8"
        "python-dotenv"
    )
    
    for package in "${basic_packages[@]}"; do
        if gum confirm "Instalar $package?"; then
            pip install "$package"
        fi
    done
}

# Função para gerenciar ambiente virtual existente
manage_virtual_env() {
    echo "🌐 Gerenciamento de Ambiente Virtual"
    echo "==================================="
    
    # Seleciona diretório do projeto
    if [[ -d "$PROJECTS_BASE_DIR" ]]; then
        projects=($(find "$PROJECTS_BASE_DIR" -maxdepth 1 -type d -name "*" | grep -v "^$PROJECTS_BASE_DIR$" | sort))
        if [[ ${#projects[@]} -gt 0 ]]; then
            project_names=($(basename -a "${projects[@]}"))
            project_names+=("📁 Outro diretório...")
            
            selected=$(gum choose "${project_names[@]}")
            
            if [[ "$selected" == "📁 Outro diretório..." ]]; then
                project_path=$(gum input --placeholder "Digite o caminho completo do projeto")
            else
                project_path="$PROJECTS_BASE_DIR/$selected"
            fi
        else
            project_path=$(gum input --placeholder "Digite o caminho completo do projeto")
        fi
    else
        project_path=$(gum input --placeholder "Digite o caminho completo do projeto")
    fi
    
    [[ -z "$project_path" ]] && return 0
    
    if [[ ! -d "$project_path" ]]; then
        log_error "Diretório não encontrado: $project_path"
        return 1
    fi
    
    cd "$project_path" || return 1
    
    venv_action=$(gum choose \
        "🔍 Verificar status do ambiente virtual" \
        "🆕 Criar novo ambiente virtual" \
        "🗑️  Remover ambiente virtual" \
        "📦 Ativar e gerenciar pacotes" \
        "📋 Exportar requirements.txt" \
        "📥 Instalar de requirements.txt")
    
    case "$venv_action" in
    "🔍 Verificar status do ambiente virtual")
        check_venv_status "$project_path"
        ;;
    "🆕 Criar novo ambiente virtual")
        create_venv_in_project "$project_path"
        ;;
    "🗑️  Remover ambiente virtual")
        remove_venv "$project_path"
        ;;
    "📦 Ativar e gerenciar pacotes")
        manage_packages "$project_path"
        ;;
    "📋 Exportar requirements.txt")
        export_requirements "$project_path"
        ;;
    "📥 Instalar de requirements.txt")
        install_from_requirements "$project_path"
        ;;
    esac
}

# Função para verificar status do ambiente virtual
check_venv_status() {
    local project_path="$1"
    
    echo "📊 Status do Ambiente Virtual"
    echo "============================="
    
    if [[ -d "$project_path/$VENV_DIR_NAME" ]]; then
        log_success "Ambiente virtual encontrado em: $project_path/$VENV_DIR_NAME"
        
        # Verifica se está ativo
        if [[ "$VIRTUAL_ENV" == "$project_path/$VENV_DIR_NAME" ]]; then
            log_success "Ambiente virtual ATIVO"
        else
            log_warning "Ambiente virtual INATIVO"
            echo "Para ativar: source $project_path/$VENV_DIR_NAME/bin/activate"
        fi
        
        # Mostra versão do Python
        python_version=$("$project_path/$VENV_DIR_NAME/bin/python" --version 2>&1)
        echo "🐍 Versão do Python: $python_version"
        
        # Lista pacotes instalados
        if gum confirm "Mostrar pacotes instalados?"; then
            echo "📦 Pacotes instalados:"
            "$project_path/$VENV_DIR_NAME/bin/pip" list
        fi
    else
        log_warning "Nenhum ambiente virtual encontrado em $project_path"
        if gum confirm "Deseja criar um novo ambiente virtual?"; then
            create_venv_in_project "$project_path"
        fi
    fi
    echo
}

# Função para criar ambiente virtual em projeto existente
create_venv_in_project() {
    local project_path="$1"
    
    log_info "Criando ambiente virtual em $project_path..."
    
    # Seleciona versão do Python
    python_cmd="python3"
    if gum confirm "Deseja especificar uma versão específica do Python?"; then
        available_pythons=()
        for version in python3.12 python3.11 python3.10 python3.9; do
            if command -v "$version" &>/dev/null; then
                available_pythons+=("$version")
            fi
        done
        
        if [[ ${#available_pythons[@]} -gt 0 ]]; then
            python_cmd=$(gum choose "${available_pythons[@]}")
        fi
    fi
    
    cd "$project_path" || return 1
    
    if [[ -d "$VENV_DIR_NAME" ]]; then
        if ! gum confirm "Ambiente virtual já existe. Sobrescrever?"; then
            return 0
        fi
        rm -rf "$VENV_DIR_NAME"
    fi
    
    if $python_cmd -m venv "$VENV_DIR_NAME"; then
        log_success "Ambiente virtual criado com sucesso!"
        
        # Ativa e atualiza pip
        source "$VENV_DIR_NAME/bin/activate"
        pip install --upgrade pip
        
        if [[ -f "requirements.txt" ]]; then
            if gum confirm "Arquivo requirements.txt encontrado. Instalar dependências?"; then
                pip install -r requirements.txt
            fi
        fi
    else
        log_error "Falha ao criar ambiente virtual"
    fi
}

# Função para remover ambiente virtual
remove_venv() {
    local project_path="$1"
    
    if [[ ! -d "$project_path/$VENV_DIR_NAME" ]]; then
        log_warning "Nenhum ambiente virtual encontrado"
        return 0
    fi
    
    if gum confirm "Tem certeza que deseja remover o ambiente virtual?"; then
        rm -rf "$project_path/$VENV_DIR_NAME"
        log_success "Ambiente virtual removido"
    fi
}

# Função para gerenciar pacotes
manage_packages() {
    local project_path="$1"
    
    if [[ ! -d "$project_path/$VENV_DIR_NAME" ]]; then
        log_error "Ambiente virtual não encontrado"
        return 1
    fi
    
    cd "$project_path" || return 1
    source "$VENV_DIR_NAME/bin/activate"
    
    package_action=$(gum choose \
        "📋 Listar pacotes instalados" \
        "📦 Instalar novo pacote" \
        "🗑️  Remover pacote" \
        "⬆️  Atualizar pacote" \
        "🔄 Atualizar todos os pacotes" \
        "🔍 Buscar pacote no PyPI")
    
    case "$package_action" in
    "📋 Listar pacotes instalados")
        echo "📦 Pacotes instalados:"
        pip list
        ;;
    "📦 Instalar novo pacote")
        package_name=$(gum input --placeholder "Digite o nome do pacote")
        [[ -n "$package_name" ]] && pip install "$package_name"
        ;;
    "🗑️  Remover pacote")
        installed_packages=$(pip list --format=freeze | cut -d'=' -f1)
        if [[ -n "$installed_packages" ]]; then
            package_to_remove=$(echo "$installed_packages" | gum choose)
            [[ -n "$package_to_remove" ]] && pip uninstall "$package_to_remove"
        fi
        ;;
    "⬆️  Atualizar pacote")
        installed_packages=$(pip list --format=freeze | cut -d'=' -f1)
        if [[ -n "$installed_packages" ]]; then
            package_to_update=$(echo "$installed_packages" | gum choose)
            [[ -n "$package_to_update" ]] && pip install --upgrade "$package_to_update"
        fi
        ;;
    "🔄 Atualizar todos os pacotes")
        if gum confirm "Deseja atualizar todos os pacotes? (Isso pode levar tempo)"; then
            pip list --outdated --format=freeze | cut -d'=' -f1 | xargs -n1 pip install --upgrade
        fi
        ;;
    "🔍 Buscar pacote no PyPI")
        search_term=$(gum input --placeholder "Digite o termo de busca")
        if [[ -n "$search_term" ]]; then
            log_info "Abrindo busca no PyPI para: $search_term"
            if command -v open &>/dev/null; then  # macOS
                open "https://pypi.org/search/?q=$search_term"
            elif command -v xdg-open &>/dev/null; then  # Linux
                xdg-open "https://pypi.org/search/?q=$search_term"
            else
                echo "URL: https://pypi.org/search/?q=$search_term"
            fi
        fi
        ;;
    esac
    echo
}

# Função para exportar requirements
export_requirements() {
    local project_path="$1"
    
    if [[ ! -d "$project_path/$VENV_DIR_NAME" ]]; then
        log_error "Ambiente virtual não encontrado"
        return 1
    fi
    
    cd "$project_path" || return 1
    source "$VENV_DIR_NAME/bin/activate"
    
    export_type=$(gum choose \
        "📋 requirements.txt (todas as dependências)" \
        "🎯 requirements-prod.txt (apenas produção)" \
        "🔧 requirements-dev.txt (apenas desenvolvimento)")
    
    case "$export_type" in
    "📋 requirements.txt (todas as dependências)")
        pip freeze > requirements.txt
        log_success "requirements.txt criado com todas as dependências"
        ;;
    "🎯 requirements-prod.txt (apenas produção)")
        log_info "Digite as dependências de produção (uma por linha, Enter vazio para finalizar):"
        > requirements-prod.txt
        while true; do
            dep=$(gum input --placeholder "Nome da dependência (ou Enter para finalizar)")
            [[ -z "$dep" ]] && break
            echo "$dep" >> requirements-prod.txt
        done
        log_success "requirements-prod.txt criado"
        ;;
    "🔧 requirements-dev.txt (apenas desenvolvimento)")
        dev_packages=("pytest" "black" "flake8" "mypy" "pytest-cov" "pre-commit")
        selected_packages=$(printf '%s\n' "${dev_packages[@]}" | gum choose --no-limit)
        echo "$selected_packages" > requirements-dev.txt
        log_success "requirements-dev.txt criado"
        ;;
    esac
    
    if [[ -f "requirements.txt" ]]; then
        echo "📄 Conteúdo do requirements.txt:"
        cat requirements.txt
    fi
}

# Função para instalar de requirements
install_from_requirements() {
    local project_path="$1"
    
    if [[ ! -d "$project_path/$VENV_DIR_NAME" ]]; then
        log_error "Ambiente virtual não encontrado"
        return 1
    fi
    
    cd "$project_path" || return 1
    
    # Lista arquivos requirements disponíveis
    req_files=($(find . -name "requirements*.txt" -maxdepth 1))
    
    if [[ ${#req_files[@]} -eq 0 ]]; then
        log_warning "Nenhum arquivo requirements.txt encontrado"
        return 1
    fi
    
    req_file=$(printf '%s\n' "${req_files[@]}" | gum choose)
    [[ -z "$req_file" ]] && return 0
    
    source "$VENV_DIR_NAME/bin/activate"
    
    log_info "Instalando dependências de $req_file..."
    if pip install -r "$req_file"; then
        log_success "Dependências instaladas com sucesso!"
    else
        log_error "Falha ao instalar algumas dependências"
    fi
}

# Função para utilitários de desenvolvimento
dev_utilities() {
    echo "🛠️  Utilitários de Desenvolvimento"
    echo "================================="
    
    util_choice=$(gum choose \
        "🔍 Analisar qualidade do código" \
        "🎨 Formatar código com Black" \
        "🧪 Executar testes" \
        "📊 Verificar cobertura de testes" \
        "🏗️  Criar estrutura de projeto avançada" \
        "📝 Gerar documentação")
    
    case "$util_choice" in
    "🔍 Analisar qualidade do código")
        analyze_code_quality
        ;;
    "🎨 Formatar código com Black")
        format_code
        ;;
    "🧪 Executar testes")
        run_tests
        ;;
    "📊 Verificar cobertura de testes")
        check_test_coverage
        ;;
    "🏗️  Criar estrutura de projeto avançada")
        create_advanced_structure
        ;;
    "📝 Gerar documentação")
        generate_docs
        ;;
    esac
}

# Função para analisar qualidade do código
analyze_code_quality() {
    project_path=$(gum input --placeholder "Caminho do projeto" --value="$(pwd)")
    [[ -z "$project_path" || ! -d "$project_path" ]] && return 0
    
    cd "$project_path" || return 1
    
    if [[ -d "$VENV_DIR_NAME" ]]; then
        source "$VENV_DIR_NAME/bin/activate"
    fi
    
    log_info "Analisando qualidade do código..."
    
    # Instala ferramentas se necessário
    tools=("flake8" "mypy" "pylint")
    for tool in "${tools[@]}"; do
        if ! pip show "$tool" &>/dev/null; then
            if gum confirm "Instalar $tool?"; then
                pip install "$tool"
            fi
        fi
    done
    
    # Executa análises
    if command -v flake8 &>/dev/null; then
        echo "🔍 Análise com Flake8:"
        flake8 src/ || true
    fi
    
    if command -v mypy &>/dev/null; then
        echo "🔍 Análise de tipos com MyPy:"
        mypy src/ || true
    fi
    
    if command -v pylint &>/dev/null; then
        echo "🔍 Análise com Pylint:"
        pylint src/ || true
    fi
}

# Função para formatar código
format_code() {
    project_path=$(gum input --placeholder "Caminho do projeto" --value="$(pwd)")
    [[ -z "$project_path" || ! -d "$project_path" ]] && return 0
    
    cd "$project_path" || return 1
    
    if [[ -d "$VENV_DIR_NAME" ]]; then
        source "$VENV_DIR_NAME/bin/activate"
    fi
    
    if ! pip show black &>/dev/null; then
        if gum confirm "Black não está instalado. Instalar?"; then
            pip install black
        else
            return 0
        fi
    fi
    
    log_info "Formatando código com Black..."
    black src/ tests/ || true
    log_success "Código formatado!"
}

# Função para executar testes
run_tests() {
    project_path=$(gum input --placeholder "Caminho do projeto" --value="$(pwd)")
    [[ -z "$project_path" || ! -d "$project_path" ]] && return 0
    
    cd "$project_path" || return 1
    
    if [[ -d "$VENV_DIR_NAME" ]]; then
        source "$VENV_DIR_NAME/bin/activate"
    fi
    
    if ! pip show pytest &>/dev/null; then
        if gum confirm "pytest não está instalado. Instalar?"; then
            pip install pytest
        else
            return 0
        fi
    fi
    
    log_info "Executando testes..."
    pytest tests/ -v || true
}

# Função para verificar cobertura
check_test_coverage() {
    project_path=$(gum input --placeholder "Caminho do projeto" --value="$(pwd)")
    [[ -z "$project_path" || ! -d "$project_path" ]] && return 0
    
    cd "$project_path" || return 1
    
    if [[ -d "$VENV_DIR_NAME" ]]; then
        source "$VENV_DIR_NAME/bin/activate"
    fi
    
    if ! pip show pytest-cov &>/dev/null; then
        if gum confirm "pytest-cov não está instalado. Instalar?"; then
            pip install pytest-cov
        else
            return 0
        fi
    fi
    
    log_info "Verificando cobertura de testes..."
    pytest tests/ --cov=src --cov-report=html --cov-report=term-missing || true
    
    if [[ -d "htmlcov" ]]; then
        log_success "Relatório de cobertura gerado em htmlcov/index.html"
        if gum confirm "Abrir relatório no navegador?"; then
            if command -v open &>/dev/null; then  # macOS
                open htmlcov/index.html
            elif command -v xdg-open &>/dev/null; then  # Linux
                xdg-open htmlcov/index.html
            fi
        fi
    fi
}

# Função para criar estrutura avançada
create_advanced_structure() {
    project_path=$(gum input --placeholder "Caminho do projeto" --value="$(pwd)")
    [[ -z "$project_path" || ! -d "$project_path" ]] && return 0
    
    cd "$project_path" || return 1
    
    log_info "Criando estrutura avançada de projeto..."
    
    # Cria diretórios adicionais
    mkdir -p {config,data,logs,notebooks,deployment,docker}
    mkdir -p src/{models,views,controllers,utils,services}
    mkdir -p tests/{unit,integration,fixtures}
    
    # Arquivos de configuração
    create_config_files "$project_path"
    
    log_success "Estrutura avançada criada!"
}

# Função para criar arquivos de configuração
create_config_files() {
    local project_path="$1"
    
    # pyproject.toml
    cat > "$project_path/pyproject.toml" << 'EOF'
[build-system]
requires = ["setuptools>=45", "wheel", "setuptools_scm[toml]>=6.2"]
build-backend = "setuptools.build_meta"

[project]
name = "your-project-name"
dynamic = ["version"]
description = "Your project description"
readme = "README.md"
license = {file = "LICENSE"}
authors = [
    {name = "Your Name", email = "your.email@example.com"},
]
classifiers = [
    "Development Status :: 3 - Alpha",
    "Intended Audience :: Developers",
    "License :: OSI Approved :: MIT License",
    "Programming Language :: Python :: 3",
    "Programming Language :: Python :: 3.8",
    "Programming Language :: Python :: 3.9",
    "Programming Language :: Python :: 3.10",
    "Programming Language :: Python :: 3.11",
]
requires-python = ">=3.8"
dependencies = [
    # Add your dependencies here
]

[project.optional-dependencies]
dev = [
    "pytest>=7.0.0",
    "pytest-cov>=3.0.0",
    "black>=22.0.0",
    "flake8>=4.0.0",
    "mypy>=0.950",
    "pre-commit>=2.17.0",
]

[tool.setuptools_scm]

[tool.black]
line-length = 88
target-version = ['py38']
include = '\.pyi?$'

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
addopts = "-v --cov=src --cov-report=term-missing"

[tool.mypy]
python_version = "3.8"
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true
EOF

    # Makefile
    cat > "$project_path/Makefile" << 'EOF'
.PHONY: install install-dev test lint format clean

install:
	pip install -e .

install-dev:
	pip install -e .[dev]

test:
	pytest

lint:
	flake8 src tests
	mypy src

format:
	black src tests

clean:
	rm -rf build/
	rm -rf dist/
	rm -rf *.egg-info/
	find . -type d -name __pycache__ -delete
	find . -type f -name "*.pyc" -delete
EOF

    # pre-commit config
    cat > "$project_path/.pre-commit-config.yaml" << 'EOF'
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files

  - repo: https://github.com/psf/black
    rev: 22.10.0
    hooks:
      - id: black

  - repo: https://github.com/pycqa/flake8
    rev: 5.0.4
    hooks:
      - id: flake8

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v0.991
    hooks:
      - id: mypy
EOF

    # Docker files
    cat > "$project_path/Dockerfile" << 'EOF'
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/ ./src/
COPY tests/ ./tests/

CMD ["python", "-m", "src.main"]
EOF

    cat > "$project_path/docker-compose.yml" << 'EOF'
version: '3.8'

services:
  app:
    build: .
    volumes:
      - .:/app
    environment:
      - PYTHONPATH=/app/src
EOF
}

# Função para gerar documentação
generate_docs() {
    project_path=$(gum input --placeholder "Caminho do projeto" --value="$(pwd)")
    [[ -z "$project_path" || ! -d "$project_path" ]] && return 0
    
    cd "$project_path" || return 1
    
    if [[ -d "$VENV_DIR_NAME" ]]; then
        source "$VENV_DIR_NAME/bin/activate"
    fi
    
    doc_tool=$(gum choose "Sphinx" "MkDocs" "Pydoc")
    
    case "$doc_tool" in
    "Sphinx")
        if ! pip show sphinx &>/dev/null; then
            pip install sphinx
        fi
        sphinx-quickstart docs
        ;;
    "MkDocs")
        if ! pip show mkdocs &>/dev/null; then
            pip install mkdocs
        fi
        mkdocs new .
        ;;
    "Pydoc")
        log_info "Gerando documentação com pydoc..."
        pydoc -w src/
        ;;
    esac
}

# Menu principal
main_menu() {
    clear
    echo "🐍 Python Project Manager - Sistema: $MACHINE"
    echo "============================================="
    echo
    
    while true; do
        opcao=$(gum choose \
            "🔍 Verificar instalação do Python" \
            "🆕 Criar novo projeto Python" \
            "🌐 Gerenciar ambiente virtual" \
            "🛠️  Utilitários de desenvolvimento" \
            "📊 Resumo de projetos existentes" \
            "🚪 Sair")
        
        case "$opcao" in
        "🔍 Verificar instalação do Python")
            check_python_installation
            gum confirm "Pressione Enter para continuar..." || true
            ;;
        "🆕 Criar novo projeto Python")
            create_new_project
            gum confirm "Pressione Enter para continuar..." || true
            ;;
        "🌐 Gerenciar ambiente virtual")
            manage_virtual_env
            gum confirm "Pressione Enter para continuar..." || true
            ;;
        "🛠️  Utilitários de desenvolvimento")
            dev_utilities
            gum confirm "Pressione Enter para continuar..." || true
            ;;
        "📊 Resumo de projetos existentes")
            show_projects_summary
            gum confirm "Pressione Enter para continuar..." || true
            ;;
        "🚪 Sair")
            echo "👋 Obrigado por usar o Python Project Manager!"
            exit 0
            ;;
        esac
        
        clear
        echo "🐍 Python Project Manager - Sistema: $MACHINE"
        echo "============================================="
        echo
    done
}

# Função para mostrar resumo de projetos
show_projects_summary() {
    echo "📊 Resumo de Projetos Python"
    echo "============================"
    
    if [[ ! -d "$PROJECTS_BASE_DIR" ]]; then
        log_warning "Diretório base de projetos não encontrado: $PROJECTS_BASE_DIR"
        return 0
    fi
    
    echo "📁 Diretório base: $PROJECTS_BASE_DIR"
    echo
    
    project_count=0
    venv_count=0
    
    for project_dir in "$PROJECTS_BASE_DIR"/*; do
        if [[ -d "$project_dir" ]]; then
            project_name=$(basename "$project_dir")
            project_count=$((project_count + 1))
            
            echo "📂 $project_name"
            
            # Verifica ambiente virtual
            if [[ -d "$project_dir/$VENV_DIR_NAME" ]]; then
                echo "   ✅ Virtual env: Sim"
                venv_count=$((venv_count + 1))
                
                # Verifica versão do Python
                if [[ -x "$project_dir/$VENV_DIR_NAME/bin/python" ]]; then
                    python_ver=$("$project_dir/$VENV_DIR_NAME/bin/python" --version 2>&1)
                    echo "   🐍 Python: $python_ver"
                fi
            else
                echo "   ❌ Virtual env: Não"
            fi
            
            # Verifica arquivos importantes
            files_check=""
            [[ -f "$project_dir/requirements.txt" ]] && files_check+="requirements.txt "
            [[ -f "$project_dir/setup.py" ]] && files_check+="setup.py "
            [[ -f "$project_dir/pyproject.toml" ]] && files_check+="pyproject.toml "
            [[ -f "$project_dir/.gitignore" ]] && files_check+=".gitignore "
            
            if [[ -n "$files_check" ]]; then
                echo "   📄 Arquivos: $files_check"
            fi
            
            echo
        fi
    done
    
    echo "📈 Estatísticas:"
    echo "   Total de projetos: $project_count"
    echo "   Com virtual env: $venv_count"
    echo "   Sem virtual env: $((project_count - venv_count))"
}

# Executa menu principal
main_menu

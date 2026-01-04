#!/bin/bash

# DevOps Toolkit - Debug Script
# Diagnóstica problemas de configuração

echo "🔍 DevOps Toolkit - Diagnóstico"
echo "==============================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "📍 Localização: $SCRIPT_DIR"
echo ""

echo "🔧 Dependências:"
echo "================"
deps=("gum" "bash" "git" "python3" "curl" "arp-scan" "docker" "php" "rsync")
for cmd in "${deps[@]}"; do
    if command -v $cmd &>/dev/null; then
        version=$(command $cmd --version 2>/dev/null | head -1 | cut -d' ' -f3- | head -c20 || echo "✓")
        echo "   ✅ $cmd ($version)"
    else
        echo "   ❌ $cmd (não encontrado)"
    fi
done

echo ""
echo "📁 Estrutura de diretórios:"
echo "========================="
dirs=("Redes" "Storage" "Django" "devops-toolkit" "tests")
for dir in "${dirs[@]}"; do
    if [[ -d "$SCRIPT_DIR/$dir" ]]; then
        count=$(find "$SCRIPT_DIR/$dir" -name "*.sh" -type f 2>/dev/null | wc -l)
        echo "   ✅ $dir ($count scripts)"
    else
        echo "   ❌ $dir (não encontrado)"
    fi
done

echo ""
echo "📋 Arquivos principais:"
echo "======================="
files=("devops-toolkit.sh" "django-project-creator-v3.sh" "VERSION")
for file in "${files[@]}"; do
    if [[ -f "$SCRIPT_DIR/$file" ]]; then
        size=$(du -h "$SCRIPT_DIR/$file" 2>/dev/null | cut -f1)
        echo "   ✅ $file ($size)"
    else
        echo "   ❌ $file (não encontrado)"
    fi
done

echo ""
echo "🔐 Permissões:"
echo "============="
if [[ -x "$SCRIPT_DIR/devops-toolkit.sh" ]]; then
    echo "   ✅ devops-toolkit.sh é executável"
else
    echo "   ❌ devops-toolkit.sh não é executável"
    echo "      Execute: chmod +x devops-toolkit.sh"
fi

echo ""
echo "🚀 Teste de execução:"
echo "===================="
echo "Tentando executar com modo debug..."
echo ""

export PS4='+ ${LINENO}: '
bash -x "$SCRIPT_DIR/devops-toolkit.sh" 2>&1 | head -20

echo ""
echo "💡 Para instalar dependências no Ubuntu:"
echo "   ./ubuntu-setup.sh"
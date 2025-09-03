# Scripts de Automação

Coleção de scripts bash para automatizar tarefas de desenvolvimento e administração de sistema, otimizados para macOS e Linux.

## 📁 Estrutura

```
Scripts/
├── django-start.sh           # 🚀 Criador de projetos Django
├── port-checker.sh           # 🔍 Monitor de portas e processos  
├── test-django.sh           # 🧪 Teste do Django creator
├── README_Django.md         # 📚 Docs do Django creator
├── README_macOS.md         # 📚 Docs do Port checker
└── Redes/
    ├── port-checker.sh      # 🌐 Verificador de portas (versão atualizada)
    └── network-config-checker.sh # 🔧 Configurações de rede
```

## 🚀 Scripts Principais

### 1. Django Project Creator (`django-start.sh`)
Script completo para criar projetos Django profissionais com configurações avançadas.

**Recursos:**
- ✅ Interface interativa com `gum`
- 🎯 3 tipos de projeto: API (DRF), Web tradicional, Fullstack
- 🐳 Configuração Docker completa
- 🗄️ Suporte PostgreSQL e Redis
- 🌱 Integração Celery
- 📦 Git com .gitignore personalizado
- 📚 Documentação automática
- 🛡️ Configurações de segurança

**Uso:**
```bash
./django-start.sh
```

**Documentação:** [README_Django.md](README_Django.md)

### 2. Port Checker (`port-checker.sh`)
Monitor interativo de portas e processos com detecção Docker.

**Recursos:**
- ✅ Compatível macOS e Linux
- 🐳 Detecção automática de containers Docker
- 🔍 Monitoramento em tempo real
- 📊 Interface interativa
- 🛡️ Sudo inteligente (macOS friendly)

**Uso:**
```bash
./port-checker.sh
```

**Documentação:** [README_macOS.md](README_macOS.md)

## 📋 Pré-requisitos Gerais

### macOS
```bash
# Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Dependências essenciais
brew install gum lsof python

# Opcionais
brew install docker postgresql redis
```

### Linux (Ubuntu/Debian)
```bash
# Atualizar sistema
sudo apt update

# Dependências essenciais
sudo apt install lsof python3 python3-pip python3-venv

# gum (interface interativa)
echo 'deb [trusted=yes] https://repo.charm.sh/apt/ /' | sudo tee /etc/apt/sources.list.d/charm.list
sudo apt update && sudo apt install gum

# Opcionais
sudo apt install docker.io docker-compose postgresql redis-server
```

## 🛠️ Instalação Rápida

### Clone dos Scripts
```bash
# Clone do repositório
git clone <repository-url>
cd Scripts

# Tornar todos executáveis
chmod +x *.sh

# Executar qualquer script
./django-start.sh
./port-checker.sh
```

### Instalação Global (Opcional)
```bash
# Criar diretório para scripts pessoais
mkdir -p ~/bin

# Copiar scripts
cp *.sh ~/bin/

# Adicionar ao PATH (adicione ao ~/.zshrc ou ~/.bashrc)
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc

# Recarregar shell
source ~/.zshrc

# Usar de qualquer lugar
django-start.sh
port-checker.sh
```

## 🔧 Configuração Avançada

### Variáveis de Ambiente
Crie um arquivo `~/.scripts_config` para personalizar comportamentos:

```bash
# Configurações padrão para Django
export DJANGO_DEFAULT_PORT=8000
export DJANGO_DEFAULT_DB=postgresql
export DJANGO_USE_DOCKER=true

# Configurações do Port Checker
export PORT_CHECKER_SUDO_TIMEOUT=300
export PORT_CHECKER_UPDATE_INTERVAL=2
```

### Aliases Úteis
Adicione ao `~/.zshrc` ou `~/.bashrc`:

```bash
# Django shortcuts
alias dj-new='~/bin/django-start.sh'
alias dj-api='~/bin/django-start.sh --type=api'
alias dj-web='~/bin/django-start.sh --type=web'

# Port monitoring
alias ports='~/bin/port-checker.sh'
alias check-port='~/bin/port-checker.sh --check'

# Network tools
alias netcheck='~/bin/network-config-checker.sh'
```

## 📊 Compatibilidade

### Sistemas Operacionais
| Script | macOS | Linux | Windows (WSL) |
|--------|-------|-------|---------------|
| django-start.sh | ✅ | ✅ | ✅ |
| port-checker.sh | ✅ | ✅ | ⚠️ |
| network-config-checker.sh | ✅ | ✅ | ⚠️ |

### Dependências
| Ferramenta | Essencial | Instalação |
|------------|-----------|------------|
| bash | ✅ | Sistema |
| python3 | ✅ | `brew install python` / `apt install python3` |
| gum | ✅ | `brew install gum` / [gum docs](https://github.com/charmbracelet/gum) |
| lsof | ✅ | `brew install lsof` / `apt install lsof` |
| docker | ⚠️ | `brew install docker` / `apt install docker.io` |

## 🚨 Solução de Problemas

### Erro: "command not found"
```bash
# Verificar se o arquivo existe e é executável
ls -la django-start.sh
chmod +x django-start.sh

# Verificar se está no PATH
echo $PATH
```

### Erro: "gum not found"
```bash
# macOS
brew install gum

# Linux
# Seguir: https://github.com/charmbracelet/gum#installation

# Verificar instalação
gum --version
```

### Erro: "Permission denied" (macOS)
```bash
# Dar permissão ao terminal
# System Preferences > Security & Privacy > Privacy > Full Disk Access
# Adicionar seu terminal (Terminal.app ou iTerm2)
```

### Erro: Docker não encontrado
```bash
# Verificar se Docker está rodando
docker --version
docker info

# macOS - iniciar Docker Desktop
open -a Docker

# Linux - iniciar serviço
sudo systemctl start docker
```

## 🎯 Exemplos de Uso

### Criação Rápida de API Django
```bash
./django-start.sh
# Seguir prompts interativos:
# - Nome: "minha_api"
# - Tipo: "API (DRF)"
# - PostgreSQL: Sim
# - Docker: Sim
# - Git: Sim
```

### Monitoramento de Porta Específica
```bash
./port-checker.sh
# Escolher "🚦 Monitorar porta"
# Digite: 8000
# Pressione 'q' para sair
```

### Verificação Rápida de Portas
```bash
./port-checker.sh
# Escolher "🔍 Verificar se porta(s) estão livres"
# Digite: "8000 8080 3000"
```

## 🔄 Atualizações

### Para manter os scripts atualizados:
```bash
# Backup das configurações
cp -r Scripts Scripts_backup_$(date +%Y%m%d)

# Atualizar via git
git pull origin main

# Ou baixar individualmente
curl -O https://raw.githubusercontent.com/repo/django-start.sh
```

## 🤝 Contribuições

Contribuições são bem-vindas! Áreas de interesse:
- 🆕 Novos scripts de automação
- 🔧 Melhorias nos scripts existentes
- 🐧 Suporte para outras distribuições Linux
- 🪟 Compatibilidade Windows/WSL
- 📚 Melhorias na documentação

### Como Contribuir
1. Fork do repositório
2. Criar branch para feature: `git checkout -b nova-feature`
3. Commit das mudanças: `git commit -am 'Adiciona nova feature'`
4. Push para branch: `git push origin nova-feature`
5. Abrir Pull Request

## 📄 Licença

MIT License - Livre para usar, modificar e distribuir.

## 🔗 Links Úteis

- [Django Documentation](https://docs.djangoproject.com/)
- [Gum - Interactive CLI](https://github.com/charmbracelet/gum)
- [Docker Documentation](https://docs.docker.com/)
- [Bash Scripting Guide](https://tldp.org/LDP/Bash-Beginners-Guide/html/)
- [macOS Terminal Tips](https://support.apple.com/guide/terminal/welcome/mac)

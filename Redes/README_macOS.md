# Port Checker - Compatível com macOS e Linux

Um script bash interativo para monitorar portas e processos, com suporte completo para macOS e Linux.

## 🚀 Recursos

- ✅ **Multiplataforma**: Funciona no macOS e Linux
- 🐳 **Detecção Docker**: Identifica containers automaticamente
- 🎨 **Interface Amigável**: Interface interativa com `gum`
- 🔍 **Busca Inteligente**: Lista e monitora portas em tempo real
- 🛡️ **Sudo Inteligente**: Usa sudo apenas quando necessário (especialmente no macOS)

## 📋 Pré-requisitos

### macOS

```bash
# Instalar Homebrew (se não tiver)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Instalar dependências
brew install gum lsof

# Docker (opcional, para detecção de containers)
brew install docker
```

### Linux (Ubuntu/Debian)

```bash
# Instalar gum
echo 'deb [trusted=yes] https://repo.charm.sh/apt/ /' | sudo tee /etc/apt/sources.list.d/charm.list
sudo apt update && sudo apt install gum

# lsof geralmente já vem instalado
sudo apt install lsof

# Docker (opcional)
sudo apt install docker.io
```

## 🛠️ Instalação

1. **Clone ou baixe o script:**

```bash
wget https://raw.githubusercontent.com/seu-repo/port-checker.sh
# ou
curl -O https://raw.githubusercontent.com/seu-repo/port-checker.sh
```

2. **Torne executável:**

```bash
chmod +x port-checker.sh
```

3. **Execute:**

```bash
./port-checker.sh
```

## 📱 Funcionalidades

### 1. 📜 Listar Portas e Processos

- Lista todas as portas em estado LISTEN
- Mostra informações detalhadas dos processos
- Detecta containers Docker automaticamente
- Interface de seleção múltipla

### 2. 🔍 Verificar Portas Livres

- Verifica se uma ou múltiplas portas estão livres
- Suporte para verificação em lote
- Opção de monitoramento direto

### 3. 🚦 Monitorar Porta

- Monitoramento em tempo real
- Atualização automática a cada 2 segundos
- Saída fácil com tecla 'q'
- Mostra status do sistema e Docker

## 🔧 Diferenças entre Sistemas

### macOS

- Tenta executar `lsof` sem sudo primeiro
- Usa formato de `ps` específico do macOS
- Tratamento especial para `read` com timeout
- Integração com Homebrew para instalação

### Linux

- Usa sudo por padrão para `lsof`
- Formato padrão do `ps` do Linux
- Suporte nativo para `read` com timeout

## 🐳 Integração Docker

O script detecta automaticamente se o Docker está:

- Instalado
- Rodando
- Acessível

Se disponível, mostra informações dos containers para processos Docker.

## 🚨 Solução de Problemas

### macOS - Permissões

Se aparecer erro de permissão no macOS:

```bash
# Dar permissão total para o terminal em:
# System Preferences > Security & Privacy > Privacy > Full Disk Access
```

### Comando `gum` não encontrado

```bash
# macOS
brew install gum

# Linux
sudo apt install gum
```

### Docker não detectado

- Verifique se o Docker Desktop está rodando (macOS)
- Verifique se o serviço docker está ativo (Linux): `sudo systemctl status docker`

## 🎯 Exemplos de Uso

### Verificar porta específica

```bash
./port-checker.sh
# Escolher "🔍 Verificar se porta(s) estão livres"
# Digite: 8080
```

### Monitorar porta em tempo real

```bash
./port-checker.sh
# Escolher "🚦 Monitorar porta"
# Digite a porta desejada
```

### Listar todas as portas

```bash
./port-checker.sh
# Escolher "📜 Listar portas e processos"
# Selecionar as portas de interesse
```

## 🔄 Atualizações

Para manter o script atualizado:

```bash
# Backup da versão atual
cp port-checker.sh port-checker.sh.bak

# Baixar nova versão
curl -O https://raw.githubusercontent.com/seu-repo/port-checker.sh
chmod +x port-checker.sh
```

## 🤝 Contribuições

Contribuições são bem-vindas! Especialmente para:

- Suporte a outros sistemas operacionais
- Melhorias na interface
- Otimizações de performance
- Correções de bugs

## 📄 Licença

MIT License - Sinta-se livre para usar e modificar.

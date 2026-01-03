# DevOps Toolkit - Release Guide

Este documento descreve o processo completo para criar releases e deployments do DevOps Toolkit.

## 🚀 Processo de Release

### 1. Preparação do Release

```bash
# 1. Certifique-se de que todos os testes passam
./tests/test-scripts.sh

# 2. Atualize a documentação se necessário
# Edite README_PROFESSIONAL.md, CHANGELOG.md, etc.

# 3. Verifique a versão atual
./version.sh current
```

### 2. Criação do Release

```bash
# Bump de versão (escolha um):
./version.sh release patch  # Bug fixes (1.0.0 -> 1.0.1)
./version.sh release minor  # New features (1.0.0 -> 1.1.0)
./version.sh release major  # Breaking changes (1.0.0 -> 2.0.0)

# O script automaticamente:
# - Incrementa a versão
# - Atualiza CHANGELOG.md
# - Faz commit das mudanças
# - Cria uma git tag anotada
```

### 3. Finalizando o Release

```bash
# 1. Edite o CHANGELOG.md para adicionar detalhes do release
vim CHANGELOG.md

# 2. Commit das mudanças do changelog
git add CHANGELOG.md
git commit -m "Update changelog for v1.1.0"

# 3. Push das mudanças e da tag
git push origin main
git push origin v1.1.0  # Substitua pela sua versão
```

### 4. GitHub Actions Pipeline

Quando você faz push da tag, o GitHub Actions automaticamente:

1. **Executa testes** em múltiplos ambientes
2. **Constrói pacotes**:
   - `.deb` para Debian/Ubuntu
   - `.rpm` para RedHat/CentOS/Fedora
   - Fórmula Homebrew para macOS
3. **Cria release** no GitHub com:
   - Tarball do código fonte
   - Binários de todos os pacotes
   - Notas de release automáticas
   - Instruções de instalação

## 📦 Instalação dos Pacotes

### Debian/Ubuntu (.deb)

```bash
# Download do GitHub Releases
wget https://github.com/sabbajohn/useful-stuff/releases/download/v1.0.0/devops-toolkit_1.0.0_all.deb

# Instalação
sudo dpkg -i devops-toolkit_1.0.0_all.deb
sudo apt-get install -f  # Corrige dependências se necessário

# Verificação
django-creator --help
```

### RedHat/CentOS (.rpm)

```bash
# Download e instalação
wget https://github.com/sabbajohn/useful-stuff/releases/download/v1.0.0/devops-toolkit-1.0.0-1.noarch.rpm
sudo rpm -ivh devops-toolkit-1.0.0-1.noarch.rpm

# Ou com dnf/yum
sudo dnf install devops-toolkit-1.0.0-1.noarch.rpm
```

### macOS (Homebrew)

```bash
# Adicionar tap (primeira vez)
brew tap sabbajohn/devops-toolkit https://github.com/sabbajohn/useful-stuff

# Instalar
brew install devops-toolkit

# Atualizar
brew upgrade devops-toolkit
```

## 🔧 Build Local para Testes

### Pré-requisitos

```bash
# Ubuntu/Debian
sudo apt-get install dpkg-dev build-essential rpm

# macOS
brew install dpkg rpm
```

### Build de Pacotes

```bash
# Build de todos os pacotes
make all

# Build específico
make deb        # Pacote Debian
make rpm        # Pacote RPM
make homebrew   # Fórmula Homebrew

# Instalação local para desenvolvimento
make install

# Testes
make test
```

## 🐳 Docker para Testes

```bash
# Build da imagem
docker build -t devops-toolkit:test -f packaging/docker/Dockerfile .

# Teste em container
docker run --rm devops-toolkit:test make test

# Container interativo
docker run -it --rm devops-toolkit:test /bin/bash
```

## 📊 Validação do Release

Após o release, valide que tudo está funcionando:

### 1. Testes Automáticos

```bash
# Os testes do GitHub Actions devem passar
# Verifique: https://github.com/sabbajohn/useful-stuff/actions

# Teste local
./dev.sh test
```

### 2. Testes de Instalação

```bash
# Teste .deb em Ubuntu/Debian
wget [URL_DO_DEB]
sudo dpkg -i devops-toolkit_*.deb
django-creator --help

# Teste .rpm em CentOS/Fedora
wget [URL_DO_RPM]
sudo rpm -ivh devops-toolkit-*.rpm
django-creator --help

# Teste Homebrew no macOS
brew tap sabbajohn/devops-toolkit [URL_DO_REPO]
brew install devops-toolkit
django-creator --help
```

### 3. Funcionalidades Principais

```bash
# Teste Django creator
django-creator --type api-drf --name test-api
cd test-api && ls -la

# Teste PHP switcher
php-switcher --list

# Teste outras ferramentas
download-manager --help
dns-fix --help
```

## 🔄 Hotfixes e Patches

Para correções urgentes:

```bash
# 1. Crie branch de hotfix
git checkout -b hotfix/v1.0.1

# 2. Faça as correções necessárias
# Edite os arquivos...

# 3. Teste as correções
./tests/test-scripts.sh

# 4. Merge para main
git checkout main
git merge hotfix/v1.0.1

# 5. Crie patch release
./version.sh release patch

# 6. Push
git push origin main
git push origin v1.0.1
```

## 📈 Monitoramento de Releases

### Métricas Importantes

- **Downloads por plataforma**: GitHub Insights
- **Issues reportadas**: GitHub Issues
- **Feedback da comunidade**: GitHub Discussions
- **Tempo de build**: GitHub Actions logs

### Logs e Debugging

```bash
# Logs do GitHub Actions
# Acesse: https://github.com/sabbajohn/useful-stuff/actions

# Logs locais de instalação
journalctl -u devops-toolkit  # systemd logs
/var/log/dpkg.log            # Debian package logs
/var/log/yum.log             # RPM package logs
```

## 🤝 Distribuição

### Repositórios Oficiais

**Em desenvolvimento:**
- Ubuntu PPA
- Fedora COPR
- Arch AUR
- Homebrew core tap

### Canais de Distribuição

1. **GitHub Releases** (principal)
2. **Docker Hub** (futuro)
3. **Snap Store** (futuro)
4. **Chocolatey** (Windows, futuro)

## 🔐 Segurança

### Verificação de Integridade

```bash
# Checksums são automaticamente gerados
# Verifique no GitHub Releases:

# SHA256 do .deb
sha256sum devops-toolkit_1.0.0_all.deb

# SHA256 do .rpm  
sha256sum devops-toolkit-1.0.0-1.noarch.rpm
```

### Assinatura de Pacotes

```bash
# TODO: Implementar GPG signing
# Para versões futuras:

# 1. Gerar chave GPG
gpg --gen-key

# 2. Assinar pacotes
dpkg-sig --sign builder devops-toolkit_*.deb
rpm --addsign devops-toolkit-*.rpm

# 3. Distribuir chave pública
gpg --armor --export [KEY-ID] > public.key
```

## 📋 Checklist de Release

### Pré-Release
- [ ] Todos os testes passando
- [ ] Documentação atualizada
- [ ] CHANGELOG.md atualizado
- [ ] Versão incrementada corretamente

### Release
- [ ] Tag criada e enviada
- [ ] GitHub Actions executou com sucesso
- [ ] Artifacts gerados corretamente
- [ ] Release notes completas

### Pós-Release
- [ ] Instalação testada em cada plataforma
- [ ] Comandos principais funcionando
- [ ] Documentação publicada
- [ ] Comunidade notificada

---

**Para dúvidas sobre o processo de release, abra uma issue no GitHub ou consulte a documentação.**
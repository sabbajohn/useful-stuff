# DevOps Toolkit 🔧

[![Build Status](https://github.com/sabbajohn/useful-stuff/actions/workflows/release.yml/badge.svg)](https://github.com/sabbajohn/useful-stuff/actions)
[![Latest Release](https://img.shields.io/github/v/release/sabbajohn/useful-stuff)](https://github.com/sabbajohn/useful-stuff/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A comprehensive collection of professional development and deployment scripts for modern software engineering workflows.

## 📦 Professional Installation Methods

### Debian/Ubuntu (.deb Package)

```bash
# Download and install the latest .deb package
wget https://github.com/sabbajohn/useful-stuff/releases/latest/download/devops-toolkit_1.0.0_all.deb
sudo dpkg -i devops-toolkit_1.0.0_all.deb

# Install dependencies if needed
sudo apt-get install -f
```

### RedHat/CentOS/Fedora (.rpm Package)

```bash
# Download and install the latest .rpm package
wget https://github.com/sabbajohn/useful-stuff/releases/latest/download/devops-toolkit-1.0.0-1.noarch.rpm
sudo rpm -i devops-toolkit-1.0.0-1.noarch.rpm

# Or using dnf/yum
sudo dnf install devops-toolkit-1.0.0-1.noarch.rpm
```

### macOS (Homebrew)

```bash
# Add our custom tap (first time only)
brew tap sabbajohn/devops-toolkit https://github.com/sabbajohn/useful-stuff

# Install the toolkit
brew install devops-toolkit

# Update to latest version
brew upgrade devops-toolkit
```

### Manual Installation (All Platforms)

```bash
# Clone the repository
git clone https://github.com/sabbajohn/useful-stuff.git
cd useful-stuff

# Install using make
make install

# Or use the installer script
sudo bash devops-toolkit/install.sh
```

### Docker (Development/Testing)

```bash
# Build the Docker image
docker build -t devops-toolkit:latest -f packaging/docker/Dockerfile .

# Run in interactive mode
docker run -it --rm -v $(pwd):/workspace devops-toolkit:latest

# Run with specific command
docker run --rm devops-toolkit:latest django-creator --help
```

## 🛠 Available Tools

After installation, these commands will be available system-wide:

| Command | Description | Use Case |
|---------|-------------|----------|
| `django-creator` | Create Django projects with templates | Django development |
| `php-switcher` | Switch between PHP versions | PHP development |
| `download-manager` | Advanced download utility | File management |
| `laravel-start` | Laravel project starter | Laravel development |
| `storage-manager` | Storage management (macOS) | System maintenance |
| `dns-fix` | Quick DNS troubleshooting | Network debugging |

### Django Project Creator

Create professional Django projects with pre-configured templates:

```bash
# Interactive mode - guided setup
django-creator

# Quick API creation
django-creator --type api-drf --name my-api

# Full-stack web application
django-creator --type web-fullstack --name my-webapp

# Decoupled frontend + backend
django-creator --type decoupled --name my-spa

# Show all options
django-creator --help
```

**Available Templates:**
- **API DRF**: Pure Django REST Framework API with PostgreSQL + Redis
- **Web Fullstack**: Traditional Django web app with templates + API + PostgreSQL + Redis  
- **Decoupled**: Django backend + Vue.js/Quasar frontend + PostgreSQL + Redis

### PHP Version Switcher

Manage multiple PHP versions on your system:

```bash
# List available PHP versions
php-switcher --list

# Switch to specific version
php-switcher --set 8.1

# Show current version
php-switcher --current

# Install new PHP version
php-switcher --install 8.2
```

### Other Tools

```bash
# Download manager with resume support
download-manager https://example.com/large-file.zip

# Laravel project with authentication
laravel-start my-project --auth

# Check disk usage and clean cache (macOS)
storage-manager --clean

# Fix common DNS issues
dns-fix --auto
```

## 🔧 Development & Building

### Prerequisites

- **For .deb packages**: `dpkg-dev`, `build-essential`
- **For .rpm packages**: `rpmbuild`, `rpm-tools`
- **General**: `bash 4.0+`, `curl`, `git`, `make`

### Building Packages

```bash
# Install build dependencies (Ubuntu/Debian)
sudo apt-get install dpkg-dev build-essential rpm

# Build all package types
make all

# Build specific package type
make deb          # Debian package
make rpm          # RPM package  
make homebrew     # Homebrew formula

# Install locally for development
make install

# Run test suite
make test

# Clean build artifacts
make clean

# Show all available targets
make help
```

### Version Management

The project uses semantic versioning with automated release management:

```bash
# Show current version
./version.sh current

# Bump version
./version.sh bump patch    # 1.0.0 -> 1.0.1
./version.sh bump minor    # 1.0.0 -> 1.1.0  
./version.sh bump major    # 1.0.0 -> 2.0.0

# Set specific version
./version.sh set 2.1.0

# Create full release (bump + changelog + git tag)
./version.sh release minor
```

### Testing

```bash
# Run the full test suite
make test

# Run tests manually
./tests/test-scripts.sh

# Verbose test output
./tests/test-scripts.sh --verbose

# Test in Docker container
docker build -t devops-toolkit-test -f packaging/docker/Dockerfile .
docker run --rm devops-toolkit-test make test
```

### CI/CD Pipeline

The project includes automated GitHub Actions workflows:

- **✅ Continuous Testing**: Syntax validation and functionality tests on every PR
- **📦 Package Building**: Automatic .deb and .rpm package generation on tags
- **🚀 Release Creation**: Automated releases with artifacts and Homebrew formula
- **🔍 Security Scanning**: Dependency and vulnerability checking

To create a new release:

```bash
# Create and push a new version tag
./version.sh release minor
git push origin main
git push origin v1.1.0  # Replace with your version
```

The pipeline will automatically:
1. Run tests across multiple environments
2. Build packages for all supported distributions
3. Create GitHub release with artifacts
4. Update Homebrew formula
5. Generate release notes

## 📁 Project Structure

```
useful-stuff/
├── devops-toolkit/              # Main toolkit directory
│   ├── bin/scripts/            # Executable scripts
│   ├── install.sh              # Simple installer
│   └── README.md              # Toolkit documentation
├── Django/                     # Django templates and resources
│   ├── django-templates-v3/    # Version 3 templates
│   └── install.sh              # Django-specific installer
├── packaging/                  # Professional packaging
│   ├── debian/                # Debian package configuration
│   ├── rpm/                   # RPM package configuration
│   ├── homebrew/              # Homebrew formula template
│   └── docker/                # Docker configuration
├── tests/                     # Test suite
├── .github/workflows/         # CI/CD pipelines
├── Makefile                   # Build automation
├── version.sh                 # Version management
├── VERSION                    # Current version
└── CHANGELOG.md              # Release notes
```

## 🤝 Contributing

We welcome contributions! Here's how to get started:

### Development Setup

```bash
# Fork and clone the repository
git clone https://github.com/YOUR-USERNAME/useful-stuff.git
cd useful-stuff

# Install for development
make install

# Run tests
make test

# Make your changes...

# Test your changes
make test
./tests/test-scripts.sh
```

### Contribution Guidelines

1. **Follow the coding style** - Use consistent bash scripting practices
2. **Add tests** - Include tests for new functionality
3. **Update documentation** - Keep README and inline docs current
4. **Use semantic versioning** - Follow semver for version changes
5. **Test cross-platform** - Ensure compatibility where possible

### Pull Request Process

1. Create a feature branch from `main`
2. Make your changes and add tests
3. Run the test suite: `make test`
4. Update documentation if needed
5. Submit a pull request with a clear description

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support & Issues

- **📖 Documentation**: Check this README and script help (`--help`)
- **🐛 Bug Reports**: [GitHub Issues](https://github.com/sabbajohn/useful-stuff/issues)
- **💡 Feature Requests**: [GitHub Discussions](https://github.com/sabbajohn/useful-stuff/discussions)
- **❓ Questions**: Use GitHub Discussions for general questions

### Troubleshooting

**Installation Issues:**
```bash
# Debian/Ubuntu dependency issues
sudo apt-get update && sudo apt-get install -f

# Permission issues
sudo chmod +x /opt/devops-toolkit/bin/scripts/*.sh

# Missing symlinks
sudo dpkg-reconfigure devops-toolkit
```

**Script Issues:**
```bash
# Check script syntax
bash -n /opt/devops-toolkit/bin/scripts/script-name.sh

# Verbose execution
bash -x django-creator --type api-drf --name test
```

## 🔮 Roadmap

- [ ] **Windows Support**: PowerShell versions and .msi installer
- [ ] **VS Code Extension**: IDE integration for project templates
- [ ] **Plugin System**: Modular architecture for custom tools
- [ ] **GUI Interface**: Desktop application for non-CLI users
- [ ] **Cloud Integration**: Direct deployment to AWS, Azure, GCP
- [ ] **Template Marketplace**: Community-contributed project templates

---

**Made with ❤️ by developers, for developers**

*Professional tooling for modern development workflows*
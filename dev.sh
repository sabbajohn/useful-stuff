#!/bin/bash

# Development helper script for DevOps Toolkit
# Automates common development tasks

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging functions
log() { echo -e "${BLUE}[DEV] $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}" >&2; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

# Check if running in development environment
check_dev_environment() {
    if [[ ! -f "$SCRIPT_DIR/Makefile" ]] || [[ ! -f "$SCRIPT_DIR/version.sh" ]]; then
        error "This script must be run from the DevOps Toolkit root directory"
        exit 1
    fi
}

# Setup development environment
setup_dev() {
    log "Setting up development environment..."
    
    # Make scripts executable
    chmod +x "$SCRIPT_DIR"/*.sh
    chmod +x "$SCRIPT_DIR"/devops-toolkit/bin/scripts/*.sh
    chmod +x "$SCRIPT_DIR"/tests/*.sh
    
    # Install development dependencies
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y dpkg-dev build-essential rpm curl git
    elif command -v brew >/dev/null 2>&1; then
        brew install dpkg rpm curl git
    fi
    
    # Install local development version
    make install
    
    success "Development environment ready!"
    echo ""
    echo "Available dev commands:"
    echo "  $0 test           - Run tests"
    echo "  $0 build          - Build all packages" 
    echo "  $0 install        - Install locally"
    echo "  $0 version        - Version management"
    echo "  $0 docker         - Docker operations"
    echo "  $0 clean          - Clean build artifacts"
}

# Run tests with detailed output
run_tests() {
    log "Running development tests..."
    
    # Run syntax checks
    echo "🔍 Checking script syntax..."
    for script in "$SCRIPT_DIR"/*.sh "$SCRIPT_DIR"/devops-toolkit/bin/scripts/*.sh; do
        if [[ -f "$script" ]]; then
            if bash -n "$script"; then
                echo "  ✅ $(basename "$script")"
            else
                echo "  ❌ $(basename "$script")"
                return 1
            fi
        fi
    done
    
    # Run full test suite
    echo ""
    echo "🧪 Running test suite..."
    "$SCRIPT_DIR"/tests/test-scripts.sh
    
    # Test installation
    echo ""
    echo "📦 Testing installation..."
    make install
    
    # Test main commands
    echo ""
    echo "🔧 Testing main commands..."
    
    if django-creator --help >/dev/null 2>&1; then
        echo "  ✅ django-creator"
    else
        echo "  ❌ django-creator"
    fi
    
    if "$SCRIPT_DIR"/version.sh current >/dev/null 2>&1; then
        echo "  ✅ version management"
    else
        echo "  ❌ version management"
    fi
    
    success "All tests completed!"
}

# Build packages for testing
build_packages() {
    log "Building packages for testing..."
    
    # Clean previous builds
    make clean
    
    # Build .deb package
    echo "🏗️  Building Debian package..."
    if make deb; then
        success "Debian package built successfully"
    else
        error "Debian package build failed"
        return 1
    fi
    
    # Build Homebrew formula
    echo "🍺 Generating Homebrew formula..."
    if make homebrew; then
        success "Homebrew formula generated"
    else
        error "Homebrew formula generation failed"
        return 1
    fi
    
    # Show build results
    echo ""
    echo "📁 Build artifacts:"
    find build -name "*.deb" -o -name "*.rpm" -o -name "*.rb" 2>/dev/null | while read -r file; do
        echo "  📦 $file"
    done
    
    success "All packages built successfully!"
}

# Docker operations
docker_ops() {
    local operation="${1:-help}"
    
    case "$operation" in
        "build")
            log "Building Docker image..."
            docker build -t devops-toolkit:dev -f packaging/docker/Dockerfile .
            success "Docker image built: devops-toolkit:dev"
            ;;
        "run")
            log "Running Docker container..."
            docker run -it --rm -v "$PWD":/workspace devops-toolkit:dev
            ;;
        "test")
            log "Testing in Docker container..."
            docker build -t devops-toolkit:test -f packaging/docker/Dockerfile .
            docker run --rm devops-toolkit:test make test
            ;;
        "clean")
            log "Cleaning Docker artifacts..."
            docker rmi devops-toolkit:dev devops-toolkit:test 2>/dev/null || true
            success "Docker artifacts cleaned"
            ;;
        *)
            echo "Docker operations:"
            echo "  $0 docker build   - Build development image"
            echo "  $0 docker run     - Run interactive container"
            echo "  $0 docker test    - Test in container"
            echo "  $0 docker clean   - Clean Docker artifacts"
            ;;
    esac
}

# Version operations
version_ops() {
    local operation="${1:-current}"
    
    case "$operation" in
        "current"|"bump"|"set"|"release")
            "$SCRIPT_DIR/version.sh" "$@"
            ;;
        *)
            echo "Version operations:"
            echo "  $0 version current        - Show current version"
            echo "  $0 version bump patch     - Bump patch version"
            echo "  $0 version bump minor     - Bump minor version"
            echo "  $0 version bump major     - Bump major version"
            echo "  $0 version set X.Y.Z      - Set specific version"
            echo "  $0 version release TYPE   - Create release"
            ;;
    esac
}

# Show project status
show_status() {
    echo "📊 DevOps Toolkit - Development Status"
    echo "======================================"
    echo ""
    
    # Version info
    echo "📋 Version Information:"
    echo "  Current: $("$SCRIPT_DIR/version.sh" current)"
    echo "  Git branch: $(git branch --show-current 2>/dev/null || echo 'unknown')"
    echo "  Git status: $(git status --porcelain | wc -l | tr -d ' ') files changed"
    echo ""
    
    # Script counts
    echo "📁 Script Inventory:"
    echo "  Main scripts: $(find . -maxdepth 1 -name "*.sh" | wc -l | tr -d ' ')"
    echo "  Toolkit scripts: $(find devops-toolkit/bin/scripts -name "*.sh" | wc -l | tr -d ' ')"
    echo "  Test scripts: $(find tests -name "*.sh" | wc -l | tr -d ' ')"
    echo ""
    
    # Package status
    echo "📦 Package Status:"
    if [[ -d "build" ]]; then
        echo "  Build artifacts: $(find build -type f | wc -l | tr -d ' ')"
    else
        echo "  Build artifacts: 0 (run 'make build')"
    fi
    echo ""
    
    # Installation status
    echo "🔧 Installation Status:"
    if command -v django-creator >/dev/null 2>&1; then
        echo "  ✅ Installed locally"
    else
        echo "  ❌ Not installed locally (run 'make install')"
    fi
    echo ""
}

# Clean everything
clean_all() {
    log "Cleaning all development artifacts..."
    
    # Clean build artifacts
    make clean
    
    # Clean Docker
    docker_ops clean
    
    # Clean temporary files
    find . -name "*.bak" -delete 2>/dev/null || true
    find . -name ".DS_Store" -delete 2>/dev/null || true
    
    success "All artifacts cleaned!"
}

# Show help
show_help() {
    cat <<EOF
DevOps Toolkit - Development Helper

Usage: $0 <command> [options]

Commands:
    setup             Setup development environment
    test              Run comprehensive test suite
    build             Build all packages
    install           Install locally for development
    status            Show project status
    version <op>      Version management operations
    docker <op>       Docker operations
    clean             Clean all artifacts
    help              Show this help

Examples:
    $0 setup                    # First time setup
    $0 test                     # Run all tests
    $0 build                    # Build packages
    $0 version bump minor       # Bump minor version
    $0 docker build             # Build Docker image
    $0 docker test              # Test in Docker

For more details, see: ./README_PROFESSIONAL.md

EOF
}

# Main script logic
main() {
    check_dev_environment
    
    case "${1:-help}" in
        "setup")
            setup_dev
            ;;
        "test")
            run_tests
            ;;
        "build")
            build_packages
            ;;
        "install")
            make install
            ;;
        "status")
            show_status
            ;;
        "version")
            shift
            version_ops "$@"
            ;;
        "docker")
            shift
            docker_ops "$@"
            ;;
        "clean")
            clean_all
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            error "Unknown command: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run with all arguments
main "$@"
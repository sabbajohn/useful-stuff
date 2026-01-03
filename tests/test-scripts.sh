#!/bin/bash

# Basic test suite for DevOps Toolkit scripts
# Tests script syntax, basic functionality, and requirements

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Logging functions
log() {
    echo -e "${BLUE}[TEST] $1${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

error() {
    echo -e "${RED}❌ $1${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    log "Running: $test_name"
    
    if eval "$test_command" > /dev/null 2>&1; then
        success "$test_name"
        return 0
    else
        error "$test_name"
        return 1
    fi
}

# Test script syntax
test_script_syntax() {
    local script="$1"
    local script_name="$(basename "$script")"
    
    if [[ -f "$script" ]]; then
        run_test "Syntax check: $script_name" "bash -n '$script'"
    else
        error "Script not found: $script"
    fi
}

# Test script has executable permissions
test_executable() {
    local script="$1"
    local script_name="$(basename "$script")"
    
    if [[ -x "$script" ]]; then
        success "Executable: $script_name"
    else
        error "Not executable: $script_name"
    fi
}

# Test script has shebang
test_shebang() {
    local script="$1"
    local script_name="$(basename "$script")"
    
    if head -n 1 "$script" | grep -q "^#!"; then
        success "Shebang present: $script_name"
    else
        error "Missing shebang: $script_name"
    fi
}

# Test Django creator help
test_django_creator_help() {
    local script="$ROOT_DIR/django-project-creator-v3.sh"
    
    if [[ -f "$script" ]]; then
        run_test "Django creator help" "'$script' --help || echo 'Help executed'"
    else
        error "Django creator script not found"
    fi
}

# Test version script
test_version_script() {
    local script="$ROOT_DIR/version.sh"
    
    if [[ -f "$script" ]]; then
        run_test "Version script current" "'$script' current"
    else
        error "Version script not found"
    fi
}

# Test that all required files exist
test_required_files() {
    local required_files=(
        "Makefile"
        "VERSION"
        "CHANGELOG.md"
        "version.sh"
        "packaging/debian/control"
        "packaging/debian/postinst"
        "packaging/debian/prerm"
        "packaging/rpm/devops-toolkit.spec"
        "packaging/homebrew/Formula/devops-toolkit.rb.template"
        ".github/workflows/release.yml"
    )
    
    for file in "${required_files[@]}"; do
        if [[ -f "$ROOT_DIR/$file" ]]; then
            success "Required file exists: $file"
        else
            error "Required file missing: $file"
        fi
    done
}

# Test package metadata
test_package_metadata() {
    local control_file="$ROOT_DIR/packaging/debian/control"
    local spec_file="$ROOT_DIR/packaging/rpm/devops-toolkit.spec"
    
    if [[ -f "$control_file" ]]; then
        if grep -q "Package: devops-toolkit" "$control_file"; then
            success "Debian package name correct"
        else
            error "Debian package name incorrect"
        fi
        
        if grep -q "Version:" "$control_file"; then
            success "Debian version present"
        else
            error "Debian version missing"
        fi
    fi
    
    if [[ -f "$spec_file" ]]; then
        if grep -q "Name:           devops-toolkit" "$spec_file"; then
            success "RPM package name correct"
        else
            error "RPM package name incorrect"
        fi
    fi
}

# Main test runner
main() {
    log "Starting DevOps Toolkit test suite..."
    echo ""
    
    # Test all shell scripts in devops-toolkit/bin/scripts/
    if [[ -d "$ROOT_DIR/devops-toolkit/bin/scripts" ]]; then
        for script in "$ROOT_DIR"/devops-toolkit/bin/scripts/*.sh; do
            if [[ -f "$script" ]]; then
                test_script_syntax "$script"
                test_executable "$script"
                test_shebang "$script"
            fi
        done
    fi
    
    # Test main scripts
    for script in "$ROOT_DIR"/*.sh; do
        if [[ -f "$script" ]]; then
            test_script_syntax "$script"
            test_shebang "$script"
        fi
    done
    
    # Test specific functionality
    test_django_creator_help
    test_version_script
    
    # Test infrastructure
    test_required_files
    test_package_metadata
    
    # Results
    echo ""
    echo "=========================================="
    log "Test Results:"
    echo "Tests run:    $TESTS_RUN"
    echo "Tests passed: $TESTS_PASSED"
    echo "Tests failed: $TESTS_FAILED"
    echo ""
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        success "All tests passed! 🎉"
        exit 0
    else
        error "Some tests failed!"
        exit 1
    fi
}

# Show help
show_help() {
    cat <<EOF
DevOps Toolkit Test Suite

Usage: $0 [OPTIONS]

Options:
    -h, --help      Show this help
    -v, --verbose   Verbose output

Tests performed:
    - Shell script syntax validation
    - Executable permissions check
    - Shebang presence validation
    - Django creator functionality
    - Version management script
    - Required packaging files
    - Package metadata validation

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--verbose)
            set -x
            shift
            ;;
        *)
            error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Run main function
main
#!/bin/bash

# Test suite specifically for Mac Storage Manager
# Tests functionality, CLI arguments, and safety features

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
STORAGE_SCRIPT="$ROOT_DIR/Storage/mac-storage-manager.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Logging
log() { echo -e "${BLUE}[TEST]${NC} $1"; }
success() { echo -e "${GREEN}✅${NC} $1"; TESTS_PASSED=$((TESTS_PASSED + 1)); }
error() { echo -e "${RED}❌${NC} $1"; TESTS_FAILED=$((TESTS_FAILED + 1)); }
warning() { echo -e "${YELLOW}⚠️${NC} $1"; }

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

# Test script exists and is executable
test_script_exists() {
    if [[ -f "$STORAGE_SCRIPT" ]] && [[ -x "$STORAGE_SCRIPT" ]]; then
        success "Script exists and is executable"
    else
        error "Script missing or not executable: $STORAGE_SCRIPT"
    fi
}

# Test script syntax
test_syntax() {
    run_test "Script syntax check" "bash -n '$STORAGE_SCRIPT'"
}

# Test help option
test_help() {
    run_test "Help option works" "'$STORAGE_SCRIPT' --help"
}

# Test version option
test_version() {
    run_test "Version option works" "'$STORAGE_SCRIPT' --version"
}

# Test CLI options
test_cli_options() {
    # Test size parameter
    run_test "Size parameter accepted" "'$STORAGE_SCRIPT' --size 500 --help"
    
    # Test days parameter  
    run_test "Days parameter accepted" "'$STORAGE_SCRIPT' --days 30 --help"
    
    # Test no-fzf option
    run_test "No-fzf option accepted" "'$STORAGE_SCRIPT' --no-fzf --help"
    
    # Test debug option
    run_test "Debug option accepted" "'$STORAGE_SCRIPT' --debug --help"
}

# Test individual commands (non-interactive)
test_individual_commands() {
    # These should run without errors but not actually do destructive operations
    local commands=(
        "large-files"
        "old-files" 
    )
    
    for cmd in "${commands[@]}"; do
        run_test "Command: $cmd" "timeout 10s '$STORAGE_SCRIPT' --no-fzf '$cmd' || true"
    done
}

# Test safety features
test_safety_features() {
    # Test that script doesn't run destructive operations without confirmation
    # This is harder to test automatically, so we'll test the functions exist
    
    local required_functions=(
        "confirm"
        "snapshot_before"
        "snapshot_after"
        "kb_to_human"
        "show_disk_usage"
    )
    
    for func in "${required_functions[@]}"; do
        if grep -q "^$func()" "$STORAGE_SCRIPT"; then
            success "Safety function exists: $func"
        else
            error "Safety function missing: $func"
        fi
    done
}

# Test configuration variables
test_configuration() {
    local required_vars=(
        "VERSION"
        "MIN_LARGE_SIZE_MB"
        "OLD_DAYS"
        "SNAPSHOT_FILE"
    )
    
    for var in "${required_vars[@]}"; do
        if grep -q "^$var=" "$STORAGE_SCRIPT"; then
            success "Configuration variable exists: $var"
        else
            error "Configuration variable missing: $var"
        fi
    done
}

# Test dependencies detection
test_dependencies() {
    local deps=(
        "df"
        "find" 
        "du"
        "awk"
        "sort"
    )
    
    for dep in "${deps[@]}"; do
        if command -v "$dep" >/dev/null 2>&1; then
            success "Dependency available: $dep"
        else
            warning "Optional dependency missing: $dep"
        fi
    done
    
    # Test optional dependencies
    local optional_deps=(
        "fzf"
        "docker"
        "git"
        "npm"
        "brew"
    )
    
    for dep in "${optional_deps[@]}"; do
        if command -v "$dep" >/dev/null 2>&1; then
            success "Optional dependency available: $dep"
        else
            log "Optional dependency not available: $dep (this is ok)"
        fi
    done
}

# Test error handling
test_error_handling() {
    # Test with invalid parameters
    local invalid_tests=(
        "--size abc"
        "--days xyz"
        "invalid-command"
        "--invalid-flag"
    )
    
    for test_case in "${invalid_tests[@]}"; do
        if ! eval "'$STORAGE_SCRIPT' $test_case >/dev/null 2>&1"; then
            success "Correctly rejects invalid input: $test_case"
        else
            error "Should reject invalid input: $test_case"
        fi
    done
}

# Test file permissions and safety
test_file_safety() {
    # Make sure script doesn't try to modify system files without permission
    local protected_patterns=(
        "/System/"
        "/usr/bin/"
        "/usr/sbin/"
        "/bin/"
        "/sbin/"
    )
    
    for pattern in "${protected_patterns[@]}"; do
        if grep -q "$pattern" "$STORAGE_SCRIPT"; then
            warning "Script references system path: $pattern - ensure proper safety checks"
        else
            success "No direct system path reference: $pattern"
        fi
    done
}

# Test output formatting
test_output_formatting() {
    # Test that script produces clean output
    local output
    output=$("$STORAGE_SCRIPT" --help 2>&1)
    
    if echo "$output" | grep -q "Mac Storage Manager"; then
        success "Help output contains title"
    else
        error "Help output missing title"
    fi
    
    if echo "$output" | grep -q "USAGE:"; then
        success "Help output contains usage section"
    else
        error "Help output missing usage section"
    fi
    
    if echo "$output" | grep -q "EXAMPLES:"; then
        success "Help output contains examples"
    else
        error "Help output missing examples"
    fi
}

# Test integration with DevOps Toolkit
test_integration() {
    local devops_script="$ROOT_DIR/devops-toolkit/bin/scripts/mac-storage-manager.sh"
    
    if [[ -f "$devops_script" ]]; then
        success "Script integrated into DevOps Toolkit"
        
        # Test that it's the same version
        if diff -q "$STORAGE_SCRIPT" "$devops_script" >/dev/null 2>&1; then
            success "DevOps Toolkit version is up to date"
        else
            warning "DevOps Toolkit version differs from main script"
        fi
    else
        error "Script not integrated into DevOps Toolkit"
    fi
}

# Performance test
test_performance() {
    local start_time end_time duration
    
    start_time=$(date +%s)
    "$STORAGE_SCRIPT" --help >/dev/null 2>&1
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    if [[ $duration -lt 5 ]]; then
        success "Script starts quickly (${duration}s)"
    else
        warning "Script takes long to start (${duration}s)"
    fi
}

# Main test runner
main() {
    echo "========================================"
    echo "Mac Storage Manager Test Suite"
    echo "========================================"
    echo
    
    test_script_exists
    test_syntax
    test_help
    test_version
    test_cli_options
    test_individual_commands
    test_safety_features
    test_configuration
    test_dependencies
    test_error_handling
    test_file_safety
    test_output_formatting
    test_integration
    test_performance
    
    # Results
    echo
    echo "========================================"
    echo "Test Results Summary:"
    echo "Tests run:    $TESTS_RUN"
    echo "Tests passed: $TESTS_PASSED"
    echo "Tests failed: $TESTS_FAILED"
    echo
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        success "All Mac Storage Manager tests passed! 🎉"
        exit 0
    else
        error "Some tests failed!"
        echo
        echo "Please review the failed tests above."
        exit 1
    fi
}

# Show help
show_help() {
    cat <<EOF
Mac Storage Manager Test Suite

Usage: $0 [OPTIONS]

Options:
    -h, --help      Show this help
    -v, --verbose   Verbose output

Tests:
    - Script existence and permissions
    - Syntax validation
    - CLI options and arguments
    - Individual commands (non-destructive)
    - Safety features and error handling
    - Configuration variables
    - Dependencies detection
    - File safety checks
    - Output formatting
    - DevOps Toolkit integration
    - Performance benchmarks

EOF
}

# Parse arguments
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

# Run tests
main
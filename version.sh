#!/bin/bash

# Version management script for DevOps Toolkit
# Handles semantic versioning and automated releases

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION_FILE="$SCRIPT_DIR/VERSION"
CHANGELOG_FILE="$SCRIPT_DIR/CHANGELOG.md"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to log messages
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}❌ Error: $1${NC}" >&2
    exit 1
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Get current version
get_current_version() {
    if [[ -f "$VERSION_FILE" ]]; then
        cat "$VERSION_FILE"
    else
        echo "0.0.0"
    fi
}

# Parse semantic version
parse_version() {
    local version="$1"
    echo "$version" | sed -E 's/^v?([0-9]+)\.([0-9]+)\.([0-9]+).*$/\1 \2 \3/'
}

# Increment version
increment_version() {
    local current_version="$1"
    local increment_type="$2"
    
    read -r major minor patch <<< "$(parse_version "$current_version")"
    
    case "$increment_type" in
        "major")
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        "minor")
            minor=$((minor + 1))
            patch=0
            ;;
        "patch")
            patch=$((patch + 1))
            ;;
        *)
            error "Invalid increment type: $increment_type. Use major, minor, or patch."
            ;;
    esac
    
    echo "${major}.${minor}.${patch}"
}

# Update version in files
update_version_files() {
    local new_version="$1"
    
    log "Updating version to $new_version..."
    
    # Update VERSION file
    echo "$new_version" > "$VERSION_FILE"
    
    # Update Makefile
    sed -i.bak "s/VERSION := .*/VERSION := $new_version/" Makefile
    rm -f Makefile.bak
    
    # Update debian control
    sed -i.bak "s/Version: .*/Version: $new_version/" packaging/debian/control
    rm -f packaging/debian/control.bak
    
    # Update RPM spec
    sed -i.bak "s/Version:        .*/Version:        $new_version/" packaging/rpm/devops-toolkit.spec
    rm -f packaging/rpm/devops-toolkit.spec.bak
    
    success "Version updated in all files"
}

# Update changelog
update_changelog() {
    local version="$1"
    local date="$(date '+%Y-%m-%d')"
    local temp_file=$(mktemp)
    
    log "Updating CHANGELOG.md..."
    
    if [[ ! -f "$CHANGELOG_FILE" ]]; then
        cat > "$CHANGELOG_FILE" <<EOF
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [${version}] - ${date}

### Added
- Initial release

EOF
    else
        # Add new version section to existing changelog
        {
            head -n 6 "$CHANGELOG_FILE"
            echo ""
            echo "## [${version}] - ${date}"
            echo ""
            echo "### Added"
            echo "- "
            echo ""
            echo "### Changed"
            echo "- "
            echo ""
            echo "### Fixed"
            echo "- "
            echo ""
            tail -n +7 "$CHANGELOG_FILE"
        } > "$temp_file"
        
        mv "$temp_file" "$CHANGELOG_FILE"
    fi
    
    success "Changelog updated"
    warning "Please edit $CHANGELOG_FILE to add release notes"
}

# Create git tag
create_git_tag() {
    local version="$1"
    local tag_name="v${version}"
    
    log "Creating git tag $tag_name..."
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        warning "Not in a git repository. Skipping git operations."
        return
    fi
    
    # Check if tag already exists
    if git tag -l "$tag_name" | grep -q "$tag_name"; then
        error "Tag $tag_name already exists"
    fi
    
    # Add and commit version changes
    git add VERSION Makefile packaging/debian/control packaging/rpm/devops-toolkit.spec CHANGELOG.md
    git commit -m "Bump version to $version"
    
    # Create annotated tag
    git tag -a "$tag_name" -m "Release version $version"
    
    success "Git tag $tag_name created"
    log "To push the tag, run: git push origin $tag_name"
}

# Show help
show_help() {
    cat <<EOF
DevOps Toolkit Version Manager

Usage: $0 [COMMAND] [OPTIONS]

Commands:
    current                 Show current version
    bump <type>            Bump version (major|minor|patch)
    set <version>          Set specific version
    release <type>         Bump version and create release
    help                   Show this help

Examples:
    $0 current                    # Show current version
    $0 bump patch                 # Increment patch version
    $0 bump minor                 # Increment minor version
    $0 bump major                 # Increment major version
    $0 set 2.1.0                  # Set specific version
    $0 release minor              # Bump minor and create release

EOF
}

# Main script logic
main() {
    case "${1:-help}" in
        "current")
            echo "Current version: $(get_current_version)"
            ;;
        "bump")
            if [[ -z "${2:-}" ]]; then
                error "Bump type required (major|minor|patch)"
            fi
            
            current_version="$(get_current_version)"
            new_version="$(increment_version "$current_version" "$2")"
            
            log "Bumping version from $current_version to $new_version"
            update_version_files "$new_version"
            success "Version bumped to $new_version"
            ;;
        "set")
            if [[ -z "${2:-}" ]]; then
                error "Version required"
            fi
            
            new_version="$2"
            log "Setting version to $new_version"
            update_version_files "$new_version"
            success "Version set to $new_version"
            ;;
        "release")
            if [[ -z "${2:-}" ]]; then
                error "Release type required (major|minor|patch)"
            fi
            
            current_version="$(get_current_version)"
            new_version="$(increment_version "$current_version" "$2")"
            
            log "Creating release $new_version from $current_version"
            update_version_files "$new_version"
            update_changelog "$new_version"
            create_git_tag "$new_version"
            
            success "Release $new_version created!"
            warning "Don't forget to:"
            echo "  1. Edit CHANGELOG.md with release notes"
            echo "  2. Commit the changelog: git add CHANGELOG.md && git commit -m 'Update changelog for v$new_version'"
            echo "  3. Push changes: git push origin main"
            echo "  4. Push tag: git push origin v$new_version"
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            error "Unknown command: $1. Use 'help' for usage information."
            ;;
    esac
}

# Run main function with all arguments
main "$@"
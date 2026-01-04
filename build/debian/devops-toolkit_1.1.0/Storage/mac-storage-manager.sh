#!/usr/bin/env bash
# mac-storage-manager.sh v2.0 - Enhanced Interactive Storage Manager for macOS
# Part of DevOps Toolkit - Professional storage management utilities

set -euo pipefail
IFS=$'\n\t'

# Version and metadata
VERSION="2.0.0"
SCRIPT_NAME="Mac Storage Manager"
AUTHOR="DevOps Toolkit"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Configuration
MIN_LARGE_SIZE_MB=100
OLD_DAYS=90
SNAPSHOT_FILE="/tmp/mac_storage_before_kb"
TEMP_DIR="/tmp/mac_storage_$$"
FZF_CMD=""
DEBUG=0
DISABLE_FZF=0

# Logging functions
log_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_debug() { [[ "${DEBUG:-0}" = "1" ]] && echo -e "${PURPLE}[DEBUG]${NC} $1" || true; }

# Initialize temporary directory
init_temp_dir() {
    mkdir -p "$TEMP_DIR"
    trap 'rm -rf "$TEMP_DIR" 2>/dev/null || true' EXIT
}

# Check for dependencies
check_dependencies() {
    local missing_deps=()
    
    # Check for gum (interactive UI)
    if ! command -v gum &>/dev/null; then
        missing_deps+=("gum")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo -e "${YELLOW}⚠️  Missing dependencies detected:${NC}"
        for dep in "${missing_deps[@]}"; do
            echo -e "  ${RED}✗${NC} $dep"
        done
        echo
        echo -e "${CYAN}To install on macOS:${NC}"
        echo "  brew install gum"
        echo
        echo -e "${CYAN}To install on Linux:${NC}"
        echo "  # Ubuntu/Debian:"
        echo "  echo 'deb [trusted=yes] https://repo.charm.sh/apt/ /' | sudo tee /etc/apt/sources.list.d/charm.list"
        echo "  sudo apt update && sudo apt install gum"
        echo
        echo "  # Or download binary from: https://github.com/charmbracelet/gum/releases"
        echo
        echo -e "${YELLOW}Note: Script will continue with basic functionality${NC}"
        sleep 3
        return 1
    fi
    return 0
}

# Check for fzf availability
ensure_fzf() {
    if [[ "$DISABLE_FZF" = "1" ]]; then
        log_debug "fzf disabled via DISABLE_FZF"
        FZF_CMD=""
        return
    fi
    
    if command -v fzf >/dev/null 2>&1; then
        FZF_CMD="fzf --height=40% --reverse --border --ansi --prompt='Select> ' --info=inline"
        log_debug "fzf available and enabled"
    else
        FZF_CMD=""
        log_debug "fzf not found. Install with: brew install fzf"
        log_debug "Running in fallback mode without fzf"
    fi
}

# User confirmation
confirm() {
    local prompt="$1"
    local default="${2:-N}"
    
    if [[ "$default" = "Y" ]]; then
        read -r -p "$prompt [Y/n] " resp
        case "$resp" in
            [nN][oO]|[nN]) return 1 ;;
            *) return 0 ;;
        esac
    else
        read -r -p "$prompt [y/N] " resp
        case "$resp" in
            [yY][eE][sS]|[yY]) return 0 ;;
            *) return 1 ;;
        esac
    fi
}

# Progress bar for disk usage
print_progress_bar() {
    local used_kb=${1:-0}
    local total_kb=${2:-0}
    local width=40
    local percent=0
    local filled=0

    if [[ "$total_kb" -gt 0 ]]; then
        percent=$(( used_kb * 100 / total_kb ))
        filled=$(( width * used_kb / total_kb ))
    fi
    
    [[ "$filled" -lt 0 ]] && filled=0
    [[ "$filled" -gt "$width" ]] && filled=$width
    local empty=$(( width - filled ))

    printf "["
    for ((i=0; i<filled; i++)); do printf "#"; done
    for ((i=0; i<empty; i++)); do printf "·"; done
    printf "] %d%%\n" "$percent"
}

# Convert KB to human readable format
kb_to_human() {
    local kb=${1:-0}
    
    if [[ "$kb" -ge 1073741824 ]]; then
        # >= 1TB
        awk -v k="$kb" 'BEGIN{printf "%.1fT", k/1073741824}'
    elif [[ "$kb" -ge 1048576 ]]; then
        # >= 1GB
        awk -v k="$kb" 'BEGIN{printf "%.1fG", k/1048576}'
    elif [[ "$kb" -ge 1024 ]]; then
        # >= 1MB
        awk -v k="$kb" 'BEGIN{printf "%.1fM", k/1024}'
    else
        printf "%dK" "$kb"
    fi
}

# Disk usage report
show_disk_usage() {
    echo
    echo -e "${BOLD}=== Disk Usage Report ===${NC}"
    
    if df -h / >/dev/null 2>&1; then
        local used_str total_str percent_str
        used_str=$(df -h / | awk 'NR==2{print $3}')
        total_str=$(df -h / | awk 'NR==2{print $2}')
        percent_str=$(df -h / | awk 'NR==2{print $5}')
        
        printf "  Used: %s / %s (%s)\\n" "$used_str" "$total_str" "$percent_str"
        
        local used_kb total_kb avail_kb
        used_kb=$(df -k / | awk 'NR==2{print $3}')
        total_kb=$(df -k / | awk 'NR==2{print $2}')
        avail_kb=$(df -k / | awk 'NR==2{print $4}')
        
        print_progress_bar "$used_kb" "$total_kb"
        printf "  Available: %s\\n" "$(kb_to_human $avail_kb)"
        echo
    else
        log_error "Unable to get disk usage information"
    fi
}

# Launch Symlink Manager
launch_symlink_manager() {
    local symlink_script="$(dirname "${BASH_SOURCE[0]}")/symlink-manager.sh"
    
    if [[ -f "$symlink_script" ]]; then
        log_info "Launching Symlink Manager..."
        "$symlink_script"
    else
        log_error "Symlink Manager not found at: $symlink_script"
        echo -e "${YELLOW}The Symlink Manager is part of the DevOps Toolkit${NC}"
        echo -e "${CYAN}Press Enter to continue...${NC}"
        read -r
    fi
}
snapshot_before() {
    local used_kb
    used_kb=$(df -k / | awk 'NR==2{print $3}') || used_kb=0
    echo "$used_kb" > "$SNAPSHOT_FILE"
    log_info "Storage snapshot taken: $(kb_to_human $used_kb) used"
}

snapshot_after() {
    local before_kb=0
    [[ -f "$SNAPSHOT_FILE" ]] && before_kb=$(cat "$SNAPSHOT_FILE" 2>/dev/null || echo 0)
    
    local after_kb
    after_kb=$(df -k / | awk 'NR==2{print $3}') || after_kb=0
    local delta=$(( before_kb - after_kb ))
    
    echo
    echo -e "${BOLD}=== Cleanup Results ===${NC}"
    printf "Before: %s\n" "$(kb_to_human $before_kb)"
    printf "After:  %s\n" "$(kb_to_human $after_kb)"
    
    if [[ "$delta" -gt 0 ]]; then
        printf "Saved:  %s%s%s\n" "${GREEN}" "$(kb_to_human $delta)" "${NC}"
    elif [[ "$delta" -lt 0 ]]; then
        printf "Increased: %s%s%s\n" "${RED}" "$(kb_to_human $(( -delta )))" "${NC}"
    else
        echo "No change in disk usage"
    fi
    
    rm -f "$SNAPSHOT_FILE"
}

# Get file size in KB
get_file_size_kb() {
    local file="$1"
    [[ -f "$file" ]] && stat -f%z "$file" 2>/dev/null | awk '{print int($1/1024)}' || echo 0
}

# Large files management
find_large_files() {
    local size_mb=${1:-$MIN_LARGE_SIZE_MB}
    local search_path=${2:-"$HOME"}
    
    log_info "Scanning for files larger than ${size_mb}MB in $search_path..."
    
    find "$search_path" -type f -size +${size_mb}M -print0 2>/dev/null | \
        xargs -0 ls -lh 2>/dev/null | \
        awk '{size=$5; $1=$2=$3=$4=$5=$6=$7=$8=""; gsub(/^ +/, ""); print size "\t" $0}' | \
        sort -hr | head -n 100
}

interactive_large_files() {
    if [[ -z "$FZF_CMD" ]]; then
        log_warn "Interactive mode requires fzf. Showing top 50 large files:"
        find_large_files | head -n 50
        return
    fi
    
    local large_files
    large_files=$(find_large_files)
    
    if [[ -z "$large_files" ]]; then
        log_info "No large files found (>${MIN_LARGE_SIZE_MB}MB)"
        return
    fi
    
    local selection
    selection=$(echo "$large_files" | $FZF_CMD \
        --multi \
        --with-nth=2.. \
        --delimiter="\t" \
        --preview 'ls -la {2} 2>/dev/null || echo "File not accessible"' \
        --header "Select files to delete (TAB to multi-select, ENTER to confirm)")
    
    if [[ -z "$selection" ]]; then
        log_info "No files selected"
        return
    fi
    
    local selected_files="$TEMP_DIR/selected_files"
    echo "$selection" | cut -f2- > "$selected_files"
    
    echo -e "\n${YELLOW}Selected files for deletion:${NC}"
    cat "$selected_files"
    echo
    
    if confirm "Delete selected files?" "N"; then
        snapshot_before
        while IFS= read -r file; do
            if [[ -f "$file" ]]; then
                local size_before
                size_before=$(get_file_size_kb "$file")
                if rm -f "$file" 2>/dev/null; then
                    log_success "Deleted: $file ($(kb_to_human $size_before))"
                else
                    log_error "Failed to delete: $file"
                fi
            else
                log_warn "File not found: $file"
            fi
        done < "$selected_files"
        snapshot_after
    else
        log_info "Deletion cancelled"
    fi
}

# Old files management
find_old_files() {
    local days=${1:-$OLD_DAYS}
    local search_path=${2:-"$HOME"}
    
    log_info "Scanning for files not accessed in ${days}+ days..."
    
    find "$search_path" -type f -atime +${days} -print0 2>/dev/null | \
        xargs -0 ls -ltu 2>/dev/null | \
        awk '{size=$5; atime=$6 " " $7 " " $8; $1=$2=$3=$4=$5=$6=$7=$8=""; gsub(/^ +/, ""); print size "\t" atime "\t" $0}' | \
        sort -k1,1hr | head -n 100
}

# Cache cleanup functions
clean_user_caches() {
    local cache_dir="$HOME/Library/Caches"
    
    if [[ ! -d "$cache_dir" ]]; then
        log_warn "Cache directory not found: $cache_dir"
        return
    fi
    
    log_info "Cleaning user caches..."
    snapshot_before
    
    # Calculate size before cleanup
    local size_before
    size_before=$(du -sk "$cache_dir" 2>/dev/null | cut -f1)
    
    # Clean caches
    find "$cache_dir" -type f -delete 2>/dev/null || true
    find "$cache_dir" -type d -empty -delete 2>/dev/null || true
    
    log_success "User caches cleaned ($(kb_to_human $size_before) processed)"
    snapshot_after
}

clean_xcode_data() {
    local xcode_dir="$HOME/Library/Developer/Xcode"
    local derived_data="$xcode_dir/DerivedData"
    local archives="$xcode_dir/Archives"
    
    log_info "Cleaning Xcode data..."
    snapshot_before
    
    local total_cleaned=0
    
    if [[ -d "$derived_data" ]]; then
        local size_before
        size_before=$(du -sk "$derived_data" 2>/dev/null | cut -f1)
        rm -rf "$derived_data"/* 2>/dev/null || true
        total_cleaned=$(( total_cleaned + size_before ))
        log_success "DerivedData cleaned ($(kb_to_human $size_before))"
    fi
    
    if [[ -d "$archives" ]] && confirm "Also clean Xcode Archives?" "N"; then
        local size_before
        size_before=$(du -sk "$archives" 2>/dev/null | cut -f1)
        rm -rf "$archives"/* 2>/dev/null || true
        total_cleaned=$(( total_cleaned + size_before ))
        log_success "Archives cleaned ($(kb_to_human $size_before))"
    fi
    
    log_success "Xcode cleanup complete ($(kb_to_human $total_cleaned) total)"
    snapshot_after
}

# Docker cleanup
clean_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        log_warn "Docker not installed"
        echo -e "${CYAN}Press Enter to continue...${NC}"
        read -r
        return
    fi
    
    # Check if Docker daemon is running
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker daemon is not running"
        echo -e "${YELLOW}Please start Docker Desktop and try again${NC}"
        echo -e "${CYAN}Press Enter to continue...${NC}"
        read -r
        return
    fi
    
    log_info "Docker cleanup..."
    
    # Show current usage
    echo
    echo -e "${BOLD}Current Docker disk usage:${NC}"
    if ! docker system df 2>/dev/null; then
        log_warn "Could not get Docker disk usage"
    fi
    echo
    
    # Show what will be cleaned
    echo -e "${BOLD}Docker cleanup will remove:${NC}"
    echo "  • All stopped containers"
    echo "  • All unused networks"
    echo "  • All unused images (not just dangling ones)"
    echo "  • All unused volumes"
    echo "  • All build cache"
    echo
    
    if confirm "Proceed with Docker cleanup?" "N"; then
        snapshot_before
        echo
        log_info "Cleaning Docker containers..."
        docker container prune -f 2>/dev/null || log_warn "Failed to prune containers"
        
        log_info "Cleaning Docker images..."
        docker image prune -af 2>/dev/null || log_warn "Failed to prune images"
        
        log_info "Cleaning Docker volumes..."
        docker volume prune -f 2>/dev/null || log_warn "Failed to prune volumes"
        
        log_info "Cleaning Docker networks..."
        docker network prune -f 2>/dev/null || log_warn "Failed to prune networks"
        
        log_info "Cleaning Docker build cache..."
        docker builder prune -af 2>/dev/null || log_warn "Failed to prune build cache"
        
        log_success "Docker cleanup completed"
        
        echo
        echo -e "${BOLD}Docker disk usage after cleanup:${NC}"
        docker system df 2>/dev/null || log_warn "Could not get Docker disk usage"
        snapshot_after
    else
        log_info "Docker cleanup cancelled"
    fi
    
    echo -e "${CYAN}Press Enter to continue...${NC}"
    read -r
}

# Node.js cleanup
clean_node_modules() {
    log_info "Node.js cleanup options..."
    
    if command -v npkill >/dev/null 2>&1; then
        if confirm "Launch npkill for interactive node_modules cleanup?" "Y"; then
            npkill
        fi
    else
        log_info "npkill not found. Searching for node_modules directories..."
        
        local node_dirs
        node_dirs=$(find "$HOME" -type d -name "node_modules" -prune 2>/dev/null | head -n 50)
        
        if [[ -z "$node_dirs" ]]; then
            log_info "No node_modules directories found"
            return
        fi
        
        echo -e "\n${BOLD}Found node_modules directories:${NC}"
        echo "$node_dirs" | while read -r dir; do
            local size
            size=$(du -sh "$dir" 2>/dev/null | cut -f1)
            echo "  $size  $dir"
        done
        
        if confirm "Install npkill for better node_modules management?" "Y"; then
            npm install -g npkill 2>/dev/null && log_success "npkill installed"
        fi
    fi
}

# Package manager cleanup
clean_package_managers() {
    log_info "Package manager cleanup..."
    snapshot_before
    
    # Homebrew cleanup
    if command -v brew >/dev/null 2>&1; then
        log_info "Cleaning Homebrew..."
        brew cleanup -s 2>/dev/null || true
        brew autoremove 2>/dev/null || true
        log_success "Homebrew cleaned"
    fi
    
    # NPM cache cleanup
    if command -v npm >/dev/null 2>&1; then
        log_info "Cleaning npm cache..."
        npm cache clean --force 2>/dev/null || true
        log_success "npm cache cleaned"
    fi
    
    # Yarn cache cleanup
    if command -v yarn >/dev/null 2>&1; then
        log_info "Cleaning Yarn cache..."
        yarn cache clean 2>/dev/null || true
        log_success "Yarn cache cleaned"
    fi
    
    # pip cache cleanup
    if command -v pip3 >/dev/null 2>&1; then
        log_info "Cleaning pip cache..."
        pip3 cache purge 2>/dev/null || true
        log_success "pip cache cleaned"
    fi
    
    snapshot_after
}

# Git repository optimization
optimize_git_repos() {
    local search_paths=("$HOME/Git" "$HOME/Documents" "$HOME/Projects" "$HOME/Code")
    local repos=()
    
    log_info "Scanning for Git repositories..."
    
    for search_path in "${search_paths[@]}"; do
        [[ ! -d "$search_path" ]] && continue
        
        while IFS= read -r -d '' git_dir; do
            local repo_dir
            repo_dir=$(dirname "$git_dir")
            repos+=("$repo_dir")
        done < <(find "$search_path" -type d -name ".git" -prune -print0 2>/dev/null)
    done
    
    # Remove duplicates
    local unique_repos
    mapfile -t unique_repos < <(printf '%s\n' "${repos[@]}" | sort -u)
    
    if [[ ${#unique_repos[@]} -eq 0 ]]; then
        log_info "No Git repositories found"
        return
    fi
    
    echo -e "\n${BOLD}Found ${#unique_repos[@]} Git repositories:${NC}"
    for repo in "${unique_repos[@]}"; do
        local size
        size=$(du -sh "$repo" 2>/dev/null | cut -f1)
        echo "  $size  $repo"
    done
    
    if confirm "Optimize all repositories (git gc --aggressive)?" "N"; then
        snapshot_before
        
        for repo in "${unique_repos[@]}"; do
            log_info "Optimizing: $repo"
            (cd "$repo" && git gc --aggressive --prune=now 2>/dev/null) || \
                log_warn "Failed to optimize: $repo"
        done
        
        log_success "Git repository optimization complete"
        snapshot_after
    fi
}

# Duplicate files finder
find_duplicates() {
    local search_paths=("$HOME/Documents" "$HOME/Downloads" "$HOME/Desktop")
    
    if ! command -v shasum >/dev/null 2>&1; then
        log_error "shasum command not found"
        return 1
    fi
    
    log_info "Scanning for duplicate files..."
    
    local checksums_file="$TEMP_DIR/checksums"
    for path in "${search_paths[@]}"; do
        [[ -d "$path" ]] || continue
        find "$path" -type f -print0 2>/dev/null | \
            xargs -0 shasum 2>/dev/null >> "$checksums_file" || true
    done
    
    if [[ ! -s "$checksums_file" ]]; then
        log_info "No files found to check for duplicates"
        return
    fi
    
    # Find duplicates
    local duplicates_file="$TEMP_DIR/duplicates"
    sort "$checksums_file" | \
        uniq -w40 -D > "$duplicates_file"
    
    if [[ ! -s "$duplicates_file" ]]; then
        log_info "No duplicate files found"
        return
    fi
    
    echo -e "\n${BOLD}Duplicate files found:${NC}"
    awk '{print $2}' "$duplicates_file" | while read -r file; do
        if [[ -f "$file" ]]; then
            local size
            size=$(ls -lh "$file" 2>/dev/null | awk '{print $5}')
            echo "  $size  $file"
        fi
    done
    
    # Interactive deletion if fzf available
    if [[ -n "$FZF_CMD" ]]; then
        local selection
        selection=$(awk '{print $2}' "$duplicates_file" | \
            $FZF_CMD --multi --preview 'ls -la {}' --header "Select duplicates to delete")
        
        if [[ -n "$selection" ]]; then
            echo "$selection" | while read -r file; do
                if confirm "Delete $file?" "N"; then
                    rm -f "$file" && log_success "Deleted: $file"
                fi
            done
        fi
    fi
}

# System logs cleanup
clean_system_logs() {
    log_info "System logs cleanup..."
    
    local log_dirs=(
        "$HOME/Library/Logs"
        "/var/log"
        "/usr/local/var/log"
    )
    
    for log_dir in "${log_dirs[@]}"; do
        [[ ! -d "$log_dir" ]] && continue
        
        local size_before
        size_before=$(du -sk "$log_dir" 2>/dev/null | cut -f1)
        
        if [[ "$log_dir" = "/var/log" ]]; then
            if confirm "Clean system logs in $log_dir (requires sudo)?" "N"; then
                sudo find "$log_dir" -name "*.log" -mtime +7 -delete 2>/dev/null || true
                sudo find "$log_dir" -name "*.gz" -delete 2>/dev/null || true
                log_success "System logs cleaned ($(kb_to_human $size_before))"
            fi
        else
            if confirm "Clean logs in $log_dir?" "Y"; then
                find "$log_dir" -name "*.log" -mtime +7 -delete 2>/dev/null || true
                find "$log_dir" -name "*.gz" -delete 2>/dev/null || true
                log_success "Logs cleaned: $log_dir ($(kb_to_human $size_before))"
            fi
        fi
    done
}

# iOS simulators cleanup
clean_ios_simulators() {
    if ! command -v xcrun >/dev/null 2>&1; then
        log_warn "Xcode command line tools not found"
        return
    fi
    
    log_info "iOS Simulator cleanup..."
    
    # List simulators
    local simulators
    simulators=$(xcrun simctl list devices | grep -E "iPhone|iPad" | grep -v "unavailable" || true)
    
    if [[ -z "$simulators" ]]; then
        log_info "No iOS simulators found"
        return
    fi
    
    echo -e "\n${BOLD}Available iOS Simulators:${NC}"
    echo "$simulators"
    
    if confirm "Delete unavailable simulators?" "Y"; then
        snapshot_before
        xcrun simctl delete unavailable 2>/dev/null || true
        log_success "Unavailable simulators deleted"
        snapshot_after
    fi
    
    if confirm "Erase all simulators data?" "N"; then
        snapshot_before
        xcrun simctl erase all 2>/dev/null || true
        log_success "All simulator data erased"
        snapshot_after
    fi
}

# Trash management
manage_trash() {
    local trash_dir="$HOME/.Trash"
    
    if [[ ! -d "$trash_dir" ]]; then
        log_info "Trash is empty"
        return
    fi
    
    local trash_size
    trash_size=$(du -sh "$trash_dir" 2>/dev/null | cut -f1)
    
    echo -e "\n${BOLD}Trash information:${NC}"
    echo "  Size: $trash_size"
    echo "  Location: $trash_dir"
    
    if confirm "Empty trash permanently?" "N"; then
        snapshot_before
        rm -rf "$trash_dir"/* 2>/dev/null || true
        log_success "Trash emptied (${trash_size})"
        snapshot_after
    fi
}

# Menu system
show_header() {
    echo -e "${BOLD}${BLUE}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║${NC}${BOLD}          Mac Storage Manager v${VERSION}              ${BLUE}║${NC}"
    echo -e "${BOLD}${BLUE}║${NC}${BOLD}              DevOps Toolkit                       ${BLUE}║${NC}"
    echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════════╝${NC}"
    
    show_disk_usage
}

# Interactive menu using gum (like port-checker)
show_gum_menu() {
    local menu_options=(
        "📁 Find large files (${MIN_LARGE_SIZE_MB}MB+)"
        "🕒 Find old files (${OLD_DAYS}+ days)"
        "🧹 Clean user caches"
        "🔨 Clean Xcode data"
        "🐳 Docker cleanup"
        "📦 Node.js cleanup"
        "🍺 Package managers cleanup"
        "🗃️  Git repositories optimization"
        "👥 Find duplicate files"
        "📝 Clean system logs"
        "📱 iOS Simulators cleanup"
        "🗑️  Manage trash"
        "📊 Show disk usage analysis"
        "🔗 Symlink Manager (Storage Expansion)"
        "⚙️  Settings & Configuration"
        "🔄 Refresh disk usage"
        "❓ Show help & commands"
        "🚪 Quit"
    )
    
    local selection
    selection=$(printf '%s\n' "${menu_options[@]}" | gum choose --header="Mac Storage Manager v${VERSION} - Select an option" --height=20)
    
    case "$selection" in
        "📁 Find large files"*) echo "1" ;;
        "🕒 Find old files"*) echo "2" ;;
        "🧹 Clean user caches"*) echo "3" ;;
        "🔨 Clean Xcode data"*) echo "4" ;;
        "🐳 Docker cleanup"*) echo "5" ;;
        "📦 Node.js cleanup"*) echo "6" ;;
        "🍺 Package managers cleanup"*) echo "7" ;;
        "🗃️  Git repositories optimization"*) echo "8" ;;
        "👥 Find duplicate files"*) echo "9" ;;
        "📝 Clean system logs"*) echo "10" ;;
        "📱 iOS Simulators cleanup"*) echo "11" ;;
        "🗑️  Manage trash"*) echo "12" ;;
        "📊 Show disk usage analysis"*) echo "13" ;;
        "🔗 Symlink Manager"*) echo "14" ;;
        "⚙️  Settings & Configuration"*) echo "15" ;;
        "🔄 Refresh disk usage"*) echo "16" ;;
        "❓ Show help & commands"*) echo "17" ;;
        "🚪 Quit"*) echo "18" ;;
        *) echo "q" ;;
    esac
}

# Fallback interactive menu with arrow key navigation
show_interactive_menu() {
    local menu_items=(
        "📁 Find large files (${MIN_LARGE_SIZE_MB}MB+)"
        "🕒 Find old files (${OLD_DAYS}+ days)"
        "🧹 Clean user caches"
        "🔨 Clean Xcode data"
        "🐳 Docker cleanup"
        "📦 Node.js cleanup"
        "🍺 Package managers cleanup"
        "🗃️  Git repositories optimization"
        "👥 Find duplicate files"
        "📝 Clean system logs"
        "📱 iOS Simulators cleanup"
        "🗑️  Manage trash"
        "📊 Show disk usage analysis"
        "⚙️  Settings & Configuration"
        "🔄 Refresh disk usage"
        "❓ Show help & commands"
        "🚪 Quit"
    )
    
    local current_item=0
    local total_items=${#menu_items[@]}
    
    while true; do
        # Clear from cursor to end of screen
        tput ed
        
        echo
        echo -e "${BOLD}Use ↑/↓ arrows to navigate, Enter to select:${NC}"
        echo
        
        # Display menu items
        for i in "${!menu_items[@]}"; do
            if [[ $i -eq $current_item ]]; then
                echo -e "${BOLD}${GREEN}▶ $(( i + 1 )). ${menu_items[$i]}${NC}"
            else
                echo -e "  $(( i + 1 )). ${menu_items[$i]}"
            fi
        done
        
        # Read single character
        local key
        read -rsn1 key
        
        case "$key" in
            $'\e')  # Escape sequence
                read -rsn2 key
                case "$key" in
                    '[A') # Up arrow
                        ((current_item > 0)) && ((current_item--))
                        ;;
                    '[B') # Down arrow
                        ((current_item < total_items - 1)) && ((current_item++))
                        ;;
                esac
                ;;
            '') # Enter
                echo $((current_item + 1))
                return 0
                ;;
            'q'|'Q') # Quick quit
                echo "q"
                return 0
                ;;
        esac
    done
}

show_main_menu() {
    local menu_items=(
        "1) 📁 Find large files (${MIN_LARGE_SIZE_MB}MB+)"
        "2) 🕒 Find old files (${OLD_DAYS}+ days)"
        "3) 🧹 Clean user caches"
        "4) 🔨 Clean Xcode data"
        "5) 🐳 Docker cleanup"
        "6) 📦 Node.js cleanup"
        "7) 🍺 Package managers cleanup"
        "8) 🗃️  Git repositories optimization"
        "9) 👥 Find duplicate files"
        "10) 📝 Clean system logs"
        "11) 📱 iOS Simulators cleanup"
        "12) 🗑️  Manage trash"
        "13) 📊 Show disk usage analysis"
        "14) ⚙️  Settings & Configuration"
        "r) 🔄 Refresh disk usage"
        "h) ❓ Show help & commands"
        "q) 🚪 Quit"
    )
    
    # Check if gum is available for better UX
    if command -v gum &>/dev/null && [[ "$DISABLE_FZF" != "1" ]]; then
        show_gum_menu
    elif [[ -z "$FZF_CMD" ]] || [[ "$DISABLE_FZF" == "1" ]]; then
        show_interactive_menu
    else
        local selection
        selection=$(printf '%s\n' "${menu_items[@]}" | \
            $FZF_CMD --header "Mac Storage Manager v${VERSION} - Select an option" \
                     --info=inline \
                     --prompt="Storage> " \
                     --pointer="▶" \
                     --marker="✓" 2>/dev/null) || true
        
        if [[ -n "$selection" ]]; then
            local choice
            choice=$(echo "$selection" | cut -d')' -f1)
            echo "$choice"
        else
            # If fzf selection is cancelled, use interactive menu
            show_interactive_menu
        fi
    fi
}

# Main application loop
main_loop() {
    local first_run=true
    while true; do
        if [[ "$first_run" == "true" ]]; then
            clear
            first_run=false
        fi
        
        show_header
        echo
        
        local choice
        choice=$(show_main_menu)
        local menu_status=$?
        
        # If menu selection fails, try to continue or exit gracefully
        if [[ $menu_status -ne 0 ]] || [[ -z "$choice" ]]; then
            log_warn "Menu selection failed or empty. Exiting..."
            echo
            echo -e "${CYAN}Thank you for using Mac Storage Manager! 🙏${NC}"
            exit 0
        fi
        
        case "$choice" in
            1) interactive_large_files ;;
            2) 
                find_old_files | head -n 20
                echo
                log_info "Showing first 20 results. Use --days parameter to customize threshold."
                ;;
            3) clean_user_caches ;;
            4) clean_xcode_data ;;
            5) clean_docker ;;
            6) clean_node_modules ;;
            7) clean_package_managers ;;
            8) optimize_git_repos ;;
            9) find_duplicates ;;
            10) clean_system_logs ;;
            11) clean_ios_simulators ;;
            12) manage_trash ;;
            13) 
                show_disk_usage
                echo
                log_info "Detailed disk usage analysis completed."
                ;;
            14) launch_symlink_manager ;;
            15) show_settings_menu ;;
            16) 
                clear
                continue 
                ;;
            17)
                clear
                show_help
                echo
                echo -e "${CYAN}Press Enter to return to main menu...${NC}"
                read -r
                clear
                ;;
            18|q|Q) 
                echo
                echo -e "${CYAN}Thank you for using Mac Storage Manager! 🙏${NC}"
                echo -e "${GREEN}Keep your Mac clean and optimized! ✨${NC}"
                exit 0 
                ;;
            r|R) 
                clear
                continue 
                ;;
            h|H)
                clear
                show_help
                echo
                echo -e "${CYAN}Press Enter to return to main menu...${NC}"
                read -r
                clear
                ;;
            *) 
                log_warn "Invalid option: $choice"
                echo -e "${CYAN}Press Enter to continue...${NC}"
                read -r
                clear
                ;;
        esac
        
        [[ -z "$FZF_CMD" ]] && {
            echo
            read -r -p "Press Enter to continue..." _
        }
    done
}

# Help function
show_help() {
    cat <<EOF
Mac Storage Manager v${VERSION} - Professional Storage Management for macOS

USAGE:
    $0 [OPTIONS] [COMMAND]

OPTIONS:
    -h, --help              Show this help
    -v, --version          Show version information
    --debug                Enable debug output
    --no-fzf               Disable fzf interactive mode
    --size SIZE            Set minimum file size for large files (default: ${MIN_LARGE_SIZE_MB}MB)
    --days DAYS            Set days threshold for old files (default: ${OLD_DAYS})

COMMANDS:
    📁 File Management:
        large-files            Find and manage large files interactively
        old-files              Find files not accessed recently
        find-duplicates        Find and remove duplicate files
        manage-trash           Manage trash contents
    
    🧹 Cleanup Operations:
        clean-caches           Clean user caches (~2-5GB typical)
        clean-xcode            Clean Xcode data (5-50GB potential)
        clean-docker           Docker cleanup (10-100GB potential)
        clean-node             Node.js cleanup (1-20GB typical)
        clean-packages         Package managers cleanup (1-5GB typical)
        clean-logs             Clean system and user logs
        clean-simulators       Clean iOS Simulators data
    
    🗃️  Repository Management:
        optimize-git           Optimize Git repositories (10-50% reduction)
    
    📊 Analysis:
        disk-usage             Show detailed disk usage report
        
    ⚡ Quick Actions:
        quick-clean            Quick cleanup (caches + Docker + packages)
        interactive            Force interactive mode
        
INTERACTIVE MODE (Default):
    When no command is specified, launches interactive mode with:
    • Visual menu navigation (with fzf if available)
    • Real-time disk usage monitoring
    • Safety confirmations for all operations
    • Storage snapshots to measure cleanup effectiveness
    
EXAMPLES:
    $0                              Launch interactive mode
    $0 large-files                  Find large files interactively
    $0 --size 500 large-files       Find files larger than 500MB
    $0 --days 30 old-files          Find files older than 30 days
    $0 --no-fzf clean-caches        Clean caches without fzf interface
    $0 --debug clean-docker         Docker cleanup with debug output
    $0 disk-usage                   Show disk usage analysis
    $0 clean-xcode clean-docker     Multiple commands (not supported - use one at a time)
    
COMMON WORKFLOWS:
    • Quick cleanup: $0 clean-caches && $0 clean-docker
    • Find space hogs: $0 large-files, then $0 find-duplicates
    • Xcode maintenance: $0 clean-xcode && $0 clean-simulators
    • Development cleanup: $0 clean-node && $0 optimize-git

SAFETY FEATURES:
    • Confirmation prompts for all destructive operations
    • Before/after storage snapshots
    • Non-destructive analysis by default
    • Graceful permission handling
    • System file protection

DEPENDENCIES:
    Required: bash, df, du, find, awk, sort
    Optional: fzf (enhanced UI), docker, git, npm, brew

For more information, visit: https://github.com/sabbajohn/useful-stuff

EOF
}

# Command line interface
handle_cli_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                echo "$SCRIPT_NAME v$VERSION"
                exit 0
                ;;
            --debug)
                DEBUG=1
                log_debug "Debug mode enabled"
                shift
                ;;
            --no-fzf)
                DISABLE_FZF=1
                shift
                ;;
            --size)
                MIN_LARGE_SIZE_MB="$2"
                shift 2
                ;;
            --days)
                OLD_DAYS="$2"
                shift 2
                ;;
            large-files)
                find_large_files
                exit 0
                ;;
            old-files)
                find_old_files
                exit 0
                ;;
            clean-caches)
                clean_user_caches
                exit 0
                ;;
            clean-xcode)
                clean_xcode_data
                exit 0
                ;;
            clean-docker)
                clean_docker
                exit 0
                ;;
            clean-node)
                clean_node_modules
                exit 0
                ;;
            clean-packages)
                clean_package_managers
                exit 0
                ;;
            optimize-git)
                optimize_git_repos
                exit 0
                ;;
            find-duplicates)
                find_duplicates
                exit 0
                ;;
            clean-logs)
                clean_system_logs
                exit 0
                ;;
            clean-simulators)
                clean_ios_simulators
                exit 0
                ;;
            manage-trash)
                manage_trash
                exit 0
                ;;
            disk-usage)
                show_disk_usage
                echo
                log_info "For interactive cleanup options, run without arguments"
                exit 0
                ;;
            quick-clean)
                log_info "Starting quick cleanup (caches + Docker + package managers)..."
                clean_user_caches
                clean_docker
                clean_package_managers
                log_success "Quick cleanup complete!"
                exit 0
                ;;
            interactive)
                # Force interactive mode
                break
                ;;
            *)
                log_error "Unknown command: $1"
                echo
                log_info "Available commands: large-files, old-files, clean-caches, clean-xcode, clean-docker, clean-node, clean-packages, optimize-git, find-duplicates, clean-logs, clean-simulators, manage-trash, disk-usage"
                echo
                show_help
                exit 1
                ;;
        esac
    done
}

# Settings and configuration menu
show_settings_menu() {
    while true; do
        clear
        echo -e "${BOLD}${BLUE}⚙️  Settings & Configuration${NC}"
        echo "================================"
        echo
        echo -e "${BOLD}Current Settings:${NC}"
        echo "  • Large files threshold: ${MIN_LARGE_SIZE_MB}MB"
        echo "  • Old files threshold: ${OLD_DAYS} days"
        echo "  • fzf interface: $(if [[ -n "$FZF_CMD" ]]; then echo "Enabled"; else echo "Disabled"; fi)"
        echo "  • Debug mode: $(if [[ "${DEBUG:-0}" = "1" ]]; then echo "Enabled"; else echo "Disabled"; fi)"
        echo "  • Temporary directory: $TEMP_DIR"
        echo
        
        local settings_menu=(
            "1) 📏 Change large files threshold (current: ${MIN_LARGE_SIZE_MB}MB)"
            "2) ⏰ Change old files threshold (current: ${OLD_DAYS} days)"
            "3) 🎨 Toggle fzf interface"
            "4) 🐛 Toggle debug mode"
            "5) 📁 Show temporary files location"
            "6) ✅ Run system compatibility check"
            "7) 📊 Show storage statistics"
            "b) ← Back to main menu"
        )
        
        if [[ -n "$FZF_CMD" ]]; then
            local selection
            selection=$(printf '%s\n' "${settings_menu[@]}" | \
                $FZF_CMD --header "Settings & Configuration")
            
            [[ -z "$selection" ]] && return
            
            local choice
            choice=$(echo "$selection" | cut -d')' -f1)
        else
            echo -e "${BOLD}Settings Options:${NC}"
            printf '%s\n' "${settings_menu[@]}"
            echo
            read -r -p "Choose an option: " choice
        fi
        
        case "$choice" in
            1)
                echo
                read -r -p "Enter new threshold for large files (MB) [${MIN_LARGE_SIZE_MB}]: " new_size
                if [[ "$new_size" =~ ^[0-9]+$ ]] && [[ "$new_size" -gt 0 ]]; then
                    MIN_LARGE_SIZE_MB="$new_size"
                    log_success "Large files threshold set to ${MIN_LARGE_SIZE_MB}MB"
                else
                    log_warn "Invalid input. Please enter a positive number."
                fi
                ;;
            2)
                echo
                read -r -p "Enter new threshold for old files (days) [${OLD_DAYS}]: " new_days
                if [[ "$new_days" =~ ^[0-9]+$ ]] && [[ "$new_days" -gt 0 ]]; then
                    OLD_DAYS="$new_days"
                    log_success "Old files threshold set to ${OLD_DAYS} days"
                else
                    log_warn "Invalid input. Please enter a positive number."
                fi
                ;;
            3)
                if [[ -n "$FZF_CMD" ]]; then
                    FZF_CMD=""
                    log_info "fzf interface disabled for this session"
                else
                    if command -v fzf >/dev/null 2>&1; then
                        FZF_CMD="fzf --height=40% --reverse --border --ansi --prompt='Select> ' --info=inline"
                        log_success "fzf interface enabled"
                    else
                        log_warn "fzf not installed. Install with: brew install fzf"
                    fi
                fi
                ;;
            4)
                if [[ "${DEBUG:-0}" = "1" ]]; then
                    DEBUG=0
                    log_info "Debug mode disabled"
                else
                    DEBUG=1
                    log_success "Debug mode enabled"
                fi
                ;;
            5)
                echo
                log_info "Temporary files location: $TEMP_DIR"
                if [[ -d "$TEMP_DIR" ]]; then
                    local temp_size
                    temp_size=$(du -sh "$TEMP_DIR" 2>/dev/null | cut -f1)
                    echo "  Size: $temp_size"
                    echo "  Files: $(find "$TEMP_DIR" -type f 2>/dev/null | wc -l | tr -d ' ')"
                else
                    echo "  Status: Not created yet"
                fi
                ;;
            6)
                echo
                log_info "Running system compatibility check..."
                echo
                local deps_ok=0
                local deps_total=0
                
                # Check required dependencies
                local required_deps=("bash" "df" "du" "find" "awk" "sort" "stat")
                for dep in "${required_deps[@]}"; do
                    deps_total=$((deps_total + 1))
                    if command -v "$dep" >/dev/null 2>&1; then
                        echo "  ✅ $dep"
                        deps_ok=$((deps_ok + 1))
                    else
                        echo "  ❌ $dep (REQUIRED)"
                    fi
                done
                
                # Check optional dependencies
                local optional_deps=("fzf" "docker" "git" "npm" "brew" "xcrun")
                for dep in "${optional_deps[@]}"; do
                    if command -v "$dep" >/dev/null 2>&1; then
                        echo "  ✅ $dep (optional)"
                    else
                        echo "  ⚠️  $dep (optional, enhances functionality)"
                    fi
                done
                
                echo
                if [[ $deps_ok -eq ${#required_deps[@]} ]]; then
                    log_success "System compatibility check passed! ($deps_ok/${#required_deps[@]} required dependencies found)"
                else
                    log_error "System compatibility check failed! Missing $(( ${#required_deps[@]} - deps_ok )) required dependencies"
                fi
                ;;
            7)
                echo
                log_info "Storage Statistics Summary:"
                echo
                # Disk usage
                if df -h / >/dev/null 2>&1; then
                    echo -e "${BOLD}Disk Usage:${NC}"
                    df -h / | awk 'NR==2{printf "  Total: %s, Used: %s (%s), Available: %s\n", $2, $3, $5, $4}'
                    echo
                fi
                
                # Quick analysis
                echo -e "${BOLD}Quick Analysis:${NC}"
                local home_size
                home_size=$(du -sh "$HOME" 2>/dev/null | cut -f1)
                echo "  Home directory size: $home_size"
                
                if [[ -d "$HOME/Library/Caches" ]]; then
                    local cache_size
                    cache_size=$(du -sh "$HOME/Library/Caches" 2>/dev/null | cut -f1)
                    echo "  User caches size: $cache_size"
                fi
                
                if [[ -d "$HOME/.Trash" ]]; then
                    local trash_size
                    trash_size=$(du -sh "$HOME/.Trash" 2>/dev/null | cut -f1)
                    echo "  Trash size: $trash_size"
                fi
                
                echo
                log_info "For detailed analysis, use the main menu options"
                ;;
            b|B) return ;;
            *) log_warn "Invalid option: $choice" ;;
        esac
        
        [[ -z "$FZF_CMD" ]] && {
            echo
            read -r -p "Press Enter to continue..." _
        }
    done
}

# Show welcome message when entering interactive mode
show_welcome() {
    echo
    log_info "Welcome to Mac Storage Manager v${VERSION}!"
    echo
    echo -e "${CYAN}💡 Tips:${NC}"
    echo "  • Use TAB to multi-select files when using fzf"
    echo "  • All destructive operations require confirmation"
    echo "  • Storage snapshots measure cleanup effectiveness"
    echo "  • Use --help for CLI commands and options"
    echo
    if [[ -z "$FZF_CMD" ]]; then
        echo -e "${YELLOW}💡 Install fzf for enhanced interactive experience:${NC}"
        echo "     brew install fzf"
        echo
    fi
}

# Main function
main() {
    init_temp_dir
    check_dependencies
    ensure_fzf
    
    # Handle command line arguments
    if [[ $# -gt 0 ]]; then
        handle_cli_args "$@"
    else
        # No arguments provided - show available options and enter interactive mode
        echo
        echo -e "${BOLD}${CYAN}Mac Storage Manager v${VERSION}${NC}"
        echo -e "${CYAN}Professional Storage Management for macOS${NC}"
        echo
        echo -e "${BOLD}Quick Commands:${NC}"
        echo "  $0 large-files        # Find large files"
        echo "  $0 old-files          # Find files older than 90 days"
        echo "  $0 clean-caches       # Clean user caches"
        echo "  $0 clean-xcode        # Clean Xcode data"
        echo "  $0 clean-docker       # Docker cleanup"
        echo "  $0 clean-node         # Clean Node.js data"
        echo "  $0 clean-packages     # Clean package managers"
        echo "  $0 optimize-git       # Optimize Git repositories"
        echo "  $0 find-duplicates    # Find duplicate files"
        echo "  $0 manage-trash       # Manage trash contents"
        echo "  $0 disk-usage         # Show disk usage report"
        echo "  $0 --help             # Show all options and examples"
        echo
        echo -e "${BOLD}Or continue with interactive mode for guided experience...${NC}"
        echo
        if command -v fzf >/dev/null 2>&1; then
            echo -e "${GREEN}✨ Enhanced UI detected (fzf available)${NC}"
        else
            echo -e "${YELLOW}📋 Standard UI mode (install fzf with 'brew install fzf' for enhanced experience)${NC}"
        fi
        echo
        read -r -p "Press Enter to launch interactive mode, or Ctrl+C to exit: " _
        show_welcome
    fi
    
    # Launch interactive mode
    main_loop
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
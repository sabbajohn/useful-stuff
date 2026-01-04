#!/usr/bin/env bash
# symlink-manager.sh v1.0 - Professional Symlink Manager for macOS Storage Expansion
# Part of DevOps Toolkit - Expand your Mac storage using external drives

set -euo pipefail
IFS=$'\n\t'

# Version and metadata
VERSION="1.0.0"
SCRIPT_NAME="Symlink Manager"
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
SYMLINK_DB="$HOME/.symlink_manager.db"
TEMP_DIR="/tmp/symlink_manager_$$"
DEBUG=0

# Logging functions
log_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_debug() { [[ "${DEBUG:-0}" = "1" ]] && echo -e "${PURPLE}[DEBUG]${NC} $1" || true; }

# Initialize
init_temp_dir() {
    mkdir -p "$TEMP_DIR"
    trap 'rm -rf "$TEMP_DIR" 2>/dev/null || true' EXIT
    
    # Create symlink database if it doesn't exist
    touch "$SYMLINK_DB"
}

# Check dependencies
check_dependencies() {
    if ! command -v gum &>/dev/null; then
        echo -e "${YELLOW}⚠️  gum is required for interactive interface${NC}"
        echo -e "${CYAN}Install with: brew install gum${NC}"
        exit 1
    fi
}

# Header
show_header() {
    clear
    echo -e "${BOLD}${BLUE}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║${NC}${BOLD}          Symlink Manager v${VERSION}                ${BLUE}║${NC}"
    echo -e "${BOLD}${BLUE}║${NC}${BOLD}           Storage Expansion Tool                  ${BLUE}║${NC}"
    echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════════╝${NC}"
    echo
}

# Detect external drives
detect_external_drives() {
    local drives=()
    
    # Get all mounted volumes except system volumes
    while IFS= read -r volume; do
        # Skip system volumes and network shares
        if [[ "$volume" =~ ^/Volumes/ ]] && [[ ! "$volume" =~ ^/Volumes/.*\.app$ ]]; then
            # Check if it's writable
            if [[ -w "$volume" ]]; then
                local size
                size=$(df -h "$volume" | tail -n 1 | awk '{print $2}')
                drives+=("$volume ($size)")
            fi
        fi
    done < <(df | awk 'NR>1 {print $9}' | grep -v '^$')
    
    printf '%s\n' "${drives[@]}"
}

# Browse directories with gum
browse_directory() {
    local current_dir="${1:-$HOME}"
    local title="${2:-Select directory to offload}"
    
    while true; do
        echo -e "${BOLD}Current path:${NC} $current_dir"
        echo
        
        local items=()
        items+=("📁 .. (Parent Directory)")
        items+=("✅ SELECT THIS DIRECTORY")
        items+=("❌ Cancel")
        items+=("---")
        
        # Add subdirectories
        if [[ -d "$current_dir" ]]; then
            while IFS= read -r item; do
                if [[ -d "$current_dir/$item" ]]; then
                    local size
                    size=$(du -sh "$current_dir/$item" 2>/dev/null | cut -f1 || echo "?")
                    items+=("📁 $item ($size)")
                fi
            done < <(ls -1 "$current_dir" 2>/dev/null | head -n 20)
        fi
        
        local selection
        selection=$(printf '%s\n' "${items[@]}" | gum choose --header="$title" --height=20)
        
        case "$selection" in
            "📁 .. (Parent Directory)")
                current_dir=$(dirname "$current_dir")
                ;;
            "✅ SELECT THIS DIRECTORY")
                echo "$current_dir"
                return 0
                ;;
            "❌ Cancel")
                return 1
                ;;
            "---")
                continue
                ;;
            📁*)
                local dir_name
                dir_name=$(echo "$selection" | sed 's/📁 //' | sed 's/ (.*)//')
                current_dir="$current_dir/$dir_name"
                ;;
            "")
                return 1
                ;;
        esac
    done
}

# Calculate directory size
get_directory_size() {
    local dir="$1"
    du -sh "$dir" 2>/dev/null | cut -f1
}

# Check if path is already symlinked
is_symlinked() {
    local path="$1"
    [[ -L "$path" ]]
}

# Offload directory to external drive
offload_directory() {
    echo -e "${BOLD}🚀 Directory Offload Process${NC}"
    echo
    
    # Step 1: Select source directory
    log_info "Step 1: Select directory to offload"
    local source_dir
    if ! source_dir=$(browse_directory "$HOME" "Select directory to offload"); then
        log_warn "Offload cancelled"
        return 1
    fi
    
    if [[ ! -d "$source_dir" ]]; then
        log_error "Directory does not exist: $source_dir"
        return 1
    fi
    
    if is_symlinked "$source_dir"; then
        log_error "Directory is already a symlink: $source_dir"
        return 1
    fi
    
    local dir_size
    dir_size=$(get_directory_size "$source_dir")
    
    echo
    log_info "Selected: $source_dir ($dir_size)"
    echo
    
    # Step 2: Select destination drive
    log_info "Step 2: Select destination drive"
    local external_drives
    mapfile -t external_drives < <(detect_external_drives)
    
    if [[ ${#external_drives[@]} -eq 0 ]]; then
        log_error "No external drives detected"
        log_info "Please connect an external drive and try again"
        return 1
    fi
    
    local dest_drive
    dest_drive=$(printf '%s\n' "${external_drives[@]}" | gum choose --header="Select destination drive")
    
    if [[ -z "$dest_drive" ]]; then
        log_warn "No drive selected"
        return 1
    fi
    
    # Extract drive path
    local drive_path
    drive_path=$(echo "$dest_drive" | sed 's/ (.*//')
    
    log_info "Selected drive: $drive_path"
    echo
    
    # Step 3: Create destination path
    local dir_name
    dir_name=$(basename "$source_dir")
    local dest_path="$drive_path/SymlinkOffload/$dir_name"
    
    echo
    log_info "Destination: $dest_path"
    echo
    
    # Step 4: Confirmation
    echo -e "${BOLD}📋 Offload Summary:${NC}"
    echo -e "  ${BOLD}Source:${NC} $source_dir ($dir_size)"
    echo -e "  ${BOLD}Destination:${NC} $dest_path"
    echo -e "  ${BOLD}Action:${NC} Move files to external drive and create symlink"
    echo
    
    if ! gum confirm "Proceed with offload?"; then
        log_warn "Offload cancelled"
        return 1
    fi
    
    # Step 5: Execute offload
    log_info "Creating destination directory..."
    mkdir -p "$(dirname "$dest_path")"
    
    log_info "Moving files to external drive..."
    if ! mv "$source_dir" "$dest_path"; then
        log_error "Failed to move directory"
        return 1
    fi
    
    log_info "Creating symlink..."
    if ! ln -s "$dest_path" "$source_dir"; then
        log_error "Failed to create symlink, attempting to restore..."
        mv "$dest_path" "$source_dir"
        return 1
    fi
    
    # Record in database
    echo "$(date '+%Y-%m-%d %H:%M:%S'),$source_dir,$dest_path,$dir_size" >> "$SYMLINK_DB"
    
    log_success "Directory successfully offloaded!"
    log_info "Symlink created: $source_dir -> $dest_path"
    echo
    echo -e "${CYAN}Press Enter to continue...${NC}"
    read -r
}

# List active symlinks
list_symlinks() {
    echo -e "${BOLD}🔗 Active Symlinks${NC}"
    echo
    
    if [[ ! -s "$SYMLINK_DB" ]]; then
        log_info "No symlinks recorded"
        echo -e "${CYAN}Press Enter to continue...${NC}"
        read -r
        return
    fi
    
    local symlinks=()
    while IFS=',' read -r date source dest size; do
        if [[ -L "$source" ]]; then
            local status="✅ Active"
            if [[ ! -e "$dest" ]]; then
                status="❌ Broken"
            fi
            symlinks+=("$source -> $dest [$size] ($status)")
        fi
    done < "$SYMLINK_DB"
    
    if [[ ${#symlinks[@]} -eq 0 ]]; then
        log_info "No active symlinks found"
    else
        local selection
        symlinks+=("🔙 Return to menu")
        selection=$(printf '%s\n' "${symlinks[@]}" | gum choose --header="Active Symlinks - Select for details")
        
        if [[ "$selection" != "🔙 Return to menu" ]] && [[ -n "$selection" ]]; then
            manage_symlink "$selection"
        fi
    fi
    
    echo -e "${CYAN}Press Enter to continue...${NC}"
    read -r
}

# Manage individual symlink
manage_symlink() {
    local symlink_info="$1"
    local source
    source=$(echo "$symlink_info" | cut -d' ' -f1)
    
    echo -e "${BOLD}🔧 Manage Symlink${NC}"
    echo -e "${BOLD}Path:${NC} $source"
    echo
    
    if [[ ! -L "$source" ]]; then
        log_error "Not a symlink: $source"
        return 1
    fi
    
    local target
    target=$(readlink "$source")
    local size
    size=$(get_directory_size "$target")
    
    echo -e "${BOLD}Details:${NC}"
    echo -e "  ${BOLD}Source:${NC} $source"
    echo -e "  ${BOLD}Target:${NC} $target"
    echo -e "  ${BOLD}Size:${NC} $size"
    echo -e "  ${BOLD}Status:${NC} $([[ -e "$target" ]] && echo "✅ Active" || echo "❌ Broken")"
    echo
    
    local actions=(
        "🔄 Restore to internal drive"
        "🗑️  Remove symlink (keep external files)"
        "❌ Delete completely"
        "🔙 Back"
    )
    
    local action
    action=$(printf '%s\n' "${actions[@]}" | gum choose --header="Select action")
    
    case "$action" in
        "🔄 Restore to internal drive")
            restore_symlink "$source" "$target"
            ;;
        "🗑️  Remove symlink (keep external files)")
            remove_symlink "$source" false
            ;;
        "❌ Delete completely")
            remove_symlink "$source" true
            ;;
    esac
}

# Restore symlink to internal drive
restore_symlink() {
    local source="$1"
    local target="$2"
    
    echo -e "${BOLD}🔄 Restore Symlink${NC}"
    echo
    
    if [[ ! -e "$target" ]]; then
        log_error "Target directory not found: $target"
        return 1
    fi
    
    local size
    size=$(get_directory_size "$target")
    
    echo -e "${BOLD}Restore Summary:${NC}"
    echo -e "  ${BOLD}From:${NC} $target"
    echo -e "  ${BOLD}To:${NC} $source"
    echo -e "  ${BOLD}Size:${NC} $size"
    echo -e "  ${BOLD}Action:${NC} Move files back to internal drive"
    echo
    
    if ! gum confirm "Proceed with restore?"; then
        log_warn "Restore cancelled"
        return 1
    fi
    
    log_info "Removing symlink..."
    rm "$source"
    
    log_info "Moving files back to internal drive..."
    if ! mv "$target" "$source"; then
        log_error "Failed to move files back"
        # Try to recreate symlink
        ln -s "$target" "$source" || true
        return 1
    fi
    
    # Remove from database
    sed -i.bak "\\|,$source,|d" "$SYMLINK_DB"
    
    log_success "Symlink restored successfully!"
    echo
    echo -e "${CYAN}Press Enter to continue...${NC}"
    read -r
}

# Remove symlink
remove_symlink() {
    local source="$1"
    local delete_files="$2"
    
    echo -e "${BOLD}🗑️  Remove Symlink${NC}"
    echo
    
    local target
    target=$(readlink "$source")
    
    if [[ "$delete_files" == "true" ]]; then
        echo -e "${RED}⚠️  WARNING: This will permanently delete all files!${NC}"
        echo -e "  ${BOLD}Symlink:${NC} $source"
        echo -e "  ${BOLD}Files:${NC} $target"
        echo
        if ! gum confirm "Are you sure you want to delete everything?"; then
            log_warn "Deletion cancelled"
            return 1
        fi
        
        rm "$source"
        rm -rf "$target"
        log_success "Symlink and files deleted"
    else
        echo -e "${BOLD}Remove symlink but keep files on external drive:${NC}"
        echo -e "  ${BOLD}Symlink:${NC} $source"
        echo -e "  ${BOLD}Files (kept):${NC} $target"
        echo
        if ! gum confirm "Remove symlink only?"; then
            log_warn "Operation cancelled"
            return 1
        fi
        
        rm "$source"
        log_success "Symlink removed, files preserved on external drive"
    fi
    
    # Remove from database
    sed -i.bak "\\|,$source,|d" "$SYMLINK_DB"
    
    echo
    echo -e "${CYAN}Press Enter to continue...${NC}"
    read -r
}

# Show help
show_help() {
    echo -e "${BOLD}❓ Symlink Manager Help${NC}"
    echo
    echo -e "${BOLD}What is this tool?${NC}"
    echo "Symlink Manager helps expand your Mac's storage by moving large"
    echo "directories to external drives while keeping them accessible from"
    echo "their original locations using symbolic links."
    echo
    echo -e "${BOLD}How it works:${NC}"
    echo "1. Select a directory you want to 'offload'"
    echo "2. Choose an external drive as destination"
    echo "3. The tool moves files to external drive"
    echo "4. Creates a symlink in the original location"
    echo "5. Directory appears normal but actually lives on external drive"
    echo
    echo -e "${BOLD}Benefits:${NC}"
    echo "• Free up internal storage space"
    echo "• Keep all your workflows unchanged"
    echo "• Files remain accessible from original paths"
    echo "• Easy to manage and restore"
    echo
    echo -e "${BOLD}Best practices:${NC}"
    echo "• Keep external drive connected when using symlinked data"
    echo "• Use fast external drives (USB 3.0+ or Thunderbolt)"
    echo "• Regularly verify symlink integrity"
    echo "• Keep a backup of important data"
    echo
    echo -e "${BOLD}Examples of good candidates for offloading:${NC}"
    echo "• ~/Downloads (large files)"
    echo "• ~/Movies or ~/Pictures"
    echo "• Development build folders"
    echo "• Virtual machine files"
    echo "• Large document archives"
    echo
    echo -e "${CYAN}Press Enter to continue...${NC}"
    read -r
}

# Main menu
show_main_menu() {
    local menu_options=(
        "📤 Offload directory to external drive"
        "🔗 List active symlinks"
        "❓ Help & Tips"
        "🚪 Quit"
    )
    
    local selection
    selection=$(printf '%s\\n' "${menu_options[@]}" | gum choose --header="Symlink Manager v${VERSION} - Select an option" --height=15)
    
    case "$selection" in
        "📤 Offload directory"*) echo "1" ;;
        "🔗 List active symlinks"*) echo "2" ;;
        "❓ Help & Tips"*) echo "3" ;;
        "🚪 Quit"*) echo "4" ;;
        *) echo "q" ;;
    esac
}

# Main application loop
main_loop() {
    while true; do
        show_header
        
        local choice
        choice=$(show_main_menu)
        
        case "$choice" in
            1) offload_directory ;;
            2) list_symlinks ;;
            3) show_help ;;
            4|q|Q) 
                echo
                echo -e "${CYAN}Thank you for using Symlink Manager! 🙏${NC}"
                echo -e "${GREEN}Keep your Mac storage optimized! ✨${NC}"
                exit 0 
                ;;
            *) 
                log_warn "Invalid option: $choice"
                sleep 1
                ;;
        esac
    done
}

# Main function
main() {
    init_temp_dir
    check_dependencies
    
    # Handle command line arguments
    if [[ $# -gt 0 ]]; then
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                echo "$SCRIPT_NAME v$VERSION"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    fi
    
    # Launch main loop
    main_loop
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
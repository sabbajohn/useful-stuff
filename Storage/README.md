# Mac Storage Manager v2.0

Professional storage management utility for macOS systems. Part of the DevOps Toolkit.

## 🎯 Features

### 📊 Smart Storage Analysis
- **Real-time disk usage reporting** with visual progress bars
- **Large files detection** with interactive selection
- **Old files identification** (customizable age threshold)
- **Duplicate files finder** with hash-based detection
- **Storage snapshots** to measure cleanup effectiveness

### 🧹 Comprehensive Cleanup Options
- **User Caches**: `~/Library/Caches` cleanup
- **Xcode Data**: DerivedData, Archives, and build artifacts
- **Docker**: Containers, images, volumes, and build cache
- **Node.js**: Interactive `node_modules` management with npkill
- **Package Managers**: Homebrew, npm, Yarn, pip cache cleanup
- **Git Repositories**: Aggressive optimization and pruning
- **System Logs**: User and system log cleanup
- **iOS Simulators**: Cleanup and data reset
- **Trash Management**: Smart trash emptying

### 🎨 Enhanced User Experience
- **Interactive mode** with `fzf` integration for better selection
- **Non-interactive CLI** for automation and scripting
- **Color-coded output** for better readability
- **Progress tracking** with before/after comparisons
- **Safety confirmations** for destructive operations
- **Detailed logging** with different verbosity levels

## 📦 Installation

### Via DevOps Toolkit Package
```bash
# Debian/Ubuntu
sudo dpkg -i devops-toolkit_*.deb

# RedHat/CentOS/Fedora  
sudo rpm -i devops-toolkit-*.rpm

# macOS (Homebrew)
brew install devops-toolkit

# Then use the command
storage-manager
```

### Manual Installation
```bash
# Clone repository
git clone https://github.com/sabbajohn/useful-stuff.git
cd useful-stuff/Storage

# Make executable
chmod +x mac-storage-manager.sh

# Run directly
./mac-storage-manager.sh
```

## 🚀 Usage

### Interactive Mode (Recommended)
```bash
# Launch with fzf interface (if available)
storage-manager

# Launch without fzf (fallback mode)
storage-manager --no-fzf
```

### Command Line Interface
```bash
# Show help
storage-manager --help

# Show version
storage-manager --version

# Find large files (non-interactive)
storage-manager large-files

# Find old files (non-interactive)  
storage-manager old-files

# Clean specific components
storage-manager clean-caches     # User caches
storage-manager clean-xcode      # Xcode data
storage-manager clean-docker     # Docker artifacts
storage-manager clean-node       # Node.js cleanup
storage-manager clean-packages   # Package managers
storage-manager optimize-git     # Git repositories
storage-manager find-duplicates  # Duplicate files
storage-manager clean-logs       # System logs
storage-manager clean-simulators # iOS Simulators
storage-manager manage-trash     # Trash management
```

### Advanced Options
```bash
# Customize file size threshold (default: 100MB)
storage-manager --size 500 large-files

# Customize age threshold (default: 90 days)
storage-manager --days 30 old-files

# Enable debug output
storage-manager --debug large-files

# Disable fzf interactive mode
storage-manager --no-fzf clean-caches
```

## 🎨 Interactive Features

### With fzf (Enhanced Experience)
When `fzf` is available, the tool provides:
- **Multi-select file deletion** with preview
- **Interactive menu navigation**
- **Real-time file preview** and metadata display
- **Fuzzy search** across all options
- **Keyboard shortcuts** for efficient navigation

### Without fzf (Standard Mode)
Falls back to traditional terminal interface:
- **Numbered menu options**
- **Standard input/output**
- **Compatible with all terminals**
- **Scriptable and automation-friendly**

## 📊 What Gets Cleaned

### User Caches (~2-5GB typical savings)
- Application caches in `~/Library/Caches`
- Browser caches and temporary files
- System-generated cache files

### Xcode Data (5-50GB potential savings)
- DerivedData build artifacts
- Device support files
- Simulator data
- Archives (optional)

### Docker (~10-100GB potential savings)
- Unused containers and images
- Build cache and volumes
- Network configurations
- System prune operations

### Node.js (~1-20GB typical savings)
- `node_modules` directories
- npm/Yarn global caches
- Package lock files (optional)

### Package Managers (~1-5GB typical savings)
- Homebrew cache and old versions
- npm global cache
- Yarn cache
- pip cache

### Git Repositories (~10-50% repo size reduction)
- Aggressive garbage collection
- Prune unreachable objects
- Optimize pack files
- Remove reflog entries

## ⚙️ Configuration

### Environment Variables
```bash
# Disable fzf permanently
export DISABLE_FZF=1

# Enable debug mode
export DEBUG=1

# Custom temporary directory
export TMPDIR="/custom/tmp"
```

### Script Configuration
Edit the script directly to modify defaults:
```bash
MIN_LARGE_SIZE_MB=100    # Minimum size for "large" files
OLD_DAYS=90              # Days threshold for "old" files  
```

## 🔒 Safety Features

### Confirmation Prompts
- **Destructive operations** require explicit confirmation
- **Large operations** show estimated impact
- **System-level changes** require elevated confirmation

### Backup and Recovery
- **Storage snapshots** before major operations
- **Detailed logging** of all deletions
- **Rollback information** for package managers

### Permission Handling  
- **Non-destructive analysis** by default
- **Graceful degradation** for insufficient permissions
- **Clear error messages** for permission issues

### File Safety
- **Hash verification** for duplicate detection
- **Symlink awareness** to prevent accidental deletions
- **System file protection** with path filtering

---

**Mac Storage Manager** - Professional storage management for macOS developers and power users.

*Part of the DevOps Toolkit by sabbajohn*
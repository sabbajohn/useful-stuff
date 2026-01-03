#!/bin/bash
# Demo script for Mac Storage Manager v2.0
# Demonstrates key features and capabilities

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STORAGE_MANAGER="$SCRIPT_DIR/Storage/mac-storage-manager.sh"

echo "🚀 Mac Storage Manager v2.0 - Feature Demo"
echo "============================================"
echo

# Check if script exists
if [[ ! -f "$STORAGE_MANAGER" ]]; then
    echo "❌ Mac Storage Manager not found at $STORAGE_MANAGER"
    exit 1
fi

echo "📋 Version Information:"
"$STORAGE_MANAGER" --version
echo

echo "📊 Quick disk usage summary:"
"$STORAGE_MANAGER" disk-usage
echo

echo "🔍 Finding large files (>100MB):"
"$STORAGE_MANAGER" large-files --size 100M --preview
echo

echo "📅 Checking for old files (>90 days):"
"$STORAGE_MANAGER" old-files --days 90 --preview
echo

echo "🧹 Available cleanup options:"
echo "  • Caches cleanup (typically saves 2-5GB)"
echo "  • Docker cleanup (can save 10-100GB)"
echo "  • Xcode cleanup (can save 5-50GB)"
echo "  • Node.js cleanup (typically saves 1-20GB)"
echo "  • Git optimization (10-50% size reduction)"
echo

echo "📖 To see all options:"
echo "  $STORAGE_MANAGER --help"
echo

echo "🎯 To run interactively:"
echo "  $STORAGE_MANAGER"
echo

echo "✨ Demo completed! The Mac Storage Manager is ready for professional use."
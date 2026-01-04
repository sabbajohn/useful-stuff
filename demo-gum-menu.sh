#!/usr/bin/env bash
# Demo simples do menu gum para Mac Storage Manager

echo "🚀 Mac Storage Manager v2.0 - Demo Menu"
echo

menu_options=(
    "📁 Find large files"
    "🕒 Find old files" 
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

while true; do
    selection=$(printf '%s\n' "${menu_options[@]}" | gum choose --header="Mac Storage Manager v2.0 - Select an option" --height=20)
    
    if [[ -z "$selection" ]]; then
        echo "❌ No selection made. Exiting..."
        exit 0
    fi
    
    case "$selection" in
        "📁 Find large files"*) 
            echo "🔍 Finding large files..."
            sleep 1
            ;;
        "🚪 Quit"*) 
            echo "👋 Thank you for using Mac Storage Manager!"
            exit 0
            ;;
        *) 
            echo "✅ Selected: $selection"
            echo "   (Feature would execute here)"
            sleep 2
            ;;
    esac
    
    echo
    if ! gum confirm "Continue to main menu?"; then
        echo "👋 Goodbye!"
        exit 0
    fi
    clear
done
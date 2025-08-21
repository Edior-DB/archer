
    # Set default fonts

# Archer KDE Plasma Vanilla Reset Script
# Restores a true fresh KDE Plasma user config (like a new user)
set -e

show_logo() {
    echo -e "\033[0;34m"
    cat << "LOGOEOF"
██    ██  █████  ███    ██ ██ ██      ██      █████      ██████  ██      █████  ███    ███  █████
██    ██ ██   ██ ████   ██ ██ ██      ██     ██   ██     ██   ██ ██     ██   ██ ████  ████ ██   ██
██    ██ ███████ ██ ██  ██ ██ ██      ██     ███████     ██████  ██     ███████ ██ ████ ██ ███████
 ██  ██  ██   ██ ██  ██ ██ ██ ██      ██     ██   ██     ██   ██ ██     ██   ██ ██  ██  ██ ██   ██
  ████   ██   ██ ██   ████ ██ ███████ ██████ ██   ██     ██████  ██████ ██   ██ ██      ██ ██   ██

LOGOEOF
    echo -e "\033[0m"
}

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/..}/install/system/common-funcs.sh"


main() {
    show_logo
    echo -e "\033[1;33mThis will switch your KDE Plasma layout to the vanilla default using KDE's native API.\033[0m"
    echo ""
    read -p "Continue? [y/N]: " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || exit 0

    # Use lookandfeeltool for global theme (if you have a matching theme, e.g., org.kde.breeze)
    # lookandfeeltool -a org.kde.breeze

    # Use D-Bus to load the vanilla layout from Archer configs
    LAYOUT_PATH="${ARCHER_DIR:-$HOME/.local/share/archer}/configs/vanilla-layout.js"
    if [ -f "$LAYOUT_PATH" ]; then
        qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.loadLayout "$LAYOUT_PATH"
        echo -e "\033[32mVanilla KDE Plasma layout applied using KDE API!\033[0m"
        echo -e "\033[33mIf you just applied a new layout, log out and back in for changes to take full effect.\033[0m"
    else
        echo -e "\033[31mLayout script $LAYOUT_PATH not found.\033[0m"
        echo -e "\033[33mPlease create a KDE Plasma layout script for Vanilla and place it in $LAYOUT_PATH.\033[0m"
    fi
}

main


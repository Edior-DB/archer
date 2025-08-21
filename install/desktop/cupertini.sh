
#!/bin/bash
# Cupertini Layout - macOS-like KDE Plasma Layout Only
# This script configures a clean, standard macOS-like layout (top bar + dock) for KDE Plasma.
# It does NOT install or change icons, fonts, cursors, or artwork.

set -e

show_logo() {
    echo -e "\033[0;34m"
    cat << "EOF"
 ██████╗██╗   ██╗██████╗ ███████╗██████╗ ████████╗██╗███╗   ██╗██╗
██╔════╝██║   ██║██╔══██╗██╔════╝██╔══██╗╚══██╔══╝██║████╗  ██║██║
██║     ██║   ██║██████╔╝█████╗  ██████╔╝   ██║   ██║██╔██╗ ██║██║
██║     ██║   ██║██╔═══╝ ██╔══╝  ██╔══██╗   ██║   ██║██║╚██╗██║██║
╚██████╗╚██████╔╝██║     ███████╗██║  ██║   ██║   ██║██║ ╚████║██║
 ╚═════╝ ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝╚═╝  ╚═══╝╚═╝
        macOS-like Layout (KDE Plasma)
EOF
    echo -e "\033[0m"
}

source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/..}/install/system/common-funcs.sh"


main() {
    show_logo
    echo -e "\033[1;33mThis will switch your KDE Plasma layout to a macOS-like (Cupertini) layout using KDE's native API.\033[0m"
    echo -e "\033[36mNo icons, fonts, or artwork will be changed.\033[0m"
    echo ""
    read -p "Continue? [y/N]: " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || exit 0

    # Use lookandfeeltool for global theme (if you have a matching theme, e.g., org.kde.breezeway)
    # lookandfeeltool -a org.kde.breezeway

    # Use D-Bus to evaluate a macOS-like layout script from Archer configs (Plasma 6 compatible)
    LAYOUT_PATH="${ARCHER_DIR:-$HOME/.local/share/archer}/configs/cupertini-layout.js"
    if [ -f "$LAYOUT_PATH" ]; then
    qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$(cat "$LAYOUT_PATH")"
        echo -e "\033[32mCupertini (macOS-like) layout applied using KDE API!\033[0m"
        echo -e "\033[33mIf you just applied a new layout, log out and back in for changes to take full effect.\033[0m"
    else
        echo -e "\033[31mLayout script $LAYOUT_PATH not found.\033[0m"
        echo -e "\033[33mPlease create a KDE Plasma layout script for Cupertini and place it in $LAYOUT_PATH.\033[0m"
    fi
}

main

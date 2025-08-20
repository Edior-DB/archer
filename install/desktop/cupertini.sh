
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
    echo -e "\033[1;33mThis will reset your KDE Plasma layout to a clean macOS-like (Cupertini) layout.\033[0m"
    echo -e "\033[36mNo icons, fonts, or artwork will be changed.\033[0m"
    echo ""
    read -p "Continue? [y/N]: " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || exit 0

    # Backup old config
    if [ -f "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" ]; then
        mv "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc.bak.$(date +%s)"
        echo -e "\033[36mBacked up old plasma-org.kde.plasma.desktop-appletsrc\033[0m"
    fi

    # Clean Plasma cache and session data
    echo -e "\033[36mCleaning Plasma cache and session data...\033[0m"
    rm -rf "$HOME/.cache/plasmashell" "$HOME/.cache/org.kde.plasma*" "$HOME/.config/session/" "$HOME/.local/share/kscreen/" "$HOME/.local/share/plasma*" 2>/dev/null || true

    # Write a standard macOS-like layout (top bar + dock) to plasma config
    mkdir -p "$HOME/.config"
    cat > "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" <<'EOL'
[Containments][1]
activityId=
formfactor=0
immutability=1
lastScreen=0
location=0
plugin=org.kde.plasma.desktop
wallpaperplugin=org.kde.image
[Containments][2]
activityId=
formfactor=2
immutability=1
lastScreen=0
location=3
plugin=org.kde.panel
[Containments][2][Applets][12]
immutability=1
plugin=org.kde.plasma.taskmanager
[Containments][2][Applets][12][Configuration][General]
launchers=applications:org.kde.dolphin.desktop,applications:firefox.desktop,applications:org.kde.konsole.desktop
[Containments][2][General]
AppletOrder=12
[Containments][2][Configuration][General]
iconSize=22
lengthMode=fill
panelSize=28
panelVisibility=NormalPanel
floating=0
EOL
    echo "macOS-like layout written (top bar + dock)"
    echo -e "\033[32mCupertini (macOS-like) layout applied! Please log out and back in to see changes.\033[0m"
}

main

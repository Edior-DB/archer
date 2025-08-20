
#!/bin/bash
# Redmondi Layout - Windows-like KDE Plasma Layout Only
# This script configures a clean, standard Windows-like layout (bottom taskbar) for KDE Plasma.
# It does NOT install or change icons, fonts, cursors, or artwork.

set -e

show_logo() {
    echo -e "\033[0;34m"
    cat << "EOF"
██████╗ ███████╗██████╗ ███╗   ███╗ ██████╗ ███╗   ██╗██████╗ ██╗
██╔══██╗██╔════╝██╔══██╗████╗ ████║██╔═══██╗████╗  ██║██╔══██╗██║
██████╔╝█████╗  ██║  ██║██╔████╔██║██║   ██║██╔██╗ ██║██║  ██║██║
██╔══██╗██╔══╝  ██║  ██║██║╚██╔╝██║██║   ██║██║╚██╗██║██║  ██║██║
██║  ██║███████╗██████╔╝██║ ╚═╝ ██║╚██████╔╝██║ ╚████║██████╔╝██║
╚═╝  ╚═╝╚══════╝╚═════╝ ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═════╝ ╚═╝
        Windows-like Layout (KDE Plasma)
EOF
    echo -e "\033[0m"
}

source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/..}/install/system/common-funcs.sh"

main() {
    show_logo
    echo -e "\033[1;33mThis will reset your KDE Plasma layout to a clean Windows-like (Redmondi) layout.\033[0m"
    echo -e "\033[36mNo icons, fonts, or artwork will be changed.\033[0m"
    echo ""
    read -p "Continue? [y/N]: " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || exit 0

    # Write a standard Windows-like layout (bottom taskbar) to plasma config
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
location=4
plugin=org.kde.panel
[Containments][2][Applets][4]
immutability=1
plugin=org.kde.plasma.taskmanager
[Containments][2][Applets][4][Configuration][General]
launchers=applications:systemsettings.desktop,applications:org.kde.dolphin.desktop,applications:firefox.desktop,applications:org.kde.konsole.desktop
[Containments][2][General]
AppletOrder=4
[Containments][2][Configuration][General]
iconSize=24
lengthMode=2
panelSize=40
panelVisibility=0
floating=0
EOL
    echo "Windows-like layout written (bottom taskbar)"
    echo -e "\033[32mRedmondi (Windows-like) layout applied! Please log out and back in to see changes.\033[0m"
}

main



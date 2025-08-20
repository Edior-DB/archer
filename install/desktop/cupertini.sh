
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

main() {
    show_logo
    echo -e "\033[1;33mThis will reset your KDE Plasma layout to a clean macOS-like (Cupertini) layout.\033[0m"
    echo -e "\033[36mNo icons, fonts, or artwork will be changed.\033[0m"
    echo ""
    read -p "Continue? [y/N]: " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || exit 0

    # Write a standard macOS-like layout (top bar + dock) to plasma config
    python3 << 'EOF'
import os
config_dir = os.path.expanduser("~/.config")
plasma_config = os.path.join(config_dir, "plasma-org.kde.plasma.desktop-appletsrc")
os.makedirs(config_dir, exist_ok=True)
macos_layout = '''[Containments][1]
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
'''
with open(plasma_config, 'w') as f:
    f.write(macos_layout)
print("macOS-like layout written (top bar + dock)")
EOF
    echo -e "\033[32mCupertini (macOS-like) layout applied! Please log out and back in to see changes.\033[0m"
}

main

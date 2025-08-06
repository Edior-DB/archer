#!/bin/bash

# Redmondi - Windows-like Desktop Environment (KDE Plasma 6-based)
# Part of Archer - Arch Linux Home Pmain Suite

set -e

# Check if KDE Plasma is installed
check_kde_installed() {
    if ! pacman -Q plasma &>/dev/null; then
        echo -e "${RED}KDE Plasma is not installed on this system.${NC}"
        echo -e "${YELLOW}Please re-run the main install.sh script to install KDE Plasma.${NC}"
        exit 1
    fi
}

# Install Windows-like themes and fonts
install_windows_themes() {
    echo -e "${BLUE}Installing Windows-like themes and fonts...${NC}"
    
    # Install AUR helper if not present
    if ! command -v yay &> /dev/null && ! command -v paru &> /dev/null; then
        echo -e "${YELLOW}Installing yay for AUR packages...${NC}"
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        cd /tmp/yay
        makepkg -si --noconfirm
        cd -
        rm -rf /tmp/yay
    fi

    # Set AUR helper
    local aur_helper="yay"
    if command -v paru &> /dev/null; then
        aur_helper="paru"
    fi

    # Install Windows fonts from AUR
    echo -e "${YELLOW}Installing Windows fonts...${NC}"
    $aur_helper -S --noconfirm --needed ttf-ms-win10 || echo -e "${YELLOW}Could not install Windows fonts, skipping...${NC}"

    # Install Windows icon theme from AUR
    echo -e "${YELLOW}Installing Windows 10 icon theme...${NC}"
    $aur_helper -S --noconfirm --needed windows-10-icon-theme || echo -e "${YELLOW}Could not install Windows 10 icons, using Breeze...${NC}"

    echo -e "${GREEN}Windows-like themes installed!${NC}"
}

# Reset KDE settings to default before applying new theme
reset_kde_settings() {
    echo -e "${BLUE}Resetting KDE settings to defaults...${NC}"
    
    # Remove existing theme configurations
    kwriteconfig5 --file kdeglobals --group KDE --key LookAndFeelPackage "org.kde.breeze.desktop"
    kwriteconfig5 --file plasmarc --group Theme --key name "default"
    kwriteconfig5 --file kdeglobals --group Icons --key Theme "breeze"
    kwriteconfig5 --file kdeglobals --group General --key cursorTheme "breeze_cursors"
    
    # Reset fonts to system defaults
    kwriteconfig5 --file kdeglobals --group General --key font ""
    kwriteconfig5 --file kdeglobals --group General --key menuFont ""
    kwriteconfig5 --file kdeglobals --group General --key toolBarFont ""
    kwriteconfig5 --file kdeglobals --group WM --key activeFont ""
    
    # Reset window decoration
    kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key library "org.kde.kwin.aurorae"
    kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key theme "__aurorae__svg__breeze"
    
    echo -e "${GREEN}KDE settings reset to defaults!${NC}"
}

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

show_logo() {
    echo -e "$BLUE"
    cat << "EOF"
██████╗ ███████╗██████╗ ███╗   ███╗ ██████╗ ███╗   ██╗██████╗ ██╗
██╔══██╗██╔════╝██╔══██╗████╗ ████║██╔═══██╗████╗  ██║██╔══██╗██║
██████╔╝█████╗  ██║  ██║██╔████╔██║██║   ██║██╔██╗ ██║██║  ██║██║
██╔══██╗██╔══╝  ██║  ██║██║╚██╔╝██║██║   ██║██║╚██╗██║██║  ██║██║
██║  ██║███████╗██████╔╝██║ ╚═╝ ██║╚██████╔╝██║ ╚████║██████╔╝██║
╚═╝  ╚═╝╚══════╝╚═════╝ ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═════╝ ╚═╝

        Windows-like Desktop Environment (KDE Plasma 6)
EOF
    echo -e "$NC"
}

confirm_action() {
    local message="$1"
    gum confirm "$message"
}

wait_for_input() {
    local message="${1:-Press Enter to continue...}"
    gum input --placeholder "$message" --value "" > /dev/null
}

# Install Windows-like KDE configuration
configure_kde_redmond() {
    echo -e "$BLUE Configuring KDE for Windows-like experience...$NC"
    sleep 3
    # Set global theme, icons, fonts, and panel layout for Windows-like look
    kwriteconfig5 --file kdeglobals --group KDE --key LookAndFeelPackage "Breeze"
    kwriteconfig5 --file plasmarc --group Theme --key name "Breeze"
    kwriteconfig5 --file kdeglobals --group Icons --key Theme "Windows-10-Dark"
    kwriteconfig5 --file kdeglobals --group General --key font "Segoe UI,11,-1,5,50,0,0,0,0,0"
    kwriteconfig5 --file kdeglobals --group General --key menuFont "Segoe UI,11,-1,5,50,0,0,0,0,0"
    kwriteconfig5 --file kdeglobals --group General --key toolBarFont "Segoe UI,10,-1,5,50,0,0,0,0,0"
    kwriteconfig5 --file kdeglobals --group WM --key activeFont "Segoe UI,11,-1,5,75,0,0,0,0,0"
    # Panel: Windows-like taskbar
    qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
        var allPanels = desktops()[0].panels;
        for (var i = 0; i < allPanels.length; ++i) {
            allPanels[i].remove();
        }
        var taskbar = new Panel;
        taskbar.location = "bottom";
        taskbar.height = 40;
        taskbar.alignment = "center";
        taskbar.addWidget("org.kde.plasma.kickoff");
        taskbar.addWidget("org.kde.plasma.icontasks");
        taskbar.addWidget("org.kde.plasma.systemtray");
        taskbar.addWidget("org.kde.plasma.digitalclock");
    '
    echo -e "$GREEN KDE configuration completed!$NC"
}

main() {
    show_logo
    check_kde_installed
    echo -e "$CYAN This will configure a Windows-like desktop using KDE Plasma 6.$NC"
    echo ""
    if ! confirm_action "Continue with Redmondi KDE configuration?"; then
        exit 0
    fi
    
    # Install themes first
    install_windows_themes
    
    # Reset settings to avoid conflicts
    reset_kde_settings
    
    # Only configure if in KDE session
    if [[ "$XDG_CURRENT_DESKTOP" == "KDE" ]] && [[ -n "$DISPLAY" ]]; then
        configure_kde_redmond
    else
        echo -e "$YELLOW Configuration will be applied after login to KDE.$NC"
        mkdir -p "$HOME/.config/autostart"
        cat > "$HOME/.config/autostart/redmondi-setup.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Redmondi Setup
Exec=/bin/bash -c 'sleep 10 && $(readlink -f "$0") --configure-only && rm "$HOME/.config/autostart/redmondi-setup.desktop"'
Hidden=false
NoDisplay=false
X-KDE-autostart-after=panel
EOF
    fi
    echo -e "$GREEN\n==========================================================================\n                        Redmondi KDE Configuration Complete!\n==========================================================================\n\n🪟 Windows-like KDE Plasma Desktop Installed:\n- KDE Plasma 6 with Windows-like layout\n- Breeze theme and Windows 10 icons\n- Windows-like fonts and taskbar\n\n📋 Next Steps:\n1. Reboot or log out and back in to KDE\n2. The desktop will auto-configure on first login\n3. Customize further using System Settings\n4. Install office suite: ./office-tools/office-suite.sh\n\n🎉 Welcome to your Windows-like Arch Linux desktop!\n\n$NC"
    wait_for_input "Press Enter to continue..."
}

if [[ "$1" == "--configure-only" ]]; then
    configure_kde_redmond
    exit 0
fi

main



=========================================================================
                        Redmondi Installation Complete!
=========================================================================

🪟 Windows-like Desktop Environment Installed:

📋 Next Steps:
1. Reboot or log out and back in
2. The desktop will auto-configure on first login
3. Customize further using GNOME Tweaks
4. Install office suite: ./office-tools/office-suite.sh
5. Install additional software as needed

🎉 Welcome to your Windows-like Arch Linux desktop!

${NC}"

#!/bin/bash

# Redmondi Theme Installer - Windows-like KDE Plasma 6 Theme
# Part of Archer - Arch Linux Home PC Transformation Suite

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/..}/install/system/common-funcs.sh"

# Install Windows-like themes and fonts
install_windows_themes() {
    echo -e "${BLUE}Installing Windows-like themes and fonts...${NC}"

    # Install Windows-compatible fonts from official repos
    echo -e "${YELLOW}Installing Windows-compatible fonts...${NC}"
    install_packages ttf-liberation ttf-dejavu

    # Install AUR helper if not present
    install_aur_helper

    # Install Windows icon theme from AUR
    echo -e "${YELLOW}Installing Windows 10 icon theme...${NC}"
    install_aur_packages windows10-icon-theme

    echo -e "${GREEN}Windows-like themes installed!${NC}"
}

show_logo() {
    echo -e "${BLUE}"
    cat << "EOF"
██████╗ ███████╗██████╗ ███╗   ███╗ ██████╗ ███╗   ██╗██████╗ ██╗
██╔══██╗██╔════╝██╔══██╗████╗ ████║██╔═══██╗████╗  ██║██╔══██╗██║
██████╔╝█████╗  ██║  ██║██╔████╔██║██║   ██║██╔██╗ ██║██║  ██║██║
██╔══██╗██╔══╝  ██║  ██║██║╚██╔╝██║██║   ██║██║╚██╗██║██║  ██║██║
██║  ██║███████╗██████╔╝██║ ╚═╝ ██║╚██████╔╝██║ ╚████║██████╔╝██║
╚═╝  ╚═╝╚══════╝╚═════╝ ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═════╝ ╚═╝

        Windows-like Desktop Environment (KDE Plasma 6)
EOF
    echo -e "${NC}"
}

# Install Windows-like KDE configuration
configure_kde_redmond() {
    echo -e "${BLUE}Configuring KDE for Windows-like experience...${NC}"
    sleep 3

    # Clear any existing theme markers first
    echo -e "${YELLOW}Clearing previous theme markers...${NC}"
    kwriteconfig5 --file kdeglobals --group Archer --key ThemeType --delete 2>/dev/null || true

    # Set global theme, icons, fonts, and panel layout for Windows-like look
    echo -e "${YELLOW}Setting global theme to Breeze...${NC}"
    kwriteconfig5 --file kdeglobals --group KDE --key LookAndFeelPackage "org.kde.breeze.desktop"

    echo -e "${YELLOW}Setting plasma theme to Breeze...${NC}"
    kwriteconfig5 --file plasmarc --group Theme --key name "default"

    # Set a marker for Redmondi theme detection
    echo -e "${YELLOW}Setting Redmondi theme marker...${NC}"
    kwriteconfig5 --file kdeglobals --group Archer --key ThemeType "redmondi"

    # Window decoration - set to Breeze (Windows-like)
    echo -e "${YELLOW}Setting Windows-like window decoration...${NC}"
    kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key library "org.kde.breeze.decoration"
    kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key theme "Breeze"

    # Reset any McMojave window decoration settings
    kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft ""
    kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight "IAX"

    echo -e "${YELLOW}Setting Windows 10 icon theme...${NC}"
    kwriteconfig5 --file kdeglobals --group Icons --key Theme "Windows10"

    # Set cursor theme to default Breeze (not macOS cursors)
    echo -e "${YELLOW}Setting cursor theme...${NC}"
    kwriteconfig5 --file kdeglobals --group General --key cursorTheme "breeze_cursors"

    echo -e "${YELLOW}Setting Liberation Sans fonts...${NC}"
    kwriteconfig5 --file kdeglobals --group General --key font "Liberation Sans,11,-1,5,50,0,0,0,0,0"
    kwriteconfig5 --file kdeglobals --group General --key menuFont "Liberation Sans,11,-1,5,50,0,0,0,0,0"
    kwriteconfig5 --file kdeglobals --group General --key toolBarFont "Liberation Sans,10,-1,5,50,0,0,0,0,0"
    kwriteconfig5 --file kdeglobals --group WM --key activeFont "Liberation Sans,11,-1,5,75,0,0,0,0,0"

    # Panel: Windows-like taskbar
    echo -e "${YELLOW}Configuring Windows-like taskbar...${NC}"
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
    echo -e "${GREEN}KDE configuration completed!${NC}"
}

main() {
    show_logo

    # Check prerequisites
    if ! check_kde_installed; then
        exit 1
    fi

    echo -e "${CYAN}This will configure a Windows-like desktop using KDE Plasma 6.${NC}"
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
        echo -e "${YELLOW}Configuration will be applied after login to KDE.${NC}"
        create_autostart_entry "Redmondi" "$(readlink -f "$0") --configure-only" "$0"
    fi

    show_completion "Redmondi KDE Configuration Complete!" "\
🪟 Windows-like KDE Plasma Desktop Installed:
- KDE Plasma 6 with Windows-like layout
- Breeze theme and Windows 10 icons
- Windows-like fonts and taskbar

📋 Next Steps:
1. Reboot or log out and back in to KDE
2. The desktop will auto-configure on first login
3. Customize further using System Settings
4. Install office suite: ./office-tools/office-suite.sh

🎉 Welcome to your Windows-like Arch Linux desktop!"

    wait_for_input "Press Enter to continue..."
}

if [[ "$1" == "--configure-only" ]]; then
    configure_kde_redmond
    exit 0
fi

main

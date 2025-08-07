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

    # Install additional packages for window decorations
    echo -e "${YELLOW}Installing window decoration packages...${NC}"
    install_packages breeze kde-cli-tools

    # Install AUR helper if not present
    install_aur_helper

    # Install Windows icon theme from AUR
    echo -e "${YELLOW}Installing Windows 10 icon theme...${NC}"
    install_aur_packages windows10-icon-theme

    # Try to install Windows-like window decorations
    echo -e "${YELLOW}Installing Windows-like window decorations...${NC}"
    local windows_decorations=(
        "lightly" "kvantum"
    )

    for decoration in "${windows_decorations[@]}"; do
        echo -e "${CYAN}Attempting to install $decoration...${NC}"
        install_aur_packages "$decoration" || echo -e "${YELLOW}⚠ Could not install $decoration (may not be available)${NC}"
    done

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

# Install missing X11/Qt dependencies
install_qt_dependencies() {
    echo -e "${BLUE}Installing Qt/X11 dependencies...${NC}"

    local qt_deps=(
        "libxcb" "xcb-util-cursor" "qt6-base" "qt6-svg"
        "libx11" "libxext" "libxfixes" "libxi" "libxrender"
        "xcb-util-cursor"
    )

    install_packages "${qt_deps[@]}"
    echo -e "${GREEN}Qt/X11 dependencies installed!${NC}"
}

# Install Windows-like KDE configuration
configure_kde_redmond() {
    echo -e "${BLUE}Configuring KDE for Windows-like experience...${NC}"

    # Check if we're in a proper KDE session
    if [[ -z "$DISPLAY" ]] && [[ -z "$WAYLAND_DISPLAY" ]]; then
        echo -e "${RED}Error: No display server detected (neither X11 nor Wayland)${NC}"
        echo -e "${YELLOW}This script should be run from within a KDE Plasma session.${NC}"
        echo -e "${CYAN}Please log into KDE Plasma and run this script again.${NC}"
        return 1
    fi

    # Check if KDE tools are available and working
    if ! command -v kwriteconfig5 &> /dev/null; then
        echo -e "${RED}Error: kwriteconfig5 not found. KDE Plasma may not be properly installed.${NC}"
        return 1
    fi

    # Test if Qt/KDE commands work
    echo -e "${BLUE}Testing KDE configuration access...${NC}"
    if ! kwriteconfig5 --file test-config --group Test --key TestKey "test" 2>/dev/null; then
        echo -e "${RED}Error: Cannot access KDE configuration system.${NC}"
        echo -e "${YELLOW}Qt platform error detected. Possible causes:${NC}"
        echo -e "${CYAN}  1. Not running in a KDE session${NC}"
        echo -e "${CYAN}  2. Missing X11/Wayland libraries${NC}"
        echo -e "${CYAN}  3. Session environment not properly set${NC}"
        echo ""
        echo -e "${YELLOW}Solutions to try:${NC}"
        echo -e "${CYAN}  1. Log out and log into KDE Plasma session${NC}"
        echo -e "${CYAN}  2. Run: export DISPLAY=:0 (if using X11)${NC}"
        echo -e "${CYAN}  3. Install missing packages: sudo pacman -S libxcb xcb-util-cursor${NC}"
        return 1
    else
        # Clean up test config
        kwriteconfig5 --file test-config --group Test --key TestKey --delete 2>/dev/null || true
        echo -e "${GREEN}✓ KDE configuration system accessible${NC}"
    fi

    sleep 3

    # Set a marker for Redmondi theme detection
    echo -e "${YELLOW}Setting Redmondi theme marker...${NC}"
    kwriteconfig5 --file kdeglobals --group Archer --key ThemeType "redmondi" 2>/dev/null || true
    echo -e "${GREEN}✓ Theme marker set${NC}"

    # Set global theme, icons, fonts, and panel layout for Windows-like look
    echo -e "${YELLOW}Setting global theme to Breeze...${NC}"
    if kwriteconfig5 --file kdeglobals --group KDE --key LookAndFeelPackage "org.kde.breeze.desktop" 2>/dev/null; then
        echo -e "${GREEN}✓ Global theme set to Breeze${NC}"
    else
        echo -e "${RED}✗ Failed to set global theme${NC}"
    fi

    echo -e "${YELLOW}Setting plasma theme to Breeze...${NC}"
    if kwriteconfig5 --file plasmarc --group Theme --key name "default" 2>/dev/null; then
        echo -e "${GREEN}✓ Plasma theme set to default (Breeze)${NC}"
    else
        echo -e "${RED}✗ Failed to set plasma theme${NC}"
    fi

    # Window decoration (Windows-like)
    echo -e "${YELLOW}Setting Windows-like window decoration...${NC}"

    # Use Breeze decoration for Windows-like experience
    if kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key library "org.kde.breeze.decoration" 2>/dev/null && \
       kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key theme "Breeze" 2>/dev/null; then
        echo -e "${GREEN}✓ Breeze window decoration set${NC}"
    else
        echo -e "${RED}✗ Failed to set window decoration${NC}"
    fi

    # Configure Windows-like window button layout (minimize, maximize, close on right)
    echo -e "${YELLOW}Setting Windows-like window button layout...${NC}"
    kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft "M" 2>/dev/null || true
    kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight "IAX" 2>/dev/null || true

    # Configure window behavior for Windows-like experience
    kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ShowToolTips "true" 2>/dev/null || true

    # Set Breeze decoration settings for Windows-like appearance
    kwriteconfig5 --file breezerc --group Common --key OutlineCloseButton "false" 2>/dev/null || true
    kwriteconfig5 --file breezerc --group Windeco --key DrawBackgroundGradient "true" 2>/dev/null || true
    kwriteconfig5 --file breezerc --group Windeco --key DrawTitleBarSeparator "true" 2>/dev/null || true
    kwriteconfig5 --file breezerc --group Windeco --key TitleAlignment "1" 2>/dev/null || true  # Left alignment like Windows

    # Configure window shadows for Windows-like effect
    kwriteconfig5 --file kwinrc --group Effect-kwin4_effect_shadow --key ShadowColor "0,0,0" 2>/dev/null || true
    kwriteconfig5 --file kwinrc --group Effect-kwin4_effect_shadow --key ShadowStrength "25" 2>/dev/null || true

    # Clear any McMojave window decoration settings
    echo -e "${GREEN}✓ Windows-like window decoration configured${NC}"    echo -e "${YELLOW}Setting Windows 10 icon theme...${NC}"
    if kwriteconfig5 --file kdeglobals --group Icons --key Theme "Windows10" 2>/dev/null; then
        echo -e "${GREEN}✓ Icon theme set to Windows10${NC}"
    else
        echo -e "${RED}✗ Failed to set icon theme${NC}"
    fi

    # Set cursor theme to default Breeze (not macOS cursors)
    echo -e "${YELLOW}Setting cursor theme...${NC}"
    if kwriteconfig5 --file kdeglobals --group General --key cursorTheme "breeze_cursors" 2>/dev/null; then
        echo -e "${GREEN}✓ Cursor theme set to breeze_cursors${NC}"
    else
        echo -e "${RED}✗ Failed to set cursor theme${NC}"
    fi

    echo -e "${YELLOW}Setting Liberation Sans fonts...${NC}"
    if kwriteconfig5 --file kdeglobals --group General --key font "Liberation Sans,11,-1,5,50,0,0,0,0,0" 2>/dev/null && \
       kwriteconfig5 --file kdeglobals --group General --key menuFont "Liberation Sans,11,-1,5,50,0,0,0,0,0" 2>/dev/null && \
       kwriteconfig5 --file kdeglobals --group General --key toolBarFont "Liberation Sans,10,-1,5,50,0,0,0,0,0" 2>/dev/null && \
       kwriteconfig5 --file kdeglobals --group WM --key activeFont "Liberation Sans,11,-1,5,75,0,0,0,0,0" 2>/dev/null; then
        echo -e "${GREEN}✓ Liberation Sans fonts set${NC}"
    else
        echo -e "${RED}✗ Failed to set Liberation Sans fonts${NC}"
    fi

    # Panel: Windows-like taskbar (single panel)
    echo -e "${YELLOW}Configuring Windows-like taskbar...${NC}"

    # Ensure all panels are removed first
    qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
        var allPanels = panels();
        for (var i = 0; i < allPanels.length; ++i) {
            allPanels[i].remove();
        }
    ' 2>/dev/null || echo "Could not remove existing panels"

    sleep 3

    # Create single Windows-like taskbar
    qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
        var taskbar = new Panel;
        if (taskbar) {
            taskbar.location = "bottom";
            taskbar.height = 40;
            taskbar.lengthMode = "FitWidth";
            taskbar.alignment = "left";

            // Add start menu
            taskbar.addWidget("org.kde.plasma.kickoff");

            // Add taskbar
            var iconTasks = taskbar.addWidget("org.kde.plasma.icontasks");
            if (iconTasks) {
                iconTasks.currentConfigGroup = ["General"];
                iconTasks.writeConfig("groupingStrategy", 1);
                iconTasks.writeConfig("showOnlyCurrentDesktop", false);
            }

            // Add system tray
            taskbar.addWidget("org.kde.plasma.systemtray");

            // Add clock
            taskbar.addWidget("org.kde.plasma.digitalclock");
        }
    ' 2>/dev/null || echo "Panel configuration failed, using fallback"

    # Fallback: Create basic panel configuration file
    cat > "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" << 'EOF'
[ActionPlugins][0]
RightButton;NoModifier=org.kde.contextmenu

[Containments][1]
activityId=
formfactor=2
immutability=1
lastScreen=0
location=4
plugin=org.kde.panel
wallpaperplugin=org.kde.image

[Containments][1][Applets][2]
immutability=1
plugin=org.kde.plasma.kickoff

[Containments][1][Applets][3]
immutability=1
plugin=org.kde.plasma.icontasks

[Containments][1][Applets][4]
immutability=1
plugin=org.kde.plasma.systemtray

[Containments][1][Applets][5]
immutability=1
plugin=org.kde.plasma.digitalclock

[Containments][1][General]
AppletOrder=2;3;4;5

[Containments][1][Configuration]
PreloadWeight=100

[Containments][1][Configuration][General]
alignment=132
iconSize=22
lengthMode=2
panelSize=40
panelVisibility=0

[ScreenMapping]
itemsOnDisabledScreens=
screenMapping=
EOF

    echo -e "${GREEN}Windows-like taskbar configured!${NC}"

    echo -e "${GREEN}KDE configuration completed!${NC}"
    echo -e "${YELLOW}Note: Theme changes will take full effect after a reboot.${NC}"
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

    # Install Qt dependencies to prevent display errors
    install_qt_dependencies

    # Install themes
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

    local completion_msg="🪟 Windows-like KDE Plasma Desktop Installed:
- KDE Plasma 6 with Windows-like layout
- Breeze theme and Windows 10 icons
- Windows-like fonts and taskbar

📋 Next Steps:
1. Reboot to apply all theme changes completely
2. Install office suite: ./office-tools/office-suite.sh
3. Customize further using System Settings

🎉 Welcome to your Windows-like Arch Linux desktop!"

    show_completion "Redmondi KDE Configuration Complete!" "$completion_msg"

    echo ""
    echo -e "${YELLOW}⚠ Theme changes require a reboot to take full effect.${NC}"
    echo ""

    if confirm_action "Would you like to reboot now to apply all theme changes?"; then
        echo -e "${BLUE}Rebooting in 3 seconds...${NC}"
        sleep 1
        echo -e "${BLUE}Rebooting in 2 seconds...${NC}"
        sleep 1
        echo -e "${BLUE}Rebooting in 1 second...${NC}"
        sleep 1
        sudo reboot
    else
        echo -e "${CYAN}Remember to reboot later to apply all theme changes completely.${NC}"
        wait_for_input "Press Enter to continue..."
    fi
}

# Handle configuration-only mode
if [[ "$1" == "--configure-only" ]]; then
    configure_kde_redmond
    exit 0
fi

# Run main function
main



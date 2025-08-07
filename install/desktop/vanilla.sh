#!/bin/bash

# Vanilla Theme Installer - Default KDE Plasma 6 Theme
# Part of Archer - Arch Linux Home PC Transformation Suite

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/..}/install/system/common-funcs.sh"

# Install default KDE themes and fonts
install_default_themes() {
    echo -e "${BLUE}Installing default KDE themes and fonts...${NC}"

    # Install default packages from official repos
    echo -e "${YELLOW}Installing default fonts and themes...${NC}"
    install_packages ttf-dejavu ttf-liberation noto-fonts

    # Install default KDE packages
    echo -e "${YELLOW}Installing default KDE packages...${NC}"
    install_packages breeze breeze-gtk kde-cli-tools plasma-desktop

    echo -e "${GREEN}Default KDE themes installed!${NC}"
}

show_logo() {
    echo -e "${BLUE}"
    cat << "EOF"
██╗   ██╗ █████╗ ███╗   ██╗██╗██╗     ██╗      █████╗
██║   ██║██╔══██╗████╗  ██║██║██║     ██║     ██╔══██╗
██║   ██║███████║██╔██╗ ██║██║██║     ██║     ███████║
╚██╗ ██╔╝██╔══██║██║╚██╗██║██║██║     ██║     ██╔══██║
 ╚████╔╝ ██║  ██║██║ ╚████║██║███████╗███████╗██║  ██║
  ╚═══╝  ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝╚══════╝╚══════╝╚═╝  ╚═╝

        Default KDE Plasma 6 Desktop Environment
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

# Configure KDE for default vanilla experience
configure_kde_vanilla() {
    echo -e "${BLUE}Configuring KDE for default vanilla experience...${NC}"

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

    # Set a marker for Vanilla theme detection
    echo -e "${YELLOW}Setting Vanilla theme marker...${NC}"
    kwriteconfig5 --file kdeglobals --group Archer --key ThemeType "vanilla" 2>/dev/null || true
    echo -e "${GREEN}✓ Theme marker set${NC}"

    # Set default global theme
    echo -e "${YELLOW}Setting default global theme to Breeze...${NC}"
    if kwriteconfig5 --file kdeglobals --group KDE --key LookAndFeelPackage "org.kde.breeze.desktop" 2>/dev/null; then
        echo -e "${GREEN}✓ Global theme set to Breeze${NC}"
    else
        echo -e "${RED}✗ Failed to set global theme${NC}"
    fi

    echo -e "${YELLOW}Setting plasma theme to default...${NC}"
    if kwriteconfig5 --file plasmarc --group Theme --key name "default" 2>/dev/null; then
        echo -e "${GREEN}✓ Plasma theme set to default${NC}"
    else
        echo -e "${RED}✗ Failed to set plasma theme${NC}"
    fi

    # Window decoration (default Breeze)
    echo -e "${YELLOW}Setting default window decoration...${NC}"
    if kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key library "org.kde.breeze.decoration" 2>/dev/null && \
       kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key theme "Breeze" 2>/dev/null; then
        echo -e "${GREEN}✓ Breeze window decoration set${NC}"
    else
        echo -e "${RED}✗ Failed to set window decoration${NC}"
    fi

    # Configure default window button layout (minimize, maximize, close on right)
    echo -e "${YELLOW}Setting default window button layout...${NC}"
    kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft "M" 2>/dev/null || true
    kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight "IAX" 2>/dev/null || true

    # Configure window behavior for default experience
    kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ShowToolTips "true" 2>/dev/null || true

    # Reset any custom Breeze decoration settings to defaults
    kwriteconfig5 --file breezerc --group Common --key OutlineCloseButton --delete 2>/dev/null || true
    kwriteconfig5 --file breezerc --group Windeco --key DrawBackgroundGradient --delete 2>/dev/null || true
    kwriteconfig5 --file breezerc --group Windeco --key DrawTitleBarSeparator --delete 2>/dev/null || true
    kwriteconfig5 --file breezerc --group Windeco --key TitleAlignment --delete 2>/dev/null || true

    echo -e "${GREEN}✓ Default window decoration configured${NC}"

    # Set default icon theme
    echo -e "${YELLOW}Setting default icon theme...${NC}"
    if kwriteconfig5 --file kdeglobals --group Icons --key Theme "breeze" 2>/dev/null; then
        echo -e "${GREEN}✓ Icon theme set to Breeze${NC}"
    else
        echo -e "${RED}✗ Failed to set icon theme${NC}"
    fi

    # Set default cursor theme
    echo -e "${YELLOW}Setting default cursor theme...${NC}"
    if kwriteconfig5 --file kdeglobals --group General --key cursorTheme "breeze_cursors" 2>/dev/null; then
        echo -e "${GREEN}✓ Cursor theme set to Breeze${NC}"
    else
        echo -e "${RED}✗ Failed to set cursor theme${NC}"
    fi

    # Set default fonts
    echo -e "${YELLOW}Setting default system fonts...${NC}"
    if kwriteconfig5 --file kdeglobals --group General --key font "Noto Sans,10,-1,5,50,0,0,0,0,0" 2>/dev/null && \
       kwriteconfig5 --file kdeglobals --group General --key menuFont "Noto Sans,10,-1,5,50,0,0,0,0,0" 2>/dev/null && \
       kwriteconfig5 --file kdeglobals --group General --key toolBarFont "Noto Sans,9,-1,5,50,0,0,0,0,0" 2>/dev/null && \
       kwriteconfig5 --file kdeglobals --group WM --key activeFont "Noto Sans,10,-1,5,75,0,0,0,0,0" 2>/dev/null; then
        echo -e "${GREEN}✓ Default fonts set${NC}"
    else
        echo -e "${RED}✗ Failed to set default fonts${NC}"
    fi

    # Panel: Default KDE layout (single bottom panel)
    echo -e "${YELLOW}Configuring default KDE panel layout...${NC}"

    # Remove any existing panels first
    qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
        var allPanels = panels();
        for (var i = 0; i < allPanels.length; ++i) {
            allPanels[i].remove();
        }
    ' 2>/dev/null || echo "Could not remove existing panels"

    sleep 3

    # Create default single bottom panel
    qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
        var panel = new Panel;
        if (panel) {
            panel.location = "bottom";
            panel.height = 44;
            panel.lengthMode = "FitWidth";
            panel.alignment = "left";

            // Add application launcher
            panel.addWidget("org.kde.plasma.kickoff");

            // Add pager (virtual desktop indicator)
            panel.addWidget("org.kde.plasma.pager");

            // Add taskbar
            var iconTasks = panel.addWidget("org.kde.plasma.icontasks");
            if (iconTasks) {
                iconTasks.currentConfigGroup = ["General"];
                iconTasks.writeConfig("groupingStrategy", 1);
                iconTasks.writeConfig("showOnlyCurrentDesktop", false);
            }

            // Add system tray
            panel.addWidget("org.kde.plasma.systemtray");

            // Add clock
            panel.addWidget("org.kde.plasma.digitalclock");

            // Add show desktop button
            panel.addWidget("org.kde.plasma.showdesktop");
        }
    ' 2>/dev/null || echo "Panel configuration failed, using fallback"

    # Fallback: Create basic default panel configuration file
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
plugin=org.kde.plasma.pager

[Containments][1][Applets][4]
immutability=1
plugin=org.kde.plasma.icontasks

[Containments][1][Applets][5]
immutability=1
plugin=org.kde.plasma.systemtray

[Containments][1][Applets][6]
immutability=1
plugin=org.kde.plasma.digitalclock

[Containments][1][Applets][7]
immutability=1
plugin=org.kde.plasma.showdesktop

[Containments][1][General]
AppletOrder=2;3;4;5;6;7

[Containments][1][Configuration]
PreloadWeight=100

[Containments][1][Configuration][General]
alignment=132
iconSize=22
lengthMode=2
panelSize=44
panelVisibility=0

[ScreenMapping]
itemsOnDisabledScreens=
screenMapping=
EOF

    echo -e "${GREEN}Default KDE panel layout configured!${NC}"

    # Reset desktop effects to defaults
    echo -e "${YELLOW}Resetting desktop effects to defaults...${NC}"
    kwriteconfig5 --file kwinrc --group Compositing --key Enabled "true"
    kwriteconfig5 --file kwinrc --group Compositing --key AnimationSpeed "3"
    kwriteconfig5 --file kwinrc --group Plugins --key slideEnabled "true"
    kwriteconfig5 --file kwinrc --group Plugins --key kwin4_effect_fadeEnabled "true"

    # Reset window behavior to defaults
    echo -e "${YELLOW}Resetting window behavior to defaults...${NC}"
    kwriteconfig5 --file kwinrc --group Windows --key FocusPolicy "ClickToFocus"
    kwriteconfig5 --file kwinrc --group MouseBindings --key CommandAllKey "Meta"
    kwriteconfig5 --file kwinrc --group Windows --key BorderlessMaximizedWindows "false"

    # Reset to default wallpaper
    echo -e "${YELLOW}Setting default wallpaper...${NC}"
    plasma-apply-wallpaperimage "/usr/share/wallpapers/Next/contents/images/2560x1600.png" 2>/dev/null || \
    plasma-apply-wallpaperimage "/usr/share/wallpapers/Flow/contents/images/2560x1600.png" 2>/dev/null || true

    echo -e "${GREEN}KDE configuration completed!${NC}"
    echo -e "${YELLOW}Note: Theme changes will take full effect after a reboot.${NC}"
}

main() {
    show_logo

    # Check prerequisites
    if ! check_kde_installed; then
        exit 1
    fi

    echo -e "${CYAN}This will configure the default vanilla KDE Plasma 6 desktop.${NC}"
    echo ""
    if ! confirm_action "Continue with Vanilla KDE configuration?"; then
        exit 0
    fi

    # Install Qt dependencies to prevent display errors
    install_qt_dependencies

    # Install default themes
    install_default_themes

    # Reset settings to clean state
    reset_kde_settings

    # Only configure if in KDE session
    if [[ "$XDG_CURRENT_DESKTOP" == "KDE" ]] && [[ -n "$DISPLAY" ]]; then
        configure_kde_vanilla
    else
        echo -e "${YELLOW}Configuration will be applied after login to KDE.${NC}"
        create_autostart_entry "Vanilla" "$(readlink -f "$0") --configure-only" "$0"
    fi

    local completion_msg="🐧 Default KDE Plasma Desktop Configured:
- Clean vanilla KDE Plasma 6 layout
- Default Breeze theme and icons
- Standard KDE fonts and panel layout

📋 Next Steps:
1. Reboot to apply all theme changes completely
2. Enjoy the clean, default KDE experience
3. Install office suite: ./office-tools/office-suite.sh
4. Customize further using System Settings

🎉 Welcome to vanilla KDE Plasma!"

    show_completion "Vanilla KDE Configuration Complete!" "$completion_msg"

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
    configure_kde_vanilla
    exit 0
fi

# Run main function
main

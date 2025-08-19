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

# Configure KDE for vanilla (default) experience (configuration only - requires reboot)
configure_kde_vanilla() {
    echo -e "${BLUE}Configuring KDE for vanilla (default) experience...${NC}"
    echo -e "${YELLOW}⚠ This will configure the theme files only. A reboot is required to apply changes.${NC}"

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


    # Panel configuration (default KDE layout - single bottom panel)
    echo -e "${YELLOW}Writing default KDE panel configuration...${NC}"
    python3 << 'EOF'
import os
config_dir = os.path.expanduser("~/.config")
plasma_config = os.path.join(config_dir, "plasma-org.kde.plasma.desktop-appletsrc")
os.makedirs(config_dir, exist_ok=True)
default_config = """[ActionPlugins][0]
RightButton;NoModifier=org.kde.contextmenu
[ActionPlugins][1]
RightButton;NoModifier=org.kde.contextmenu
[Containments][1]
activityId=
formfactor=0
immutability=1
lastScreen=0
location=0
plugin=org.kde.plasma.desktop
wallpaperplugin=org.kde.image
[Containments][1][ConfigDialog]
DialogHeight=540
DialogWidth=720
[Containments][1][General]
ToolBoxButtonState=topright
ToolBoxButtonX=555
ToolBoxButtonY=30
[Containments][1][Wallpaper][org.kde.image][General]
Image=file:///usr/share/wallpapers/Next/contents/images/2560x1600.png
SlidePaths=/usr/share/wallpapers
[Containments][2]
activityId=
formfactor=2
immutability=1
lastScreen=0
location=4
plugin=org.kde.panel
wallpaperplugin=org.kde.image
[Containments][2][Applets][5]
immutability=1
plugin=org.kde.plasma.icontasks
[Containments][2][Applets][5][Configuration]
PreloadWeight=100
[Containments][2][Applets][5][Configuration][General]
groupingStrategy=1
iconSpacing=2
launchers=applications:systemsettings.desktop,applications:org.kde.dolphin.desktop,applications:firefox.desktop,applications:org.kde.konsole.desktop
maxStripes=1
showOnlyCurrentDesktop=false
[Containments][2][General]
AppletOrder=5
[Containments][2][General]
AppletOrder=3;4;5;6;7;8
[Containments][2][Configuration]
PreloadWeight=100
[Containments][2][Configuration][General]
alignment=132
iconSize=22
lengthMode=2
panelSize=44
panelVisibility=0
floating=0
[ScreenMapping]
itemsOnDisabledScreens=
screenMapping=desktop:/home,0,desktop:/Downloads,0,desktop:/tmp,0
"""
with open(plasma_config, 'w') as f:
    f.write(default_config)
EOF

    # Robustness: ensure appletsrc exists and is non-empty, else let Plasma regenerate
    APPLETSRC="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
    if [[ ! -s "$APPLETSRC" ]]; then
        echo -e "${YELLOW}Appletsrc missing or empty, letting Plasma regenerate...${NC}"
        rm -f "$APPLETSRC"
        killall plasmashell 2>/dev/null
        (sleep 2 && plasmashell --replace &) &
        sleep 5
    fi

    echo -e "${GREEN}Default KDE panel configuration written!${NC}"

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

    # Reset to default wallpaper configuration
    echo -e "${YELLOW}Writing default wallpaper configuration...${NC}"
    kwriteconfig5 --file kdeglobals --group Wallpaper --key Image "/usr/share/wallpapers/Next/contents/images/2560x1600.png" 2>/dev/null || \
    kwriteconfig5 --file kdeglobals --group Wallpaper --key Image "/usr/share/wallpapers/Flow/contents/images/2560x1600.png" 2>/dev/null || true

    echo -e "${GREEN}✓ Vanilla KDE configuration completed!${NC}"
    echo -e "${YELLOW}⚠ All changes will take effect after reboot${NC}"
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

    # Update system
    update_system

    # Reset settings to clean state
    reset_kde_settings

    # Install Qt dependencies to prevent display errors
    install_qt_dependencies

    # Install default themes
    install_default_themes

    # Configure (theme files only - no dynamic application)
    configure_kde_vanilla

    local completion_msg="🐧 Default KDE Plasma Desktop Configured:
- Clean vanilla KDE Plasma 6 layout
- Default Breeze theme and icons
- Standard KDE fonts and panel layout
- Single bottom taskbar with standard widgets

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

# Run main function
main

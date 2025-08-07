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

# Configure KDE for Windows-like experience (configuration only - requires reboot)
configure_kde_redmond() {
    echo -e "${BLUE}Configuring KDE for Windows-like experience...${NC}"
    echo -e "${YELLOW}⚠ This will configure the theme files only. A reboot is required to apply changes.${NC}"

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

    # Panel configuration (Windows-like taskbar)
    echo -e "${YELLOW}Writing Windows-like taskbar configuration...${NC}"

    # Create proper Windows-like panel configuration
    python3 << 'EOF'
import os

# Create/modify panel configuration for Windows-like layout
config_dir = os.path.expanduser("~/.config")
plasma_config = os.path.join(config_dir, "plasma-org.kde.plasma.desktop-appletsrc")

# Ensure config directory exists
os.makedirs(config_dir, exist_ok=True)

# Create Windows-like panel configuration (desktop + single bottom taskbar)
windows_config = """[ActionPlugins][0]
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
Image=file:///usr/share/wallpapers/Flow/contents/images/2560x1600.png
SlidePaths=/usr/share/wallpapers

[Containments][2]
activityId=
formfactor=2
immutability=1
lastScreen=0
location=4
plugin=org.kde.panel
wallpaperplugin=org.kde.image

[Containments][2][Applets][3]
immutability=1
plugin=org.kde.plasma.kickoff

[Containments][2][Applets][3][Configuration]
PreloadWeight=100

[Containments][2][Applets][3][Configuration][General]
icon=start-here-kde
useCustomButtonImage=false

[Containments][2][Applets][4]
immutability=1
plugin=org.kde.plasma.icontasks

[Containments][2][Applets][4][Configuration]
PreloadWeight=100

[Containments][2][Applets][4][Configuration][General]
groupingStrategy=1
iconSpacing=2
launchers=applications:systemsettings.desktop,applications:org.kde.dolphin.desktop,applications:firefox.desktop,applications:org.kde.konsole.desktop
maxStripes=1
showOnlyCurrentDesktop=false

[Containments][2][Applets][5]
immutability=1
plugin=org.kde.plasma.systemtray

[Containments][2][Applets][5][Configuration]
PreloadWeight=100

[Containments][2][Applets][6]
immutability=1
plugin=org.kde.plasma.digitalclock

[Containments][2][Applets][6][Configuration]
PreloadWeight=100

[Containments][2][Applets][6][Configuration][Appearance]
showDate=true
use24hFormat=2

[Containments][2][General]
AppletOrder=3;4;5;6

[Containments][2][Configuration]
PreloadWeight=100

[Containments][2][Configuration][General]
alignment=132
iconSize=24
lengthMode=2
panelSize=40
panelVisibility=0
floating=0

[ScreenMapping]
itemsOnDisabledScreens=
screenMapping=desktop:/home,0,desktop:/Downloads,0,desktop:/tmp,0
"""

with open(plasma_config, 'w') as f:
    f.write(windows_config)

print("Windows-like configuration written (desktop + single bottom taskbar)")
EOF

    echo -e "${GREEN}Windows-like taskbar configuration written!${NC}"

    # Desktop effects configuration (for smooth Windows-like experience)
    echo -e "${YELLOW}Writing desktop effects configuration...${NC}"
    kwriteconfig5 --file kwinrc --group Compositing --key Enabled "true" 2>/dev/null || true
    kwriteconfig5 --file kwinrc --group Compositing --key AnimationSpeed "3" 2>/dev/null || true
    kwriteconfig5 --file kwinrc --group Plugins --key slideEnabled "true" 2>/dev/null || true
    kwriteconfig5 --file kwinrc --group Plugins --key kwin4_effect_fadeEnabled "true" 2>/dev/null || true

    # Window behavior configuration (Windows-like)
    echo -e "${YELLOW}Writing window behavior configuration...${NC}"
    kwriteconfig5 --file kwinrc --group Windows --key FocusPolicy "ClickToFocus" 2>/dev/null || true
    kwriteconfig5 --file kwinrc --group MouseBindings --key CommandAllKey "Meta" 2>/dev/null || true
    kwriteconfig5 --file kwinrc --group Windows --key BorderlessMaximizedWindows "false" 2>/dev/null || true

    # Set Windows-like wallpaper configuration
    echo -e "${YELLOW}Writing Windows-like wallpaper configuration...${NC}"
    kwriteconfig5 --file kdeglobals --group Wallpaper --key Image "/usr/share/wallpapers/Flow/contents/images/2560x1600.png" 2>/dev/null || true

    echo -e "${GREEN}✓ Redmondi KDE configuration completed!${NC}"
    echo -e "${YELLOW}⚠ All changes will take effect after reboot${NC}"
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

    # Update system
    update_system

    # Reset settings to avoid conflicts
    reset_kde_settings

    # Install Qt dependencies to prevent display errors
    install_qt_dependencies

    # Install themes
    install_windows_themes

    # Configure (theme files only - no dynamic application)
    configure_kde_redmond

    local completion_msg="🪟 Windows-like KDE Plasma Desktop Configured:
- KDE Plasma 6 with Windows-like layout
- Breeze theme and Windows 10 icons
- Liberation Sans fonts and Windows-like taskbar
- Single bottom taskbar with Windows-style widgets

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

# Run main function
main



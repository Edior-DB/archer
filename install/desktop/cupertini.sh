#!/bin/bash

# Cupertini Theme Installer - macOS-like KDE Plasma 6 Theme
# Part of Archer - Arch Linux Home PC Transformation Suite

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/..}/install/system/common-funcs.sh"

# Show logo
show_logo() {
    echo -e "${BLUE}"
    cat << "EOF"
 ██████╗██╗   ██╗██████╗ ███████╗██████╗ ████████╗██╗███╗   ██╗██╗
██╔════╝██║   ██║██╔══██╗██╔════╝██╔══██╗╚══██╔══╝██║████╗  ██║██║
██║     ██║   ██║██████╔╝█████╗  ██████╔╝   ██║   ██║██╔██╗ ██║██║
██║     ██║   ██║██╔═══╝ ██╔══╝  ██╔══██╗   ██║   ██║██║╚██╗██║██║
╚██████╗╚██████╔╝██║     ███████╗██║  ██║   ██║   ██║██║ ╚████║██║
 ╚═════╝ ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝╚═╝  ╚═══╝╚═╝

        macOS-like Desktop Environment (KDE Plasma)
EOF
    echo -e "${NC}"
}


# Install essential KDE applications
install_essential_apps() {
    echo -e "${BLUE}Installing essential KDE applications...${NC}"

    local apps=(
        # File manager and utilities
        "dolphin" "ark" "kdeconnect" "kdenetwork-filesharing"
        # Text editors
        "kate" "kwrite"
        # System utilities
        "systemsettings" "kcalc" "spectacle" "kfind" "kcharselect" "kde-cli-tools"
        # Multimedia
        "dragon" "elisa" "gwenview" "okular"
        # Web browser
        "firefox"
        # Graphics
        "krita" "kolourpaint"
        # Terminal
        "konsole"
        # Network
        "plasma-nm" "plasma-pa"
        # System monitor
        "plasma-systemmonitor"
        # Bluetooth
        "bluedevil"
    )

    install_packages "${apps[@]}"

    # Install kdeplasma-addons from official repo (replacement for plasma-widgets-addons)
    echo -e "${YELLOW}Installing kdeplasma-addons (official Plasma widgets package)...${NC}"
    install_packages kdeplasma-addons

    echo -e "${GREEN}Essential KDE applications installed!${NC}"
}

# Install macOS-like themes and widgets
install_themes() {
    echo -e "${BLUE}Installing macOS-like themes and widgets...${NC}"

    # Install theme packages from official repos
    local theme_packages=(
        "breeze" "breeze-gtk" "kvantum" "papirus-icon-theme"
        "ttf-roboto" "ttf-dejavu" "noto-fonts" "noto-fonts-emoji" "ttf-liberation"
        "kde-cli-tools" "systemsettings"
    )

    install_packages "${theme_packages[@]}"

    # Install AUR helper if not present
    install_aur_helper

    # Install macOS-like themes from AUR
    local aur_themes=(
        "plasma6-theme-mcmojave-git" "mcmojave-cursors" "mcmojave-circle-icon-theme-git"
        "kvantum-theme-libadwaita-git" "plasma5-wallpapers-dynamic" "sddm-sugar-candy-git"
        "otf-apple-fonts"
    )

    install_aur_packages "${aur_themes[@]}"

    # Try to install additional macOS-like window decorations
    echo -e "${YELLOW}Installing additional macOS-like window decorations...${NC}"
    local additional_decorations=(
        "lightly" "kvantum"
    )

    for decoration in "${additional_decorations[@]}"; do
        echo -e "${CYAN}Attempting to install $decoration...${NC}"
        install_aur_packages "$decoration" || echo -e "${YELLOW}⚠ Could not install $decoration (may not be available)${NC}"
    done

    # Verify theme installation
    echo -e "${YELLOW}Verifying McMojave theme installation...${NC}"
    local theme_dirs=(
        "/usr/share/plasma/desktoptheme/mcmojave"
        "/usr/share/plasma/desktoptheme/McMojave"
        "$HOME/.local/share/plasma/desktoptheme/mcmojave"
        "$HOME/.local/share/plasma/desktoptheme/McMojave"
    )

    local theme_found=false
    for theme_dir in "${theme_dirs[@]}"; do
        if [[ -d "$theme_dir" ]]; then
            echo -e "${GREEN}✓ Found McMojave plasma theme in: $theme_dir${NC}"
            theme_found=true
            break
        fi
    done

    if [[ "$theme_found" != "true" ]]; then
        echo -e "${YELLOW}⚠ McMojave plasma theme not found in expected locations${NC}"
        echo -e "${YELLOW}  Theme installation may have failed - will use Breeze fallback${NC}"

        # List available plasma themes for debugging
        echo -e "${CYAN}Available plasma themes:${NC}"
        if [[ -d "/usr/share/plasma/desktoptheme" ]]; then
            ls -1 /usr/share/plasma/desktoptheme/ | head -5
        fi
        if [[ -d "$HOME/.local/share/plasma/desktoptheme" ]]; then
            echo -e "${CYAN}User themes:${NC}"
            ls -1 "$HOME/.local/share/plasma/desktoptheme/" 2>/dev/null | head -5 || echo "None found"
        fi
    fi

    echo -e "${GREEN}macOS-like themes installed!${NC}"
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

# Configure KDE for macOS-like experience (configuration only - requires reboot)
configure_kde() {
    echo -e "${BLUE}Configuring KDE for macOS-like experience...${NC}"
    echo -e "${YELLOW}⚠ This will configure the theme files only. A reboot is required to apply changes.${NC}"

    # Set a marker for Cupertini theme detection
    echo -e "${YELLOW}Setting Cupertini theme marker...${NC}"
    kwriteconfig5 --file kdeglobals --group Archer --key ThemeType "cupertini" 2>/dev/null || true
    echo -e "${GREEN}✓ Theme marker set${NC}"

    # Check if McMojave look-and-feel package exists before trying to set it
    local global_theme=""
    if [[ -d "/usr/share/plasma/look-and-feel/mcmojave" ]] || [[ -d "$HOME/.local/share/plasma/look-and-feel/mcmojave" ]]; then
        global_theme="mcmojave"
    elif [[ -d "/usr/share/plasma/look-and-feel/McMojave" ]] || [[ -d "$HOME/.local/share/plasma/look-and-feel/McMojave" ]]; then
        global_theme="McMojave"
    else
        global_theme="org.kde.breezedark.desktop"
        echo -e "${YELLOW}⚠ McMojave look-and-feel not found, using breeze-dark fallback${NC}"
    fi

    # Write configuration files (no dynamic application)
    echo -e "${YELLOW}Writing theme configuration...${NC}"
    kwriteconfig5 --file kdeglobals --group KDE --key LookAndFeelPackage "$global_theme" 2>/dev/null || true

    # Check if McMojave themes exist before trying to set them
    local plasma_theme=""
    if [[ -d "/usr/share/plasma/desktoptheme/mcmojave" ]] || [[ -d "$HOME/.local/share/plasma/desktoptheme/mcmojave" ]]; then
        plasma_theme="mcmojave"
    elif [[ -d "/usr/share/plasma/desktoptheme/McMojave" ]] || [[ -d "$HOME/.local/share/plasma/desktoptheme/McMojave" ]]; then
        plasma_theme="McMojave"
    else
        plasma_theme="breeze-dark"
        echo -e "${YELLOW}⚠ McMojave plasma theme not found, using breeze-dark fallback${NC}"
    fi

    kwriteconfig5 --file plasmarc --group Theme --key name "$plasma_theme" 2>/dev/null || true

    # Window decoration (macOS-like) - configuration only
    echo -e "${YELLOW}Writing macOS-like window decoration configuration...${NC}"

    # First try McMojave window decoration if available
    if [[ -d "/usr/share/aurorae/themes/mcmojave" ]] || [[ -d "$HOME/.local/share/aurorae/themes/mcmojave" ]]; then
        echo -e "${CYAN}Configuring McMojave window decoration...${NC}"
        kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key library "org.kde.kwin.aurorae" 2>/dev/null || true
        kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key theme "__aurorae__svg__mcmojave" 2>/dev/null || true
    else
        # Fallback to Breeze with macOS-like configuration
        echo -e "${YELLOW}McMojave decoration not found, configuring Breeze with macOS-like settings...${NC}"
        kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key library "org.kde.breeze.decoration" 2>/dev/null || true
        kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key theme "Breeze" 2>/dev/null || true
    fi

    # Configure macOS-like window button layout (close, minimize, maximize on left)
    kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft "XIA" 2>/dev/null || true
    kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight "H" 2>/dev/null || true
    kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ShowToolTips "false" 2>/dev/null || true

    # Set window decoration colors to match macOS
    kwriteconfig5 --file breezerc --group Common --key OutlineCloseButton "true" 2>/dev/null || true
    kwriteconfig5 --file breezerc --group Windeco --key DrawBackgroundGradient "false" 2>/dev/null || true
    kwriteconfig5 --file breezerc --group Windeco --key DrawTitleBarSeparator "false" 2>/dev/null || true

    # Icons configuration
    echo -e "${YELLOW}Writing icon theme configuration...${NC}"
    kwriteconfig5 --file kdeglobals --group Icons --key Theme "McMojave-circle" 2>/dev/null || true

    # Cursors configuration
    echo -e "${YELLOW}Writing cursor theme configuration...${NC}"
    kwriteconfig5 --file kdeglobals --group General --key cursorTheme "McMojave-cursors" 2>/dev/null || true

    # Fonts configuration
    echo -e "${YELLOW}Writing font configuration...${NC}"
    # Try SF Pro Display first (from otf-apple-fonts)
    if fc-list | grep -i "SF Pro Display" > /dev/null; then
        echo -e "${GREEN}Using SF Pro Display fonts...${NC}"
        kwriteconfig5 --file kdeglobals --group General --key font "SF Pro Display,11,-1,5,50,0,0,0,0,0" 2>/dev/null || true
        kwriteconfig5 --file kdeglobals --group General --key menuFont "SF Pro Display,11,-1,5,50,0,0,0,0,0" 2>/dev/null || true
        kwriteconfig5 --file kdeglobals --group General --key toolBarFont "SF Pro Display,10,-1,5,50,0,0,0,0,0" 2>/dev/null || true
        kwriteconfig5 --file kdeglobals --group WM --key activeFont "SF Pro Display,11,-1,5,75,0,0,0,0,0" 2>/dev/null || true
    else
        echo -e "${YELLOW}SF Pro Display not found, using Roboto as fallback...${NC}"
        kwriteconfig5 --file kdeglobals --group General --key font "Roboto,11,-1,5,50,0,0,0,0,0" 2>/dev/null || true
        kwriteconfig5 --file kdeglobals --group General --key menuFont "Roboto,11,-1,5,50,0,0,0,0,0" 2>/dev/null || true
        kwriteconfig5 --file kdeglobals --group General --key toolBarFont "Roboto,10,-1,5,50,0,0,0,0,0" 2>/dev/null || true
        kwriteconfig5 --file kdeglobals --group WM --key activeFont "Roboto,11,-1,5,75,0,0,0,0,0" 2>/dev/null || true
    fi

    # Panel configuration (macOS-like dock configuration)
    echo -e "${YELLOW}Writing macOS-like panel configuration...${NC}"

    # Create proper macOS-like panel configuration
    python3 << 'EOF'
import os

# Create/modify panel configuration for macOS-like dock
config_dir = os.path.expanduser("~/.config")
plasma_config = os.path.join(config_dir, "plasma-org.kde.plasma.desktop-appletsrc")

# Ensure config directory exists
os.makedirs(config_dir, exist_ok=True)

# Create macOS-like panel configuration (desktop + top menu bar + bottom dock)
dock_config = """[ActionPlugins][0]
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
Image=file:///home/Pictures/Wallpapers/macOS-ventura.jpg
SlidePaths=/home/Pictures/Wallpapers,/usr/share/pixmaps

[Containments][2]
activityId=
formfactor=2
immutability=1
lastScreen=0
location=3
plugin=org.kde.panel
wallpaperplugin=org.kde.image

[Containments][2][Applets][7]
immutability=1
plugin=org.kde.plasma.kickoff

[Containments][2][Applets][7][Configuration]
PreloadWeight=100

[Containments][2][Applets][7][Configuration][General]
icon=applications-system
useCustomButtonImage=false

[Containments][2][Applets][8]
immutability=1
plugin=org.kde.plasma.appmenu

[Containments][2][Applets][8][Configuration]
PreloadWeight=100

[Containments][2][Applets][8][Configuration][General]
view=0
compactView=false

[Containments][2][Applets][9]
immutability=1
plugin=org.kde.plasma.panelspacer

[Containments][2][Applets][10]
immutability=1
plugin=org.kde.plasma.systemtray

[Containments][2][Applets][10][Configuration]
PreloadWeight=100

[Containments][2][Applets][11]
immutability=1
plugin=org.kde.plasma.digitalclock

[Containments][2][Applets][11][Configuration]
PreloadWeight=100

[Containments][2][Applets][11][Configuration][Appearance]
showDate=false
use24hFormat=0

[Containments][2][General]
AppletOrder=7;8;9;10;11

[Containments][2][Configuration]
PreloadWeight=100

[Containments][2][Configuration][General]
alignment=left
iconSize=22
lengthMode=fill
panelSize=28
panelVisibility=NormalPanel
floating=0

[Containments][3]
activityId=
formfactor=2
immutability=1
lastScreen=0
location=4
plugin=org.kde.panel
wallpaperplugin=org.kde.image

[Containments][3][Applets][12]
immutability=1
plugin=org.kde.plasma.icontasks

[Containments][3][Applets][12][Configuration]
PreloadWeight=100

[Containments][3][Applets][12][Configuration][General]
groupingStrategy=0
iconSpacing=3
launchers=applications:org.kde.dolphin.desktop,applications:firefox.desktop,applications:org.kde.konsole.desktop,applications:org.kde.kate.desktop
maxStripes=1
showOnlyCurrentDesktop=false
indicateAudioStreams=false
fill=true

[Containments][3][General]
AppletOrder=12

[Containments][3][Configuration]
PreloadWeight=100

[Containments][3][Configuration][General]
alignment=center
iconSize=64
lengthMode=fit
maxLength=1200
minLength=400
panelSize=72
panelVisibility=NormalPanel
floating=0

[ScreenMapping]
itemsOnDisabledScreens=
screenMapping=desktop:/home,0,desktop:/Downloads,0,desktop:/tmp,0
"""

with open(plasma_config, 'w') as f:
    f.write(dock_config)

print("macOS-like configuration written (desktop + top menu bar + bottom dock)")
EOF

    echo -e "${GREEN}macOS-like panel configuration written!${NC}"

    # Desktop effects configuration (for smooth animations like macOS)
    echo -e "${YELLOW}Writing desktop effects configuration...${NC}"
    kwriteconfig5 --file kwinrc --group Compositing --key Enabled "true" 2>/dev/null || true
    kwriteconfig5 --file kwinrc --group Compositing --key AnimationSpeed "3" 2>/dev/null || true
    kwriteconfig5 --file kwinrc --group Plugins --key slideEnabled "true" 2>/dev/null || true
    kwriteconfig5 --file kwinrc --group Plugins --key kwin4_effect_fadeEnabled "true" 2>/dev/null || true
    kwriteconfig5 --file kwinrc --group Plugins --key kwin4_effect_translucencyEnabled "true" 2>/dev/null || true
    kwriteconfig5 --file kwinrc --group Plugins --key blurEnabled "true" 2>/dev/null || true

    # Window behavior configuration (more macOS-like)
    echo -e "${YELLOW}Writing window behavior configuration...${NC}"
    kwriteconfig5 --file kwinrc --group Windows --key FocusPolicy "ClickToFocus" 2>/dev/null || true
    kwriteconfig5 --file kwinrc --group MouseBindings --key CommandAllKey "Meta" 2>/dev/null || true
    kwriteconfig5 --file kwinrc --group Windows --key BorderlessMaximizedWindows "true" 2>/dev/null || true

    # Wallpaper configuration
    echo -e "${YELLOW}Writing wallpaper configuration...${NC}"
    mkdir -p "$HOME/Pictures/Wallpapers"
    if [[ ! -f "$HOME/Pictures/Wallpapers/macOS-ventura.jpg" ]]; then
        echo -e "${YELLOW}Downloading macOS-like wallpaper...${NC}"
        curl -L -o "$HOME/Pictures/Wallpapers/macOS-ventura.jpg" \
            "https://4kwallpapers.com/images/wallpapers/macos-ventura-apple-layers-fluidic-colorful-gradient-3840x2160-6680.jpg" \
            2>/dev/null || echo "Could not download wallpaper - using default"
    fi

    # Konsole configuration (Terminal.app-like)
    echo -e "${YELLOW}Writing terminal configuration...${NC}"
    mkdir -p "$HOME/.local/share/konsole/"
    cat > "$HOME/.local/share/konsole/macOS.profile" << EOF
[Appearance]
ColorScheme=DarkPastels
Font=SF Mono,12,-1,5,50,0,0,0,0,0

[General]
Name=macOS
Parent=FALLBACK/

[Scrolling]
ScrollBarPosition=2

[Terminal Features]
BlinkingCursorEnabled=true
EOF

    # Set default Konsole profile
    kwriteconfig5 --file konsolerc --group Desktop\ Entry --key DefaultProfile "macOS.profile" 2>/dev/null || true

    # SDDM theme configuration
    echo -e "${YELLOW}Writing login screen configuration...${NC}"
    sudo kwriteconfig5 --file /etc/sddm.conf --group Theme --key Current "sugar-candy" 2>/dev/null || \
    sudo bash -c 'echo -e "[Theme]\nCurrent=sugar-candy" > /etc/sddm.conf'

    echo -e "${GREEN}✓ Cupertini theme configuration completed!${NC}"
    echo -e "${YELLOW}⚠ All changes will take effect after reboot${NC}"
}

# Ensure X11 session is available at login
ensure_x11_session() {
    echo -e "${BLUE}Ensuring X11 session availability...${NC}"

    # Create SDDM config directory if it doesn't exist
    sudo mkdir -p /etc/sddm.conf.d

    # Ensure SDDM shows session selection
    sudo bash -c 'cat > /etc/sddm.conf.d/kde_settings.conf << EOF
[Theme]
Current=sugar-candy

[General]
HaltCommand=/usr/bin/systemctl poweroff
RebootCommand=/usr/bin/systemctl reboot

[X11]
ServerPath=/usr/bin/X
SessionCommand=/usr/share/sddm/scripts/Xsession
SessionDir=/usr/share/xsessions

[Wayland]
SessionDir=/usr/share/wayland-sessions
EOF'

    echo -e "${GREEN}X11 and Wayland sessions configured!${NC}"
}

# Install multimedia codecs
install_codecs() {
    echo -e "${BLUE}Installing multimedia codecs...${NC}"

    local codecs=(
        "gstreamer" "gst-plugins-base" "gst-plugins-good"
        "gst-plugins-bad" "gst-plugins-ugly" "gst-libav" "ffmpeg"
    )

    install_packages "${codecs[@]}"

    # Install phonon-qt5-gstreamer from AUR
    echo -e "${YELLOW}Installing phonon-qt5-gstreamer from AUR...${NC}"
    install_aur_packages phonon-qt5-gstreamer

    echo -e "${GREEN}Multimedia codecs installed!${NC}"
}

# Main installation function
main() {
    show_logo

    # Check prerequisites
    if ! check_kde_installed; then
        exit 1
    fi

    echo -e "${CYAN}This will install a macOS-like desktop environment using KDE Plasma.${NC}"
    echo -e "${CYAN}It includes themes, widgets, and applications for a familiar macOS experience.${NC}"
    echo ""

    if ! confirm_action "Continue with Cupertini installation?"; then
        exit 0
    fi

    # Update system
    update_system

    # Reset settings to avoid conflicts
    reset_kde_settings

    # Check if GDM is enabled and offer to switch to SDDM
    if systemctl is-enabled gdm &>/dev/null; then
        echo -e "${YELLOW}GDM (GNOME Display Manager) is currently enabled.${NC}"
        echo -e "${YELLOW}KDE Plasma uses SDDM for the best experience.${NC}"
        if confirm_action "Switch login manager from GDM to SDDM?"; then
            echo -e "${BLUE}Disabling GDM and enabling SDDM...${NC}"
            sudo systemctl disable gdm
            sudo systemctl enable sddm
            echo -e "${GREEN}SDDM is now the active login manager.${NC}"
        else
            echo -e "${YELLOW}GDM will remain enabled. You may switch manually later.${NC}"
        fi
    fi

    # Install Qt dependencies to prevent display errors
    install_qt_dependencies

    # Install components
    install_essential_apps
    install_themes
    install_codecs

    # Ensure both X11 and Wayland sessions are available
    ensure_x11_session

    # Configure (theme files only - no dynamic application)
    configure_kde

    local completion_msg="🍎 macOS-like Desktop Environment Installed:
- KDE Plasma 6 with macOS-like layout and McMojave theme
- Apple SF Pro fonts (official Apple fonts)
- McMojave circle icons and cursors
- macOS-like dock panel configuration
- X11 and Wayland session support
- SDDM login manager with Sugar Candy theme

📋 Next Steps:
1. Reboot to apply all theme changes completely
2. At the login screen, choose Plasma (X11) for best experience
3. Install office suite: ./office-tools/office-suite.sh
4. Customize further using System Settings

🎉 Welcome to your macOS-like Arch Linux desktop!"

    show_completion "Cupertini Installation Complete!" "$completion_msg"

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

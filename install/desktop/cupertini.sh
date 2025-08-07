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
    )

    install_packages "${qt_deps[@]}"
    echo -e "${GREEN}Qt/X11 dependencies installed!${NC}"
}

# Configure KDE for macOS-like experience
configure_kde() {
    echo -e "${BLUE}Configuring KDE for macOS-like experience...${NC}"

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
        echo -e "${CYAN}  3. Install missing packages: sudo pacman -S libxcb libxcb-cursor${NC}"
        return 1
    else
        # Clean up test config
        kwriteconfig5 --file test-config --group Test --key TestKey --delete 2>/dev/null || true
        echo -e "${GREEN}✓ KDE configuration system accessible${NC}"
    fi

    # Check if we're in a Wayland session and warn user
    if [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
        echo -e "${YELLOW}Warning: Running on Wayland. Some configuration options work better on X11.${NC}"
        echo -e "${YELLOW}You can switch to X11 session at the login screen for better compatibility.${NC}"
    fi

    # Wait for KDE session
    sleep 3

    # Clear any existing theme markers first
    echo -e "${YELLOW}Clearing previous theme markers...${NC}"
    if ! kwriteconfig5 --file kdeglobals --group Archer --key ThemeType --delete 2>/dev/null; then
        echo -e "${YELLOW}Warning: Could not clear theme markers (file may not exist yet)${NC}"
    fi

    # Global theme
    echo -e "${YELLOW}Setting global theme...${NC}"
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

    if kwriteconfig5 --file kdeglobals --group KDE --key LookAndFeelPackage "$global_theme" 2>/dev/null; then
        echo -e "${GREEN}✓ Global theme set to $global_theme${NC}"
    else
        echo -e "${RED}✗ Failed to set global theme${NC}"
    fi

    # Set a marker for Cupertini theme detection
    echo -e "${YELLOW}Setting Cupertini theme marker...${NC}"
    if kwriteconfig5 --file kdeglobals --group Archer --key ThemeType "cupertini" 2>/dev/null; then
        echo -e "${GREEN}✓ Theme marker set${NC}"
    else
        echo -e "${RED}✗ Failed to set theme marker${NC}"
    fi

    # Plasma theme
    echo -e "${YELLOW}Setting plasma theme...${NC}"
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

    if kwriteconfig5 --file plasmarc --group Theme --key name "$plasma_theme" 2>/dev/null; then
        echo -e "${GREEN}✓ Plasma theme set to $plasma_theme${NC}"
    else
        echo -e "${RED}✗ Failed to set plasma theme${NC}"
    fi

    # Window decoration
    echo -e "${YELLOW}Setting window decoration...${NC}"
    if kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key library "org.kde.kwin.aurorae" 2>/dev/null && \
       kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key theme "__aurorae__svg__mcmojave" 2>/dev/null; then
        echo -e "${GREEN}✓ Window decoration set${NC}"
    else
        echo -e "${RED}✗ Failed to set window decoration${NC}"
    fi

    # Icons
    echo -e "${YELLOW}Setting icon theme...${NC}"
    if kwriteconfig5 --file kdeglobals --group Icons --key Theme "McMojave-circle" 2>/dev/null; then
        echo -e "${GREEN}✓ Icon theme set to McMojave-circle${NC}"
    else
        echo -e "${RED}✗ Failed to set icon theme${NC}"
    fi

    # Cursors
    echo -e "${YELLOW}Setting cursor theme...${NC}"
    if kwriteconfig5 --file kdeglobals --group General --key cursorTheme "McMojave-cursors" 2>/dev/null; then
        echo -e "${GREEN}✓ Cursor theme set to McMojave-cursors${NC}"
    else
        echo -e "${RED}✗ Failed to set cursor theme${NC}"
    fi

    # Fonts
    echo -e "${YELLOW}Setting fonts...${NC}"
    # Try SF Pro Display first (from otf-apple-fonts)
    if fc-list | grep -i "SF Pro Display" > /dev/null; then
        echo -e "${GREEN}Using SF Pro Display fonts...${NC}"
        kwriteconfig5 --file kdeglobals --group General --key font "SF Pro Display,11,-1,5,50,0,0,0,0,0"
        kwriteconfig5 --file kdeglobals --group General --key menuFont "SF Pro Display,11,-1,5,50,0,0,0,0,0"
        kwriteconfig5 --file kdeglobals --group General --key toolBarFont "SF Pro Display,10,-1,5,50,0,0,0,0,0"
        kwriteconfig5 --file kdeglobals --group WM --key activeFont "SF Pro Display,11,-1,5,75,0,0,0,0,0"
    else
        echo -e "${YELLOW}SF Pro Display not found, using Roboto as fallback...${NC}"
        kwriteconfig5 --file kdeglobals --group General --key font "Roboto,11,-1,5,50,0,0,0,0,0"
        kwriteconfig5 --file kdeglobals --group General --key menuFont "Roboto,11,-1,5,50,0,0,0,0,0"
        kwriteconfig5 --file kdeglobals --group General --key toolBarFont "Roboto,10,-1,5,50,0,0,0,0,0"
        kwriteconfig5 --file kdeglobals --group WM --key activeFont "Roboto,11,-1,5,75,0,0,0,0,0"
    fi

    # Panel configuration (macOS-like: bottom dock-style panel)
    echo -e "${YELLOW}Configuring macOS-like dock panel...${NC}"

    # Try to configure panels with better error handling
    if [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
        echo -e "${YELLOW}Configuring panels for Wayland session...${NC}"
    else
        echo -e "${YELLOW}Configuring panels for X11 session...${NC}"
    fi

    # Use qdbus to configure panels more reliably
    if command -v qdbus &> /dev/null; then
        echo -e "${YELLOW}Using qdbus to configure panels...${NC}"
        # Remove existing panels - use correct API
        qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
            var allPanels = panels();
            for (var i = 0; i < allPanels.length; ++i) {
                allPanels[i].remove();
            }
        ' 2>/dev/null || echo "Could not remove existing panels"

        sleep 3

        # Create macOS-like dock panel - simplified approach
        qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
            var panel = new Panel;
            if (panel) {
                panel.location = "bottom";
                panel.height = 56;
                panel.lengthMode = "FitContent";
                panel.maximumLength = 1200;
                panel.minimumLength = 400;
                panel.alignment = "center";

                // Add dock-style launcher (Icons-only Task Manager)
                var taskManager = panel.addWidget("org.kde.plasma.icontasks");
                if (taskManager) {
                    taskManager.currentConfigGroup = ["General"];
                    taskManager.writeConfig("launchers", "applications:org.kde.dolphin.desktop,applications:firefox.desktop,applications:org.kde.konsole.desktop,applications:org.kde.kate.desktop");
                    taskManager.writeConfig("showOnlyCurrentDesktop", false);
                    taskManager.writeConfig("groupingStrategy", 0);
                    taskManager.writeConfig("iconSpacing", 1);
                    taskManager.writeConfig("maxStripes", 1);
                }

                // Add system tray (minimized)
                var systray = panel.addWidget("org.kde.plasma.systemtray");
                if (systray) {
                    systray.currentConfigGroup = ["General"];
                    systray.writeConfig("scaleIconsToFit", true);
                }
            }
        ' 2>/dev/null || echo "qdbus panel configuration failed, using fallback"
    fi

    # Fallback: Use direct config file modification for better macOS-like dock
    python3 << 'EOF'
import os
import configparser
import time

# Create/modify panel configuration for macOS-like dock
config_dir = os.path.expanduser("~/.config")
plasma_config = os.path.join(config_dir, "plasma-org.kde.plasma.desktop-appletsrc")

# Ensure config directory exists
os.makedirs(config_dir, exist_ok=True)

# Create macOS-like dock configuration
dock_config = """[ActionPlugins][0]
RightButton;NoModifier=org.kde.contextmenu

[ActionPlugins][1]
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
plugin=org.kde.plasma.icontasks

[Containments][1][Applets][2][Configuration]
PreloadWeight=100

[Containments][1][Applets][2][Configuration][General]
groupingStrategy=0
iconSpacing=1
launchers=applications:org.kde.dolphin.desktop,applications:firefox.desktop,applications:org.kde.konsole.desktop,applications:org.kde.kate.desktop
maxStripes=1
showOnlyCurrentDesktop=false

[Containments][1][General]
AppletOrder=2

[Containments][1][ConfigDialog]
DialogHeight=84
DialogWidth=1920

[Containments][1][Configuration]
PreloadWeight=100

[Containments][1][Configuration][General]
alignment=132
iconSize=48
lengthMode=1
maxLength=1200
minLength=400
panelSize=56
panelVisibility=0

[ScreenMapping]
itemsOnDisabledScreens=
screenMapping=desktop:/home,0,desktop:/Downloads,0,desktop:/tmp,0
"""

with open(plasma_config, 'w') as f:
    f.write(dock_config)

print("macOS-like dock configuration written")
EOF

    echo -e "${GREEN}macOS-like dock configured!${NC}"

    # Desktop effects (for smooth animations like macOS)
    echo -e "${YELLOW}Configuring desktop effects...${NC}"
    kwriteconfig5 --file kwinrc --group Compositing --key Enabled "true"
    kwriteconfig5 --file kwinrc --group Compositing --key AnimationSpeed "3"
    kwriteconfig5 --file kwinrc --group Plugins --key slideEnabled "true"
    kwriteconfig5 --file kwinrc --group Plugins --key kwin4_effect_fadeEnabled "true"
    kwriteconfig5 --file kwinrc --group Plugins --key kwin4_effect_translucencyEnabled "true"
    kwriteconfig5 --file kwinrc --group Plugins --key blurEnabled "true"

    # Window behavior (more macOS-like)
    echo -e "${YELLOW}Configuring window behavior...${NC}"
    kwriteconfig5 --file kwinrc --group Windows --key FocusPolicy "ClickToFocus"
    kwriteconfig5 --file kwinrc --group MouseBindings --key CommandAllKey "Meta"
    kwriteconfig5 --file kwinrc --group Windows --key BorderlessMaximizedWindows "true"

    # Set macOS-like desktop wallpaper
    echo -e "${YELLOW}Setting macOS-like wallpaper...${NC}"
    # Download a macOS-like wallpaper if none exists
    mkdir -p "$HOME/Pictures/Wallpapers"
    if [[ ! -f "$HOME/Pictures/Wallpapers/macOS-ventura.jpg" ]]; then
        echo -e "${YELLOW}Downloading macOS-like wallpaper...${NC}"
        curl -L -o "$HOME/Pictures/Wallpapers/macOS-ventura.jpg" \
            "https://4kwallpapers.com/images/wallpapers/macos-ventura-apple-layers-fluidic-colorful-gradient-3840x2160-6680.jpg" \
            2>/dev/null || echo "Could not download wallpaper - using default"
    fi

    # Set wallpaper using plasma-apply-wallpaperimage
    if [[ -f "$HOME/Pictures/Wallpapers/macOS-ventura.jpg" ]]; then
        plasma-apply-wallpaperimage "$HOME/Pictures/Wallpapers/macOS-ventura.jpg" 2>/dev/null || true
    fi

    # Configure desktop to be more macOS-like
    kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 1 --group Wallpaper --group org.kde.image --group General --key Image "file://$HOME/Pictures/Wallpapers/macOS-ventura.jpg"

    # Konsole configuration (Terminal.app-like)
    echo -e "${YELLOW}Configuring terminal...${NC}"
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
    kwriteconfig5 --file konsolerc --group Desktop\ Entry --key DefaultProfile "macOS.profile"

    # SDDM theme configuration
    echo -e "${YELLOW}Configuring login screen...${NC}"
    sudo kwriteconfig5 --file /etc/sddm.conf --group Theme --key Current "sugar-candy" 2>/dev/null || \
    sudo bash -c 'echo -e "[Theme]\nCurrent=sugar-candy" > /etc/sddm.conf'

    # Force theme application by reloading configuration
    echo -e "${YELLOW}Applying all configuration changes...${NC}"
    kquitapp5 plasmashell 2>/dev/null || true
    sleep 3

    # Reload KDE configuration
    kbuildsycoca5 --noincremental 2>/dev/null || true
    sleep 2

    # Restart services
    plasmashell &
    sleep 2

    # Try to force theme application
    lookandfeeltool -a mcmojave 2>/dev/null || echo "Look and feel tool not available"

    # Apply icon theme specifically
    /usr/bin/plasma-changeicons McMojave-circle 2>/dev/null || true

    echo -e "${GREEN}KDE configuration completed!${NC}"
    echo -e "${CYAN}Note: For best results, log out and log back in, preferably using X11 session.${NC}"
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

    # Install components
    install_essential_apps
    install_themes
    install_codecs

    # Ensure both X11 and Wayland sessions are available
    ensure_x11_session

    # Configure (only if in KDE session)
    if [[ "$XDG_CURRENT_DESKTOP" == "KDE" ]] && [[ -n "$DISPLAY" ]]; then
        configure_kde
    else
        echo -e "${YELLOW}Configuration will be applied after login to KDE.${NC}"
        create_autostart_entry "Cupertini" "$(readlink -f "$0") --configure-only" "$0"
    fi

    local completion_msg="🍎 macOS-like Desktop Environment Installed:
- KDE Plasma 6 with macOS-like layout and McMojave theme
- Apple SF Pro fonts (official Apple fonts)
- McMojave circle icons and cursors
- macOS-like dock panel configuration
- X11 and Wayland session support
- SDDM login manager with Sugar Candy theme

📋 Next Steps:
1. REBOOT your system to ensure all changes take effect
2. At the login screen, you'll see both X11 and Wayland session options
3. For best macOS-like experience, choose Plasma (X11) session
4. The desktop should now look significantly more like macOS
5. Install office suite: ./office-tools/office-suite.sh
6. Customize further using System Settings

⚠️  Important: If the desktop doesn't look like macOS after login:
- Try logging out and selecting Plasma (X11) instead of Wayland
- Run this script again with: \$0 --configure-only
- Check System Settings > Appearance > Global Theme

Welcome to your macOS-like Arch Linux desktop!"

    show_completion "Cupertini Installation Complete!" "$completion_msg"

    wait_for_input "Press Enter to continue..."
}

# Handle configuration-only mode
if [[ "$1" == "--configure-only" ]]; then
    configure_kde
    exit 0
fi

# Run main function
main

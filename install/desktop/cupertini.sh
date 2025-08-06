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

    echo -e "${GREEN}macOS-like themes installed!${NC}"
}

# Configure KDE for macOS-like experience
configure_kde() {
    echo -e "${BLUE}Configuring KDE for macOS-like experience...${NC}"

    # Check if we're in a Wayland session and warn user
    if [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
        echo -e "${YELLOW}Warning: Running on Wayland. Some configuration options work better on X11.${NC}"
        echo -e "${YELLOW}You can switch to X11 session at the login screen for better compatibility.${NC}"
    fi

    # Wait for KDE session
    sleep 3

    # Ensure both Wayland and X11 sessions are available
    echo -e "${YELLOW}Ensuring X11 session is available...${NC}"
    if [[ ! -f "/usr/share/xsessions/plasma.desktop" ]]; then
        echo -e "${YELLOW}Installing X11 session support...${NC}"
        install_packages plasma-workspace-x11
    fi

    # Global theme
    echo -e "${YELLOW}Setting global theme...${NC}"
    kwriteconfig5 --file kdeglobals --group KDE --key LookAndFeelPackage "McMojave"

    # Plasma theme
    echo -e "${YELLOW}Setting plasma theme...${NC}"
    kwriteconfig5 --file plasmarc --group Theme --key name "McMojave"

    # Window decoration
    echo -e "${YELLOW}Setting window decoration...${NC}"
    kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key library "org.kde.kwin.aurorae"
    kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key theme "__aurorae__svg__McMojave"

    # Icons
    echo -e "${YELLOW}Setting icon theme...${NC}"
    kwriteconfig5 --file kdeglobals --group Icons --key Theme "McMojave-circle"

    # Cursors
    echo -e "${YELLOW}Setting cursor theme...${NC}"
    kwriteconfig5 --file kdeglobals --group General --key cursorTheme "McMojave-cursors"

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

    # Use plasma-interactiveconsole or direct config files for better reliability
    python3 << 'EOF'
import os
import configparser

# Create/modify panel configuration
config_dir = os.path.expanduser("~/.config")
plasma_config = os.path.join(config_dir, "plasma-org.kde.plasma.desktop-appletsrc")

# Ensure config directory exists
os.makedirs(config_dir, exist_ok=True)

# Create basic panel configuration
panel_config = """[ActionPlugins][0]
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

[Containments][1][Applets][1]
immutability=1
plugin=org.kde.plasma.kickoff

[Containments][1][Applets][2]
immutability=1
plugin=org.kde.plasma.icontasks

[Containments][1][Applets][3]
immutability=1
plugin=org.kde.plasma.systemtray

[Containments][1][Applets][4]
immutability=1
plugin=org.kde.plasma.digitalclock

[Containments][1][General]
AppletOrder=1;2;3;4

[ScreenMapping]
itemsOnDisabledScreens=
screenMapping=desktop:/home,0,desktop:/Downloads,0,desktop:/tmp,0
"""

with open(plasma_config, 'w') as f:
    f.write(panel_config)

print("Panel configuration written")
EOF

    echo -e "${GREEN}Panels configured: macOS-like dock panel!${NC}"

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
    lookandfeeltool -a McMojave 2>/dev/null || echo "Look and feel tool not available"

    # Apply icon theme specifically
    /usr/bin/plasma-changeicons McMojave-circle 2>/dev/null || true

    echo -e "${GREEN}KDE configuration completed!${NC}"
    echo -e "${CYAN}Note: For best results, log out and log back in, preferably using X11 session.${NC}"
}

# Ensure X11 session is available at login
ensure_x11_session() {
    echo -e "${BLUE}Ensuring X11 session availability...${NC}"

    # Install X11 session support if missing
    if [[ ! -f "/usr/share/xsessions/plasma.desktop" ]]; then
        echo -e "${YELLOW}Installing KDE X11 session support...${NC}"
        install_packages plasma-workspace-x11
    fi

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

    show_completion "Cupertini Installation Complete!" "\
🍎 macOS-like Desktop Environment Installed:
- KDE Plasma 6 with macOS-like layout and McMojave theme
- Apple SF Pro fonts (official Apple fonts)
- McMojave circle icons and cursors
- macOS-like dock panel configuration
- X11 and Wayland session support
- SDDM login manager with Sugar Candy theme

📋 Next Steps:
1. REBOOT your system to ensure all changes take effect
2. At the login screen, you'll see both X11 and Wayland session options
3. For best macOS-like experience, choose 'Plasma (X11)' session
4. The desktop should now look significantly more like macOS
5. Install office suite: ./office-tools/office-suite.sh
6. Customize further using System Settings

⚠️  Important: If the desktop doesn't look like macOS after login:
- Try logging out and selecting 'Plasma (X11)' instead of Wayland
- Run this script again with: $0 --configure-only
- Check System Settings > Appearance > Global Theme

🎉 Welcome to your macOS-like Arch Linux desktop!"

    wait_for_input "Press Enter to continue..."
}

# Handle configuration-only mode
if [[ "$1" == "--configure-only" ]]; then
    configure_kde
    exit 0
fi

# Run main function
main

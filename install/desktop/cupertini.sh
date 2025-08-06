#!/bin/bash

# Cupertini - macOS-like Desktop Environment (KDE Plasma-based)
# Part of Archer - Arch Linux Home PC Transformation Suite

set -e

# Check if KDE Plasma is installed
check_kde_installed() {
    if ! pacman -Q plasma-desktop &>/dev/null; then
        echo -e "${RED}KDE Plasma is not installed on this system.${NC}"
        echo -e "${YELLOW}Please re-run the main install.sh script to install KDE Plasma.${NC}"
        exit 1
    fi
}


# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

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

# Confirm function using gum
confirm_action() {
    local message="$1"
    gum confirm "$message"
}

# Wait function using gum
wait_for_input() {
    local message="${1:-Press Enter to continue...}"
    gum input --placeholder "$message" --value "" > /dev/null
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


# Install essential KDE applications
install_essential_apps() {
    echo -e "${BLUE}Installing essential KDE applications...${NC}"

    local apps=(
        # File manager and utilities
        "dolphin"
        "ark"
        "kdeconnect"
        "kdenetwork-filesharing"

        # Text editors
        "kate"
        "kwrite"

        # System utilitie
        "systemsettings"
        "kcalc"
        "spectacle"
        "kfind"
        "kcharselect"

        # Multimedia
        "dragon"
        "elisa"
        "gwenview"
        "okular"

        # Web browser
        "firefox"

        # Graphics
        "krita"
        "kolourpaint"

        # Terminal
        "konsole"

        # Network
        "plasma-nm"
        "plasma-pa"

        # System monitor
        "plasma-systemmonitor"

        # Bluetooth
        "bluedevil"
    )


    for app in "${apps[@]}"; do
        echo -e "${YELLOW}Installing $app...${NC}"
        sudo pacman -S --noconfirm --needed "$app"
    done

    # Install kdeplasma-addons from official repo (replacement for plasma-widgets-addons)
    echo -e "${YELLOW}Installing kdeplasma-addons (official Plasma widgets package)...${NC}"
    sudo pacman -S --noconfirm --needed kdeplasma-addons

    echo -e "${GREEN}Essential KDE applications installed!${NC}"
}

# Install macOS-like themes and widgets
install_themes() {
    echo -e "${BLUE}Installing macOS-like themes and widgets...${NC}"

    # Install theme packages from official repos
    local theme_packages=(
        "breeze"
        "breeze-gtk"
        "kvantum"
        "papirus-icon-theme"
        "ttf-roboto"
        "ttf-dejavu"
        "noto-fonts"
        "noto-fonts-emoji"
        "ttf-liberation"
    )

    for package in "${theme_packages[@]}"; do
        echo -e "${YELLOW}Installing $package...${NC}"
        sudo pacman -S --noconfirm --needed "$package"
    done

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

    # Install macOS-like themes from AUR
    local aur_themes=(
        "latte-dock"
        "mcmojave-kde-theme-git"
        "mcmojave-cursors"
        "tela-icon-theme-bin"
        "kvantum-theme-mojave"
        "plasma5-wallpapers-dynamic"
        "sddm-sugar-candy-git"
    )

    for theme in "${aur_themes[@]}"; do
        echo -e "${YELLOW}Installing $theme...${NC}"
        $aur_helper -S --noconfirm --needed "$theme" || echo -e "${YELLOW}Could not install $theme, skipping...${NC}"
    done

    echo -e "${GREEN}macOS-like themes installed!${NC}"
}

# Configure KDE for macOS-like experience
configure_kde() {
    echo -e "${BLUE}Configuring KDE for macOS-like experience...${NC}"

    # Wait for KDE session
    sleep 3

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
    kwriteconfig5 --file kdeglobals --group Icons --key Theme "Tela"

    # Cursors
    echo -e "${YELLOW}Setting cursor theme...${NC}"
    kwriteconfig5 --file kdeglobals --group General --key cursorTheme "McMojave-cursors"

    # Fonts
    echo -e "${YELLOW}Setting fonts...${NC}"
    kwriteconfig5 --file kdeglobals --group General --key font "SF Pro Display,11,-1,5,50,0,0,0,0,0"
    kwriteconfig5 --file kdeglobals --group General --key menuFont "SF Pro Display,11,-1,5,50,0,0,0,0,0"
    kwriteconfig5 --file kdeglobals --group General --key toolBarFont "SF Pro Display,10,-1,5,50,0,0,0,0,0"
    kwriteconfig5 --file kdeglobals --group WM --key activeFont "SF Pro Display,11,-1,5,75,0,0,0,0,0"

    # Panel configuration (macOS-like: bottom dock + top panel)
    echo -e "${YELLOW}Configuring panels (dock and top panel)...${NC}"
    qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
        // Remove all existing panels
        var allPanels = desktops()[0].panels;
        for (var i = 0; i < allPanels.length; ++i) {
            allPanels[i].remove();
        }

        // Bottom dock panel
        var dock = new Panel;
        dock.location = "bottom";
        dock.height = 56;
        dock.alignment = "center";
        dock.addWidget("org.kde.plasma.kickoff");
        dock.addWidget("org.kde.plasma.icontasks");
        dock.addWidget("org.kde.plasma.systemtray");
        dock.addWidget("org.kde.plasma.digitalclock");

        // Top panel
        var topPanel = new Panel;
        topPanel.location = "top";
        topPanel.height = 32;
        topPanel.alignment = "center";
        // Add global menu and start widgets (if available)
        topPanel.addWidget("org.kde.plasma.appmenu"); // Global menu
        topPanel.addWidget("org.kde.plasma.kickoff"); // Start menu (optional)
        topPanel.addWidget("org.kde.plasma.showdesktop"); // Show desktop (optional)
    '
    echo -e "${GREEN}Panels configured: dock and top panel!${NC}"

    # Desktop effects (for smooth animations like macOS)
    echo -e "${YELLOW}Configuring desktop effects...${NC}"
    kwriteconfig5 --file kwinrc --group Compositing --key Enabled "true"
    kwriteconfig5 --file kwinrc --group Compositing --key AnimationSpeed "3"
    kwriteconfig5 --file kwinrc --group Plugins --key slideEnabled "true"
    kwriteconfig5 --file kwinrc --group Plugins --key kwin4_effect_fadeEnabled "true"
    kwriteconfig5 --file kwinrc --group Plugins --key kwin4_effect_translucencyEnabled "true"

    # Window behavior (more macOS-like)
    echo -e "${YELLOW}Configuring window behavior...${NC}"
    kwriteconfig5 --file kwinrc --group Windows --key FocusPolicy "FocusFollowsMouse"
    kwriteconfig5 --file kwinrc --group MouseBindings --key CommandAllKey "Meta"

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
    sudo kwriteconfig5 --file /etc/sddm.conf --group Theme --key Current "sugar-candy"

    # Restart plasmashell to apply changes
    echo -e "${YELLOW}Restarting plasma shell...${NC}"
    killall plasmashell 2>/dev/null || true
    sleep 2
    plasmashell &

    echo -e "${GREEN}KDE configuration completed!${NC}"
}

# Install multimedia codecs
install_codecs() {
    echo -e "${BLUE}Installing multimedia codecs...${NC}"


    local codecs=(
        "gstreamer"
        "gst-plugins-base"
        "gst-plugins-good"
        "gst-plugins-bad"
        "gst-plugins-ugly"
        "gst-libav"
        "ffmpeg"
    )

    for codec in "${codecs[@]}"; do
        echo -e "${YELLOW}Installing $codec...${NC}"
        sudo pacman -S --noconfirm --needed "$codec"
    done

    # Install phonon-qt5-gstreamer from AUR
    echo -e "${YELLOW}Installing phonon-qt5-gstreamer from AUR...${NC}"
    $aur_helper -S --noconfirm --needed phonon-qt5-gstreamer || echo -e "${YELLOW}Could not install phonon-qt5-gstreamer, skipping...${NC}"

    echo -e "${GREEN}Multimedia codecs installed!${NC}"
}

# Main installation function
main() {
    show_logo

    check_kde_installed

    echo -e "${CYAN}This will install a macOS-like desktop environment using KDE Plasma.${NC}"
    echo -e "${CYAN}It includes themes, widgets, and applications for a familiar macOS experience.${NC}"
    echo ""

    if ! confirm_action "Continue with Cupertini installation?"; then
        exit 0
    fi

    # Update system
    echo -e "${BLUE}Updating system...${NC}"
    sudo pacman -Syu --noconfirm

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

    # Configure (only if in KDE session)
    if [[ "$XDG_CURRENT_DESKTOP" == "KDE" ]] && [[ -n "$DISPLAY" ]]; then
        configure_kde
    else
        echo -e "${YELLOW}Configuration will be applied after login to KDE.${NC}"

        # Create autostart script for first login
        mkdir -p "$HOME/.config/autostart"
        cat > "$HOME/.config/autostart/cupertini-setup.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Cupertini Setup
Exec=/bin/bash -c 'sleep 10 && $(readlink -f "$0") --configure-only && rm "$HOME/.config/autostart/cupertini-setup.desktop"'
Hidden=false
NoDisplay=false
X-KDE-autostart-after=panel
EOF
    fi

    echo -e "${GREEN}
=========================================================================
                        Cupertini Installation Complete!
=========================================================================

🍎 macOS-like Desktop Environment Installed:
- KDE Plasma with macOS-like layout
- McMojave theme with macOS styling
- Latte Dock for macOS-like dock experience
- Tela icon theme (macOS-inspired)
- macOS-like cursors and fonts
- Essential macOS-like applications

📋 Next Steps:
1. Reboot or log out and back in to KDE
2. The desktop will auto-configure on first login
3. Customize further using System Settings
4. Install office suite: ./office-tools/office-suite.sh
5. Use Latte Dock for the authentic macOS dock experience

🎉 Welcome to your macOS-like Arch Linux desktop!

${NC}"

    wait_for_input "Press Enter to continue..."
}

# Handle configuration-only mode
if [[ "$1" == "--configure-only" ]]; then
    configure_kde
    exit 0
fi

# Run main function
main

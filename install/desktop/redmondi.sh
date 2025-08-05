#!/bin/bash

# Redmondi - Windows-like Desktop Environment (GNOME-based)
# Part of Archer - Arch Linux Home PC Transformation Suite

set -e

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
██████╗ ███████╗██████╗ ███╗   ███╗ ██████╗ ███╗   ██╗██████╗ ██╗
██╔══██╗██╔════╝██╔══██╗████╗ ████║██╔═══██╗████╗  ██║██╔══██╗██║
██████╔╝█████╗  ██║  ██║██╔████╔██║██║   ██║██╔██╗ ██║██║  ██║██║
██╔══██╗██╔══╝  ██║  ██║██║╚██╔╝██║██║   ██║██║╚██╗██║██║  ██║██║
██║  ██║███████╗██████╔╝██║ ╚═╝ ██║╚██████╔╝██║ ╚████║██████╔╝██║
╚═╝  ╚═╝╚══════╝╚═════╝ ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═════╝ ╚═╝

        Windows-like Desktop Environment (GNOME)
EOF
    echo -e "${NC}"
}

# Install GNOME desktop environment
install_gnome() {
    echo -e "${BLUE}Installing GNOME desktop environment...${NC}"

    # Core GNOME packages
    local gnome_packages=(
        "gnome"
        "gnome-extra"
        "gdm"
        "xorg"
        "xorg-server"
        "xorg-apps"
        "xorg-xinit"
    )

    for package in "${gnome_packages[@]}"; do
        echo -e "${YELLOW}Installing $package...${NC}"
        sudo pacman -S --noconfirm --needed "$package"
    done

    # Enable GDM
    sudo systemctl enable gdm

    echo -e "${GREEN}GNOME desktop environment installed!${NC}"
}

# Install essential applications
install_essential_apps() {
    echo -e "${BLUE}Installing essential applications...${NC}"

    local apps=(
        # File manager and archives
        "nautilus"
        "file-roller"
        "nautilus-share"

        # Text editors
        "gedit"
        "gnome-text-editor"

        # System utilities
        "gnome-system-monitor"
        "gnome-disk-utility"
        "gnome-control-center"
        "gnome-tweaks"

        # Multimedia
        "totem"
        "rhythmbox"
        "gnome-photos"

        # Web browser
        "firefox"

        # Image viewer and editor
        "eog"
        "gimp"

        # Terminal
        "gnome-terminal"

        # Archive manager
        "file-roller"

        # Calculator
        "gnome-calculator"

        # Screenshot tool
        "gnome-screenshot"

        # Weather
        "gnome-weather"

        # Calendar
        "gnome-calendar"
    )

    for app in "${apps[@]}"; do
        echo -e "${YELLOW}Installing $app...${NC}"
        sudo pacman -S --noconfirm --needed "$app"
    done

    echo -e "${GREEN}Essential applications installed!${NC}"
}

# Install GNOME extensions manager and extensions
install_gnome_extensions() {
    echo -e "${BLUE}Installing GNOME Extensions...${NC}"

    # Install extension manager
    sudo pacman -S --noconfirm --needed gnome-shell-extensions extension-manager

    # Install AUR helper if not present (for AUR extensions)
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

    # Install Windows-like extensions from AUR
    local extensions=(
        "gnome-shell-extension-dash-to-panel"
        "gnome-shell-extension-arc-menu"
        "gnome-shell-extension-places-status-indicator"
        "gnome-shell-extension-removable-drive-menu"
        "gnome-shell-extension-user-themes"
        "gnome-shell-extension-appindicator"
        "gnome-shell-extension-caffeine"
        "gnome-shell-extension-clipboard-indicator"
        "gnome-shell-extension-desktop-icons-ng"
    )

    for extension in "${extensions[@]}"; do
        echo -e "${YELLOW}Installing $extension...${NC}"
        $aur_helper -S --noconfirm --needed "$extension" || echo -e "${YELLOW}Could not install $extension, skipping...${NC}"
    done

    echo -e "${GREEN}GNOME extensions installed!${NC}"
}

# Install Windows-like themes
install_themes() {
    echo -e "${BLUE}Installing Windows-like themes...${NC}"

    # Install theme packages
    local theme_packages=(
        "arc-gtk-theme"
        "papirus-icon-theme"
        "ttf-dejavu"
        "ttf-liberation"
        "ttf-roboto"
        "noto-fonts"
        "noto-fonts-emoji"
    )

    for package in "${theme_packages[@]}"; do
        echo -e "${YELLOW}Installing $package...${NC}"
        sudo pacman -S --noconfirm --needed "$package"
    done

    # Set AUR helper
    local aur_helper="yay"
    if command -v paru &> /dev/null; then
        aur_helper="paru"
    fi

    # Install Windows-like themes from AUR
    local aur_themes=(
        "windows-10-icon-theme"
        "windows-10-gtk-theme"
        "numix-gtk-theme"
        "numix-icon-theme-git"
        "tela-icon-theme"
    )

    for theme in "${aur_themes[@]}"; do
        echo -e "${YELLOW}Installing $theme...${NC}"
        $aur_helper -S --noconfirm --needed "$theme" || echo -e "${YELLOW}Could not install $theme, skipping...${NC}"
    done

    echo -e "${GREEN}Themes installed!${NC}"
}

# Configure GNOME settings for Windows-like experience
configure_gnome() {
    echo -e "${BLUE}Configuring GNOME for Windows-like experience...${NC}"

    # Wait for user session (if running during login)
    sleep 2

    # Enable extensions
    echo -e "${YELLOW}Enabling extensions...${NC}"
    gnome-extensions enable dash-to-panel@jderose9.github.com || true
    gnome-extensions enable arcmenu@arcmenu.com || true
    gnome-extensions enable places-menu@gnome-shell-extensions.gcampax.github.com || true
    gnome-extensions enable drive-menu@gnome-shell-extensions.gcampax.github.com || true
    gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com || true
    gnome-extensions enable appindicatorsupport@rgcjonas.gmail.com || true
    gnome-extensions enable caffeine@patapon.info || true
    gnome-extensions enable clipboard-indicator@tudmotu.com || true
    gnome-extensions enable desktop-icons-ng@rastersoft.com || true

    # Configure interface settings
    echo -e "${YELLOW}Configuring interface settings...${NC}"
    gsettings set org.gnome.desktop.interface gtk-theme "Arc-Dark"
    gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"
    gsettings set org.gnome.desktop.interface cursor-theme "Adwaita"
    gsettings set org.gnome.desktop.interface font-name "Roboto 11"
    gsettings set org.gnome.desktop.interface document-font-name "Roboto 11"
    gsettings set org.gnome.desktop.interface monospace-font-name "Roboto Mono 10"

    # Configure window settings
    echo -e "${YELLOW}Configuring window settings...${NC}"
    gsettings set org.gnome.desktop.wm.preferences button-layout "appmenu:minimize,maximize,close"
    gsettings set org.gnome.desktop.wm.preferences theme "Arc-Dark"
    gsettings set org.gnome.desktop.wm.preferences titlebar-font "Roboto Bold 11"

    # Configure shell settings
    echo -e "${YELLOW}Configuring shell settings...${NC}"
    gsettings set org.gnome.shell.extensions.user-theme name "Arc-Dark"

    # Configure dash-to-panel for Windows-like taskbar
    echo -e "${YELLOW}Configuring taskbar...${NC}"
    gsettings set org.gnome.shell.extensions.dash-to-panel panel-position "BOTTOM"
    gsettings set org.gnome.shell.extensions.dash-to-panel taskbar-position "LEFTPANEL"
    gsettings set org.gnome.shell.extensions.dash-to-panel location-clock "STATUSRIGHT"
    gsettings set org.gnome.shell.extensions.dash-to-panel show-activities-button false
    gsettings set org.gnome.shell.extensions.dash-to-panel show-showdesktop-button true
    gsettings set org.gnome.shell.extensions.dash-to-panel panel-size 40

    # Configure Arc Menu for Windows-like start menu
    echo -e "${YELLOW}Configuring start menu...${NC}"
    gsettings set org.gnome.shell.extensions.arcmenu menu-layout "Windows"
    gsettings set org.gnome.shell.extensions.arcmenu position-in-panel "Left"
    gsettings set org.gnome.shell.extensions.arcmenu menu-button-icon "Start_Here_Symbolic"

    # Configure desktop icons
    echo -e "${YELLOW}Configuring desktop icons...${NC}"
    gsettings set org.gnome.shell.extensions.desktop-icons show-home true
    gsettings set org.gnome.shell.extensions.desktop-icons show-trash true

    # Configure file manager
    echo -e "${YELLOW}Configuring file manager...${NC}"
    gsettings set org.gnome.nautilus.preferences default-folder-viewer "list-view"
    gsettings set org.gnome.nautilus.preferences show-hidden-files false
    gsettings set org.gnome.nautilus.list-view use-tree-view true

    # Configure background
    echo -e "${YELLOW}Setting wallpaper...${NC}"
    gsettings set org.gnome.desktop.background picture-uri "file:///usr/share/backgrounds/gnome/adwaita-timed.xml"
    gsettings set org.gnome.desktop.background picture-uri-dark "file:///usr/share/backgrounds/gnome/adwaita-timed.xml"

    echo -e "${GREEN}GNOME configuration completed!${NC}"
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

    echo -e "${GREEN}Multimedia codecs installed!${NC}"
}

# Main installation function
main() {
    show_logo

    echo -e "${CYAN}This will install a Windows-like desktop environment using GNOME.${NC}"
    echo -e "${CYAN}It includes themes, extensions, and applications for a familiar Windows experience.${NC}"
    echo ""
    read -p "Continue with Redmondi installation? (Y/n): " continue_install

    if [[ "$continue_install" =~ ^[Nn]$ ]]; then
        exit 0
    fi

    # Update system
    echo -e "${BLUE}Updating system...${NC}"
    sudo pacman -Syu --noconfirm

    # Install components
    install_gnome
    install_essential_apps
    install_gnome_extensions
    install_themes
    install_codecs

    # Configure (only if in user session)
    if [[ -n "$DISPLAY" && -n "$XDG_CURRENT_DESKTOP" ]]; then
        configure_gnome
    else
        echo -e "${YELLOW}Configuration will be applied after login.${NC}"

        # Create autostart script for first login
        mkdir -p "$HOME/.config/autostart"
        cat > "$HOME/.config/autostart/redmondi-setup.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Redmondi Setup
Exec=/bin/bash -c 'sleep 5 && $(readlink -f "$0") --configure-only && rm "$HOME/.config/autostart/redmondi-setup.desktop"'
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF
    fi

    echo -e "${GREEN}
=========================================================================
                        Redmondi Installation Complete!
=========================================================================

🪟 Windows-like Desktop Environment Installed:
- GNOME with Windows-like layout
- Dash to Panel (Windows-like taskbar)
- Arc Menu (Windows-like start menu)
- Desktop icons enabled
- Arc-Dark theme with Papirus icons
- Essential Windows-like applications

📋 Next Steps:
1. Reboot or log out and back in
2. The desktop will auto-configure on first login
3. Customize further using GNOME Tweaks
4. Install office suite: ./office-tools/office-suite.sh
5. Install additional software as needed

🎉 Welcome to your Windows-like Arch Linux desktop!

${NC}"

    read -p "Press Enter to continue..."
}

# Handle configuration-only mode
if [[ "$1" == "--configure-only" ]]; then
    configure_gnome
    exit 0
fi

# Run main function
main

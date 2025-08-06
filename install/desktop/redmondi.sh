#!/bin/bash

#!/bin/bash

# Redmondi - Windows-like Desktop Environment (KDE Plasma 6-based)
# Part of Archer - Arch Linux Home PC Transformation Suite

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

show_logo() {
    echo -e "$BLUE"
    cat << "EOF"
██████╗ ███████╗██████╗ ███╗   ███╗ ██████╗ ███╗   ██╗██████╗ ██╗
██╔══██╗██╔════╝██╔══██╗████╗ ████║██╔═══██╗████╗  ██║██╔══██╗██║
██████╔╝█████╗  ██║  ██║██╔████╔██║██║   ██║██╔██╗ ██║██║  ██║██║
██╔══██╗██╔══╝  ██║  ██║██║╚██╔╝██║██║   ██║██║╚██╗██║██║  ██║██║
██║  ██║███████╗██████╔╝██║ ╚═╝ ██║╚██████╔╝██║ ╚████║██████╔╝██║
╚═╝  ╚═╝╚══════╝╚═════╝ ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═════╝ ╚═╝

        Windows-like Desktop Environment (KDE Plasma 6)
EOF
    echo -e "$NC"
}

confirm_action() {
    local message="$1"
    gum confirm "$message"
}

wait_for_input() {
    local message="${1:-Press Enter to continue...}"
    gum input --placeholder "$message" --value "" > /dev/null
}

# Install Windows-like KDE configuration
configure_kde_redmond() {
    echo -e "$BLUE Configuring KDE for Windows-like experience...$NC"
    sleep 3
    # Set global theme, icons, fonts, and panel layout for Windows-like look
    kwriteconfig5 --file kdeglobals --group KDE --key LookAndFeelPackage "Breeze"
    kwriteconfig5 --file plasmarc --group Theme --key name "Breeze"
    kwriteconfig5 --file kdeglobals --group Icons --key Theme "Windows-10-Dark"
    kwriteconfig5 --file kdeglobals --group General --key font "Segoe UI,11,-1,5,50,0,0,0,0,0"
    kwriteconfig5 --file kdeglobals --group General --key menuFont "Segoe UI,11,-1,5,50,0,0,0,0,0"
    kwriteconfig5 --file kdeglobals --group General --key toolBarFont "Segoe UI,10,-1,5,50,0,0,0,0,0"
    kwriteconfig5 --file kdeglobals --group WM --key activeFont "Segoe UI,11,-1,5,75,0,0,0,0,0"
    # Panel: Windows-like taskbar
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
    echo -e "$GREEN KDE configuration completed!$NC"
}

main() {
    show_logo
    echo -e "$CYAN This will configure a Windows-like desktop using KDE Plasma 6.$NC"
    echo ""
    if ! confirm_action "Continue with Redmondi KDE configuration?"; then
        exit 0
    fi
    # Only configure if in KDE session
    if [[ "$XDG_CURRENT_DESKTOP" == "KDE" ]] && [[ -n "$DISPLAY" ]]; then
        configure_kde_redmond
    else
        echo -e "$YELLOW Configuration will be applied after login to KDE.$NC"
        mkdir -p "$HOME/.config/autostart"
        cat > "$HOME/.config/autostart/redmondi-setup.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Redmondi Setup
Exec=/bin/bash -c 'sleep 10 && $(readlink -f "$0") --configure-only && rm "$HOME/.config/autostart/redmondi-setup.desktop"'
Hidden=false
NoDisplay=false
X-KDE-autostart-after=panel
EOF
    fi
    echo -e "$GREEN\n==========================================================================\n                        Redmondi KDE Configuration Complete!\n==========================================================================\n\n🪟 Windows-like KDE Plasma Desktop Installed:\n- KDE Plasma 6 with Windows-like layout\n- Breeze theme and Windows 10 icons\n- Windows-like fonts and taskbar\n\n📋 Next Steps:\n1. Reboot or log out and back in to KDE\n2. The desktop will auto-configure on first login\n3. Customize further using System Settings\n4. Install office suite: ./office-tools/office-suite.sh\n\n🎉 Welcome to your Windows-like Arch Linux desktop!\n\n$NC"
    wait_for_input "Press Enter to continue..."
}

if [[ "$1" == "--configure-only" ]]; then
    configure_kde_redmond
    exit 0
fi

main

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

# Install GNOME desktop environment

# Install essential applications
install_essential_apps() {
    echo -e "${BLUE}Installing essential applications...${NC}"

    local apps=(
        # File manager and archives
        "dolphin"           # KDE file manager
        "ark"               # KDE archive manager

        # Text editors
        "kate"              # KDE text editor
        "kwrite"            # KDE lightweight text editor

        # System utilities
        "ksysguard"         # KDE system monitor
        "partitionmanager"  # KDE disk utility
        "systemsettings"    # KDE control center

        # Multimedia
        "elisa"             # KDE music player
        "gwenview"          # KDE image viewer
        "kdenlive"          # KDE video editor

        # Web browser
        "firefox"           # Cross-platform browser

        # Image editor
        "gimp"              # Advanced image editor

        # Terminal
        "konsole"           # KDE terminal emulator

        # Calculator
        "kcalc"             # KDE calculator

        # Screenshot tool
        "spectacle"         # KDE screenshot tool

        # Weather
        "kweather"          # KDE weather app (if available)

        # Calendar
        "korganizer"        # KDE calendar/organizer
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

    # Install gnome-shell-extensions (extension-manager is not in official repos)
    sudo pacman -S --noconfirm --needed gnome-shell-extensions

    # Try to install extension-manager from AUR
    echo -e "${BLUE}Installing Extension Manager (GNOME extension manager)...${NC}"
    EXT_MGR_INSTALLED=false
    if command -v yay &> /dev/null || command -v paru &> /dev/null; then
        local aur_helper="yay"
        if command -v paru &> /dev/null; then
            aur_helper="paru"
        fi
        if $aur_helper -S --noconfirm --needed extension-manager; then
            EXT_MGR_INSTALLED=true
        fi
    fi

    # Fallback to Flatpak if AUR install failed
    if [[ "$EXT_MGR_INSTALLED" != true ]]; then
        if command -v flatpak &> /dev/null; then
            echo -e "${YELLOW}Trying to install Extension Manager from Flatpak...${NC}"
            flatpak install -y flathub com.mattjakeman.ExtensionManager && EXT_MGR_INSTALLED=true
        fi
    fi

    if [[ "$EXT_MGR_INSTALLED" == true ]]; then
        echo -e "${GREEN}Extension Manager installed!${NC}"
    else
        echo -e "${YELLOW}Warning: Could not install Extension Manager from AUR or Flatpak.${NC}"
    fi

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


    # Install arc-gtk-theme from AUR
    local aur_helper="yay"
    if command -v paru &> /dev/null; then
        aur_helper="paru"
    fi
    echo -e "${YELLOW}Installing arc-gtk-theme from AUR...${NC}"
    $aur_helper -S --noconfirm --needed arc-gtk-theme || echo -e "${YELLOW}Could not install arc-gtk-theme, skipping...${NC}"

    # Install Zorin themes from AUR
    echo -e "${YELLOW}Installing zorin-desktop-themes from AUR...${NC}"
    $aur_helper -S --noconfirm --needed zorin-desktop-themes || echo -e "${YELLOW}Could not install zorin-desktop-themes, skipping...${NC}"

    # Install Windows fonts from AUR
    echo -e "${YELLOW}Installing ttf-ms-win10 from AUR...${NC}"
    $aur_helper -S --noconfirm --needed ttf-ms-win10 || echo -e "${YELLOW}Could not install ttf-ms-win10, skipping...${NC}"

    # Install other theme packages from pacman
    local theme_packages=(
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
    gsettings set org.gnome.desktop.interface gtk-theme "ZorinBlue-Dark"
    gsettings set org.gnome.desktop.interface icon-theme "Windows-10-Dark"
    gsettings set org.gnome.desktop.interface cursor-theme "Adwaita"
    gsettings set org.gnome.desktop.interface font-name "Segoe UI 11"
    gsettings set org.gnome.desktop.interface document-font-name "Segoe UI 11"
    gsettings set org.gnome.desktop.interface monospace-font-name "Consolas 10"

    # Configure window settings
    echo -e "${YELLOW}Configuring window settings...${NC}"
    gsettings set org.gnome.desktop.wm.preferences button-layout "appmenu:minimize,maximize,close"
    gsettings set org.gnome.desktop.wm.preferences theme "ZorinBlue-Dark"
    gsettings set org.gnome.desktop.wm.preferences titlebar-font "Segoe UI Bold 11"

    # Configure shell settings
    echo -e "${YELLOW}Configuring shell settings...${NC}"
    gsettings set org.gnome.shell.extensions.user-theme name "ZorinBlue-Dark"

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
    gsettings set org.gnome.shell.extensions.arcmenu menu-button-icon "windows-logo-symbolic"

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
    # Download Windows 10 wallpaper if not present
    WALLPAPER_PATH="$HOME/Pictures/windows-10-wallpaper.jpg"
    if [[ ! -f "$WALLPAPER_PATH" ]]; then
        wget -O "$WALLPAPER_PATH" "https://wallpapercave.com/wp/wp2550360.jpg" || true
    fi
    gsettings set org.gnome.desktop.background picture-uri "file://$WALLPAPER_PATH"
    gsettings set org.gnome.desktop.background picture-uri-dark "file://$WALLPAPER_PATH"

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

    if ! confirm_action "Continue with Redmondi installation?"; then
        exit 0
    fi

    # Update system
    echo -e "${BLUE}Updating system...${NC}"
    sudo pacman -Syu --noconfirm

    # Check if SDDM is enabled and offer to switch to GDM
    if systemctl is-enabled sddm &>/dev/null; then
        echo -e "${YELLOW}SDDM (KDE Display Manager) is currently enabled.${NC}"
        echo -e "${YELLOW}GNOME uses GDM for the best experience.${NC}"
        if confirm_action "Switch login manager from SDDM to GDM?"; then
            echo -e "${BLUE}Disabling SDDM and enabling GDM...${NC}"
            sudo systemctl disable sddm
            sudo systemctl enable gdm
            echo -e "${GREEN}GDM is now the active login manager.${NC}"
        else
            echo -e "${YELLOW}SDDM will remain enabled. You may switch manually later.${NC}"
        fi
    fi

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

    wait_for_input "Press Enter to continue..."
}

# Handle configuration-only mode
if [[ "$1" == "--configure-only" ]]; then
    configure_gnome
    exit 0
fi

# Run main function
main

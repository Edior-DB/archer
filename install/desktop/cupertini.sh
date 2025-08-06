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
        "mcmojave-kde-theme-git" "mcmojave-cursors" "tela-icon-theme-bin"
        "kvantum-theme-libadwaita-git" "plasma5-wallpapers-dynamic" "sddm-sugar-candy-git"
    )

    install_aur_packages "${aur_themes[@]}"

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

    # Panel configuration (macOS-like: bottom dock-style panel)
    echo -e "${YELLOW}Configuring macOS-like dock panel...${NC}"
    qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
        // Remove all existing panels
        var allPanels = desktops()[0].panels;
        for (var i = 0; i < allPanels.length; ++i) {
            allPanels[i].remove();
        }

        // Create bottom dock-style panel
        var dock = new Panel;
        dock.location = "bottom";
        dock.height = 60;
        dock.alignment = "center";
        dock.lengthMode = "fit";
        dock.hiding = "none";
        dock.floating = true;

        // Add widgets to dock
        dock.addWidget("org.kde.plasma.kickoff");
        dock.addWidget("org.kde.plasma.icontasks");
        dock.addWidget("org.kde.plasma.marginsseparator");
        dock.addWidget("org.kde.plasma.systemtray");
        dock.addWidget("org.kde.plasma.digitalclock");

        // Configure icon tasks for dock-like behavior
        var iconTasks = dock.widgetById("org.kde.plasma.icontasks");
        if (iconTasks) {
            iconTasks.currentConfigGroup = ["General"];
            iconTasks.writeConfig("launchers", "applications:org.kde.dolphin.desktop,applications:firefox.desktop,applications:org.kde.konsole.desktop");
            iconTasks.writeConfig("showOnlyCurrentDesktop", false);
            iconTasks.writeConfig("groupingStrategy", 0);
            iconTasks.writeConfig("indicateAudioStreams", true);
        }

        // Create top panel for global menu (optional)
        var topPanel = new Panel;
        topPanel.location = "top";
        topPanel.height = 28;
        topPanel.alignment = "stretch";
        topPanel.hiding = "none";

        // Add minimal widgets to top panel
        topPanel.addWidget("org.kde.plasma.appmenu");
        topPanel.addWidget("org.kde.plasma.panelspacer");
        topPanel.addWidget("org.kde.plasma.systemmonitor");
        topPanel.addWidget("org.kde.plasma.showdesktop");
    '
    echo -e "${GREEN}Panels configured: macOS-like dock panel!${NC}"

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

    # Configure (only if in KDE session)
    if [[ "$XDG_CURRENT_DESKTOP" == "KDE" ]] && [[ -n "$DISPLAY" ]]; then
        configure_kde
    else
        echo -e "${YELLOW}Configuration will be applied after login to KDE.${NC}"
        create_autostart_entry "Cupertini" "$(readlink -f "$0") --configure-only" "$0"
    fi

    show_completion "Cupertini Installation Complete!" "\
🍎 macOS-like Desktop Environment Installed:
- KDE Plasma 6 with macOS-like layout
- McMojave theme with macOS styling
- Native Plasma dock-style panel (floating, centered)
- Tela icon theme (macOS-inspired)
- macOS-like cursors and fonts
- Essential macOS-like applications

📋 Next Steps:
1. Reboot or log out and back in to KDE
2. The desktop will auto-configure on first login
3. Customize further using System Settings
4. Install office suite: ./office-tools/office-suite.sh
5. Adjust panel settings in System Settings > Workspace > Panels if needed

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

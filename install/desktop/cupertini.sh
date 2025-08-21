

#!/bin/bash
# Cupertini Layout - macOS-like KDE Plasma Layout (Full Resource Check & Install)
# This script configures a macOS-like layout for KDE Plasma, installing required themes, icons, cursors, and fonts
# from repo/AUR if available, or from local resources if present. Notifies KDE using native APIs.

set -e

show_logo() {
    echo -e "\033[0;34m"
    cat << "EOF"
 ██████╗██╗   ██╗██████╗ ███████╗██████╗ ████████╗██╗███╗   ██╗██╗
██╔════╝██║   ██║██╔══██╗██╔════╝██╔══██╗╚══██╔══╝██║████╗  ██║██║
██║     ██║   ██║██████╔╝█████╗  ██████╔╝   ██║   ██║██╔██╗ ██║██║
██║     ██║   ██║██╔═══╝ ██╔══╝  ██╔══██╗   ██║   ██║██║╚██╗██║██║
╚██████╗╚██████╔╝██║     ███████╗██║  ██║   ██║   ██║██║ ╚████║██║
 ╚═════╝ ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝╚═╝  ╚═══╝╚═╝
        macOS-like Layout (KDE Plasma)
EOF
    echo -e "\033[0m"
}

source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/..}/install/system/common-funcs.sh"


# List of required packages (AUR or repo)
REQUIRED_PKGS=(
    plasma6-theme-mcmojave-git
    mcmojave-circle-icon-theme-git
    mcmojave-cursors
    otf-apple-fonts
    kvantum
    whitesur-gtk-theme
    kvantum-theme-whitesur-git
    whitesur-kde-theme
    # SDDM macOS-like theme (if available in AUR, e.g., sddm-theme-redrock)
    sddm-theme-redrock
)

# List of local resource directories (relative to ARCHER_DIR)
LOCAL_RESOURCES=(
    "resources/plasma6-theme-mcmojave/"
    "resources/mcmojave-circle-icon-theme/"
    "resources/mcmojave-cursors/"
    "resources/otf-apple-fonts/"
    "resources/kvantum/"
    "resources/whitesur-gtk-theme/"
    "resources/kvantum-theme-whitesur/"
    "resources/whitesur-kde-theme/"
    "resources/sddm-theme-redrock/"
)

install_from_local() {
    local resource_dir="$1"
    local dest_dir="$2"
    if [ -d "$resource_dir" ]; then
        echo -e "${YELLOW}Installing from local: $resource_dir -> $dest_dir${NC}"
        mkdir -p "$dest_dir"
        cp -rT "$resource_dir" "$dest_dir"
        return 0
    else
        return 1
    fi
}

main() {
    show_logo
    echo -e "\033[1;33mThis will switch your KDE Plasma layout to a macOS-like (Cupertini) layout.\033[0m"
    echo -e "\033[36mAll required themes, icons, cursors, fonts, SDDM, and GTK/Qt themes will be installed from repo/AUR or local resources.\033[0m"
    echo -e "\033[36mPlasmoids/widgets and layout/global config must be downloaded and installed manually.\033[0m"
    echo ""
    echo -e "${YELLOW}Manual steps required:${NC}"
    echo -e "- Download and install the following plasmoids/widgets from KDE Store/Pling:"
    echo -e "  • Global Menu (org.kde.plasma.globalmenu)"
    echo -e "  • Window Buttons (org.kde.plasma.windowbuttons)"
    echo -e "  • Active Window Control (org.kde.active-window-control)"
    echo -e "- Place your layout/global config in configs/ or resources/ as needed."
    echo ""
    read -p "Continue? [y/N]: " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || exit 0

    # Check and install required packages from repo/AUR if available
    local missing_pkgs=()
    for pkg in "${REQUIRED_PKGS[@]}"; do
        if ! pacman -Q "$pkg" &>/dev/null; then
            missing_pkgs+=("$pkg")
        fi
    done

    if [ ${#missing_pkgs[@]} -gt 0 ]; then
        echo -e "${CYAN}Attempting to install missing packages from repo/AUR: ${missing_pkgs[*]}${NC}"
        install_aur_packages "${missing_pkgs[@]}"
    fi

    # After attempting AUR install, check again for missing
    local still_missing=()
    for i in "${!REQUIRED_PKGS[@]}"; do
        pkg="${REQUIRED_PKGS[$i]}"
        if ! pacman -Q "$pkg" &>/dev/null; then
            # Try to install from local resource
            local_dir="${ARCHER_DIR:-$HOME/.local/share/archer}/${LOCAL_RESOURCES[$i]}"
            case "$pkg" in
                plasma6-theme-mcmojave-git)
                    install_from_local "$local_dir" "$HOME/.local/share/plasma/desktoptheme/mcmojave" || still_missing+=("$pkg")
                    ;;
                mcmojave-circle-icon-theme-git)
                    install_from_local "$local_dir" "$HOME/.local/share/icons/McMojave-circle" || still_missing+=("$pkg")
                    ;;
                mcmojave-cursors)
                    install_from_local "$local_dir" "$HOME/.local/share/icons/McMojave-cursors" || still_missing+=("$pkg")
                    ;;
                otf-apple-fonts)
                    install_from_local "$local_dir" "$HOME/.local/share/fonts/otf-apple-fonts" || still_missing+=("$pkg")
                    ;;
                kvantum)
                    install_from_local "$local_dir" "$HOME/.config/Kvantum" || still_missing+=("$pkg")
                    ;;
                whitesur-gtk-theme)
                    install_from_local "$local_dir" "$HOME/.themes/WhiteSur-gtk-theme" || still_missing+=("$pkg")
                    ;;
                kvantum-theme-whitesur-git)
                    install_from_local "$local_dir" "$HOME/.config/Kvantum/WhiteSur" || still_missing+=("$pkg")
                    ;;
                whitesur-kde-theme)
                    install_from_local "$local_dir" "$HOME/.local/share/plasma/desktoptheme/whitesur" || still_missing+=("$pkg")
                    ;;
                sddm-theme-redrock)
                    install_from_local "$local_dir" "/usr/share/sddm/themes/redrock" || still_missing+=("$pkg")
                    ;;
                *)
                    still_missing+=("$pkg")
                    ;;
            esac
        fi
    done

    if [ ${#still_missing[@]} -gt 0 ]; then
        echo -e "${RED}The following required resources are missing and could not be installed from repo/AUR or local source:${NC}"
        for pkg in "${still_missing[@]}"; do
            echo -e "  - $pkg"
        done
        echo -e "${YELLOW}Please download and place these resources in the appropriate local directory, then re-run this script.${NC}"
        exit 1
    fi

    # Apply the layout using KDE's native API
    LAYOUT_PATH="${ARCHER_DIR:-$HOME/.local/share/archer}/configs/cupertini-layout.js"
    if [ -f "$LAYOUT_PATH" ]; then
        if command -v qdbus &>/dev/null; then
            qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$(cat "$LAYOUT_PATH")"
        elif command -v qdbus6 &>/dev/null; then
            qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$(cat "$LAYOUT_PATH")"
        else
            echo -e "${RED}Neither qdbus nor qdbus6 found. Cannot apply layout via KDE API.${NC}"
            exit 1
        fi
        echo -e "${GREEN}Cupertini (macOS-like) layout applied using KDE API!${NC}"
        echo -e "${YELLOW}If you just applied a new layout, log out and back in for changes to take full effect.${NC}"
    else
        echo -e "${RED}Layout script $LAYOUT_PATH not found.${NC}"
        echo -e "${YELLOW}Please create a KDE Plasma layout script for Cupertini and place it in $LAYOUT_PATH.${NC}"
        exit 1
    fi
}

main

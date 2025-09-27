
#!/bin/bash

# Redmondi Layout - Windows-like KDE Plasma Layout (Full Resource Check & Install)
# This script configures a Windows-like layout for KDE Plasma, installing required themes, icons, cursors, and fonts
# from repo/AUR if available, or from local resources if present. Notifies KDE using native APIs.


set -e

# Color codes
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[1;33m"
CYAN="\033[36m"
NC="\033[0m"

show_logo() {
    echo -e "\033[0;34m"
    cat << "EOF"
██████╗ ███████╗██████╗ ███╗   ███╗ ██████╗ ███╗   ██╗██████╗ ██╗
██╔══██╗██╔════╝██╔══██╗████╗ ████║██╔═══██╗████╗  ██║██╔══██╗██║
██████╔╝█████╗  ██║  ██║██╔████╔██║██║   ██║██╔██╗ ██║██║  ██║██║
██╔══██╗██╔══╝  ██║  ██║██║╚██╔╝██║██║   ██║██║╚██╗██║██║  ██║██║
██║  ██║███████╗██████╔╝██║ ╚═╝ ██║╚██████╔╝██║ ╚████║██████╔╝██║
╚═╝  ╚═╝╚══════╝╚═════╝ ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═════╝ ╚═╝
        Windows-like Layout (KDE Plasma)
EOF
    echo -e "\033[0m"
}


source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/..}/install/system/common-funcs.sh"

# List of required packages (AUR or repo)
REQUIRED_PKGS=(
    windows10-icon-theme
    ttf-liberation
    # Add more if available in AUR/repo
)

# List of local resource directories (relative to ARCHER_DIR)
# Include packages that have to be downloaded manually (see comments)
LOCAL_RESOURCES=(
    "resources/windows10-icon-theme/"           # AUR or manual
    "resources/ttf-liberation/"                # AUR or manual
    # The following must be downloaded manually from KDE Store/Pling:
    "resources/windows10-global-theme/"         # Windows-like global theme (Plasma 6, manual)
    "resources/windows10-cursors/"              # Windows 10/11 cursor theme (manual)
    "resources/windows10-window-deco/"          # Window decorations (manual)
    "resources/windows10-wallpaper/"            # Wallpaper (manual, optional)
    "resources/windows10-widgets/"              # Extra widgets/plasmoids (manual, optional)
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
    echo -e "${YELLOW}This will switch your KDE Plasma layout to a Windows-like (Redmondi) layout.${NC}"
    echo -e "${CYAN}All required icons and fonts will be installed from repo/AUR or local resources if available.${NC}"
    echo -e "${CYAN}Some components (global theme, cursors, window decorations) may require manual installation from KDE Store/Pling.${NC}"
    echo ""
    echo -e "${YELLOW}Manual steps required:${NC}"
    echo -e "- Download and install any missing Windows-like global themes, cursors, or window decorations from KDE Store/Pling."
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
                windows10-icon-theme)
                    install_from_local "$local_dir" "$HOME/.local/share/icons/windows10" || still_missing+=("$pkg")
                    ;;
                ttf-liberation)
                    install_from_local "$local_dir" "$HOME/.local/share/fonts/ttf-liberation" || still_missing+=("$pkg")
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
            archer_die "Missing required resources: ${still_missing[*]}"
    fi

    # Apply the layout using KDE's native API
    LAYOUT_PATH="${ARCHER_DIR:-$HOME/.local/share/archer}/configs/redmondi-layout.js"
    if [ -f "$LAYOUT_PATH" ]; then
        if command -v qdbus &>/dev/null; then
            qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$(cat "$LAYOUT_PATH")"
        elif command -v qdbus6 &>/dev/null; then
            qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$(cat "$LAYOUT_PATH")"
        else
            echo -e "${RED}Neither qdbus nor qdbus6 found. Cannot apply layout via KDE API.${NC}"
            archer_die "Neither qdbus nor qdbus6 found. Cannot apply layout via KDE API."
        fi
        echo -e "${GREEN}Redmondi (Windows-like) layout applied using KDE API!${NC}"
        echo -e "${YELLOW}If you just applied a new layout, log out and back in for changes to take full effect.${NC}"
    else
        echo -e "${RED}Layout script $LAYOUT_PATH not found.${NC}"
        echo -e "${YELLOW}Please create a KDE Plasma layout script for Redmondi and place it in $LAYOUT_PATH.${NC}"
        archer_die "Layout script $LAYOUT_PATH not found."
    fi
}

main



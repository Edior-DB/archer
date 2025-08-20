
    # Set default fonts

# Archer KDE Plasma Vanilla Reset Script
# Restores a true fresh KDE Plasma user config (like a new user)
set -e

show_logo() {
    echo -e "\033[0;34m"
    cat << "LOGOEOF"
██    ██  █████  ███    ██ ██ ██      ██      █████      ██████  ██      █████  ███    ███  █████
██    ██ ██   ██ ████   ██ ██ ██      ██     ██   ██     ██   ██ ██     ██   ██ ████  ████ ██   ██
██    ██ ███████ ██ ██  ██ ██ ██      ██     ███████     ██████  ██     ███████ ██ ████ ██ ███████
 ██  ██  ██   ██ ██  ██ ██ ██ ██      ██     ██   ██     ██   ██ ██     ██   ██ ██  ██  ██ ██   ██
  ████   ██   ██ ██   ████ ██ ███████ ██████ ██   ██     ██████  ██████ ██   ██ ██      ██ ██   ██

LOGOEOF
    echo -e "\033[0m"
}

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/..}/install/system/common-funcs.sh"

main() {
    show_logo
    echo -e "\033[1;33mSwitching to the vanilla KDE Plasma layout...\033[0m"
    mkdir -p "$HOME/.config"
    cp "${ARCHER_DIR:-$HOME/.local/share/archer}/configs/default-plasma-org.kde.plasma.desktop-appletsrc" "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
    echo -e "\033[1;32mVanilla KDE Plasma layout applied! Please log out and back in to see changes.\033[0m"
}

main


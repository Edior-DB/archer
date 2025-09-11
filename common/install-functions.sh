#!/bin/bash

# Archer - Common Installation Functions
# Shared installation functions for consistency across all scripts

# Prevent multiple sourcing
if [[ "${ARCHER_INSTALL_FUNCS_LOADED}" == "1" ]]; then
    return 0
fi
ARCHER_INSTALL_FUNCS_LOADED=1

# Basic installation function
basic_install() {
    sudo pacman -S --needed "$@"
}

# AUR installation function
aur_install() {
    if command -v yay >/dev/null 2>&1; then
        yay -S --needed "$@"
    elif command -v paru >/dev/null 2>&1; then
        paru -S --needed "$@"
    else
        echo "Error: No AUR helper found. Please install yay or paru first."
        return 1
    fi
}

# Enhanced installation with retries (alias to common-funcs.sh function)
install_with_retries() {
    # Try to source the enhanced function from common-funcs.sh
    if [[ -f "$(dirname "${BASH_SOURCE[0]}")/../install/system/common-funcs.sh" ]]; then
        source "$(dirname "${BASH_SOURCE[0]}")/../install/system/common-funcs.sh"
        # Use the enhanced function from common-funcs.sh
        install_with_retries "$@"
    else
        # Fallback to basic installation
        basic_install "$@"
    fi
}

# Check and install AUR helper if needed
ensure_aur_helper() {
    if ! command -v yay >/dev/null 2>&1 && ! command -v paru >/dev/null 2>&1; then
        echo "Installing yay AUR helper..."
        cd /tmp
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
        cd -
        rm -rf /tmp/yay
    fi
}

#!/bin/bash

# VSCodium Installation Script for Arch Linux
# Handles conflicts with VS Code and fallback options

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/..}/install/system/common-funcs.sh"

show_banner "VSCodium Installation"

# Check if AUR helper is available
if ! check_aur_helper; then
    echo -e "${RED}AUR helper not found. Please run post-install.sh first.${NC}"
    exit 1
fi

# Check for VS Code conflict - if installed, use Flatpak for VSCodium
check_vscode_conflict() {
    if command -v code >/dev/null 2>&1 || pacman -Q visual-studio-code-bin >/dev/null 2>&1; then
        echo -e "${YELLOW}VS Code detected. Installing VSCodium via Flatpak to avoid conflicts...${NC}"

        # Install Flatpak if not present
        if ! command -v flatpak >/dev/null 2>&1; then
            sudo pacman -S --noconfirm flatpak
            flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        fi

        # Install VSCodium via Flatpak
        flatpak install -y flathub com.vscodium.codium

        # Create desktop entry for consistency
        mkdir -p ~/.local/share/applications
        cat > ~/.local/share/applications/codium-flatpak.desktop << 'DESKTOP_EOF'
[Desktop Entry]
Name=VSCodium (Flatpak)
Comment=Code Editing. Redefined.
GenericName=Text Editor
Exec=flatpak run com.vscodium.codium %F
Icon=com.vscodium.codium
Type=Application
StartupNotify=true
StartupWMClass=VSCodium
Categories=Utility;TextEditor;Development;IDE;
MimeType=text/plain;inode/directory;application/x-code-workspace;
Actions=new-empty-window;
Keywords=vscodium;

[Desktop Action new-empty-window]
Name=New Empty Window
Exec=flatpak run com.vscodium.codium --new-window %F
Icon=com.vscodium.codium
DESKTOP_EOF

        echo -e "${GREEN}VSCodium installed via Flatpak due to VS Code conflict${NC}"
        return 0
    fi
    return 1
}

# Install VSCodium via AUR
install_vscodium_aur() {
    echo -e "${BLUE}Installing VSCodium from AUR...${NC}"

    # Try to install from AUR
    if yay -S --noconfirm vscodium-bin; then
        echo -e "${GREEN}VSCodium installed successfully from AUR${NC}"
        return 0
    else
        echo -e "${YELLOW}Failed to install from AUR, trying Flatpak fallback...${NC}"
        return 1
    fi
}

# Install VSCodium via Flatpak (fallback)
install_vscodium_flatpak() {
    echo -e "${BLUE}Installing VSCodium via Flatpak...${NC}"

    # Install Flatpak if not present
    if ! command -v flatpak >/dev/null 2>&1; then
        sudo pacman -S --noconfirm flatpak
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    fi

    # Install VSCodium via Flatpak
    flatpak install -y flathub com.vscodium.codium
    echo -e "${GREEN}VSCodium installed via Flatpak${NC}"
}

# Configure VSCodium
configure_vscodium() {
    echo -e "${BLUE}Configuring VSCodium...${NC}"

    # Determine config directory based on installation method
    local config_dir=""
    if command -v codium >/dev/null 2>&1; then
        config_dir="$HOME/.config/VSCodium/User"
    elif flatpak list | grep -q com.vscodium.codium; then
        config_dir="$HOME/.var/app/com.vscodium.codium/config/VSCodium/User"
    fi

    if [[ -n "$config_dir" ]]; then
        mkdir -p "$config_dir"

        # Create basic settings if config exists in Archer
        if [[ -f "${ARCHER_DIR}/configs/vscode.json" ]]; then
            cp "${ARCHER_DIR}/configs/vscode.json" "$config_dir/settings.json"
        fi

        # Install default extensions
        echo -e "${YELLOW}Installing default VSCodium extensions...${NC}"
        local codium_cmd="codium"
        if flatpak list | grep -q com.vscodium.codium && ! command -v codium >/dev/null 2>&1; then
            codium_cmd="flatpak run com.vscodium.codium"
        fi

        # Install popular extensions (using open-vsx registry for VSCodium)
        $codium_cmd --install-extension ms-python.python || true
        $codium_cmd --install-extension ms-vscode.cpptools || true
        $codium_cmd --install-extension rust-lang.rust-analyzer || true
        $codium_cmd --install-extension enkia.tokyo-night || true
        $codium_cmd --install-extension ms-vscode.vscode-typescript-next || true

        echo -e "${GREEN}VSCodium configured with default extensions${NC}"
    fi
}

# Main execution
main() {
    echo -e "${YELLOW}This script will install VSCodium (open-source VS Code).${NC}"
    echo -e "${CYAN}It will check for conflicts with VS Code and use appropriate installation method.${NC}"
    echo ""

    if ! confirm_action "Continue with VSCodium installation?"; then
        echo -e "${YELLOW}Installation cancelled.${NC}"
        exit 0
    fi

    # Check if VSCodium is already installed
    if command -v codium >/dev/null 2>&1 || pacman -Q vscodium-bin >/dev/null 2>&1; then
        echo -e "${GREEN}VSCodium is already installed.${NC}"
        if confirm_action "Configure VSCodium with default settings?"; then
            configure_vscodium
        fi
        exit 0
    fi

    # Check for VS Code conflict
    if check_vscode_conflict; then
        configure_vscodium
        exit 0
    fi

    # Try AUR installation first
    if ! install_vscodium_aur; then
        # Fallback to Flatpak
        install_vscodium_flatpak
    fi

    # Configure VSCodium
    configure_vscodium

    echo -e "${GREEN}
=========================================================================
                    VSCodium Installation Complete!
=========================================================================

VSCodium has been installed and configured with default extensions:
- Python support
- C++ support
- Rust Analyzer
- Tokyo Night theme
- TypeScript support

Launch VSCodium:
- Native: Run 'codium' in terminal or from applications menu
- Flatpak: Run 'flatpak run com.vscodium.codium' or from applications menu

Note: VSCodium uses the Open VSX registry for extensions instead of
the Microsoft marketplace.

${NC}"

    wait_for_input
}

# Run main function
main

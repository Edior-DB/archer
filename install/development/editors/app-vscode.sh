#!/bin/bash

# Visual Studio Code Installation Script for Arch Linux
# Handles GPG keys, conflicts with VSCodium, and fallback options

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/..}/install/system/common-funcs.sh"

show_banner "Visual Studio Code Installation"

# Check if AUR helper is available
if ! check_aur_helper; then
    echo -e "${RED}AUR helper not found. Please run post-install.sh first.${NC}"
    archer_die "AUR helper not found"
fi

# Check for VSCodium conflict - if installed, use Flatpak for VS Code
check_vscodium_conflict() {
    if command -v codium >/dev/null 2>&1 || pacman -Q vscodium-bin >/dev/null 2>&1 || pacman -Q codium >/dev/null 2>&1; then
        echo -e "${YELLOW}VSCodium detected. Installing VS Code via Flatpak to avoid conflicts...${NC}"

        # Install Flatpak if not present
        if ! command -v flatpak >/dev/null 2>&1; then
            sudo pacman -S --noconfirm flatpak
            flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        fi

        # Install VS Code via Flatpak
        flatpak install -y flathub com.visualstudio.code

        # Create desktop entry for consistency
        mkdir -p ~/.local/share/applications
        cat > ~/.local/share/applications/code-flatpak.desktop << 'DESKTOP_EOF'
[Desktop Entry]
Name=Visual Studio Code (Flatpak)
Comment=Code Editing. Redefined.
GenericName=Text Editor
Exec=flatpak run com.visualstudio.code %F
Icon=com.visualstudio.code
Type=Application
StartupNotify=true
StartupWMClass=Code
Categories=Utility;TextEditor;Development;IDE;
MimeType=text/plain;inode/directory;application/x-code-workspace;
Actions=new-empty-window;
Keywords=vscode;

[Desktop Action new-empty-window]
Name=New Empty Window
Exec=flatpak run com.visualstudio.code --new-window %F
Icon=com.visualstudio.code
DESKTOP_EOF

        echo -e "${GREEN}VS Code installed via Flatpak due to VSCodium conflict${NC}"
        return 0
    fi
    return 1
}

# Install VS Code via AUR
install_vscode_aur() {
    echo -e "${BLUE}Installing Visual Studio Code from AUR...${NC}"

    # Try to install from AUR
    if yay -S --noconfirm visual-studio-code-bin; then
        echo -e "${GREEN}VS Code installed successfully from AUR${NC}"
        return 0
    else
        echo -e "${YELLOW}Failed to install from AUR, trying Flatpak fallback...${NC}"
        return 1
    fi
}

# Install VS Code via Flatpak (fallback)
install_vscode_flatpak() {
    echo -e "${BLUE}Installing Visual Studio Code via Flatpak...${NC}"

    # Install Flatpak if not present
    if ! command -v flatpak >/dev/null 2>&1; then
        sudo pacman -S --noconfirm flatpak
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    fi

    # Install VS Code via Flatpak
    flatpak install -y flathub com.visualstudio.code
    echo -e "${GREEN}VS Code installed via Flatpak${NC}"
}

# Configure VS Code
configure_vscode() {
    echo -e "${BLUE}Configuring VS Code...${NC}"

    # Determine config directory based on installation method
    local config_dir=""
    if command -v code >/dev/null 2>&1; then
        config_dir="$HOME/.config/Code/User"
    elif flatpak list | grep -q com.visualstudio.code; then
        config_dir="$HOME/.var/app/com.visualstudio.code/config/Code/User"
    fi

    if [[ -n "$config_dir" ]]; then
        mkdir -p "$config_dir"

        # Create basic settings if config exists in Archer
        if [[ -f "${ARCHER_DIR}/configs/vscode.json" ]]; then
            cp "${ARCHER_DIR}/configs/vscode.json" "$config_dir/settings.json"
        fi

        # Install default extensions
        echo -e "${YELLOW}Installing default VS Code extensions...${NC}"
        local code_cmd="code"
        if flatpak list | grep -q com.visualstudio.code && ! command -v code >/dev/null 2>&1; then
            code_cmd="flatpak run com.visualstudio.code"
        fi

        # Install popular extensions
        $code_cmd --install-extension ms-python.python || true
        $code_cmd --install-extension ms-vscode.cpptools || true
        $code_cmd --install-extension rust-lang.rust-analyzer || true
        $code_cmd --install-extension enkia.tokyo-night || true
        $code_cmd --install-extension ms-vscode.vscode-typescript-next || true

        echo -e "${GREEN}VS Code configured with default extensions${NC}"
    fi
}

# Main execution
main() {
    echo -e "${YELLOW}This script will install Visual Studio Code.${NC}"
    echo -e "${CYAN}It will check for conflicts with VSCodium and use appropriate installation method.${NC}"
    echo ""

    if ! archer_confirm_or_default "Continue with VS Code installation?"; then
        echo -e "${YELLOW}Installation cancelled.${NC}"
        exit 0
    fi

    # Check if VS Code is already installed
    if command -v code >/dev/null 2>&1 || pacman -Q visual-studio-code-bin >/dev/null 2>&1; then
        echo -e "${GREEN}VS Code is already installed.${NC}"
    if archer_confirm_or_default "Configure VS Code with default settings?"; then
            configure_vscode
        fi
        exit 0
    fi

    # Check for VSCodium conflict
    if check_vscodium_conflict; then
        configure_vscode
        exit 0
    fi

    # Try AUR installation first
    if ! install_vscode_aur; then
        # Fallback to Flatpak
        install_vscode_flatpak
    fi

    # Configure VS Code
    configure_vscode

    echo -e "${GREEN}
=========================================================================
                    Visual Studio Code Installation Complete!
=========================================================================

VS Code has been installed and configured with default extensions:
- Python support
- C++ support
- Rust Analyzer
- Tokyo Night theme
- TypeScript support

Launch VS Code:
- Native: Run 'code' in terminal or from applications menu
- Flatpak: Run 'flatpak run com.visualstudio.code' or from applications menu

${NC}"

    wait_for_input
}

# Run main function
main

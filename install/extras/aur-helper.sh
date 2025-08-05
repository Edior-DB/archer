#!/bin/bash

# AUR Helper Installation Script
# Installs and configures AUR helpers (yay, paru)

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}
=========================================================================
                        AUR Helper Setup
=========================================================================
${NC}"

# Check if base-devel is installed
if ! pacman -Qi base-devel &> /dev/null; then
    echo -e "${YELLOW}Installing base-devel...${NC}"
    sudo pacman -S --noconfirm base-devel
fi

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo -e "${YELLOW}Installing git...${NC}"
    sudo pacman -S --noconfirm git
fi

# Function to install yay
install_yay() {
    echo -e "${BLUE}Installing yay AUR helper...${NC}"
    
    cd /tmp
    rm -rf yay
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd /
    rm -rf /tmp/yay
    
    echo -e "${GREEN}yay installed successfully!${NC}"
    
    # Configure yay
    yay --save --answerclean All --answerdiff None --answeredit None --answerupgrade None
    echo -e "${GREEN}yay configured with safe defaults${NC}"
}

# Function to install paru
install_paru() {
    echo -e "${BLUE}Installing paru AUR helper...${NC}"
    
    cd /tmp
    rm -rf paru
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si --noconfirm
    cd /
    rm -rf /tmp/paru
    
    echo -e "${GREEN}paru installed successfully!${NC}"
    
    # Configure paru
    mkdir -p ~/.config/paru
    cat > ~/.config/paru/paru.conf << 'EOF'
[options]
PgpFetch
Devel
Provides
DevelSuffixes = -git -cvs -svn -bzr -darcs -always
BottomUp
RemoveMake
SudoLoop
UpgradeMenu
NewsOnUpgrade

[bin]
FileManager = ranger
Editor = nano
EOF
    
    echo -e "${GREEN}paru configured${NC}"
}

# Function to install pikaur
install_pikaur() {
    echo -e "${BLUE}Installing pikaur AUR helper...${NC}"
    
    cd /tmp
    rm -rf pikaur
    git clone https://aur.archlinux.org/pikaur.git
    cd pikaur
    makepkg -si --noconfirm
    cd /
    rm -rf /tmp/pikaur
    
    echo -e "${GREEN}pikaur installed successfully!${NC}"
}

# Check what's already installed
check_existing() {
    echo -e "${BLUE}Checking for existing AUR helpers...${NC}"
    
    if command -v yay &> /dev/null; then
        echo -e "${GREEN}yay is already installed${NC}"
        return 1
    fi
    
    if command -v paru &> /dev/null; then
        echo -e "${GREEN}paru is already installed${NC}"
        return 1
    fi
    
    if command -v pikaur &> /dev/null; then
        echo -e "${GREEN}pikaur is already installed${NC}"
        return 1
    fi
    
    return 0
}

# Main menu
show_menu() {
    echo -e "${BLUE}Select AUR helper to install:${NC}"
    echo ""
    echo -e "${GREEN}1. yay${NC} (Yet Another Yogurt - Most popular, Go-based)"
    echo -e "   - Fast and reliable"
    echo -e "   - Good for beginners"
    echo -e "   - Active development"
    echo ""
    echo -e "${GREEN}2. paru${NC} (Rust-based, pacman-like)"
    echo -e "   - Feature-rich"
    echo -e "   - pacman-like syntax"
    echo -e "   - Modern Rust implementation"
    echo ""
    echo -e "${GREEN}3. pikaur${NC} (Python-based)"
    echo -e "   - Good conflict resolution"
    echo -e "   - Interactive package selection"
    echo -e "   - Python implementation"
    echo ""
    echo "4. Install all (not recommended)"
    echo "0. Exit"
    echo ""
}

# Essential AUR packages
install_essential_aur() {
    local aur_helper="$1"
    
    echo -e "${BLUE}Installing essential AUR packages...${NC}"
    
    essential_aur=(
        "google-chrome"
        "visual-studio-code-bin"
        "spotify"
        "discord"
        "slack-desktop"
        "zoom"
        "dropbox"
        "1password"
        "timeshift"
        "timeshift-autosnap"
        "downgrade"
    )
    
    echo -e "${YELLOW}Recommended AUR packages:${NC}"
    for package in "${essential_aur[@]}"; do
        echo "  - $package"
    done
    
    read -p "Install recommended AUR packages? (y/N): " install_essential
    
    if [[ "$install_essential" =~ ^[Yy]$ ]]; then
        for package in "${essential_aur[@]}"; do
            echo -e "${YELLOW}Installing $package...${NC}"
            case "$aur_helper" in
                "yay") yay -S --noconfirm "$package" || echo -e "${RED}Failed to install $package${NC}" ;;
                "paru") paru -S --noconfirm "$package" || echo -e "${RED}Failed to install $package${NC}" ;;
                "pikaur") pikaur -S --noconfirm "$package" || echo -e "${RED}Failed to install $package${NC}" ;;
            esac
        done
    fi
}

# Setup aliases
setup_aliases() {
    local aur_helper="$1"
    
    echo -e "${BLUE}Setting up helpful aliases...${NC}"
    
    cat >> ~/.bashrc << EOF

# AUR helper aliases
alias aurinstall='$aur_helper -S'
alias aursearch='$aur_helper -Ss'
alias aurupdate='$aur_helper -Syu'
alias aurinfo='$aur_helper -Si'
alias cleanup='sudo pacman -Rns \$(pacman -Qtdq) 2>/dev/null; sudo pacman -Sc'
EOF

    echo -e "${GREEN}Aliases added to ~/.bashrc${NC}"
}

# Main execution
main() {
    if check_existing; then
        show_menu
        read -p "Enter your choice [0-4]: " choice
        
        case $choice in
            1)
                install_yay
                install_essential_aur "yay"
                setup_aliases "yay"
                ;;
            2)
                install_paru
                install_essential_aur "paru"
                setup_aliases "paru"
                ;;
            3)
                install_pikaur
                install_essential_aur "pikaur"
                setup_aliases "pikaur"
                ;;
            4)
                install_yay
                install_paru
                install_pikaur
                echo -e "${YELLOW}All AUR helpers installed. yay will be used for essential packages.${NC}"
                install_essential_aur "yay"
                setup_aliases "yay"
                ;;
            0)
                echo -e "${YELLOW}Installation cancelled.${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice.${NC}"
                exit 1
                ;;
        esac
    fi
    
    echo -e "${GREEN}
=========================================================================
                        AUR Helper Setup Complete!
=========================================================================

Your AUR helper is now ready to use!

Common commands:
- Install package: aurinstall <package>
- Search packages: aursearch <query>
- Update system: aurupdate
- Package info: aurinfo <package>
- Cleanup system: cleanup

Remember to restart your terminal or run 'source ~/.bashrc' to use new aliases.

${NC}"
    
    read -p "Press Enter to continue..."
}

# Run main function
main

#!/bin/bash

# Archer - Post-Installation Setup Script
# Runs on installed Arch Linux systems to setup development environment

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
ARCHER_DIR="$HOME/archer"
REPO_URL="https://github.com/Edior-DB/archer.git"

# Logo
show_logo() {
    clear
    echo -e "${BLUE}"
    cat << "LOGOEOF"
 █████╗ ██████╗  ██████╗██╗  ██╗███████╗██████╗
██╔══██╗██╔══██╗██╔════╝██║  ██║██╔════╝██╔══██╗
███████║██████╔╝██║     ███████║█████╗  ██████╔╝
██╔══██║██╔══██╗██║     ██╔══██║██╔══╝  ██╔══██╗
██║  ██║██║  ██║╚██████╗██║  ██║███████╗██║  ██║
╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝

       Archer Post-Installation Setup
LOGOEOF
    echo -e "${NC}"
}

# Check if running from Live ISO
check_environment() {
    if grep -q "archiso" /proc/cmdline 2>/dev/null; then
        show_logo
        echo -e "${RED}ERROR: This script should NOT be run from Live ISO!${NC}"
        echo ""
        echo -e "${CYAN}You are currently running from Arch Linux Live ISO.${NC}"
        echo -e "${CYAN}For fresh system installation, use:${NC}"
        echo ""
        echo -e "${GREEN}  curl -fsSL https://raw.githubusercontent.com/Edior-DB/archer/master/install-system.sh | bash${NC}"
        echo ""
        echo -e "${YELLOW}After installation and reboot, run this script again.${NC}"
        exit 1
    fi

    # Check if Arch Linux
    if [[ ! -f /etc/arch-release ]]; then
        echo -e "${RED}ERROR: This script is designed for Arch Linux only.${NC}"
        exit 1
    fi

    # Check if running as regular user (not root)
    if [[ "$EUID" -eq 0 ]]; then
        echo -e "${RED}ERROR: Do not run this script as root!${NC}"
        echo -e "${YELLOW}Run as your regular user account.${NC}"
        exit 1
    fi
}

# Check internet connection
check_internet() {
    echo -e "${CYAN}Checking internet connection...${NC}"
    if ! ping -c 1 8.8.8.8 &> /dev/null; then
        echo -e "${RED}No internet connection detected.${NC}"
        echo -e "${YELLOW}Please ensure you have an active internet connection.${NC}"
        exit 1
    fi
    echo -e "${GREEN}Internet connection: OK${NC}"
}

# Install essential packages
install_essentials() {
    echo -e "${CYAN}Installing essential packages...${NC}"

    # Update system first
    echo -e "${YELLOW}Updating system packages...${NC}"
    sudo pacman -Syu --noconfirm

    # Install gum for better UX
    echo -e "${YELLOW}Installing gum for better user experience...${NC}"
    sudo pacman -S --noconfirm gum || echo -e "${YELLOW}Warning: Could not install gum${NC}"

    # Install git if not present
    sudo pacman -S --noconfirm git

    echo -e "${GREEN}Essential packages installed${NC}"
}

# Setup Archer repository
setup_archer_repo() {
    echo -e "${CYAN}Setting up Archer repository...${NC}"

    # Remove existing archer directory if it exists
    if [[ -d "$ARCHER_DIR" ]]; then
        echo -e "${YELLOW}Removing existing archer directory...${NC}"
        rm -rf "$ARCHER_DIR"
    fi

    # Clone fresh repository
    echo -e "${YELLOW}Cloning Archer repository...${NC}"
    if git clone "$REPO_URL" "$ARCHER_DIR"; then
        echo -e "${GREEN}Archer repository cloned successfully${NC}"
    else
        echo -e "${RED}Failed to clone Archer repository${NC}"
        exit 1
    fi

    # Make scripts executable
    chmod +x "$ARCHER_DIR/bin/archer.sh"
    chmod +x "$ARCHER_DIR/install-system.sh"
    chmod +x "$ARCHER_DIR/install-archer.sh"
}

# Install development base packages
install_development_base() {
    echo -e "${CYAN}Installing development base packages...${NC}"

    # Development tools
    local dev_packages=(
        # Base development
        "base-devel"
        "git"
        "vim"
        "nano"
        "wget"
        "curl"

        # Build tools
        "cmake"
        "make"
        "gcc"
        "clang"
        "python"
        "python-pip"
        "nodejs"
        "npm"

        # System tools
        "htop"
        "tree"
        "unzip"
        "zip"
        "rsync"
        "neofetch"

        # Network tools
        "openssh"
        "nmap"
        "traceroute"

        # Archive tools
        "p7zip"
        "unrar"

        # System libraries
        "glibc"
        "lib32-glibc"
        "linux-headers"
    )

    echo -e "${YELLOW}Installing development packages...${NC}"
    for package in "${dev_packages[@]}"; do
        echo -e "${CYAN}Installing $package...${NC}"
        sudo pacman -S --noconfirm "$package" 2>/dev/null || echo -e "${YELLOW}Warning: Could not install $package${NC}"
    done

    echo -e "${GREEN}Development base packages installed${NC}"
}

# Install GPU drivers
install_gpu_drivers() {
    echo -e "${CYAN}Installing GPU drivers...${NC}"

    # Detect GPU
    gpu_type=$(lspci | grep -E "VGA|3D|Display" 2>/dev/null || echo "")

    if echo "$gpu_type" | grep -E "NVIDIA|GeForce" >/dev/null; then
        echo -e "${YELLOW}NVIDIA GPU detected, installing drivers...${NC}"
        sudo pacman -S --noconfirm nvidia nvidia-utils lib32-nvidia-utils

    elif echo "$gpu_type" | grep -E "Radeon|AMD" >/dev/null; then
        echo -e "${YELLOW}AMD GPU detected, installing drivers...${NC}"
        sudo pacman -S --noconfirm xf86-video-amdgpu mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon

    elif echo "$gpu_type" | grep -E "Intel.*Graphics" >/dev/null; then
        echo -e "${YELLOW}Intel GPU detected, installing drivers...${NC}"
        sudo pacman -S --noconfirm mesa lib32-mesa vulkan-intel lib32-vulkan-intel

    else
        echo -e "${YELLOW}GPU type not detected or unknown, installing generic mesa drivers...${NC}"
        sudo pacman -S --noconfirm mesa lib32-mesa
    fi

    echo -e "${GREEN}GPU drivers installed${NC}"
}

# Install WiFi drivers and tools
install_wifi_support() {
    echo -e "${CYAN}Installing WiFi support...${NC}"

    local wifi_packages=(
        "networkmanager"
        "wpa_supplicant"
        "wireless_tools"
        "iw"
        "dhcpcd"
        "netctl"
    )

    for package in "${wifi_packages[@]}"; do
        sudo pacman -S --noconfirm "$package" 2>/dev/null || echo -e "${YELLOW}Warning: Could not install $package${NC}"
    done

    # Enable NetworkManager if not already enabled
    sudo systemctl enable NetworkManager
    sudo systemctl start NetworkManager

    echo -e "${GREEN}WiFi support installed${NC}"
}

# Install AUR helper (yay)
install_aur_helper() {
    echo -e "${CYAN}Installing AUR helper (yay)...${NC}"

    # Check if yay is already installed
    if command -v yay >/dev/null 2>&1; then
        echo -e "${GREEN}yay is already installed${NC}"
        return
    fi

    # Install yay
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd "$HOME"
    rm -rf /tmp/yay

    if command -v yay >/dev/null 2>&1; then
        echo -e "${GREEN}yay installed successfully${NC}"
    else
        echo -e "${YELLOW}Warning: yay installation may have failed${NC}"
    fi
}

# Create archer command alias
create_archer_command() {
    echo -e "${CYAN}Creating archer command...${NC}"

    # Add to bashrc if not already present
    if ! grep -q "alias archer=" "$HOME/.bashrc" 2>/dev/null; then
        echo "" >> "$HOME/.bashrc"
        echo "# Archer command alias" >> "$HOME/.bashrc"
        echo "alias archer='$ARCHER_DIR/bin/archer.sh'" >> "$HOME/.bashrc"
        echo -e "${GREEN}Archer command alias added to ~/.bashrc${NC}"
    else
        echo -e "${YELLOW}Archer command alias already exists${NC}"
    fi

    # Create symbolic link in user's local bin if it exists
    if [[ -d "$HOME/.local/bin" ]]; then
        ln -sf "$ARCHER_DIR/bin/archer.sh" "$HOME/.local/bin/archer" 2>/dev/null
        echo -e "${GREEN}Archer command linked to ~/.local/bin/archer${NC}"
    fi
}

# Main installation function
run_setup() {
    show_logo
    echo -e "${CYAN}Starting Archer post-installation setup...${NC}"
    echo ""

    # Environment checks
    check_environment
    check_internet

    # Setup steps
    echo -e "${CYAN}=== Step 1: Installing Essential Packages ===${NC}"
    install_essentials
    echo ""

    echo -e "${CYAN}=== Step 2: Setting up Archer Repository ===${NC}"
    setup_archer_repo
    echo ""

    echo -e "${CYAN}=== Step 3: Installing Development Base ===${NC}"
    install_development_base
    echo ""

    echo -e "${CYAN}=== Step 4: Installing GPU Drivers ===${NC}"
    install_gpu_drivers
    echo ""

    echo -e "${CYAN}=== Step 5: Installing WiFi Support ===${NC}"
    install_wifi_support
    echo ""

    echo -e "${CYAN}=== Step 6: Installing AUR Helper ===${NC}"
    install_aur_helper
    echo ""

    echo -e "${CYAN}=== Step 7: Creating Archer Command ===${NC}"
    create_archer_command
    echo ""

    # Final message
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Archer setup completed successfully! ${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo -e "${CYAN} 1. Reload your shell: source ~/.bashrc${NC}"
    echo -e "${CYAN} 2. Run the main menu: archer${NC}"
    echo -e "${CYAN} 3. Or directly: $ARCHER_DIR/bin/archer.sh${NC}"
    echo ""
    echo -e "${YELLOW}The 'archer' command is now available for additional setup options.${NC}"

    # Ask if user wants to run archer now
    if command -v gum >/dev/null 2>&1; then
        if gum confirm "Do you want to run Archer now?"; then
            exec "$ARCHER_DIR/bin/archer.sh"
        fi
    else
        read -r -p "Do you want to run Archer now? (y/N): " response
        if [[ "${response,,}" =~ ^(y|yes)$ ]]; then
            exec "$ARCHER_DIR/bin/archer.sh"
        fi
    fi
}

# Main execution
main() {
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        echo "Archer Post-Installation Setup"
        echo ""
        echo "Usage: $0"
        echo ""
        echo "This script sets up the Archer development environment on an installed Arch Linux system."
        echo "It should NOT be run from Live ISO - use install-system.sh for fresh installations."
        echo ""
        echo "What this script does:"
        echo " • Updates system packages"
        echo " • Installs development tools and libraries"
        echo " • Sets up GPU drivers"
        echo " • Installs WiFi support"
        echo " • Installs AUR helper (yay)"
        echo " • Clones Archer repository"
        echo " • Creates 'archer' command alias"
        exit 0
    fi

    run_setup
}

# Run main function
main "$@"




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
ARCHER_DIR="${ARCHER_DIR:-$HOME/.local/share/archer}"
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


install_with_retries() {
    local command_type=""
    local target_dir=""
    local packages=()
    local filtered_packages=()

    # Parse command type and arguments
    if [[ "$1" == "pacstrap" ]]; then
        command_type="pacstrap"
        target_dir="$2"
        shift 2  # Remove 'pacstrap' and target directory from arguments
        packages=("$@")
        # For pacstrap, we can't check if packages are already installed since target is /mnt
        filtered_packages=("${packages[@]}")
    elif [[ "$1" == "yay" || "$1" == "paru" ]]; then
        command_type="$1"
        shift  # Remove AUR helper from arguments
        packages=("$@")
        # Check if packages are already installed for AUR helpers
        for pkg in "${packages[@]}"; do
            if pacman -Q "$pkg" &>/dev/null; then
                echo -e "${GREEN}$pkg is already installed and up-to-date${NC}"
            else
                filtered_packages+=("$pkg")
            fi
        done
    else
        command_type="pacman"
        packages=("$@")
        # Check if packages are already installed for pacman
        for pkg in "${packages[@]}"; do
            if pacman -Q "$pkg" &>/dev/null; then
                echo -e "${GREEN}$pkg is already installed and up-to-date${NC}"
            else
                filtered_packages+=("$pkg")
            fi
        done
    fi

    # If all packages are already installed (except for pacstrap)
    if [[ ${#filtered_packages[@]} -eq 0 && "$command_type" != "pacstrap" ]]; then
        echo -e "${GREEN}All packages are already installed and up-to-date${NC}"
        return 0
    fi

    local retry_count=0
    local max_retries=7

    while [ $retry_count -lt $max_retries ]; do
        echo -e "${CYAN}Installing: ${filtered_packages[*]} - Attempt $((retry_count + 1)) of $max_retries...${NC}"

        local install_success=false
        case "$command_type" in
            "pacstrap")
                if pacstrap "$target_dir" "${filtered_packages[@]}" --noconfirm --needed; then
                    install_success=true
                fi
                ;;
            "yay"|"paru")
                if "$command_type" -S --noconfirm --needed "${filtered_packages[@]}"; then
                    install_success=true
                fi
                ;;
            "pacman")
                if sudo pacman -S --noconfirm --needed "${filtered_packages[@]}"; then
                    install_success=true
                fi
                ;;
        esac

        if [ "$install_success" = true ]; then
            echo -e "${GREEN}Packages installed successfully: ${filtered_packages[*]}${NC}"
            return 0
        fi

        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $max_retries ]; then
            echo -e "${YELLOW}Installation failed, retrying in 3 seconds...${NC}"
            sleep 3
            if [[ "$command_type" == "pacstrap" ]]; then
                pacman -Sy --noconfirm
            elif [[ "$command_type" == "pacman" ]]; then
                sudo pacman -Sy --noconfirm
            else
                # For AUR helpers, update package databases
                "$command_type" -Sy --noconfirm
            fi
        else
            echo -e "${RED}ERROR: Installation failed after $max_retries attempts!${NC}"
            echo -e "${RED}Please check your network connection.${NC}"
            if command -v gum >/dev/null 2>&1 && gum confirm "Would you like to try installing again?"; then
                retry_count=0
                echo -e "${CYAN}Retrying installation...${NC}"
                if [[ "$command_type" == "pacstrap" ]]; then
                    pacman -Sy --noconfirm
                elif [[ "$command_type" == "pacman" ]]; then
                    sudo pacman -Sy --noconfirm
                else
                    "$command_type" -Sy --noconfirm
                fi
            else
                echo -e "${RED}Installation cannot continue without these packages: ${filtered_packages[*]}${NC}"
                exit 1
            fi
        fi
    done
}


# Confirm function with fallback
confirm_action() {
    local message="$1"
    if command -v gum >/dev/null 2>&1; then
        gum confirm "$message"
    else
        echo -n "$message (y/N): "
        read -r response
        case "$response" in
            [yY]|[yY][eE][sS]) return 0 ;;
            *) return 1 ;;
        esac
    fi
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


install_kde_minimal() {
    echo -e "${BLUE}Installing minimal KDE Plasma 6 desktop...${NC}"
    local kde_packages=(
        # Core Plasma desktop
        "plasma-desktop"
        "plasma-workspace"
        "plasma-x11-session"
        "discover"
        "packagekit-qt6"
        "qt5-tools"
        "kde-cli-tools"
        "kconfig5"
        "konsole"
        "sddm"
        "xorg"
        "xorg-server"
        # XDG menu support (for applications.menu)
        "xdg-utils"
        #"xdg-menu"
        # Optional but recommended for a full experience
        "breeze"
        "breeze-gtk"
        "breeze-icons"
        "kde-gtk-config"
        "systemsettings"
        "dolphin"
        "ark"
        "kwalletmanager"
        "kdeplasma-addons"
    )
    install_with_retries "${kde_packages[@]}"
    sudo systemctl enable sddm
    echo -e "${GREEN}Minimal KDE Plasma desktop installed!${NC}"

    # Create golden KDE Plasma config backup if not already present
    GOLDEN_CONFIG_DIR="${ARCHER_DIR:-$HOME/.local/share/archer}/defaults/.config"
    if [ ! -d "$GOLDEN_CONFIG_DIR" ]; then
        echo -e "${CYAN}Creating golden KDE Plasma config backup for future resets...${NC}"
        mkdir -p "$GOLDEN_CONFIG_DIR"
        # Wait for user to log in and Plasma to generate configs
        echo -e "${YELLOW}Please log in to KDE Plasma at least once before running a reset!${NC}"
        if [ -d "$HOME/.config" ]; then
            cp -a "$HOME/.config/"* "$GOLDEN_CONFIG_DIR/"
            echo -e "${GREEN}Golden KDE Plasma config saved to $GOLDEN_CONFIG_DIR${NC}"
        else
            echo -e "${RED}Warning: ~/.config not found. Golden config not created.${NC}"
        fi
    fi
}

# Install essential packages
install_essentials() {
    echo -e "${CYAN}Installing essential packages...${NC}"

    # Update system first
    echo -e "${YELLOW}Updating system packages...${NC}"
    install_with_retries git gum

    echo -e "${GREEN}Essential packages installed${NC}"
}

# Setup Archer repository
setup_archer_repo() {
    echo -e "${CYAN}Setting up Archer repository...${NC}"

    # Create .local/share directory if it doesn't exist
    mkdir -p "$(dirname "$ARCHER_DIR")"

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
        "mise"

        # System tools
        "htop"
        "tree"
        "unzip"
        "zip"
        "rsync"
        "fastfetch"
        "gum"

        # Network tools
        "openssh"
        "nmap"
        "traceroute"

        # Archive tools
        "p7zip"
        "unrar"

        # System libraries
        # "glibc"
        "lib32-glibc"
        "linux-headers"
    )

    echo -e "${YELLOW}Installing development packages...${NC}"
    install_with_retries "${dev_packages[@]}"

    echo -e "${GREEN}Development base packages installed${NC}"
}

# Install GPU drivers
install_gpu_drivers() {
    echo -e "${CYAN}Installing GPU drivers using Archer's modular script...${NC}"
    bash "$ARCHER_DIR/install/system/gpu-drivers.sh"
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

    install_with_retries "${wifi_packages[@]}"

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



    # Temporarily enable passwordless sudo for yay install
    SUDO_NP_FILE="/etc/sudoers.d/archer_nopasswd"
    if [[ $EUID -ne 0 ]]; then
        echo -e "${YELLOW}Switching to sudo for temporary NOPASSWD setup...${NC}"
        sudo bash -c 'echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/archer_nopasswd && chmod 440 /etc/sudoers.d/archer_nopasswd'
    else
        echo "%wheel ALL=(ALL) NOPASSWD: ALL" > "$SUDO_NP_FILE" && chmod 440 "$SUDO_NP_FILE"
    fi

    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd "$HOME"
    rm -rf /tmp/yay

    # Remove temporary passwordless sudo
    if [[ $EUID -ne 0 ]]; then
        sudo rm -f /etc/sudoers.d/archer_nopasswd
    else
        rm -f "$SUDO_NP_FILE"
    fi

    if command -v yay >/dev/null 2>&1; then
        echo -e "${GREEN}yay installed successfully${NC}"
    else
        echo -e "${YELLOW}Warning: yay installation may have failed${NC}"
    fi
}

# Create archer command alias
create_archer_command() {
    echo -e "${CYAN}Creating archer command...${NC}"

    # Create ~/.local/bin directory if it doesn't exist
    mkdir -p "$HOME/.local/bin"

    # Create symbolic link in user's local bin
    ln -sf "$ARCHER_DIR/bin/archer.sh" "$HOME/.local/bin/archer"
    echo -e "${GREEN}Archer command linked to ~/.local/bin/archer${NC}"

    # Add ~/.local/bin to PATH in bashrc if not already present
    if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc" 2>/dev/null; then
        echo "" >> "$HOME/.bashrc"
        echo "# Add ~/.local/bin to PATH" >> "$HOME/.bashrc"
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
        echo -e "${GREEN}~/.local/bin added to PATH in ~/.bashrc${NC}"
    fi

    # Export ARCHER_DIR environment variable if not already present
    if ! grep -q "export ARCHER_DIR=" "$HOME/.bashrc" 2>/dev/null; then
        echo "" >> "$HOME/.bashrc"
        echo "# Archer directory environment variable" >> "$HOME/.bashrc"
        echo "export ARCHER_DIR=\"$HOME/.local/share/archer\"" >> "$HOME/.bashrc"
        echo -e "${GREEN}ARCHER_DIR environment variable added to ~/.bashrc${NC}"
    fi

    # Also add archer alias as backup
    if ! grep -q "alias archer=" "$HOME/.bashrc" 2>/dev/null; then
        echo "" >> "$HOME/.bashrc"
        echo "# Archer command alias (backup)" >> "$HOME/.bashrc"
        echo "alias archer='$ARCHER_DIR/bin/archer.sh'" >> "$HOME/.bashrc"
        echo -e "${GREEN}Archer command alias added to ~/.bashrc${NC}"
    fi

    # Add to current session PATH if not already there
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        export PATH="$HOME/.local/bin:$PATH"
        echo -e "${GREEN}~/.local/bin added to current session PATH${NC}"
    fi
}

update_archer_repo() {
    show_logo
    echo -e "${CYAN}Updating Archer repository...${NC}"
    if [[ -d "$ARCHER_DIR/.git" ]]; then
        cd "$ARCHER_DIR"
        if git pull; then
            echo -e "${GREEN}Archer repository updated successfully!${NC}"
        else
            echo -e "${RED}Failed to update Archer repository.${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}Archer directory not found or not a git repo. Cannot update.${NC}"
        exit 1
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
    echo -e "${CYAN}=== Step 3b: Installing Minimal KDE Plasma ===${NC}"
    install_kde_minimal
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
    echo -e "${CYAN} 1. The 'archer' command is now available in your current session${NC}"
    echo -e "${CYAN} 2. Run the main menu: archer${NC}"
    echo -e "${CYAN} 3. For new terminal sessions, ~/.local/bin is now in your PATH${NC}"
    echo ""
    echo -e "${YELLOW}The 'archer' command provides additional setup options and system management.${NC}"

    # Ask if user wants to run archer now
    if confirm_action "Do you want to run Archer now?"; then
        echo -e "${BLUE}Starting Archer...${NC}"
        # Pre-authenticate sudo to avoid issues in archer
        echo -e "${CYAN}Authenticating sudo access...${NC}"
        if sudo -v; then
            echo -e "${GREEN}✓ Sudo access confirmed${NC}"
        fi
        # Use direct execution instead of exec to maintain terminal state
        "$ARCHER_DIR/bin/archer.sh"
    fi
}

# Main execution
main() {
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        echo "Archer Post-Installation Setup"
        echo ""
        echo "Usage: $0 [--update|-u]"
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
        echo ""
        echo "Options:"
        echo "  --update, -u   Only update the Archer repository and exit"
        exit 0
    fi

    if [[ "$1" == "--update" ]] || [[ "$1" == "-u" ]]; then
        update_archer_repo
        exit 0
    fi

    run_setup
}

# Run main function
main "$@"

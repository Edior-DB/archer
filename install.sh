#!/bin/bash

# Archer - Arch Linux Home PC Transformation Suite
# Main installer script

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$SCRIPT_DIR/install"

# Logo
show_logo() {
    echo -e "${BLUE}"
    cat << "EOF"
 █████╗ ██████╗  ██████╗██╗  ██╗███████╗██████╗
██╔══██╗██╔══██╗██╔════╝██║  ██║██╔════╝██╔══██╗
███████║██████╔╝██║     ███████║█████╗  ██████╔╝
██╔══██║██╔══██╗██║     ██╔══██║██╔══╝  ██╔══██╗
██║  ██║██║  ██║╚██████╗██║  ██║███████╗██║  ██║
╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝

    Arch Linux Home PC Transformation Suite
EOF
    echo -e "${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        echo -e "${RED}This script should not be run as root directly.${NC}"
        echo -e "${YELLOW}It will request sudo when needed.${NC}"
        exit 1
    fi
}

# Check if Arch Linux or Live ISO
check_arch() {
    if [[ ! -f /etc/arch-release ]] && [[ ! -f /etc/hostname ]] || ! grep -q "archiso" /proc/cmdline 2>/dev/null && [[ ! -f /etc/arch-release ]]; then
        echo -e "${RED}This script is designed for Arch Linux only.${NC}"
        echo -e "${YELLOW}Run from Arch Linux Live ISO for fresh installation, or from installed Arch Linux system.${NC}"
        exit 1
    fi
}

# Check internet connection
check_internet() {
    echo -e "${BLUE}Checking internet connection...${NC}"
    if ! ping -c 1 8.8.8.8 &> /dev/null; then
        echo -e "${RED}No internet connection detected.${NC}"
        echo -e "${YELLOW}Please ensure you have an active internet connection.${NC}"
        echo -e "${YELLOW}You can use the WiFi setup script: ./install/network/wifi-setup.sh${NC}"
        exit 1
    fi
    echo -e "${GREEN}Internet connection: OK${NC}"
}

# Update system
update_system() {
    echo -e "${BLUE}Updating system packages...${NC}"
    sudo pacman -Syu --noconfirm
}

# Install git if not present
ensure_git() {
    if ! command -v git &> /dev/null; then
        echo -e "${YELLOW}Installing git...${NC}"
        sudo pacman -S --noconfirm git
    fi
}

# System optimization functions (inspired by Chris Titus Tech's LinUtil)
# Source: https://github.com/ChrisTitusTech/linutil
setup_system_optimizations() {
    echo -e "${BLUE}Setting up system optimization utilities...${NC}"
    echo -e "${CYAN}Individual scripts adapted from Chris Titus Tech's LinUtil collection${NC}"
    echo -e "${CYAN}Original source: https://github.com/ChrisTitusTech/linutil${NC}"
    echo -e "${GREEN}System optimization tools ready!${NC}"
}

# Show main menu
show_menu() {
    clear
    show_logo
    echo -e "${CYAN}===============================================${NC}"
    echo -e "${CYAN}        Arch Linux Transformation Menu        ${NC}"
    echo -e "${CYAN}===============================================${NC}"
    echo ""
    echo -e "${GREEN}System Installation:${NC}"
    echo "  1) Fresh Arch Linux Installation (Run from Live ISO)"
    echo ""
    echo -e "${GREEN}System Setup:${NC}"
    echo "  2) Post-Installation Setup (Essential packages, AUR)"
    echo "  3) System Tweaks & Optimizations"
    echo ""
    echo -e "${GREEN}Desktop Environment:${NC}"
    echo "  4) Install Desktop Environment"
    echo "  5) Desktop Applications"
    echo "  6) Themes & Customization"
    echo ""
    echo -e "${GREEN}Gaming & Multimedia:${NC}"
    echo "  7) Gaming Setup (Steam, Lutris, Drivers)"
    echo "  8) Media Applications (VLC, OBS, etc.)"
    echo "  9) Audio/Video Codecs"
    echo ""
    echo -e "${GREEN}Terminal & Shell:${NC}"
    echo " 10) Terminal Setup (Zsh, Oh-My-Zsh)"
    echo " 11) Terminal Applications"
    echo " 12) Dotfiles Management"
    echo ""
    echo -e "${GREEN}Development Environment:${NC}"
    echo " 13) Development Tools & Languages"
    echo " 14) Code Editors & IDEs"
    echo " 15) Container Tools (Docker, Podman)"
    echo ""
    echo -e "${GREEN}Security & Privacy:${NC}"
    echo " 16) Security Tools"
    echo " 17) Privacy Applications"
    echo " 18) Backup Solutions"
    echo ""
    echo -e "${GREEN}Utilities:${NC}"
    echo " 19) Flatpak Setup"
    echo " 20) Personal Tweaks"
    echo " 21) System Optimizations (Chris Titus Tools)"
    echo ""
    echo -e "${YELLOW}Quick Options:${NC}"
    echo " 22) Full Installation (Everything)"
    echo " 23) Gaming Rig Profile (Recommended for Home PC)"
    echo " 24) Multimedia Center Profile"
    echo " 25) Developer Workstation Profile"
    echo ""
    echo " 0) Exit"
    echo ""
    echo -e "${CYAN}===============================================${NC}"
}

# Execute script safely
run_script() {
    local script_path="$1"
    local script_name="$(basename "$script_path")"

    if [[ -f "$script_path" ]]; then
        echo -e "${BLUE}Running $script_name...${NC}"
        chmod +x "$script_path"
        "$script_path"
        echo -e "${GREEN}$script_name completed successfully!${NC}"
        read -p "Press Enter to continue..."
    else
        echo -e "${RED}Script not found: $script_path${NC}"
        echo -e "${YELLOW}This feature is coming soon!${NC}"
        read -p "Press Enter to continue..."
    fi
}

# Full installation
full_installation() {
    echo -e "${BLUE}Starting full installation...${NC}"
    echo -e "${YELLOW}This will install everything. Continue? (y/N)${NC}"
    read -r confirm

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        local scripts=(
            "$INSTALL_DIR/system/arch-server-setup.sh"
            "$INSTALL_DIR/system/post-install.sh"
            "$INSTALL_DIR/system/system-tweaks.sh"
            "$INSTALL_DIR/desktop/de-installer.sh"
            "$INSTALL_DIR/desktop/applications.sh"
            "$INSTALL_DIR/multimedia/gaming.sh"
            "$INSTALL_DIR/multimedia/media-apps.sh"
            "$INSTALL_DIR/multimedia/codecs.sh"
            "$INSTALL_DIR/terminal/shell-setup.sh"
            "$INSTALL_DIR/development/dev-tools.sh"
            "$INSTALL_DIR/security/firewall.sh"
            "$INSTALL_DIR/extras/flatpak.sh"
        )

        for script in "${scripts[@]}"; do
            if [[ -f "$script" ]]; then
                run_script "$script"
            fi
        done

        echo -e "${GREEN}Full installation completed!${NC}"
    fi
}

# Profile installations
install_profile() {
    local profile="$1"

    case "$profile" in
        "developer")
            echo -e "${BLUE}Installing Developer Workstation Profile...${NC}"
            run_script "$INSTALL_DIR/system/arch-server-setup.sh"
            run_script "$INSTALL_DIR/system/post-install.sh"
            run_script "$INSTALL_DIR/terminal/shell-setup.sh"
            run_script "$INSTALL_DIR/development/dev-tools.sh"
            run_script "$INSTALL_DIR/development/editors.sh"
            run_script "$INSTALL_DIR/development/containers.sh"
            ;;
        "gaming")
            echo -e "${BLUE}Installing Gaming Rig Profile...${NC}"
            run_script "$INSTALL_DIR/system/arch-server-setup.sh"
            run_script "$INSTALL_DIR/system/post-install.sh"
            run_script "$INSTALL_DIR/desktop/de-installer.sh"
            run_script "$INSTALL_DIR/multimedia/gaming.sh"
            run_script "$INSTALL_DIR/multimedia/codecs.sh"
            ;;
        "multimedia")
            echo -e "${BLUE}Installing Multimedia Center Profile...${NC}"
            run_script "$INSTALL_DIR/system/arch-server-setup.sh"
            run_script "$INSTALL_DIR/system/post-install.sh"
            run_script "$INSTALL_DIR/desktop/de-installer.sh"
            run_script "$INSTALL_DIR/multimedia/media-apps.sh"
            run_script "$INSTALL_DIR/multimedia/codecs.sh"
            ;;
    esac
}

# Handle command line arguments
handle_args() {
    case "$1" in
        "--install")
            run_script "$INSTALL_DIR/system/arch-server-setup.sh"
            exit 0
            ;;
        "--full")
            full_installation
            exit 0
            ;;
        "--profile")
            if [[ -n "$2" ]]; then
                install_profile "$2"
                exit 0
            else
                echo -e "${RED}Profile name required. Available: developer, gaming, multimedia${NC}"
                exit 1
            fi
            ;;
        "--desktop")
            run_script "$INSTALL_DIR/desktop/de-installer.sh"
            exit 0
            ;;
        "--development")
            run_script "$INSTALL_DIR/development/dev-tools.sh"
            exit 0
            ;;
        "--gaming")
            run_script "$INSTALL_DIR/multimedia/gaming.sh"
            exit 0
            ;;
        "--help"|"-h")
            show_logo
            echo "Usage: $0 [option]"
            echo ""
            echo "Options:"
            echo "  --install              Fresh Arch Linux installation (run from Live ISO)"
            echo "  --full                 Full installation"
            echo "  --profile PROFILE      Install specific profile (developer, gaming, multimedia)"
            echo "  --desktop             Desktop environment only"
            echo "  --development         Development tools only"
            echo "  --gaming              Gaming setup only"
            echo "  --help, -h            Show this help"
            echo ""
            echo "Run without arguments for interactive mode."
            exit 0
            ;;
    esac
}

# Main execution
main() {
    # Handle command line arguments first
    if [[ $# -gt 0 ]]; then
        handle_args "$@"
    fi

    # Initial checks
    check_root
    check_arch
    check_internet
    update_system
    ensure_git

    # Interactive menu
    while true; do
        show_menu
        read -p "Select an option [0-25]: " choice

        case $choice in
            1) run_script "$INSTALL_DIR/system/arch-server-setup.sh" ;;
            2) run_script "$INSTALL_DIR/system/post-install.sh" ;;
            3) run_script "$INSTALL_DIR/system/system-tweaks.sh" ;;
            4) run_script "$INSTALL_DIR/desktop/de-installer.sh" ;;
            5) run_script "$INSTALL_DIR/desktop/applications.sh" ;;
            6) run_script "$INSTALL_DIR/desktop/themes.sh" ;;
            7) run_script "$INSTALL_DIR/multimedia/gaming.sh" ;;
            8) run_script "$INSTALL_DIR/multimedia/media-apps.sh" ;;
            9) run_script "$INSTALL_DIR/multimedia/codecs.sh" ;;
            10) run_script "$INSTALL_DIR/terminal/shell-setup.sh" ;;
            11) run_script "$INSTALL_DIR/terminal/terminal-apps.sh" ;;
            12) run_script "$INSTALL_DIR/terminal/dotfiles.sh" ;;
            13) run_script "$INSTALL_DIR/development/dev-tools.sh" ;;
            14) run_script "$INSTALL_DIR/development/editors.sh" ;;
            15) run_script "$INSTALL_DIR/development/containers.sh" ;;
            16) run_script "$INSTALL_DIR/security/firewall.sh" ;;
            17) run_script "$INSTALL_DIR/security/privacy.sh" ;;
            18) run_script "$INSTALL_DIR/security/backup.sh" ;;
            19) run_script "$INSTALL_DIR/extras/flatpak.sh" ;;
            20) run_script "$INSTALL_DIR/extras/personal-tweaks.sh" ;;
            21)
                echo -e "${BLUE}Running system optimizations...${NC}"
                run_script "$INSTALL_DIR/system/system-tweaks.sh"
                ;;
            22) full_installation ;;
            23) install_profile "gaming" ;;
            24) install_profile "multimedia" ;;
            25) install_profile "developer" ;;
            0)
                echo -e "${GREEN}Thank you for using Archer!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Run main function with all arguments
main "$@"

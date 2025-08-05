#!/bin/bash

# Archer - Post-Installation Management Tool
# Comprehensive system management after initial installation

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
INSTALL_DIR="$(dirname "$SCRIPT_DIR")/install"

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

    Post-Installation System Management
EOF
    echo -e "${NC}"
}

# Check if we're on a properly installed Arch system
check_installed_system() {
    if [[ ! -f /etc/arch-release ]]; then
        echo -e "${RED}This script requires a properly installed Arch Linux system.${NC}"
        echo -e "${YELLOW}Use the main install.sh for fresh installations.${NC}"
        exit 1
    fi

    # Check if we're running from Live ISO
    if grep -q "archiso" /proc/cmdline 2>/dev/null; then
        echo -e "${RED}This script should not be run from Live ISO.${NC}"
        echo -e "${YELLOW}Use the main install.sh for fresh installations.${NC}"
        exit 1
    fi
}

# Check if user has sudo privileges
check_sudo() {
    echo -e "${BLUE}Checking sudo privileges...${NC}"

    if [[ $EUID -eq 0 ]]; then
        echo -e "${YELLOW}Warning: Running as root. This is not recommended for post-installation.${NC}"
        echo -e "${YELLOW}Consider running as a regular user with sudo privileges.${NC}"
        return 0
    fi

    # Check if user is in sudo group or wheel group
    if groups | grep -q '\(sudo\|wheel\)'; then
        echo -e "${GREEN}✓ User has sudo group membership${NC}"
    else
        echo -e "${RED}✗ User is not in sudo or wheel group${NC}"
        echo -e "${YELLOW}Please add your user to the wheel group:${NC}"
        echo -e "${CYAN}  su -c 'usermod -aG wheel \$USER'${NC}"
        echo -e "${CYAN}  Then logout and login again${NC}"
        exit 1
    fi

    # Test sudo access
    if sudo -n true 2>/dev/null; then
        echo -e "${GREEN}✓ Sudo access confirmed${NC}"
    else
        echo -e "${YELLOW}Testing sudo access...${NC}"
        if sudo -v; then
            echo -e "${GREEN}✓ Sudo access granted${NC}"
        else
            echo -e "${RED}✗ Sudo access denied${NC}"
            echo -e "${YELLOW}This script requires sudo privileges to install packages and modify system settings.${NC}"
            exit 1
        fi
    fi
}

# Check internet connection
check_internet() {
    echo -e "${BLUE}Checking internet connection...${NC}"
    if ! ping -c 1 8.8.8.8 &> /dev/null; then
        echo -e "${RED}No internet connection detected.${NC}"
        echo -e "${YELLOW}Please ensure you have an active internet connection.${NC}"
        exit 1
    fi
    echo -e "${GREEN}Internet connection: OK${NC}"
}

# Show main menu
show_menu() {
    clear
    show_logo
    echo -e "${CYAN}===============================================${NC}"
    echo -e "${CYAN}        Post-Installation Management         ${NC}"
    echo -e "${CYAN}===============================================${NC}"
    echo ""
    echo -e "${GREEN}Hardware & Drivers:${NC}"
    echo "  1) GPU Drivers (Hardware Upgrade/Issues)"
    echo "  2) WiFi Setup & Network Drivers"
    echo ""
    echo -e "${GREEN}Gaming & Multimedia:${NC}"
    echo "  3) Gaming Setup (Steam, Lutris, Wine)"
    echo "  4) Media Applications (VLC, OBS, etc.)"
    echo "  5) Audio/Video Codecs"
    echo ""
    echo -e "${GREEN}Terminal & Shell:${NC}"
    echo "  6) Terminal Setup (Zsh, Oh-My-Zsh)"
    echo "  7) Terminal Applications"
    echo "  8) Dotfiles Management"
    echo ""
    echo -e "${GREEN}Development Environment:${NC}"
    echo "  9) Development Tools & Languages"
    echo " 10) Code Editors & IDEs"
    echo " 11) Container Tools (Docker, Podman)"
    echo ""
    echo -e "${GREEN}Security & Privacy:${NC}"
    echo " 12) Security Tools"
    echo " 13) Privacy Applications"
    echo " 14) Backup Solutions"
    echo ""
    echo -e "${GREEN}Office & Productivity:${NC}"
    echo " 15) Office Suites"
    echo " 16) Personal Tweaks"
    echo ""
    echo -e "${GREEN}System Utilities:${NC}"
    echo " 17) Flatpak Setup"
    echo " 18) System Optimizations"
    echo ""
    echo -e "${YELLOW}Quick Profiles:${NC}"
    echo " 19) Complete Gaming Setup"
    echo " 20) Complete Development Environment"
    echo " 21) Complete Multimedia Workstation"
    echo ""
    echo " 0) Exit"
    echo ""
    echo -e "${CYAN}===============================================${NC}"
    echo -e "${YELLOW}Note: Options 1-2 are perfect for hardware upgrades${NC}"
}

# Execute script safely
run_script() {
    local script_path="$1"
    local script_name="$(basename "$script_path")"

    if [[ -f "$script_path" ]]; then
        echo -e "${BLUE}Running $script_name...${NC}"
        chmod +x "$script_path"

        # Special handling for hardware-related scripts
        case "$script_name" in
            "gpu-drivers.sh")
                echo -e "${CYAN}Hardware Detection: Checking for GPU changes...${NC}"
                echo -e "${YELLOW}This will re-detect your GPU hardware and update drivers accordingly.${NC}"
                echo -e "${YELLOW}Perfect for hardware upgrades or driver issues.${NC}"
                read -p "Continue with GPU driver detection and installation? (y/N): " gpu_confirm
                if [[ ! "$gpu_confirm" =~ ^[Yy]$ ]]; then
                    echo -e "${YELLOW}GPU driver installation cancelled.${NC}"
                    return 0
                fi
                ;;
            "wifi-setup.sh")
                echo -e "${CYAN}Network Setup: Configuring WiFi connections...${NC}"
                echo -e "${YELLOW}This will help you set up new WiFi connections or fix network issues.${NC}"
                read -p "Continue with WiFi setup? (y/N): " wifi_confirm
                if [[ ! "$wifi_confirm" =~ ^[Yy]$ ]]; then
                    echo -e "${YELLOW}WiFi setup cancelled.${NC}"
                    return 0
                fi
                ;;
        esac

        # Run with sudo if needed
        if [[ $EUID -ne 0 ]]; then
            "$script_path"
        else
            echo -e "${YELLOW}Warning: Running as root. Consider running as regular user.${NC}"
            "$script_path"
        fi

        echo -e "${GREEN}$script_name completed successfully!${NC}"
        read -p "Press Enter to continue..."
    else
        echo -e "${RED}Script not found: $script_path${NC}"
        echo -e "${YELLOW}This feature is coming soon!${NC}"
        read -p "Press Enter to continue..."
    fi
}

# Profile installations
install_profile() {
    local profile="$1"

    echo -e "${YELLOW}This may require multiple reboots. Continue? (y/N)${NC}"
    read -r confirm

    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        return 0
    fi

    case "$profile" in
        "gaming")
            echo -e "${BLUE}Installing Complete Gaming Setup...${NC}"
            run_script "$INSTALL_DIR/multimedia/gaming.sh"
            run_script "$INSTALL_DIR/multimedia/codecs.sh"
            run_script "$INSTALL_DIR/desktop/applications.sh"
            run_script "$INSTALL_DIR/system/system-tweaks.sh"
            ;;
        "development")
            echo -e "${BLUE}Installing Complete Development Environment...${NC}"
            run_script "$INSTALL_DIR/terminal/shell-setup.sh"
            run_script "$INSTALL_DIR/development/dev-tools.sh"
            run_script "$INSTALL_DIR/development/editors.sh"
            run_script "$INSTALL_DIR/development/containers.sh"
            run_script "$INSTALL_DIR/extras/flatpak.sh"
            ;;
        "multimedia")
            echo -e "${BLUE}Installing Complete Multimedia Workstation...${NC}"
            run_script "$INSTALL_DIR/multimedia/media-apps.sh"
            run_script "$INSTALL_DIR/multimedia/codecs.sh"
            run_script "$INSTALL_DIR/desktop/applications.sh"
            run_script "$INSTALL_DIR/desktop/themes.sh"
            ;;
    esac
}

# Handle command line arguments
handle_args() {
    case "$1" in
        "--gpu")
            run_script "$INSTALL_DIR/system/gpu-drivers.sh"
            exit 0
            ;;
        "--wifi")
            run_script "$INSTALL_DIR/network/wifi-setup.sh"
            exit 0
            ;;
        "--gaming")
            install_profile "gaming"
            exit 0
            ;;
        "--development")
            install_profile "development"
            exit 0
            ;;
        "--multimedia")
            install_profile "multimedia"
            exit 0
            ;;
        "--help"|"-h")
            show_logo
            echo "Usage: archer [option]"
            echo ""
            echo "Hardware Management:"
            echo "  --gpu                 GPU drivers (hardware upgrades)"
            echo "  --wifi                WiFi setup and network drivers"
            echo ""
            echo "Software Profiles:"
            echo "  --gaming              Complete gaming setup"
            echo "  --development         Complete development environment"
            echo "  --multimedia          Complete multimedia workstation"
            echo ""
            echo "General:"
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
    check_installed_system
    check_sudo
    check_internet

    # Interactive menu
    while true; do
        show_menu
        read -p "Select an option [0-21]: " choice

        case $choice in
            1) run_script "$INSTALL_DIR/system/gpu-drivers.sh" ;;
            2) run_script "$INSTALL_DIR/network/wifi-setup.sh" ;;
            3) run_script "$INSTALL_DIR/multimedia/gaming.sh" ;;
            4) run_script "$INSTALL_DIR/multimedia/media-apps.sh" ;;
            5) run_script "$INSTALL_DIR/multimedia/codecs.sh" ;;
            6) run_script "$INSTALL_DIR/terminal/shell-setup.sh" ;;
            7) run_script "$INSTALL_DIR/terminal/terminal-apps.sh" ;;
            8) run_script "$INSTALL_DIR/terminal/dotfiles.sh" ;;
            9) run_script "$INSTALL_DIR/development/dev-tools.sh" ;;
            10) run_script "$INSTALL_DIR/development/editors.sh" ;;
            11) run_script "$INSTALL_DIR/development/containers.sh" ;;
            12) run_script "$INSTALL_DIR/security/firewall.sh" ;;
            13) run_script "$INSTALL_DIR/security/privacy.sh" ;;
            14) run_script "$INSTALL_DIR/security/backup.sh" ;;
            15) run_script "$INSTALL_DIR/desktop/office-tools/office-suite.sh" ;;
            16) run_script "$INSTALL_DIR/extras/personal-tweaks.sh" ;;
            17) run_script "$INSTALL_DIR/extras/flatpak.sh" ;;
            18) run_script "$INSTALL_DIR/system/system-tweaks.sh" ;;
            19) install_profile "gaming" ;;
            20) install_profile "development" ;;
            21) install_profile "multimedia" ;;
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

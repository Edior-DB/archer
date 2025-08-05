#!/bin/bash

# Archer - Main Menu and Tools System
# Comprehensive post-installation management and customization

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

# Enhanced selection function using gum if available
select_option() {
    local options=("$@")

    if command -v gum >/dev/null 2>&1; then
        gum choose "${options[@]}"
    else
        # Fallback to arrow navigation
        local num_options=${#options[@]}
        local selected=0
        local last_selected=-1

        while true; do
            if [ $last_selected -ne -1 ]; then
                echo -ne "\033[${num_options}A"
            fi

            if [ $last_selected -eq -1 ]; then
                echo "Please select an option using the arrow keys and Enter:"
            fi
            for i in "${!options[@]}"; do
                if [ "$i" -eq $selected ]; then
                    echo "> ${options[$i]}"
                else
                    echo "  ${options[$i]}"
                fi
            done

            last_selected=$selected

            read -rsn1 key
            case $key in
                $'\x1b')
                    read -rsn2 -t 0.1 key
                    case $key in
                        '[A') ((selected--)); [ $selected -lt 0 ] && selected=$((num_options - 1));;
                        '[B') ((selected++)); [ $selected -ge $num_options ] && selected=0;;
                    esac
                    ;;
                '') break;;
            esac
        done

        echo "${options[$selected]}"
    fi
}

# Logo
show_logo() {
    clear
    echo -e "${BLUE}"
    cat << "EOF"
 █████╗ ██████╗  ██████╗██╗  ██╗███████╗██████╗
██╔══██╗██╔══██╗██╔════╝██║  ██║██╔════╝██╔══██╗
███████║██████╔╝██║     ███████║█████╗  ██████╔╝
██╔══██║██╔══██╗██║     ██╔══██║██╔══╝  ██╔══██╗
██║  ██║██║  ██║╚██████╗██║  ██║███████╗██║  ██║
╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝

       Archer - System Management & Customization
EOF
    echo -e "${NC}"
}

# Check if we're on a properly installed Arch system
check_installed_system() {
    if [[ ! -f /etc/arch-release ]]; then
        echo -e "${RED}This script requires a properly installed Arch Linux system.${NC}"
        echo -e "${YELLOW}For fresh installations, use install-system.sh from Live ISO.${NC}"
        echo -e "${YELLOW}For initial setup, use install-archer.sh after installation.${NC}"
        exit 1
    fi

    # Check if we're running from Live ISO
    if grep -q "archiso" /proc/cmdline 2>/dev/null; then
        echo -e "${RED}This script should not be run from Live ISO.${NC}"
        echo -e "${YELLOW}For fresh installations, use install-system.sh instead.${NC}"
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
    show_logo
    echo -e "${CYAN}===============================================${NC}"
    echo -e "${CYAN}    System Management & Customization Menu   ${NC}"
    echo -e "${CYAN}===============================================${NC}"
    echo ""
    echo -e "${GREEN}Hardware & System:${NC}"
    echo "  1) GPU Drivers Installation"
    echo "  2) WiFi Setup & Network Configuration"
    echo ""
    echo -e "${GREEN}Desktop Environments:${NC}"
    echo "  3) GNOME (Cupertino-like)"
    echo "  4) KDE Plasma (Windows-like)"
    echo ""
    echo -e "${GREEN}Development:${NC}"
    echo "  5) Development Tools & Languages"
    echo "  6) Code Editors & IDEs"
    echo ""
    echo -e "${GREEN}Gaming & Multimedia:${NC}"
    echo "  7) Gaming Setup (Steam, Lutris, Wine)"
    echo "  8) Multimedia Applications"
    echo ""
    echo -e "${GREEN}Office & Productivity:${NC}"
    echo "  9) Office Suite Installation"
    echo ""
    echo -e "${GREEN}System Tools:${NC}"
    echo " 10) AUR Helper Setup"
    echo " 11) System Utilities"
    echo ""
    echo -e "${YELLOW}Quick Profiles:${NC}"
    echo " 12) Complete Gaming Workstation"
    echo " 13) Complete Development Environment"
    echo " 14) Complete Multimedia Setup"
    echo ""
    echo " 0) Exit"
    echo ""
    echo -e "${CYAN}===============================================${NC}"
    echo -e "${YELLOW}Perfect for customizing your fresh Arch installation!${NC}"
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

        if command -v gum >/dev/null 2>&1; then
            # Use gum for menu selection
            options=(
                "1) GPU Drivers Installation"
                "2) WiFi Setup & Network Configuration"
                "3) GNOME (Cupertino-like)"
                "4) KDE Plasma (Windows-like)"
                "5) Development Tools & Languages"
                "6) Code Editors & IDEs"
                "7) Gaming Setup (Steam, Lutris, Wine)"
                "8) Multimedia Applications"
                "9) Office Suite Installation"
                "10) AUR Helper Setup"
                "11) System Utilities"
                "12) Complete Gaming Workstation"
                "13) Complete Development Environment"
                "14) Complete Multimedia Setup"
                "0) Exit"
            )

            selection=$(select_option "${options[@]}")
            choice="${selection:0:2}"  # Extract number from selection
            choice="${choice// /}"     # Remove any spaces
        else
            # Fallback to traditional input
            echo -n "Select an option [0-14]: "
            read -r choice
        fi

        echo ""

        case $choice in
            1)  run_script "$INSTALL_DIR/system/gpu-drivers.sh" ;;
            2)  run_script "$INSTALL_DIR/network/wifi-setup.sh" ;;
            3)  run_script "$INSTALL_DIR/desktop/cupertini.sh" ;;
            4)  run_script "$INSTALL_DIR/desktop/redmondi.sh" ;;
            5)  run_script "$INSTALL_DIR/development/dev-tools.sh" ;;
            6)  run_script "$INSTALL_DIR/development/editors.sh" ;;
            7)  run_script "$INSTALL_DIR/multimedia/gaming.sh" ;;
            8)  run_script "$INSTALL_DIR/multimedia/media-apps.sh" ;;
            9)  run_script "$INSTALL_DIR/desktop/office-tools/office-suite.sh" ;;
            10) run_script "$INSTALL_DIR/extras/aur-helper.sh" ;;
            11) run_script "$INSTALL_DIR/system/system-utilities.sh" ;;
            12) install_profile "gaming" ;;
            13) install_profile "development" ;;
            14) install_profile "multimedia" ;;
            0)
                echo -e "${GREEN}Thank you for using Archer!${NC}"
                exit 0
                ;;
            *)
                if command -v gum >/dev/null 2>&1; then
                    gum style --foreground="#ff0000" "Invalid selection. Please try again."
                    sleep 1
                else
                    echo -e "${RED}Invalid option. Please try again.${NC}"
                    sleep 1
                fi
                ;;
        esac
    done
}

# Run main function with all arguments
main "$@"

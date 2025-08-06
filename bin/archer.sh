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

# Confirm function using gum
confirm_action() {
    local message="$1"
    gum confirm "$message"
}

# Wait function using gum
wait_for_input() {
    local message="${1:-Press Enter to continue...}"
    gum input --placeholder "$message" --value "" > /dev/null
}

# Enhanced selection function using gum
select_option() {
    local options=("$@")
    gum choose "${options[@]}"
}

# Logo
show_logo() {
    # Use printf instead of clear to avoid terminal issues
    printf '\033[2J\033[H'  # Clear screen and move cursor to top
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
    # Check if we're running from Live ISO first (most restrictive)
    if grep -q "archiso" /proc/cmdline 2>/dev/null; then
        echo -e "${RED}This script should not be run from Live ISO.${NC}"
        echo -e "${YELLOW}For fresh installations, use install-system.sh instead.${NC}"
        exit 1
    fi

    # Check for Arch Linux indicators (more flexible)
    if [[ ! -f /etc/arch-release ]] && [[ ! -f /etc/os-release ]] && ! command -v pacman >/dev/null 2>&1; then
        echo -e "${RED}This script requires an Arch Linux system.${NC}"
        echo -e "${YELLOW}For fresh installations, use install-system.sh from Live ISO.${NC}"
        echo -e "${YELLOW}For initial setup, use install-archer.sh after installation.${NC}"
        exit 1
    fi

    # Additional check for os-release if arch-release doesn't exist
    if [[ ! -f /etc/arch-release ]] && [[ -f /etc/os-release ]]; then
        if ! grep -q "Arch Linux" /etc/os-release 2>/dev/null; then
            echo -e "${YELLOW}Warning: This script is designed for Arch Linux systems.${NC}"
            echo -e "${YELLOW}Detected system may not be fully compatible.${NC}"
            # Don't exit here, just warn
        fi
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

    # Test sudo access (non-interactive first)
    if sudo -n true 2>/dev/null; then
        echo -e "${GREEN}✓ Sudo access confirmed (cached)${NC}"
    else
        echo -e "${YELLOW}Sudo access verification required...${NC}"
        echo -e "${CYAN}Please enter your password when prompted:${NC}"
        if timeout 30 sudo -v 2>/dev/null; then
            echo -e "${GREEN}✓ Sudo access granted${NC}"
        else
            echo -e "${YELLOW}Sudo verification timed out or failed${NC}"
            echo -e "${YELLOW}Some features may require manual sudo password entry${NC}"
            echo -e "${YELLOW}Continuing with limited functionality...${NC}"
            # Don't exit here, just warn and continue
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
    echo "  3) KDE Plasma (macOS-like)"
    echo "  4) GNOME (Windows-like)"
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
    echo ""
    echo -e "${BLUE}Use arrow keys (↑↓) to navigate, Enter to select${NC}"
}

# Execute script safely
run_script() {
    local script_path="$1"
    local script_name="$(basename "$script_path")"

    if [[ -f "$script_path" ]]; then
        echo -e "${BLUE}Running $script_name...${NC}"
        chmod +x "$script_path"
        "$script_path"
        wait_for_input
    else
        echo -e "${RED}Script not found: $script_path${NC}"
        wait_for_input
    fi
}

# Profile installations
install_profile() {
    local profile="$1"

    if ! confirm_action "This may require multiple reboots. Continue with profile installation?"; then
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
        "--skip-checks")
            # Hidden flag for testing/development
            SKIP_CHECKS=true
            return 0
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

    # Initial checks (unless skipped)
    if [[ "$SKIP_CHECKS" != "true" ]]; then
        check_installed_system
        check_sudo
        check_internet
    else
        echo -e "${YELLOW}Skipping system checks (development mode)${NC}"
    fi

    # Interactive menu
    while true; do
        # Ensure clean terminal state before showing menu
        stty sane 2>/dev/null || true

        show_menu

        local choice=""
        local selection_error=false

        # Use gum for menu selection
        options=(
            "1) GPU Drivers Installation"
            "2) WiFi Setup & Network Configuration"
            "3) KDE Plasma (macOS-like)"
            "4) GNOME (Windows-like)"
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

        # Handle gum selection with better error handling
        selection=""
        if selection=$(select_option "${options[@]}" 2>/dev/null) && [[ -n "$selection" ]]; then
            # Extract number from selection like "10) AUR Helper Setup" -> "10"
            choice=$(echo "$selection" | cut -d')' -f1)

            # Validate that choice is a number
            if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
                selection_error=true
            fi
        else
            # If gum fails, show a simple message and exit gracefully
            echo -e "${RED}Interactive selection unavailable.${NC}"
            echo -e "${YELLOW}Please run archer in a proper interactive terminal.${NC}"
            echo -e "${YELLOW}Or use command-line options: archer --help${NC}"
            exit 1
        fi        # Handle selection errors
        if [[ "$selection_error" == true ]] || [[ -z "$choice" ]]; then
            gum style --foreground="#ff0000" "Invalid selection or input error. Please try again."
            sleep 2
            continue
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
                gum style --foreground="#ff0000" "Invalid selection. Please try again."
                sleep 1
                ;;
        esac
    done
}

# Run main function with all arguments
main "$@"

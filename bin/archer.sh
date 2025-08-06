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
    echo "  4) KDE Plasma (Windows-like)"
    echo "  5) Switch Desktop Theme (Cupertini ↔ Redmondi)"
    echo ""
    echo -e "${GREEN}Development:${NC}"
    echo "  6) Development Tools & Languages"
    echo "  7) Code Editors & IDEs"
    echo ""
    echo -e "${GREEN}Gaming & Multimedia:${NC}"
    echo "  8) Gaming Setup (Steam, Lutris, Wine)"
    echo "  9) Multimedia Applications"
    echo ""
    echo -e "${GREEN}Office & Productivity:${NC}"
    echo " 10) Office Suite Installation"
    echo ""
    echo -e "${GREEN}System Tools:${NC}"
    echo " 11) AUR Helper Setup"
    echo " 12) System Utilities"
    echo ""
    echo -e "${YELLOW}Quick Profiles:${NC}"
    echo " 13) Complete Gaming Workstation"
    echo " 14) Complete Development Environment"
    echo " 15) Complete Multimedia Setup"
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

        # Special handling for hardware-related scripts
        case "$script_name" in
            "gpu-drivers.sh")
                echo -e "${CYAN}Hardware Detection: Checking for GPU changes...${NC}"
                echo -e "${YELLOW}This will re-detect your GPU hardware and update drivers accordingly.${NC}"
                echo -e "${YELLOW}Perfect for hardware upgrades or driver issues.${NC}"
                if ! confirm_action "Continue with GPU driver detection and installation?"; then
                    echo -e "${YELLOW}GPU driver installation cancelled.${NC}"
                    return 0
                fi
                ;;
            "wifi-setup.sh")
                echo -e "${CYAN}Network Setup: Configuring WiFi connections...${NC}"
                echo -e "${YELLOW}This will help you set up new WiFi connections or fix network issues.${NC}"
                if ! confirm_action "Continue with WiFi setup?"; then
                    echo -e "${YELLOW}WiFi setup cancelled.${NC}"
                    return 0
                fi
                ;;
        esac

        # Run script with proper error handling
        local exit_code=0
        if [[ $EUID -ne 0 ]]; then
            # Reset terminal state and run script
            reset 2>/dev/null || true
            set +e  # Temporarily disable exit on error
            "$script_path"
            exit_code=$?
            set -e  # Re-enable exit on error
        else
            echo -e "${YELLOW}Warning: Running as root. Consider running as regular user.${NC}"
            reset 2>/dev/null || true
            set +e
            "$script_path"
            exit_code=$?
            set -e
        fi

        # Clean up terminal state
        stty sane 2>/dev/null || true
        reset 2>/dev/null || true

        # Clear any leftover input
        while read -r -t 0.1; do true; done 2>/dev/null || true

        if [[ $exit_code -eq 0 ]]; then
            echo -e "${GREEN}$script_name completed successfully!${NC}"
        else
            echo -e "${YELLOW}$script_name exited with code $exit_code${NC}"
            echo -e "${YELLOW}You can try running it again or check for any error messages above.${NC}"
        fi

        wait_for_input
    else
        echo -e "${RED}Script not found: $script_path${NC}"
        wait_for_input
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

# Detect current desktop theme
detect_current_theme() {
    # Check for theme indicators in KDE config files
    if [[ -f "$HOME/.config/kdeglobals" ]]; then
        # Check for McMojave theme (Cupertini)
        if kreadconfig5 --file kdeglobals --group KDE --key LookAndFeelPackage 2>/dev/null | grep -q "McMojave"; then
            echo "cupertini"
            return 0
        fi

        # Check for Windows-like theme indicators (Redmondi)
        if kreadconfig5 --file kdeglobals --group Icons --key Theme 2>/dev/null | grep -q "Windows10"; then
            echo "redmondi"
            return 0
        fi

        # Check plasma theme
        local plasma_theme=$(kreadconfig5 --file plasmarc --group Theme --key name 2>/dev/null || echo "")
        if [[ "$plasma_theme" == "McMojave" ]]; then
            echo "cupertini"
            return 0
        elif [[ "$plasma_theme" =~ [Ww]indows ]]; then
            echo "redmondi"
            return 0
        fi
    fi

    echo "unknown"
}

# Check if a theme is installed
check_theme_installed() {
    local theme="$1"

    case "$theme" in
        "cupertini")
            # Check for KDE Plasma and McMojave theme components
            if ! pacman -Q plasma-desktop &>/dev/null; then
                echo "plasma_missing"
                return 1
            fi

            # Check if kwriteconfig5 is available
            if ! command -v kwriteconfig5 &> /dev/null; then
                echo "theme_missing"
                return 1
            fi

            # Check for McMojave theme (from AUR) - updated package names
            # Check for main theme components installed by cupertini.sh
            local has_theme=false
            local has_cursors=false
            local has_icons=false

            # Check for plasma6 McMojave theme
            if pacman -Q plasma6-theme-mcmojave-git &>/dev/null; then
                has_theme=true
            fi

            # Check for cursors
            if pacman -Q mcmojave-cursors &>/dev/null; then
                has_cursors=true
            fi

            # Check for icon theme
            if pacman -Q mcmojave-circle-icon-theme-git &>/dev/null; then
                has_icons=true
            fi

            # Consider installed if we have at least the main theme and cursors
            if [[ "$has_theme" == true ]] && [[ "$has_cursors" == true ]]; then
                echo "installed"
                return 0
            else
                echo "theme_missing"
                return 1
            fi

            echo "installed"
            return 0
            ;;
        "redmondi")
            # Check for KDE Plasma
            if ! pacman -Q plasma-desktop &>/dev/null; then
                echo "plasma_missing"
                return 1
            fi

            # Check if kwriteconfig5 is available
            if ! command -v kwriteconfig5 &> /dev/null; then
                echo "theme_missing"
                return 1
            fi

            # Check for Windows-like components (fonts and icon theme)
            local has_fonts=false
            local has_icons=false

            # Check for fonts (Liberation or DejaVu are sufficient)
            if pacman -Q ttf-liberation &>/dev/null || pacman -Q ttf-dejavu &>/dev/null; then
                has_fonts=true
            fi

            # Check for icon theme (corrected package name)
            if pacman -Q windows10-icon-theme &>/dev/null; then
                has_icons=true
            fi

            if [[ "$has_fonts" == false ]] || [[ "$has_icons" == false ]]; then
                echo "theme_missing"
                return 1
            fi

            echo "installed"
            return 0
            ;;
    esac

    echo "unknown"
    return 1
}

# Switch between desktop themes
switch_theme() {
    local target_theme="$1"
    local current_theme=$(detect_current_theme)

    echo -e "${BLUE}Theme Switcher${NC}"
    echo -e "${CYAN}===============================================${NC}"

    if [[ "$current_theme" == "unknown" ]]; then
        echo -e "${YELLOW}Current theme: Unknown or default${NC}"
    else
        echo -e "${GREEN}Current theme: ${current_theme^}${NC}"
    fi

    if [[ -n "$target_theme" ]]; then
        echo -e "${YELLOW}Target theme: ${target_theme^}${NC}"
    else
        echo -e "${YELLOW}Available themes:${NC}"
        echo "  • Cupertini (macOS-like KDE Plasma)"
        echo "  • Redmondi (Windows-like KDE Plasma)"
        echo ""

        if [[ "$current_theme" == "cupertini" ]]; then
            echo -e "${CYAN}Switching to Redmondi (Windows-like theme)...${NC}"
            target_theme="redmondi"
        elif [[ "$current_theme" == "redmondi" ]]; then
            echo -e "${CYAN}Switching to Cupertini (macOS-like theme)...${NC}"
            target_theme="cupertini"
        else
            echo -e "${YELLOW}No current theme detected. Please choose:${NC}"
            local theme_options=("Cupertini (macOS-like)" "Redmondi (Windows-like)" "Cancel")
            local selection=$(select_option "${theme_options[@]}")
            case "$selection" in
                "Cupertini (macOS-like)")
                    target_theme="cupertini"
                    ;;
                "Redmondi (Windows-like)")
                    target_theme="redmondi"
                    ;;
                *)
                    echo -e "${YELLOW}Theme switching cancelled.${NC}"
                    return 0
                    ;;
            esac
        fi
    fi

    # Check if target theme is installed
    echo -e "${BLUE}Checking theme installation...${NC}"
    local install_status=$(check_theme_installed "$target_theme")

    case "$install_status" in
        "plasma_missing")
            echo -e "${RED}KDE Plasma is not installed on this system.${NC}"
            echo -e "${YELLOW}The target theme '$target_theme' requires KDE Plasma.${NC}"
            if confirm_action "Would you like to install KDE Plasma first?"; then
                echo -e "${BLUE}Please run the main installation script first to install KDE Plasma.${NC}"
                echo -e "${CYAN}Use: ./install-archer.sh or the full system installation.${NC}"
                return 1
            else
                echo -e "${YELLOW}Theme switching cancelled.${NC}"
                return 0
            fi
            ;;
        "theme_missing")
            echo -e "${YELLOW}Theme components for '$target_theme' are not fully installed.${NC}"
            case "$target_theme" in
                "cupertini")
                    echo -e "${CYAN}Missing components: McMojave theme and related packages${NC}"
                    ;;
                "redmondi")
                    echo -e "${CYAN}Missing components: Windows-like themes and related packages${NC}"
                    ;;
            esac
            echo ""
            if confirm_action "Would you like to install the missing theme components?"; then
                echo -e "${GREEN}Theme components will be installed as part of the theme switch.${NC}"
            else
                echo -e "${YELLOW}Theme switching cancelled.${NC}"
                return 0
            fi
            ;;
        "installed")
            echo -e "${GREEN}✓ Theme '$target_theme' components are already installed.${NC}"
            ;;
        *)
            echo -e "${YELLOW}⚠ Could not verify theme installation status.${NC}"
            echo -e "${YELLOW}Proceeding with theme switch (components will be installed if needed).${NC}"
            ;;
    esac

    echo ""
    echo -e "${YELLOW}This will:${NC}"
    case "$target_theme" in
        "cupertini")
            echo "  • Reset KDE settings to avoid conflicts"
            echo "  • Install McMojave theme and macOS-like components"
            echo "  • Configure dock + top panel layout"
            echo "  • Set SF Pro Display fonts and Tela icons"
            ;;
        "redmondi")
            echo "  • Reset KDE settings to avoid conflicts"
            echo "  • Install Windows-like themes and components"
            echo "  • Configure single bottom taskbar layout"
            echo "  • Set Liberation Sans fonts and Windows10 icons"
            ;;
    esac
    echo ""

    if ! confirm_action "Continue with theme switch to ${target_theme^}?"; then
        echo -e "${YELLOW}Theme switching cancelled.${NC}"
        return 0
    fi

    # Run the appropriate theme script
    case "$target_theme" in
        "cupertini")
            run_script "$INSTALL_DIR/desktop/cupertini.sh"
            ;;
        "redmondi")
            run_script "$INSTALL_DIR/desktop/redmondi.sh"
            ;;
    esac

    echo -e "${GREEN}Theme switch completed!${NC}"
    echo -e "${YELLOW}Please log out and back in to see all changes.${NC}"
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
        "--switch-theme")
            switch_theme "$2"
            exit 0
            ;;
        "--cupertini")
            switch_theme "cupertini"
            exit 0
            ;;
        "--redmondi")
            switch_theme "redmondi"
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
            echo "Desktop Theme Switching:"
            echo "  --switch-theme        Auto-detect and switch between themes"
            echo "  --cupertini           Switch to Cupertini (macOS-like)"
            echo "  --redmondi            Switch to Redmondi (Windows-like)"
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
        show_menu
        options=(
            "1) GPU Drivers Installation"
            "2) WiFi Setup & Network Configuration"
            "3) KDE Plasma (macOS-like)"
            "4) KDE Plasma (Windows-like)"
            "5) Switch Desktop Theme (Cupertini ↔ Redmondi)"
            "6) Development Tools & Languages"
            "7) Code Editors & IDEs"
            "8) Gaming Setup (Steam, Lutris, Wine)"
            "9) Multimedia Applications"
            "10) Office Suite Installation"
            "11) AUR Helper Setup"
            "12) System Utilities"
            "13) Complete Gaming Workstation"
            "14) Complete Development Environment"
            "15) Complete Multimedia Setup"
            "0) Exit"
        )

        selection_error=false
        choice=""
        if selection=$(select_option "${options[@]}") && [[ -n "$selection" ]]; then
            choice=$(echo "$selection" | cut -d')' -f1)
            echo -e "${GREEN}Your selection: ${selection}${NC}"
        else
            # Fallback: use gum input for manual entry
            choice=$(gum input --placeholder "Select an option [0-15]: " --width=20)
            if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
                selection_error=true
            fi
        fi

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
            5)  switch_theme ;;
            6)  run_script "$INSTALL_DIR/development/dev-tools.sh" ;;
            7)  run_script "$INSTALL_DIR/development/editors.sh" ;;
            8)  run_script "$INSTALL_DIR/multimedia/gaming.sh" ;;
            9)  run_script "$INSTALL_DIR/multimedia/media-apps.sh" ;;
            10) run_script "$INSTALL_DIR/desktop/office-tools/office-suite.sh" ;;
            11) run_script "$INSTALL_DIR/extras/aur-helper.sh" ;;
            12) run_script "$INSTALL_DIR/system/system-utilities.sh" ;;
            13) install_profile "gaming" ;;
            14) install_profile "development" ;;
            15) install_profile "multimedia" ;;
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

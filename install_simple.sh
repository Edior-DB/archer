#!/bin/bash

# Archer - Arch Linux Home PC Transformation Suite
# Simplified installer script to avoid looping issues

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Repository configuration
REPO_RAW_URL="https://raw.githubusercontent.com/Edior-DB/archer/master"

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

    Arch Linux Home PC Transformation Suite
EOF
    echo -e "${NC}"
}

# Simple menu
show_menu() {
    show_logo
    echo -e "${CYAN}===============================================${NC}"
    echo -e "${CYAN}        Arch Linux Fresh Installation        ${NC}"
    echo -e "${CYAN}===============================================${NC}"
    echo ""

    # Check if running as root on Live ISO
    if grep -q "archiso" /proc/cmdline 2>/dev/null && [[ "$EUID" -eq 0 ]]; then
        echo -e "${RED}Running as ROOT on Live ISO${NC}"
        echo -e "${GREEN}Available Options:${NC}"
        echo "  1) Fresh Arch Linux Installation"
        echo "  0) Exit"
    else
        echo -e "${GREEN}Options:${NC}"
        echo "  1) Fresh Arch Linux Installation"
        echo "  2) Post-Installation Setup"
        echo "  3) GPU Drivers Installation"
        echo "  4) Desktop Environment Installation"
        echo "  0) Exit"
    fi
    echo ""
    echo -e "${CYAN}===============================================${NC}"
}

# Download and run script
run_arch_install() {
    echo -e "${CYAN}Downloading arch-server-setup.sh...${NC}"
    local github_url="$REPO_RAW_URL/install/system/arch-server-setup.sh"
    local temp_file="/tmp/arch-server-setup.sh"

    if curl -fsSL "$github_url" -o "$temp_file" && chmod +x "$temp_file"; then
        echo -e "${GREEN}Downloaded successfully ($(wc -c < "$temp_file") bytes)${NC}"
        echo -e "${YELLOW}Starting installation...${NC}"
        "$temp_file"
        echo -e "${GREEN}Installation completed!${NC}"
    else
        echo -e "${RED}Failed to download installation script${NC}"
        echo -e "${YELLOW}Please check your internet connection${NC}"
    fi

    echo ""
    read -p "Press Enter to continue..."
}

# Simple placeholder for other options
run_placeholder() {
    local option_name="$1"
    echo -e "${YELLOW}$option_name${NC}"
    echo -e "${CYAN}This feature will be available after base installation${NC}"
    echo ""
    read -p "Press Enter to continue..."
}

# Main function
main() {
    # Check if Arch Linux
    if [[ ! -f /etc/arch-release ]] && ! grep -q "archiso" /proc/cmdline 2>/dev/null; then
        echo -e "${RED}This script is designed for Arch Linux only.${NC}"
        exit 1
    fi

    # Check internet
    if ! ping -c 1 8.8.8.8 &> /dev/null; then
        echo -e "${RED}No internet connection detected.${NC}"
        exit 1
    fi

    # Main loop
    while true; do
        show_menu

        # Get user choice
        if grep -q "archiso" /proc/cmdline 2>/dev/null && [[ "$EUID" -eq 0 ]]; then
            echo -n "Select option [0-1]: "
        else
            echo -n "Select option [0-4]: "
        fi

        read -r choice
        echo ""

        case "$choice" in
            1)
                if grep -q "archiso" /proc/cmdline 2>/dev/null && [[ "$EUID" -eq 0 ]]; then
                    run_arch_install
                else
                    run_placeholder "Fresh Arch Linux Installation (use on Live ISO as root)"
                fi
                ;;
            2)
                if ! (grep -q "archiso" /proc/cmdline 2>/dev/null && [[ "$EUID" -eq 0 ]]); then
                    run_placeholder "Post-Installation Setup"
                else
                    echo -e "${RED}Invalid option${NC}"
                    sleep 1
                fi
                ;;
            3)
                if ! (grep -q "archiso" /proc/cmdline 2>/dev/null && [[ "$EUID" -eq 0 ]]); then
                    run_placeholder "GPU Drivers Installation"
                else
                    echo -e "${RED}Invalid option${NC}"
                    sleep 1
                fi
                ;;
            4)
                if ! (grep -q "archiso" /proc/cmdline 2>/dev/null && [[ "$EUID" -eq 0 ]]); then
                    run_placeholder "Desktop Environment Installation"
                else
                    echo -e "${RED}Invalid option${NC}"
                    sleep 1
                fi
                ;;
            0)
                echo -e "${GREEN}Thank you for using Archer!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                sleep 1
                ;;
        esac
    done
}

# Run main function
main "$@"

#!/bin/bash

# Archer - Arch Linux Home PC Transformation Suite
# Main installer script

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
    cat << "LOGOEOF"
 █████╗ ██████╗  ██████╗██╗  ██╗███████╗██████╗
██╔══██╗██╔══██╗██╔════╝██║  ██║██╔════╝██╔══██╗
███████║██████╔╝██║     ███████║█████╗  ██████╔╝
██╔══██║██╔══██╗██║     ██╔══██║██╔══╝  ██╔══██╗
██║  ██║██║  ██║╚██████╗██║  ██║███████╗██║  ██║
╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝

    Arch Linux Home PC Transformation Suite
LOGOEOF
    echo -e "${NC}"
    
    # Show test mode if enabled
    if [[ "$TEST_MODE" == "true" ]]; then
        echo -e "${YELLOW}TEST MODE - Running on $(lsb_release -d 2>/dev/null | cut -f2 || echo "Non-Arch system")${NC}"
    fi
}

# Show main menu
show_menu() {
    show_logo
    echo -e "${CYAN}===============================================${NC}"
    echo -e "${CYAN}        Arch Linux Fresh Installation        ${NC}"
    echo -e "${CYAN}===============================================${NC}"
    echo ""

    # Check if running as root on Live ISO
    if grep -q "archiso" /proc/cmdline 2>/dev/null && [[ "$EUID" -eq 0 ]] && [[ "$TEST_MODE" != "true" ]]; then
        echo -e "${RED}Running as ROOT on Live ISO${NC}"
        echo -e "${YELLOW}Security restriction: Only base system installation allowed${NC}"
        echo ""
        echo -e "${GREEN}Available Options:${NC}"
        echo "  1) Fresh Arch Linux Installation (arch-server-setup.sh)"
        echo ""
        echo -e "${CYAN}After installation:${NC}"
        echo -e "${CYAN} • Reboot and login as your new user${NC}"
        echo -e "${CYAN} • Run this installer again for additional setup${NC}"
        echo ""
        echo " 0) Exit"
    else
        echo -e "${GREEN}Core Installation (Run from Live ISO):${NC}"
        echo "  1) Fresh Arch Linux Installation"
        echo "  2) Post-Installation Setup (Essential packages, AUR)"
        echo "  3) GPU Drivers Installation"
        echo "  4) Desktop Environment Installation"
        echo "  5) WiFi Setup (if needed)"
        echo ""
        echo -e "${YELLOW}Quick Installation Profiles:${NC}"
        echo "  6) Complete Base System (1+2+3+4+5)"
        echo "  7) Gaming Ready System (Base + Gaming optimizations)"
        echo "  8) Developer Workstation (Base + Dev tools)"
        echo ""
        echo -e "${CYAN}Post-Installation Management:${NC}"
        echo "  9) Launch Archer Post-Installation Tool"
        echo ""
        echo " 0) Exit"
    fi

    echo ""
    echo -e "${CYAN}===============================================${NC}"

    if grep -q "archiso" /proc/cmdline 2>/dev/null && [[ "$EUID" -eq 0 ]] && [[ "$TEST_MODE" != "true" ]]; then
        echo -e "${YELLOW}Note: Additional features available after user login${NC}"
    else
        echo -e "${YELLOW}Note: After base installation, use 'archer' command${NC}"
        echo -e "${YELLOW}for additional software and customizations.${NC}"
    fi
}

# Download and run arch-server-setup.sh
run_arch_install() {
    echo -e "${CYAN}Fetching arch-server-setup.sh from GitHub...${NC}"
    local github_url="$REPO_RAW_URL/install/system/arch-server-setup.sh"
    local temp_file="/tmp/arch-server-setup.sh"
    
    if curl -fsSL "$github_url" -o "$temp_file" && chmod +x "$temp_file"; then
        echo -e "${GREEN}Successfully downloaded ($(wc -c < "$temp_file") bytes)${NC}"
        echo -e "${CYAN}Starting installation...${NC}"
        "$temp_file"
        echo -e "${GREEN}Installation script completed!${NC}"
    else
        echo -e "${RED}Failed to fetch arch-server-setup.sh from GitHub${NC}"
        echo -e "${YELLOW}Please check your internet connection${NC}"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Placeholder for other options
show_placeholder() {
    local option_name="$1"
    echo -e "${YELLOW}$option_name${NC}"
    echo -e "${CYAN}This feature will be available in a future update${NC}"
    echo ""
    read -p "Press Enter to continue..."
}

# Main function
main() {
    # Handle test mode
    if [[ "$1" == "--test" ]]; then
        export TEST_MODE="true"
        echo -e "${CYAN}TEST MODE ENABLED${NC}"
        echo -e "${YELLOW}Script will run in test mode - no actual system changes will be made${NC}"
        sleep 2
    fi

    # Check if Arch Linux or Live ISO (skip in test mode)
    if [[ "$TEST_MODE" != "true" ]]; then
        if [[ ! -f /etc/arch-release ]] && ! grep -q "archiso" /proc/cmdline 2>/dev/null; then
            echo -e "${RED}This script is designed for Arch Linux only.${NC}"
            echo -e "${YELLOW}Run from Arch Linux Live ISO for fresh installation, or from installed Arch Linux system.${NC}"
            echo -e "${CYAN}For testing on other systems, use: $0 --test${NC}"
            exit 1
        fi

        # Check internet connection
        if ! ping -c 1 8.8.8.8 &> /dev/null; then
            echo -e "${RED}No internet connection detected.${NC}"
            echo -e "${YELLOW}Please ensure you have an active internet connection.${NC}"
            exit 1
        fi
        echo -e "${GREEN}Internet connection: OK${NC}"
    fi

    # Main interactive loop
    while true; do
        show_menu
        
        # Get user input
        if grep -q "archiso" /proc/cmdline 2>/dev/null && [[ "$EUID" -eq 0 ]] && [[ "$TEST_MODE" != "true" ]]; then
            echo -n "Select an option [0-1]: "
        else
            echo -n "Select an option [0-9]: "
        fi
        
        read -r choice
        echo ""
        
        # Process choice
        case "$choice" in
            1)
                if [[ "$TEST_MODE" == "true" ]]; then
                    echo -e "${CYAN}TEST MODE: Would execute Fresh Arch Linux Installation${NC}"
                    read -p "Press Enter to continue..."
                elif grep -q "archiso" /proc/cmdline 2>/dev/null && [[ "$EUID" -eq 0 ]]; then
                    run_arch_install
                else
                    echo -e "${YELLOW}Fresh Arch Linux Installation should be run from Live ISO as root${NC}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            2)
                if grep -q "archiso" /proc/cmdline 2>/dev/null && [[ "$EUID" -eq 0 ]] && [[ "$TEST_MODE" != "true" ]]; then
                    echo -e "${RED}Option not available as root on Live ISO${NC}"
                    echo -e "${YELLOW}Please complete base installation first${NC}"
                    read -p "Press Enter to continue..."
                else
                    show_placeholder "Post-Installation Setup"
                fi
                ;;
            3)
                if grep -q "archiso" /proc/cmdline 2>/dev/null && [[ "$EUID" -eq 0 ]] && [[ "$TEST_MODE" != "true" ]]; then
                    echo -e "${RED}Option not available as root on Live ISO${NC}"
                    echo -e "${YELLOW}Please complete base installation first${NC}"
                    read -p "Press Enter to continue..."
                else
                    show_placeholder "GPU Drivers Installation"
                fi
                ;;
            4)
                if grep -q "archiso" /proc/cmdline 2>/dev/null && [[ "$EUID" -eq 0 ]] && [[ "$TEST_MODE" != "true" ]]; then
                    echo -e "${RED}Option not available as root on Live ISO${NC}"
                    echo -e "${YELLOW}Please complete base installation first${NC}"
                    read -p "Press Enter to continue..."
                else
                    show_placeholder "Desktop Environment Installation"
                fi
                ;;
            5)
                if grep -q "archiso" /proc/cmdline 2>/dev/null && [[ "$EUID" -eq 0 ]] && [[ "$TEST_MODE" != "true" ]]; then
                    echo -e "${RED}Option not available as root on Live ISO${NC}"
                    echo -e "${YELLOW}Please complete base installation first${NC}"
                    read -p "Press Enter to continue..."
                else
                    show_placeholder "WiFi Setup"
                fi
                ;;
            6|7|8|9)
                if grep -q "archiso" /proc/cmdline 2>/dev/null && [[ "$EUID" -eq 0 ]] && [[ "$TEST_MODE" != "true" ]]; then
                    echo -e "${RED}Option not available as root on Live ISO${NC}"
                    echo -e "${YELLOW}Please complete base installation first${NC}"
                    read -p "Press Enter to continue..."
                else
                    show_placeholder "Installation Profile"
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

# Run main function with all arguments
main "$@"

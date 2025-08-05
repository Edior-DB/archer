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

# Enhanced input function using gum if available
get_user_confirmation() {
    local prompt="$1"
    local default="${2:-N}"

    if command -v gum >/dev/null 2>&1; then
        # Use gum for better UX
        if gum confirm "$prompt"; then
            echo "y"
        else
            echo "n"
        fi
    else
        # Fallback to standard read
        echo -e "${YELLOW}$prompt (y/N)${NC}"
        echo -n "> "
        read -r response
        echo "${response:-$default}"
    fi
}

# Enhanced menu selection using gum if available
get_menu_selection() {
    local title="$1"
    shift
    local options=("$@")

    if command -v gum >/dev/null 2>&1; then
        # Use gum for better menu UX
        gum choose --header="$title" "${options[@]}"
    else
        # Fallback to traditional menu
        echo -e "${CYAN}$title${NC}"
        for i in "${!options[@]}"; do
            echo "  $((i+1))) ${options[$i]}"
        done
        echo ""
        echo -n "Select an option: "
        read -r choice

        # Convert number to option text
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -gt 0 ] && [ "$choice" -le "${#options[@]}" ]; then
            echo "${options[$((choice-1))]}"
        else
            echo "Invalid"
        fi
    fi
}

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

# Show Live ISO installation prompt
show_livecd_prompt() {
    show_logo
    echo -e "${CYAN}===============================================${NC}"
    echo -e "${CYAN}        Arch Linux Fresh Installation        ${NC}"
    echo -e "${CYAN}===============================================${NC}"
    echo ""
    echo -e "${RED}Running as ROOT on Live ISO${NC}"
    echo -e "${YELLOW}Ready to install Arch Linux to your system${NC}"
    echo ""
    echo -e "${GREEN}This will:${NC}"
    echo -e "${GREEN} • Download and run arch-server-setup.sh${NC}"
    echo -e "${GREEN} • Guide you through disk partitioning${NC}"
    echo -e "${GREEN} • Install base Arch Linux system${NC}"
    echo -e "${GREEN} • Create user account${NC}"
    echo ""
    echo -e "${CYAN}After installation:${NC}"
    echo -e "${CYAN} • Reboot and login as your new user${NC}"
    echo -e "${CYAN} • Run this installer again for additional setup${NC}"
    echo ""
    echo -e "${CYAN}===============================================${NC}"
}

# Show main menu
show_menu() {
    show_logo
    echo -e "${CYAN}===============================================${NC}"
    echo -e "${CYAN}        Arch Linux Fresh Installation        ${NC}"
    echo -e "${CYAN}===============================================${NC}"
    echo ""

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

    echo ""
    echo -e "${CYAN}===============================================${NC}"
    echo -e "${YELLOW}Note: After base installation, use 'archer' command${NC}"
    echo -e "${YELLOW}for additional software and customizations.${NC}"
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

    if command -v gum >/dev/null 2>&1; then
        gum style --foreground="#ffff00" --bold "$option_name"
        gum style --foreground="#00ffff" "This feature will be available in a future update"
        echo ""
        gum style --foreground="#ffffff" "Press Enter to continue..."
        read -r
    else
        echo -e "${YELLOW}$option_name${NC}"
        echo -e "${CYAN}This feature will be available in a future update${NC}"
        echo ""
        read -p "Press Enter to continue..."
    fi
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

        # Install required packages on any Arch system
        if command -v pacman >/dev/null 2>&1; then
            echo -e "${CYAN}Ensuring required packages are installed...${NC}"
            if ! command -v gum >/dev/null 2>&1 || ! command -v git >/dev/null 2>&1; then
                echo -e "${YELLOW}Installing git and gum for better user experience...${NC}"
                if pacman -Sy --noconfirm git gum >/dev/null 2>&1; then
                    echo -e "${GREEN}Required packages installed successfully${NC}"
                else
                    echo -e "${YELLOW}Warning: Could not install some packages, falling back to basic prompts${NC}"
                    # At least try to install git which is essential
                    pacman -Sy --noconfirm git >/dev/null 2>&1 || true
                fi
            else
                echo -e "${GREEN}Required packages already installed${NC}"
            fi
        fi
    fi

    # Main interactive loop
    while true; do
        # Check if running as root on Live ISO
        if grep -q "archiso" /proc/cmdline 2>/dev/null && [[ "$EUID" -eq 0 ]] && [[ "$TEST_MODE" != "true" ]]; then
            # Live ISO mode - direct installation prompt
            show_livecd_prompt
            echo ""

            # Get user confirmation using gum if available
            confirm=$(get_user_confirmation "Do you want to proceed with Arch Linux installation?")

            case "${confirm,,}" in
                y|yes)
                    run_arch_install
                    # After installation, exit the script
                    echo -e "${GREEN}Installation completed. Please reboot your system.${NC}"
                    exit 0
                    ;;
                n|no|"")
                    echo -e "${CYAN}Installation cancelled. Exiting...${NC}"
                    exit 0
                    ;;
                *)
                    echo -e "${RED}Please answer 'y' for yes or 'n' for no.${NC}"
                    echo ""
                    read -p "Press Enter to try again..." -r
                    ;;
            esac
        else
            # Normal mode - show full menu
            show_menu

            if command -v gum >/dev/null 2>&1; then
                # Use gum for menu selection
                options=(
                    "1) Fresh Arch Linux Installation"
                    "2) Post-Installation Setup (Essential packages, AUR)"
                    "3) GPU Drivers Installation"
                    "4) Desktop Environment Installation"
                    "5) WiFi Setup (if needed)"
                    "6) Complete Base System (1+2+3+4+5)"
                    "7) Gaming Ready System (Base + Gaming optimizations)"
                    "8) Developer Workstation (Base + Dev tools)"
                    "9) Launch Archer Post-Installation Tool"
                    "0) Exit"
                )

                selection=$(gum choose --header="Select an option:" "${options[@]}")
                choice="${selection:0:1}"  # Extract number from selection
            else
                # Fallback to traditional input
                echo -n "Select an option [0-9]: "
                read -r choice
            fi

            echo ""

            # Process choice
            case "$choice" in
                1)
                    if [[ "$TEST_MODE" == "true" ]]; then
                        echo -e "${CYAN}TEST MODE: Would execute Fresh Arch Linux Installation${NC}"
                        read -p "Press Enter to continue..."
                    else
                        echo -e "${YELLOW}Fresh Arch Linux Installation should be run from Live ISO as root${NC}"
                        read -p "Press Enter to continue..."
                    fi
                    ;;
                2)
                    show_placeholder "Post-Installation Setup"
                    ;;
                3)
                    show_placeholder "GPU Drivers Installation"
                    ;;
                4)
                    show_placeholder "Desktop Environment Installation"
                    ;;
                5)
                    show_placeholder "WiFi Setup"
                    ;;
                6|7|8|9)
                    show_placeholder "Installation Profile"
                    ;;
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
        fi
    done
}

# Run main function with all arguments
main "$@"

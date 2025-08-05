#!/bin/bash

# Archer - Arch Linux Home PC Transformation Suite
# Test version for non-Arch systems

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
    TEST MODE - Running on $(lsb_release -d 2>/dev/null | cut -f2 || echo "Non-Arch system")
EOF
    echo -e "${NC}"
}

# Simple menu
show_menu() {
    show_logo
    echo -e "${CYAN}===============================================${NC}"
    echo -e "${CYAN}        TEST MODE - Menu Demonstration        ${NC}"
    echo -e "${CYAN}===============================================${NC}"
    echo ""

    echo -e "${GREEN}Available Options:${NC}"
    echo "  1) Test Download (arch-server-setup.sh)"
    echo "  2) Test Option 2"
    echo "  3) Test Option 3"
    echo "  4) Test Option 4"
    echo "  0) Exit"
    echo ""
    echo -e "${CYAN}===============================================${NC}"
}

# Test download
test_download() {
    echo -e "${CYAN}Testing download of arch-server-setup.sh...${NC}"
    local github_url="$REPO_RAW_URL/install/system/arch-server-setup.sh"
    local temp_file="/tmp/test-arch-server-setup.sh"

    if curl -fsSL "$github_url" -o "$temp_file"; then
        echo -e "${GREEN}Download successful! ($(wc -c < "$temp_file") bytes)${NC}"
        echo -e "${YELLOW}First 5 lines:${NC}"
        head -5 "$temp_file"
        echo -e "${YELLOW}Last 3 lines:${NC}"
        tail -3 "$temp_file"
        rm -f "$temp_file"
    else
        echo -e "${RED}Download failed${NC}"
    fi

    echo ""
    read -p "Press Enter to continue..."
}

# Test placeholder
test_option() {
    local option_num="$1"
    echo -e "${YELLOW}Testing Option $option_num${NC}"
    echo -e "${CYAN}This is a test of menu option $option_num${NC}"
    echo -e "${GREEN}Menu system working correctly!${NC}"
    echo ""
    read -p "Press Enter to continue..."
}

# Main function
main() {
    echo -e "${YELLOW}Starting Archer installer test...${NC}"
    sleep 1

    # Main loop
    while true; do
        show_menu

        # Get user choice
        echo -n "Select option [0-4]: "
        read -r choice
        echo ""

        case "$choice" in
            1)
                test_download
                ;;
            2)
                test_option "2"
                ;;
            3)
                test_option "3"
                ;;
            4)
                test_option "4"
                ;;
            0)
                echo -e "${GREEN}Thank you for testing Archer!${NC}"
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

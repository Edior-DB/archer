#!/bin/bash

# Desktop Environment Installer
# Part of Archer - Arch Linux Home PC Transformation Suite

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/..}/install/system/common-funcs.sh"

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Show logo
show_logo() {
    echo -e "${BLUE}"
    cat << "EOF"
██████╗ ███████╗███████╗██╗  ██╗████████╗ ██████╗ ██████╗
██╔══██╗██╔════╝██╔════╝██║ ██╔╝╚══██╔══╝██╔═══██╗██╔══██╗
██║  ██║█████╗  ███████╗█████╔╝    ██║   ██║   ██║██████╔╝
██║  ██║██╔══╝  ╚════██║██╔═██╗    ██║   ██║   ██║██╔═══╝
██████╔╝███████╗███████║██║  ██╗   ██║   ╚██████╔╝██║
╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝

        Desktop Environment Installer
EOF
    echo -e "${NC}"
}

# Show menu
show_menu() {
    clear
    show_logo
    echo -e "${CYAN}===============================================${NC}"
    echo -e "${CYAN}        Choose Your Desktop Experience        ${NC}"
    echo -e "${CYAN}===============================================${NC}"
    echo ""
    echo -e "${GREEN}Available Desktop Environments:${NC}"
    echo ""
    echo -e "${BLUE}1) Redmondi${NC} - Windows-like Experience"
    echo -e "   ${YELLOW}• Based on GNOME with Windows 10/11 styling${NC}"
    echo -e "   ${YELLOW}• Familiar taskbar and start menu${NC}"
    echo -e "   ${YELLOW}• Arc-Dark theme with Windows-like layout${NC}"
    echo -e "   ${YELLOW}• Perfect for Windows users transitioning to Linux${NC}"
    echo ""
    echo -e "${PURPLE}2) Cupertini${NC} - macOS-like Experience"
    echo -e "   ${YELLOW}• Based on KDE Plasma with macOS styling${NC}"
    echo -e "   ${YELLOW}• macOS-like dock and menu bar${NC}"
    echo -e "   ${YELLOW}• McMojave theme with macOS animations${NC}"
    echo -e "   ${YELLOW}• Perfect for macOS users or those who love clean design${NC}"
    echo ""
    echo -e "${CYAN}3) Custom Installation${NC} - Choose Your Own"
    echo -e "   ${YELLOW}• Install base GNOME or KDE without theming${NC}"
    echo -e "   ${YELLOW}• Customize yourself${NC}"
    echo ""
    echo -e "${GREEN}4) Office Tools${NC} - Install Office Suite"
    echo -e "   ${YELLOW}• Choose from LibreOffice, OnlyOffice, WPS, etc.${NC}"
    echo -e "   ${YELLOW}• Web-based options (Office 365, Google Workspace)${NC}"
    echo ""
    echo " 0) Back to Main Menu"
    echo ""
    echo -e "${CYAN}===============================================${NC}"
}

# Install base GNOME
install_base_gnome() {
    echo -e "${BLUE}Installing base GNOME desktop environment...${NC}"

    local gnome_packages=(
        "gnome"
        "gnome-extra"
        "gdm"
        "xorg"
        "xorg-server"
        "firefox"
        "file-roller"
        "gnome-tweaks"
    )

    for package in "${gnome_packages[@]}"; do
        echo -e "${YELLOW}Installing $package...${NC}"
    done
    install_packages "${gnome_packages[@]}"

    sudo systemctl enable gdm
    echo -e "${GREEN}Base GNOME installed!${NC}"
}

# Install base KDE
install_base_kde() {
    echo -e "${BLUE}Installing base KDE Plasma desktop environment...${NC}"

    local kde_packages=(
        "plasma"
        "kde-applications"
        "sddm"
        "xorg"
        "xorg-server"
        "firefox"
        "ark"
    )

    for package in "${kde_packages[@]}"; do
        echo -e "${YELLOW}Installing $package...${NC}"
    done
    install_packages "${kde_packages[@]}"

    sudo systemctl enable sddm
    echo -e "${GREEN}Base KDE Plasma installed!${NC}"
}

# Custom installation menu
custom_installation() {
    echo -e "${BLUE}Custom Desktop Environment Installation${NC}"
    echo ""
    echo "1) Base GNOME"
    echo "2) Base KDE Plasma"
    echo "0) Back"
    echo ""
    read -p "Select an option [0-2]: " choice

    case $choice in
        1) install_base_gnome ;;
        2) install_base_kde ;;
        0) return ;;
        *) echo -e "${RED}Invalid option${NC}" ;;
    esac
}

# Main function
main() {
    while true; do
        show_menu
        read -p "Select an option [0-4]: " choice

        case $choice in
            1)
                echo -e "${BLUE}Starting Redmondi (Windows-like) installation...${NC}"
                if [[ -f "$SCRIPT_DIR/redmondi.sh" ]]; then
                    chmod +x "$SCRIPT_DIR/redmondi.sh"
                    "$SCRIPT_DIR/redmondi.sh"
                else
                    echo -e "${RED}Redmondi script not found!${NC}"
                fi
                read -p "Press Enter to continue..."
                ;;
            2)
                echo -e "${BLUE}Starting Cupertini (macOS-like) installation...${NC}"
                if [[ -f "$SCRIPT_DIR/cupertini.sh" ]]; then
                    chmod +x "$SCRIPT_DIR/cupertini.sh"
                    "$SCRIPT_DIR/cupertini.sh"
                else
                    echo -e "${RED}Cupertini script not found!${NC}"
                fi
                read -p "Press Enter to continue..."
                ;;
            3)
                custom_installation
                read -p "Press Enter to continue..."
                ;;
            4)
                echo -e "${BLUE}Opening Office Tools installer...${NC}"
                if [[ -f "$SCRIPT_DIR/office-tools/office-suite.sh" ]]; then
                    chmod +x "$SCRIPT_DIR/office-tools/office-suite.sh"
                    "$SCRIPT_DIR/office-tools/office-suite.sh"
                else
                    echo -e "${RED}Office suite script not found!${NC}"
                fi
                read -p "Press Enter to continue..."
                ;;
            0)
                echo -e "${GREEN}Returning to main menu...${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Run main function
main

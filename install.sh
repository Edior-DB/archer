#!/bin/bash

# Archer - Arch Linux Installation Suite
# Main entry point script

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
    echo -e "${BLUE}"
    cat << "LOGOEOF"
 █████╗ ██████╗  ██████╗██╗  ██╗███████╗██████╗
██╔══██╗██╔══██╗██╔════╝██║  ██║██╔════╝██╔══██╗
███████║██████╔╝██║     ███████║█████╗  ██████╔╝
██╔══██║██╔══██╗██║     ██╔══██║██╔══╝  ██╔══██╗
██║  ██║██║  ██║╚██████╗██║  ██║███████╗██║  ██║
╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝

       Arch Linux Installation Suite
LOGOEOF
    echo -e "${NC}"
}

# Detect environment and provide guidance
detect_environment() {
    show_logo
    echo -e "${CYAN}===============================================${NC}"
    echo -e "${CYAN}          Environment Detection              ${NC}"
    echo -e "${CYAN}===============================================${NC}"
    echo ""

    # Check if Arch Linux Live ISO
    if grep -q "archiso" /proc/cmdline 2>/dev/null; then
        echo -e "${GREEN}✓ Arch Linux Live ISO detected${NC}"
        echo ""
        echo -e "${CYAN}For fresh Arch Linux installation:${NC}"
        echo -e "${GREEN}  curl -fsSL $REPO_RAW_URL/install-system.sh | bash${NC}"
        echo ""
        echo -e "${YELLOW}This will guide you through complete system installation.${NC}"

    elif [[ -f /etc/arch-release ]]; then
        echo -e "${GREEN}✓ Installed Arch Linux system detected${NC}"
        echo ""
        echo -e "${CYAN}For post-installation setup and customization:${NC}"
        echo -e "${GREEN}  curl -fsSL $REPO_RAW_URL/install-archer.sh | bash${NC}"
        echo ""
        echo -e "${YELLOW}This will install development tools, drivers, and setup the 'archer' command.${NC}"

    else
        echo -e "${YELLOW}⚠ Non-Arch system detected${NC}"
        echo ""
        echo -e "${RED}Archer is designed specifically for Arch Linux.${NC}"
        echo ""
        echo -e "${CYAN}To use Archer:${NC}"
        echo -e "${CYAN} 1. Boot from Arch Linux Live ISO${NC}"
        echo -e "${CYAN} 2. Run: curl -fsSL $REPO_RAW_URL/install-system.sh | bash${NC}"
        echo -e "${CYAN} 3. After installation, run: curl -fsSL $REPO_RAW_URL/install-archer.sh | bash${NC}"
    fi

    echo ""
    echo -e "${CYAN}===============================================${NC}"
}

# Interactive mode for direct execution
interactive_mode() {
    # Install gum for better UX across all environments
    echo -e "${CYAN}Installing gum for better user experience...${NC}"
    if grep -q "archiso" /proc/cmdline 2>/dev/null; then
        # Live ISO - use pacman directly
        pacman -Sy --noconfirm gum 2>/dev/null || echo -e "${YELLOW}Gum not available, using fallback interface${NC}"
    elif [[ -f /etc/arch-release ]]; then
        # Installed Arch - use sudo
        sudo pacman -S --noconfirm gum 2>/dev/null || echo -e "${YELLOW}Gum not available, using fallback interface${NC}"
    fi
    echo ""

    # Show environment detection first
    detect_environment
    echo ""

    if grep -q "archiso" /proc/cmdline 2>/dev/null && [[ "$EUID" -eq 0 ]]; then
        # Live ISO as root - offer system installation
        if gum confirm "Do you want to proceed with Arch Linux system installation?"; then
            echo -e "${CYAN}Downloading and running system installer...${NC}"
            curl -fsSL "$REPO_RAW_URL/install-system.sh" | bash
        else
            echo -e "${CYAN}Installation cancelled.${NC}"
        fi

    elif [[ -f /etc/arch-release ]] && [[ "$EUID" -ne 0 ]]; then
        # Installed Arch as user - offer post-installation setup
        if gum confirm "Do you want to proceed with Archer post-installation setup?"; then
            echo -e "${CYAN}Downloading and running post-installation setup...${NC}"
            curl -fsSL "$REPO_RAW_URL/install-archer.sh" | bash
        else
            echo -e "${CYAN}Setup cancelled.${NC}"
        fi

    else
        # Show guidance only - already shown above
        echo -e "${CYAN}Please follow the instructions above for your environment.${NC}"
    fi
}

# Main execution
main() {
    case "${1:-}" in
        --help|-h)
            show_logo
            echo "Archer - Arch Linux Installation Suite"
            echo ""
            echo "Usage:"
            echo "  $0                    Interactive mode with environment detection"
            echo "  $0 --help, -h        Show this help"
            echo ""
            echo "Environment-specific installers:"
            echo "  install-system.sh     Fresh Arch installation (Live ISO only)"
            echo "  install-archer.sh     Post-installation setup (installed Arch only)"
            echo ""
            echo "The main script will detect your environment and guide you to the appropriate installer."
            exit 0
            ;;
        *)
            interactive_mode
            ;;
    esac
}

# Run main function
main "$@"

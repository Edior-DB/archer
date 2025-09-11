#!/bin/bash

# Extras Installation Script
# Install additional software and applications

set -e

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$(dirname "$SCRIPT_DIR")"

# Source common functions
source "$INSTALL_DIR/system/common-funcs.sh"

# Default installations for different modes
install_essential() {
    echo -e "${BLUE}Installing essential extra applications...${NC}"

    # Essential browsers
    execute_with_progress "Installing Firefox" bash "$SCRIPT_DIR/browsers/firefox-install.sh"
    execute_with_progress "Installing Brave Browser" bash "$SCRIPT_DIR/browsers/brave-install.sh"

    # Basic virtualization
    execute_with_progress "Installing Virtual Machine Manager" bash "$SCRIPT_DIR/virtualization/virt-manager-install.sh"

    echo -e "${GREEN}✓ Essential extra applications installed${NC}"
}

install_all() {
    echo -e "${BLUE}Installing all extra applications...${NC}"

    # All browsers
    install_browsers

    # All virtualization
    install_virtualization

    # All communication tools
    install_communication

    # All utilities
    install_utilities

    echo -e "${GREEN}✓ All extra applications installed${NC}"
}

install_browsers() {
    echo -e "${BLUE}Installing web browsers...${NC}"

    if [[ -f "$SCRIPT_DIR/browsers/install.sh" ]]; then
        bash "$SCRIPT_DIR/browsers/install.sh"
    else
        execute_with_progress "Installing Firefox" bash "$SCRIPT_DIR/browsers/firefox-install.sh"
        execute_with_progress "Installing Brave Browser" bash "$SCRIPT_DIR/browsers/brave-install.sh"
    fi
}

install_virtualization() {
    echo -e "${BLUE}Installing virtualization tools...${NC}"

    if [[ -f "$SCRIPT_DIR/virtualization/install.sh" ]]; then
        bash "$SCRIPT_DIR/virtualization/install.sh"
    else
        execute_with_progress "Installing Virtual Machine Manager" bash "$SCRIPT_DIR/virtualization/virt-manager-install.sh"
    fi
}

install_communication() {
    echo -e "${BLUE}Installing communication tools...${NC}"

    if [[ -f "$SCRIPT_DIR/communication/install.sh" ]]; then
        bash "$SCRIPT_DIR/communication/install.sh"
    else
        echo -e "${YELLOW}⚠ Communication tools not yet implemented${NC}"
    fi
}

install_utilities() {
    echo -e "${BLUE}Installing utilities...${NC}"

    if [[ -f "$SCRIPT_DIR/utilities/install.sh" ]]; then
        bash "$SCRIPT_DIR/utilities/install.sh"
    else
        echo -e "${YELLOW}⚠ Utilities not yet implemented${NC}"
    fi
}

# Main installation logic
main() {
    check_system_requirements

    case "${1:-}" in
        --essential)
            install_essential
            ;;
        --all)
            install_all
            ;;
        --browsers)
            install_browsers
            ;;
        --virtualization)
            install_virtualization
            ;;
        --communication)
            install_communication
            ;;
        --utilities)
            install_utilities
            ;;
        "")
            echo -e "${BLUE}Archer Extras Installation${NC}"
            echo ""
            echo "Available options:"
            echo "  --essential        Install essential extra applications"
            echo "  --all              Install all extra applications"
            echo "  --browsers         Install web browsers only"
            echo "  --virtualization   Install virtualization tools only"
            echo "  --communication    Install communication tools only"
            echo "  --utilities        Install utilities only"
            echo ""
            read -p "Choose installation type [essential/all/browsers/virtualization]: " choice
            case "$choice" in
                essential|e) install_essential ;;
                all|a) install_all ;;
                browsers|b) install_browsers ;;
                virtualization|v) install_virtualization ;;
                communication|c) install_communication ;;
                utilities|u) install_utilities ;;
                *) echo -e "${RED}Invalid choice${NC}"; exit 1 ;;
            esac
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --essential, --all, --browsers, --virtualization, --communication, or --utilities"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"

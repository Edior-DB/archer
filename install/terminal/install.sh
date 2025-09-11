#!/bin/bash

# Terminal Tools Installation Script
# Install command-line utilities, shell enhancements, and terminal tools

set -e

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$(dirname "$SCRIPT_DIR")"

# Source common functions
source "$INSTALL_DIR/system/common-funcs.sh"

# Default installations for different modes
install_essential() {
    echo -e "${BLUE}Installing essential terminal tools...${NC}"

    # Essential CLI tools
    execute_with_progress "Installing Essential CLI Tools" bash "$SCRIPT_DIR/cli-tools/essential-tools.sh"
    execute_with_progress "Installing System Monitors" bash "$SCRIPT_DIR/monitoring/htop-btop.sh"
    execute_with_progress "Installing Shell Enhancements" bash "$SCRIPT_DIR/shell/zsh-setup.sh"

    echo -e "${GREEN}✓ Essential terminal tools installed${NC}"
}

install_all() {
    echo -e "${BLUE}Installing all terminal tools...${NC}"

    # Install all categories
    install_shell_tools
    install_cli_tools
    install_monitoring_tools
    install_text_tools
    install_file_tools
    install_network_tools

    echo -e "${GREEN}✓ All terminal tools installed${NC}"
}

install_modern() {
    echo -e "${BLUE}Installing modern CLI replacements...${NC}"

    execute_with_progress "Installing Modern CLI Tools" bash "$SCRIPT_DIR/cli-tools/modern-replacements.sh"
    execute_with_progress "Installing Modern File Tools" bash "$SCRIPT_DIR/file-tools/modern-file-tools.sh"
    execute_with_progress "Installing Modern Text Tools" bash "$SCRIPT_DIR/text-tools/modern-text-tools.sh"

    echo -e "${GREEN}✓ Modern CLI tools installed${NC}"
}

install_shell_tools() {
    echo -e "${BLUE}Installing shell enhancements...${NC}"

    if [[ -f "$SCRIPT_DIR/shell/install.sh" ]]; then
        bash "$SCRIPT_DIR/shell/install.sh"
    else
        execute_with_progress "Installing Shell Setup" bash "$SCRIPT_DIR/shell/zsh-setup.sh"
    fi
}

install_cli_tools() {
    echo -e "${BLUE}Installing command line tools...${NC}"

    if [[ -f "$SCRIPT_DIR/cli-tools/install.sh" ]]; then
        bash "$SCRIPT_DIR/cli-tools/install.sh"
    else
        execute_with_progress "Installing CLI Tools" bash "$SCRIPT_DIR/cli-tools/essential-tools.sh"
    fi
}

install_monitoring_tools() {
    echo -e "${BLUE}Installing monitoring tools...${NC}"

    if [[ -f "$SCRIPT_DIR/monitoring/install.sh" ]]; then
        bash "$SCRIPT_DIR/monitoring/install.sh"
    else
        execute_with_progress "Installing Monitoring Tools" bash "$SCRIPT_DIR/monitoring/htop-btop.sh"
    fi
}

install_text_tools() {
    echo -e "${BLUE}Installing text processing tools...${NC}"

    if [[ -f "$SCRIPT_DIR/text-tools/install.sh" ]]; then
        bash "$SCRIPT_DIR/text-tools/install.sh"
    else
        echo -e "${YELLOW}⚠ Text processing tools not yet implemented${NC}"
    fi
}

install_file_tools() {
    echo -e "${BLUE}Installing file management tools...${NC}"

    if [[ -f "$SCRIPT_DIR/file-tools/install.sh" ]]; then
        bash "$SCRIPT_DIR/file-tools/install.sh"
    else
        echo -e "${YELLOW}⚠ File management tools not yet implemented${NC}"
    fi
}

install_network_tools() {
    echo -e "${BLUE}Installing network tools...${NC}"

    if [[ -f "$SCRIPT_DIR/network-tools/install.sh" ]]; then
        bash "$SCRIPT_DIR/network-tools/install.sh"
    else
        echo -e "${YELLOW}⚠ Network tools not yet implemented${NC}"
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
        --modern)
            install_modern
            ;;
        --shell)
            install_shell_tools
            ;;
        --cli)
            install_cli_tools
            ;;
        --monitoring)
            install_monitoring_tools
            ;;
        --text)
            install_text_tools
            ;;
        --file)
            install_file_tools
            ;;
        --network)
            install_network_tools
            ;;
        "")
            echo -e "${BLUE}Archer Terminal Tools Installation${NC}"
            echo ""
            echo "Available options:"
            echo "  --essential     Install essential terminal tools"
            echo "  --all           Install all terminal tools"
            echo "  --modern        Install modern CLI replacements"
            echo "  --shell         Install shell enhancements only"
            echo "  --cli           Install command line tools only"
            echo "  --monitoring    Install monitoring tools only"
            echo "  --text          Install text processing tools only"
            echo "  --file          Install file management tools only"
            echo "  --network       Install network tools only"
            echo ""
            read -p "Choose installation type [essential/all/modern]: " choice
            case "$choice" in
                essential|e) install_essential ;;
                all|a) install_all ;;
                modern|m) install_modern ;;
                shell|s) install_shell_tools ;;
                cli|c) install_cli_tools ;;
                monitoring|mon) install_monitoring_tools ;;
                text|t) install_text_tools ;;
                file|f) install_file_tools ;;
                network|n) install_network_tools ;;
                *) echo -e "${RED}Invalid choice${NC}"; exit 1 ;;
            esac
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --essential, --all, --modern, or specific category options"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"

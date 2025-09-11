#!/bin/bash

# Archer - Enhanced Main Script with TOML Menu Support
# Comprehensive post-installation management with modular TOML-based menus

set -e

# Set global variables
export ARCHER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export ARCHER_VERBOSE="${ARCHER_VERBOSE:-false}"
export ARCHER_QUIET="${ARCHER_QUIET:-false}"

# Source common functions
source "${ARCHER_DIR}/install/system/common-funcs.sh"

# Command line arguments
ARCHER_MENU=""
ARCHER_INSTALL=""
INSTALL_ALL="false"

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --menu)
                ARCHER_MENU="$2"
                shift 2
                ;;
            --install)
                ARCHER_INSTALL="$2"
                shift 2
                ;;
            --install-all)
                INSTALL_ALL="true"
                shift
                ;;
            --verbose)
                export ARCHER_VERBOSE="true"
                shift
                ;;
            --quiet)
                export ARCHER_QUIET="true"
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                show_help
                exit 1
                ;;
        esac
    done
}

# Show help information
show_help() {
    cat << EOF
Archer - Arch Linux Post-Installation Manager (TOML-Based)

USAGE:
    archer-toml.sh [OPTIONS]

OPTIONS:
    --menu <path>         Jump directly to specific menu
                         Examples: development, desktop/fonts, multimedia/audio

    --install <path>      Unopinionated installation of directory contents
                         Examples: development, desktop/fonts

    --install-all         Install everything (completely unopinionated)

    --verbose            Show detailed installation output
    --quiet              Minimal output (default)

    --help, -h           Show this help message

EXAMPLES:
    archer-toml.sh                                    # Interactive main menu
    archer-toml.sh --menu development                 # Jump to development tools
    archer-toml.sh --menu development/languages       # Jump to languages submenu
    archer-toml.sh --install desktop/fonts --verbose  # Install all fonts with output
    archer-toml.sh --install-all --quiet             # Silent full installation

MENU PATHS:
    Main categories: desktop, development, multimedia, network, system
    Subcategories: fonts, themes, languages, editors, terminals, audio, video

EOF
}

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

       Archer - TOML-Based System Management
EOF
    echo -e "${NC}"
}

# Check system requirements
check_system_requirements() {
    echo -e "${BLUE}Checking system requirements...${NC}"

    # Check if running on Arch Linux
    if [[ ! -f /etc/arch-release ]] && ! command -v pacman >/dev/null 2>&1; then
        echo -e "${RED}This script requires an Arch Linux system.${NC}"
        exit 1
    fi

    # Check for gum
    if ! command -v gum >/dev/null 2>&1; then
        echo -e "${YELLOW}Installing gum (required for UI)...${NC}"
        if ! install_with_retries gum; then
            echo -e "${RED}Failed to install gum. Please install it manually.${NC}"
            exit 1
        fi
    fi

    # Check TOML requirements
    if ! check_toml_requirements; then
        echo -e "${RED}Failed to set up TOML requirements.${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓ System requirements met${NC}"
}

# Unopinionated installation functions
install_everything() {
    echo -e "${BLUE}Starting complete Archer installation...${NC}"
    execute_with_progress "Installing all components..." bash "${ARCHER_DIR}/install/install.sh"
}

install_directory() {
    local dir_path="$1"
    local full_path="${ARCHER_DIR}/install/$dir_path"

    if [[ -f "$full_path/install.sh" ]]; then
        echo -e "${BLUE}Installing $dir_path components...${NC}"
        execute_with_progress "Installing $dir_path..." bash "$full_path/install.sh"
    else
        echo -e "${RED}No installation script found for: $dir_path${NC}"
        echo -e "${YELLOW}Available directories:${NC}"
        discover_toml_menus "${ARCHER_DIR}/install" | head -10
        exit 1
    fi
}

# Show main TOML menu
show_main_menu() {
    while true; do
        show_logo
        echo -e "${CYAN}Select a category to configure:${NC}"
        echo ""

        if build_main_toml_menu; then
            continue
        else
            # Exit selected
            echo -e "${BLUE}Goodbye!${NC}"
            exit 0
        fi
    done
}

# Main execution logic
main() {
    parse_arguments "$@"

    # Handle different execution modes
    if [[ "$INSTALL_ALL" == "true" ]]; then
        check_system_requirements
        install_everything
    elif [[ -n "$ARCHER_INSTALL" ]]; then
        check_system_requirements
        install_directory "$ARCHER_INSTALL"
    elif [[ -n "$ARCHER_MENU" ]]; then
        check_system_requirements
        local menu_path="${ARCHER_DIR}/install/$ARCHER_MENU"
        if [[ -f "$menu_path/menu.toml" ]]; then
            navigate_to_toml_menu "$menu_path"
        else
            echo -e "${RED}Menu not found: $ARCHER_MENU${NC}"
            echo -e "${YELLOW}Available menus:${NC}"
            discover_toml_menus "${ARCHER_DIR}/install"
            exit 1
        fi
    else
        check_system_requirements
        show_main_menu
    fi
}

# Execute main function
main "$@"

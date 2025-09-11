#!/bin/bash

# Font Installation Manager for Archer
# Comprehensive font collection installer with user choice

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../..}/install/system/common-funcs.sh"

show_banner "Font Installation Manager"

# Create fonts directory if it doesn't exist
ensure_fonts_directory() {
    mkdir -p ~/.local/share/fonts
    mkdir -p /tmp/archer-fonts
}

# Clean up temporary files
cleanup_temp() {
    rm -rf /tmp/archer-fonts
}

# Refresh font cache
refresh_fonts() {
    echo -e "${BLUE}Refreshing font cache...${NC}"
    fc-cache -fv
    echo -e "${GREEN}Font cache updated${NC}"
}

# Font installation functions
install_font_collection() {
    local collection="$1"

    ensure_fonts_directory

    case "$collection" in
        "nerd-fonts")
            bash "${ARCHER_DIR}/install/desktop/fonts/nerd-fonts.sh"
            ;;
        "google-fonts")
            bash "${ARCHER_DIR}/install/desktop/fonts/google-fonts.sh"
            ;;
        "adobe-fonts")
            bash "${ARCHER_DIR}/install/desktop/fonts/adobe-fonts.sh"
            ;;
        "coding-fonts")
            bash "${ARCHER_DIR}/install/desktop/fonts/coding-fonts.sh"
            ;;
        "system-fonts")
            bash "${ARCHER_DIR}/install/desktop/fonts/system-fonts.sh"
            ;;
        "apple-fonts")
            bash "${ARCHER_DIR}/install/desktop/fonts/apple-fonts.sh"
            ;;
        "microsoft-fonts")
            bash "${ARCHER_DIR}/install/desktop/fonts/microsoft-fonts.sh"
            ;;
        *)
            echo -e "${RED}Unknown font collection: $collection${NC}"
            return 1
            ;;
    esac

    refresh_fonts
}

# Main font installation menu
show_font_menu() {
    echo -e "${CYAN}===============================================${NC}"
    echo -e "${CYAN}         Font Collection Installer            ${NC}"
    echo -e "${CYAN}===============================================${NC}"
    echo ""
    echo -e "${GREEN}Programming & Development:${NC}"
    echo "  1) Nerd Fonts Collection (JetBrains, Fira Code, etc.)"
    echo "  2) Coding Fonts (iA Writer, SF Mono, Source Code Pro)"
    echo ""
    echo -e "${GREEN}System & UI Fonts:${NC}"
    echo "  3) Google Fonts Collection (Roboto, Open Sans, etc.)"
    echo "  4) Adobe Source Fonts (Source Sans, Source Serif)"
    echo "  5) System Enhancement Fonts (Better defaults)"
    echo ""
    echo -e "${GREEN}Commercial Fonts:${NC}"
    echo "  6) Apple Fonts (SF Pro, NY, Monaco)"
    echo "  7) Microsoft Fonts (Segoe UI, Cascadia Code)"
    echo ""
    echo -e "${YELLOW}Quick Install:${NC}"
    echo "  8) Essential Developer Fonts (Nerd + Coding)"
    echo "  9) Complete Font Package (All collections)"
    echo ""
    echo "  0) Exit"
    echo ""
    echo -e "${CYAN}===============================================${NC}"
}

# Main execution
main() {
    echo -e "${YELLOW}This will install font collections to improve your system typography.${NC}"
    if ! confirm_action "Continue with font installation?"; then
        echo -e "${YELLOW}Font installation cancelled.${NC}"
        exit 0
    fi

    while true; do
        show_font_menu

        choice=$(get_input "Enter your choice (0-9):" "1")

        case $choice in
            1)
                echo -e "${BLUE}Installing Nerd Fonts Collection...${NC}"
                install_font_collection "nerd-fonts"
                ;;
            2)
                echo -e "${BLUE}Installing Coding Fonts...${NC}"
                install_font_collection "coding-fonts"
                ;;
            3)
                echo -e "${BLUE}Installing Google Fonts...${NC}"
                install_font_collection "google-fonts"
                ;;
            4)
                echo -e "${BLUE}Installing Adobe Fonts...${NC}"
                install_font_collection "adobe-fonts"
                ;;
            5)
                echo -e "${BLUE}Installing System Enhancement Fonts...${NC}"
                install_font_collection "system-fonts"
                ;;
            6)
                echo -e "${BLUE}Installing Apple Fonts...${NC}"
                install_font_collection "apple-fonts"
                ;;
            7)
                echo -e "${BLUE}Installing Microsoft Fonts...${NC}"
                install_font_collection "microsoft-fonts"
                ;;
            8)
                echo -e "${BLUE}Installing Essential Developer Fonts...${NC}"
                install_font_collection "nerd-fonts"
                install_font_collection "coding-fonts"
                ;;
            9)
                echo -e "${BLUE}Installing Complete Font Package...${NC}"
                if confirm_action "This will install ALL font collections. Continue?"; then
                    install_font_collection "nerd-fonts"
                    install_font_collection "coding-fonts"
                    install_font_collection "google-fonts"
                    install_font_collection "adobe-fonts"
                    install_font_collection "system-fonts"
                    install_font_collection "apple-fonts"
                    install_font_collection "microsoft-fonts"
                fi
                ;;
            0)
                echo -e "${GREEN}Font installation completed!${NC}"
                cleanup_temp
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice. Please try again.${NC}"
                ;;
        esac

        echo ""
        wait_for_input "Press Enter to continue..."
    done
}

# Run main function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

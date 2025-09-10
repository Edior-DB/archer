#!/bin/bash

# Adobe Source Fonts Collection Installer
# Professional typography from Adobe

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../../..}/install/system/common-funcs.sh"

show_banner "Adobe Source Fonts Installation"

install_adobe_fonts() {
    echo -e "${BLUE}Installing Adobe Source Fonts collection...${NC}"

    # Adobe Source fonts from official repos
    local adobe_packages=(
        "adobe-source-sans-fonts"     # Sans-serif family
        "adobe-source-serif-fonts"    # Serif family
        "adobe-source-code-pro-fonts" # Monospace (if not already installed)
        "adobe-source-han-sans-fonts" # CJK support
        "adobe-source-han-serif-fonts" # CJK serif
    )

    echo -e "${YELLOW}Installing Adobe Source font families...${NC}"

    for package in "${adobe_packages[@]}"; do
        if confirm_action "Install ${package/adobe-source-/Source }?"; then
            if install_with_retries "$package"; then
                echo -e "${GREEN}✓ ${package/adobe-source-/Source } installed${NC}"
            else
                echo -e "${YELLOW}⚠ ${package} not available, trying manual installation...${NC}"

                # Manual installation fallback
                case "$package" in
                    "adobe-source-sans-fonts")
                        install_source_font "source-sans-pro" "Source Sans Pro"
                        ;;
                    "adobe-source-serif-fonts")
                        install_source_font "source-serif-pro" "Source Serif Pro"
                        ;;
                    "adobe-source-code-pro-fonts")
                        install_source_font "source-code-pro" "Source Code Pro"
                        ;;
                esac
            fi
        fi
    done

    echo -e "${GREEN}Adobe Source Fonts installation completed!${NC}"

    # Set Source Sans Pro as system font if requested
    if confirm_action "Set Source Sans Pro as default system font?"; then
        if command -v gsettings &> /dev/null; then
            gsettings set org.gnome.desktop.interface font-name "Source Sans Pro 11"
            gsettings set org.gnome.desktop.interface document-font-name "Source Serif Pro 11"
            echo -e "${GREEN}GNOME fonts updated to Source fonts${NC}"
        fi

        # For KDE
        if command -v kwriteconfig5 &> /dev/null; then
            kwriteconfig5 --file kdeglobals --group General --key font "Source Sans Pro,11,-1,5,50,0,0,0,0,0"
            echo -e "${GREEN}KDE fonts updated to Source Sans Pro${NC}"
        fi
    fi
}

# Helper function to install Source fonts manually
install_source_font() {
    local font_name="$1"
    local display_name="$2"

    echo -e "${CYAN}Downloading $display_name manually...${NC}"

    mkdir -p /tmp/archer-fonts/adobe
    cd /tmp/archer-fonts/adobe

    if wget -q "https://github.com/adobe-fonts/${font_name}/releases/latest/download/${font_name}-ttf.zip"; then
        unzip -q "${font_name}-ttf.zip"
        find . -name "*.ttf" -exec cp {} ~/.local/share/fonts/ \;
        echo -e "${GREEN}✓ $display_name installed manually${NC}"
        rm -rf "${font_name}-ttf.zip" TTF
    else
        echo -e "${RED}✗ Failed to download $display_name${NC}"
    fi

    cd - > /dev/null
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_adobe_fonts
fi

#!/bin/bash

# Google Fonts Collection Installer
# Popular web and UI fonts from Google

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../../..}/install/system/common-funcs.sh"

show_banner "Google Fonts Installation"

install_google_fonts() {
    echo -e "${BLUE}Installing Google Fonts collection...${NC}"

    # Install from official repos if available
    if confirm_action "Install Google Fonts from official repositories?"; then
        echo -e "${CYAN}Installing Google Fonts packages...${NC}"

        # Common Google font packages in Arch repos
        local font_packages=(
            "noto-fonts"              # Comprehensive Unicode support
            "noto-fonts-emoji"        # Emoji support
            "noto-fonts-extra"        # Additional Noto variants
            "ttf-roboto-fonts"        # Android's default font (fixed package name)
            "ttf-ubuntu-font"         # Ubuntu fonts (fixed package name)
        )

        for package in "${font_packages[@]}"; do
            if install_with_retries "$package"; then
                echo -e "${GREEN}✓ $package installed${NC}"
            else
                echo -e "${YELLOW}⚠ $package not available${NC}"
            fi
        done
    fi

    # Additional Google Fonts from AUR
    if confirm_action "Install additional Google Fonts from AUR?"; then
        # Check if AUR helper is available
        if ! check_aur_helper; then
            echo -e "${YELLOW}AUR helper not found. Skipping AUR fonts installation.${NC}"
            echo -e "${CYAN}Install an AUR helper (yay/paru) to access additional fonts.${NC}"
        else
            echo -e "${CYAN}Installing Google Fonts from AUR...${NC}"

            # AUR-only Google font packages
            local aur_fonts=(
                "ttf-open-sans"           # Open Sans family
                "ttf-lato"                # Lato family (AUR only)
                "ttf-roboto-mono"         # Roboto monospace
            )

            for font in "${aur_fonts[@]}"; do
                if confirm_action "Install $font from AUR?"; then
                    if install_with_retries yay "$font"; then
                        echo -e "${GREEN}✓ $font installed from AUR${NC}"
                    else
                        echo -e "${YELLOW}⚠ $font not available in AUR${NC}"
                    fi
                fi
            done
        fi
    fi

    # Manual Google Fonts installation for fonts not in repos
    if confirm_action "Install additional Google Fonts manually?"; then
        echo -e "${CYAN}Downloading additional Google Fonts...${NC}"

        # Create temporary directory
        mkdir -p /tmp/archer-fonts/google
        cd /tmp/archer-fonts/google

        # Popular Google Fonts not in repos
        local manual_fonts=(
            "Inter"                    # Modern UI font
            "Poppins"                  # Geometric sans-serif
            "Montserrat"               # Elegant headers
            "Source+Sans+Pro"          # Adobe collaboration
            "Playfair+Display"         # Elegant serif
            "Lora"                     # Well-balanced serif
            "Fira+Sans"                # Mozilla's font
            "Work+Sans"                # Optimized for screens
        )

        # Ensure fonts directory exists
        mkdir -p ~/.local/share/fonts/

        for font in "${manual_fonts[@]}"; do
            if confirm_action "Install ${font//+/ } font?"; then
                echo -e "${CYAN}Downloading ${font//+/ }...${NC}"

                # Download from Google Fonts API
                font_url="https://fonts.google.com/download?family=${font}"
                if wget -q "$font_url" -O "${font}.zip"; then
                    unzip -q "${font}.zip" -d "$font"
                    find "$font" -name "*.ttf" -exec cp {} ~/.local/share/fonts/ \;
                    echo -e "${GREEN}✓ ${font//+/ } installed${NC}"
                    rm -rf "${font}.zip" "$font"
                else
                    echo -e "${RED}✗ Failed to download ${font//+/ }${NC}"
                fi
            fi
        done

        cd - > /dev/null
    fi

    echo -e "${GREEN}Google Fonts installation completed!${NC}"

    # Update font cache
    echo -e "${CYAN}Updating font cache...${NC}"
    fc-cache -fv >/dev/null 2>&1

    # Set system fonts if requested
    if confirm_action "Set Roboto as default system font?"; then
        if command -v gsettings &> /dev/null; then
            gsettings set org.gnome.desktop.interface font-name "Roboto 11"
            gsettings set org.gnome.desktop.interface document-font-name "Roboto 11"
            echo -e "${GREEN}GNOME fonts updated to Roboto${NC}"
        fi

        # For KDE
        if command -v kwriteconfig5 &> /dev/null; then
            kwriteconfig5 --file kdeglobals --group General --key font "Roboto,11,-1,5,50,0,0,0,0,0"
            echo -e "${GREEN}KDE fonts updated to Roboto${NC}"
        fi
    fi
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_google_fonts
fi

#!/bin/bash

# Apple Fonts Collection Installer
# Apple's system fonts (SF Pro, NY, etc.)

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../../..}/install/system/common-funcs.sh"

show_banner "Apple Fonts Installation"

install_apple_fonts() {
    echo -e "${BLUE}Installing Apple Fonts collection...${NC}"

    # SF Pro Display/Text (System font)
    if confirm_action "Install SF Pro Display/Text (Apple's system font)?"; then
        echo -e "${CYAN}Installing SF Pro fonts...${NC}"
        if install_with_retries yay otf-apple-fonts; then
            echo -e "${GREEN}✓ Apple fonts installed from AUR${NC}"
        else
            echo -e "${YELLOW}Attempting manual installation...${NC}"
            install_sf_pro_manual
        fi
    fi

    # SF Mono (already covered in coding-fonts, but offer separately)
    if confirm_action "Install SF Mono (Apple's monospace font)?"; then
        echo -e "${CYAN}Installing SF Mono...${NC}"
        if install_with_retries yay otf-apple-sf-mono; then
            echo -e "${GREEN}✓ SF Mono installed from AUR${NC}"
        else
            install_sf_mono_manual
        fi
    fi

    # New York (Apple's serif font)
    if confirm_action "Install New York (Apple's serif font)?"; then
        echo -e "${CYAN}Installing New York font...${NC}"
        if install_with_retries yay otf-apple-new-york; then
            echo -e "${GREEN}✓ New York installed from AUR${NC}"
        else
            install_new_york_manual
        fi
    fi

    echo -e "${GREEN}Apple Fonts installation completed!${NC}"

    # Set SF Pro as system font if requested
    if confirm_action "Set SF Pro Display as default system font (macOS-like)?"; then
        if command -v gsettings &> /dev/null; then
            gsettings set org.gnome.desktop.interface font-name "SF Pro Display 11"
            gsettings set org.gnome.desktop.interface document-font-name "SF Pro Text 11"
            echo -e "${GREEN}GNOME fonts updated to SF Pro${NC}"
        fi

        # For KDE (Cupertini theme compatibility)
        if command -v kwriteconfig5 &> /dev/null; then
            kwriteconfig5 --file kdeglobals --group General --key font "SF Pro Display,11,-1,5,50,0,0,0,0,0"
            echo -e "${GREEN}KDE fonts updated to SF Pro Display${NC}"
        fi
    fi
}

# Manual SF Pro installation
install_sf_pro_manual() {
    mkdir -p /tmp/archer-fonts/apple
    cd /tmp/archer-fonts/apple

    if wget -q "https://github.com/sahibjotsaggu/San-Francisco-Pro-Fonts/archive/master.zip" -O sf-pro.zip; then
        unzip -q sf-pro.zip
        find San-Francisco-Pro-Fonts-master -name "*.otf" -exec cp {} ~/.local/share/fonts/ \;
        echo -e "${GREEN}✓ SF Pro fonts installed manually${NC}"
        rm -rf sf-pro.zip San-Francisco-Pro-Fonts-master
    else
        echo -e "${RED}✗ Failed to install SF Pro fonts manually${NC}"
    fi

    cd - > /dev/null
}

# Manual SF Mono installation
install_sf_mono_manual() {
    mkdir -p /tmp/archer-fonts/apple
    cd /tmp/archer-fonts/apple

    if wget -q "https://github.com/supercomputra/SF-Mono-Font/archive/master.zip" -O sf-mono.zip; then
        unzip -q sf-mono.zip
        find SF-Mono-Font-master -name "*.otf" -exec cp {} ~/.local/share/fonts/ \;
        echo -e "${GREEN}✓ SF Mono installed manually${NC}"
        rm -rf sf-mono.zip SF-Mono-Font-master
    else
        echo -e "${RED}✗ Failed to install SF Mono manually${NC}"
    fi

    cd - > /dev/null
}

# Manual New York installation
install_new_york_manual() {
    mkdir -p /tmp/archer-fonts/apple
    cd /tmp/archer-fonts/apple

    echo -e "${YELLOW}Note: New York font requires manual extraction from Apple sources.${NC}"
    echo -e "${CYAN}You can download it from Apple Developer resources or use alternatives.${NC}"

    # Try alternative serif fonts that look similar
    if confirm_action "Install Charter (similar serif alternative)?"; then
        if install_with_retries ttf-charter; then
            echo -e "${GREEN}✓ Charter font installed as alternative${NC}"
        fi
    fi

    cd - > /dev/null
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_apple_fonts
fi

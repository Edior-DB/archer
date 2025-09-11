#!/bin/bash

# Microsoft Fonts Collection Installer
# Windows system fonts and modern Microsoft typography

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../../..}/install/system/common-funcs.sh"

show_banner "Microsoft Fonts Installation"

install_microsoft_fonts() {
    echo -e "${BLUE}Installing Microsoft Fonts collection...${NC}"

    # Core Windows fonts
    if confirm_action "Install Core Windows fonts (Arial, Times New Roman, etc.)?"; then
        echo -e "${CYAN}Installing Core Windows fonts...${NC}"

        # Check if AUR helper is available
        if ! check_aur_helper; then
            echo -e "${YELLOW}AUR helper not found. Installing Microsoft-compatible alternatives...${NC}"
            install_core_windows_fonts_manual
        else
            if install_with_retries yay ttf-ms-fonts; then
                echo -e "${GREEN}✓ Core Windows fonts installed${NC}"
            else
                echo -e "${YELLOW}Core Windows fonts not available, installing alternatives...${NC}"
                install_core_windows_fonts_manual
            fi
        fi
    fi

    # Segoe UI (Modern Windows system font)
    if confirm_action "Install Segoe UI (Windows 10/11 system font)?"; then
        echo -e "${CYAN}Installing Segoe UI...${NC}"

        # Check if AUR helper is available
        if ! check_aur_helper; then
            echo -e "${YELLOW}AUR helper not found. Installing DejaVu as alternative...${NC}"
            install_segoe_ui_manual
        else
            if install_with_retries yay ttf-segoe-ui-variable; then
                echo -e "${GREEN}✓ Segoe UI installed from AUR${NC}"
            else
                echo -e "${YELLOW}Segoe UI not available, installing alternative...${NC}"
                install_segoe_ui_manual
            fi
        fi
    fi

    # Cascadia Code (Microsoft's developer font)
    if confirm_action "Install Cascadia Code (Microsoft's coding font)?"; then
        echo -e "${CYAN}Installing Cascadia Code...${NC}"
        if install_with_retries ttf-cascadia-code; then
            echo -e "${GREEN}✓ Cascadia Code installed from official repos${NC}"
        else
            install_cascadia_code_manual
        fi
    fi

    # Calibri and modern Office fonts
    if confirm_action "Install Microsoft Office fonts (Calibri, Cambria, etc.)?"; then
        echo -e "${CYAN}Installing Office fonts...${NC}"

        # Check if AUR helper is available
        if ! check_aur_helper; then
            echo -e "${YELLOW}AUR helper not found. Office fonts require AUR access.${NC}"
            echo -e "${CYAN}Installing Liberation fonts as alternatives...${NC}"
            install_with_retries ttf-liberation
        else
            if install_with_retries yay ttf-office-2007-fonts; then
                echo -e "${GREEN}✓ Office fonts installed${NC}"
            else
                echo -e "${YELLOW}Office fonts not available via AUR${NC}"
                echo -e "${CYAN}Note: These fonts require a Windows/Office license${NC}"
                echo -e "${CYAN}Installing Liberation fonts as alternatives...${NC}"
                install_with_retries ttf-liberation
            fi
        fi
    fi

    # Alternative Microsoft-compatible fonts
    if confirm_action "Install Microsoft-compatible alternative fonts?"; then
        echo -e "${CYAN}Installing Liberation fonts (MS-compatible)...${NC}"
        install_with_retries ttf-liberation

        echo -e "${CYAN}Installing Croscore fonts (Chrome OS alternatives)...${NC}"
        install_with_retries ttf-croscore

        echo -e "${GREEN}✓ Microsoft-compatible alternatives installed${NC}"
    fi

    echo -e "${GREEN}Microsoft Fonts installation completed!${NC}"

    # Update font cache
    echo -e "${CYAN}Updating font cache...${NC}"
    fc-cache -fv >/dev/null 2>&1

    # Set Windows-like fonts if requested
    if confirm_action "Set Segoe UI as default system font (Windows-like)?"; then
        if command -v gsettings &> /dev/null; then
            gsettings set org.gnome.desktop.interface font-name "Segoe UI 9"
            gsettings set org.gnome.desktop.interface document-font-name "Segoe UI 9"
            echo -e "${GREEN}GNOME fonts updated to Segoe UI${NC}"
        fi

        # For KDE (Redmondi theme compatibility)
        if command -v kwriteconfig5 &> /dev/null; then
            kwriteconfig5 --file kdeglobals --group General --key font "Segoe UI,9,-1,5,50,0,0,0,0,0"
            echo -e "${GREEN}KDE fonts updated to Segoe UI${NC}"
        fi
    fi
}

# Manual installation functions
install_core_windows_fonts_manual() {
    echo -e "${YELLOW}Core Windows fonts require manual installation due to licensing.${NC}"
    echo -e "${CYAN}Installing Liberation fonts as alternatives...${NC}"

    local alt_packages=(
        "ttf-liberation"      # Arial, Times New Roman, Courier alternatives
        "ttf-dejavu"          # High-quality alternatives
        "ttf-croscore"        # Google alternatives
    )

    for package in "${alt_packages[@]}"; do
        install_with_retries "$package"
    done

    echo -e "${GREEN}✓ Alternative fonts installed${NC}"
}

install_segoe_ui_manual() {
    mkdir -p /tmp/archer-fonts/microsoft
    cd /tmp/archer-fonts/microsoft

    echo -e "${YELLOW}Segoe UI requires Windows installation. Installing alternatives...${NC}"

    # Use system-ui compatible fonts
    if install_with_retries ttf-dejavu; then
        echo -e "${GREEN}✓ DejaVu fonts installed as Segoe UI alternative${NC}"
    fi

    cd - > /dev/null
}

install_cascadia_code_manual() {
    mkdir -p /tmp/archer-fonts/microsoft
    cd /tmp/archer-fonts/microsoft

    echo -e "${CYAN}Downloading Cascadia Code manually...${NC}"

    if wget -q "https://github.com/microsoft/cascadia-code/releases/latest/download/CascadiaCode.zip"; then
        unzip -q CascadiaCode.zip -d cascadia
        find cascadia -name "*.ttf" -exec cp {} ~/.local/share/fonts/ \;
        echo -e "${GREEN}✓ Cascadia Code installed manually${NC}"
        rm -rf CascadiaCode.zip cascadia
    else
        echo -e "${RED}✗ Failed to download Cascadia Code${NC}"
    fi

    cd - > /dev/null
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_microsoft_fonts
fi

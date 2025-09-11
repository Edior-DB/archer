#!/bin/bash

# Nerd Fonts Collection Installer
# Popular programming fonts with icon support

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../../..}/install/system/common-funcs.sh"

show_banner "Nerd Fonts Installation"

install_nerd_fonts() {
    echo -e "${BLUE}Installing Nerd Fonts collection...${NC}"

    # Create temporary directory
    mkdir -p /tmp/archer-fonts/nerd-fonts
    cd /tmp/archer-fonts/nerd-fonts

    # Popular Nerd Fonts
    local fonts=(
        "JetBrainsMono"     # Most popular for coding
        "FiraCode"          # Ligatures support
        "Meslo"             # Based on Debian-OK choice
        "Hack"              # Clean and readable
        "SourceCodePro"     # Adobe's coding font
        "UbuntuMono"        # Ubuntu's monospace
        "DejaVuSansMono"    # Default Linux mono
        "CascadiaCode"      # Microsoft's newest
        "Iosevka"           # Narrow and space-efficient
        "RobotoMono"        # Google's monospace
    )

    echo -e "${YELLOW}Available Nerd Fonts:${NC}"
    for i in "${!fonts[@]}"; do
        echo "  $((i+1))) ${fonts[$i]}"
    done
    echo "  0) Install all fonts"
    echo ""

    choice=$(get_input "Select fonts to install (0 for all, or comma-separated numbers):" "0")

    if [[ "$choice" == "0" ]]; then
        # Install all fonts
        selected_fonts=("${fonts[@]}")
    else
        # Parse user selection
        IFS=',' read -ra choices <<< "$choice"
        selected_fonts=()
        for c in "${choices[@]}"; do
            c=$(echo "$c" | tr -d ' ')  # Remove spaces
            if [[ "$c" =~ ^[0-9]+$ ]] && [ "$c" -ge 1 ] && [ "$c" -le "${#fonts[@]}" ]; then
                selected_fonts+=("${fonts[$((c-1))]}")
            fi
        done
    fi

    if [ ${#selected_fonts[@]} -eq 0 ]; then
        echo -e "${YELLOW}No valid fonts selected.${NC}"
        return 0
    fi

    # Ensure fonts directory exists
    mkdir -p ~/.local/share/fonts/

    echo -e "${GREEN}Installing selected fonts...${NC}"

    for font in "${selected_fonts[@]}"; do
        echo -e "${CYAN}Downloading $font...${NC}"

        if wget -q "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.zip"; then
            echo -e "${YELLOW}Extracting $font...${NC}"
            unzip -q "${font}.zip" -d "$font"

            # Copy TTF and OTF files to fonts directory
            find "$font" -name "*.ttf" -o -name "*.otf" | while read -r fontfile; do
                cp "$fontfile" ~/.local/share/fonts/
            done

            echo -e "${GREEN}✓ $font installed${NC}"
            rm -rf "${font}.zip" "$font"
        else
            echo -e "${RED}✗ Failed to download $font${NC}"
        fi
    done

    echo -e "${GREEN}Nerd Fonts installation completed!${NC}"

    # Update font cache
    echo -e "${CYAN}Updating font cache...${NC}"
    fc-cache -fv ~/.local/share/fonts/ >/dev/null 2>&1

    # Set default monospace font if requested
    if confirm_action "Set JetBrains Mono Nerd Font as default monospace font?"; then
        if command -v gsettings &> /dev/null; then
            gsettings set org.gnome.desktop.interface monospace-font-name "JetBrainsMono Nerd Font 10"
            echo -e "${GREEN}Default monospace font updated${NC}"
        fi

        # For KDE
        if command -v kwriteconfig5 &> /dev/null; then
            kwriteconfig5 --file kdeglobals --group General --key fixed "JetBrainsMono Nerd Font,10,-1,5,50,0,0,0,0,0"
            echo -e "${GREEN}KDE monospace font updated${NC}"
        fi
    fi

    cd - > /dev/null
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_nerd_fonts
fi

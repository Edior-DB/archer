#!/bin/bash

# System Enhancement Fonts Installer
# Essential fonts for better system typography

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../../..}/install/system/common-funcs.sh"

show_banner "System Enhancement Fonts Installation"

install_system_fonts() {
    echo -e "${BLUE}Installing system enhancement fonts...${NC}"

    # Essential system fonts
    echo -e "${YELLOW}Installing essential system fonts...${NC}"

    local essential_fonts=(
        "ttf-dejavu"              # High-quality default fonts
        "ttf-liberation"          # Microsoft-compatible fonts
        "noto-fonts"              # Google's comprehensive Unicode fonts
        "noto-fonts-emoji"        # Emoji support
        "ttf-droid"               # Android fonts (VERIFIED CORRECT NAME)
        "cantarell-fonts"         # GNOME default
    )

    for font in "${essential_fonts[@]}"; do
        if install_with_retries "$font"; then
            echo -e "${GREEN}✓ $font installed${NC}"
        else
            echo -e "${YELLOW}⚠ $font not available${NC}"
        fi
    done

    # International language support
    if confirm_action "Install extended language support fonts?"; then
        echo -e "${CYAN}Installing international fonts...${NC}"

        local intl_fonts=(
            "noto-fonts-cjk"         # Chinese, Japanese, Korean (VERIFIED AVAILABLE)
            "noto-fonts-extra"       # Additional scripts
            "ttf-arphic-ukai"        # Chinese Kaiti (VERIFIED AVAILABLE)
            "ttf-arphic-uming"       # Chinese Ming (VERIFIED AVAILABLE)
            "ttf-baekmuk"            # Korean fonts (VERIFIED AVAILABLE)
            "adobe-source-han-sans-otc-fonts"  # CJK sans (CORRECTED NAME)
            "adobe-source-han-serif-otc-fonts" # CJK serif (CORRECTED NAME)
        )

        for font in "${intl_fonts[@]}"; do
            if install_with_retries "$font"; then
                echo -e "${GREEN}✓ $font installed${NC}"
            else
                echo -e "${YELLOW}⚠ $font not available${NC}"
            fi
        done
    fi

    # Mathematical and scientific fonts
    if confirm_action "Install mathematical and scientific fonts?"; then
        echo -e "${CYAN}Installing math/science fonts...${NC}"

        local math_fonts=(
            "texlive-fontsextra"     # LaTeX math fonts
            "otf-latin-modern"       # Modern LaTeX fonts
        )

        for font in "${math_fonts[@]}"; do
            if install_with_retries "$font"; then
                echo -e "${GREEN}✓ $font installed${NC}"
            else
                echo -e "${YELLOW}⚠ $font not available${NC}"
            fi
        done
    fi

    # Configure fontconfig for better rendering
    if confirm_action "Configure fontconfig for better font rendering?"; then
        echo -e "${CYAN}Configuring fontconfig...${NC}"

        mkdir -p ~/.config/fontconfig
        cat > ~/.config/fontconfig/fonts.conf << 'EOF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <!-- Enable sub-pixel rendering -->
  <match target="font">
    <edit name="rgba" mode="assign"><const>rgb</const></edit>
  </match>

  <!-- Enable hinting -->
  <match target="font">
    <edit name="hinting" mode="assign"><bool>true</bool></edit>
  </match>

  <!-- Hinting style -->
  <match target="font">
    <edit name="hintstyle" mode="assign"><const>hintslight</const></edit>
  </match>

  <!-- Anti-aliasing -->
  <match target="font">
    <edit name="antialias" mode="assign"><bool>true</bool></edit>
  </match>

  <!-- Font substitutions for better defaults -->
  <alias>
    <family>serif</family>
    <prefer>
      <family>Noto Serif</family>
      <family>Liberation Serif</family>
      <family>DejaVu Serif</family>
    </prefer>
  </alias>

  <alias>
    <family>sans-serif</family>
    <prefer>
      <family>Noto Sans</family>
      <family>Liberation Sans</family>
      <family>DejaVu Sans</family>
    </prefer>
  </alias>

  <alias>
    <family>monospace</family>
    <prefer>
      <family>Noto Sans Mono</family>
      <family>Liberation Mono</family>
      <family>DejaVu Sans Mono</family>
    </prefer>
  </alias>
</fontconfig>
EOF
        echo -e "${GREEN}✓ Fontconfig configured for better rendering${NC}"
    fi

    # Modern coding and display fonts
    if confirm_action "Install modern coding and display fonts?"; then
        echo -e "${CYAN}Installing modern fonts...${NC}"

        local modern_fonts=(
            "ttf-jetbrains-mono"     # JetBrains coding font with ligatures
            "ttf-cascadia-code"      # Microsoft's coding font
            "ttf-hack"               # Hand groomed coding font
            "ttf-fira-code"          # Monospace with ligatures
            "ttf-fira-sans"          # Mozilla's sans-serif
            "ttf-fira-mono"          # Mozilla's monospace
            "ttf-inconsolata"        # Monospace for code listings
            "ttf-lato"               # Modern sans-serif
        )

        for font in "${modern_fonts[@]}"; do
            if install_with_retries "$font"; then
                echo -e "${GREEN}✓ $font installed${NC}"
            else
                echo -e "${YELLOW}⚠ $font not available${NC}"
            fi
        done
    fi

    # Update font cache
    echo -e "${CYAN}Updating font cache...${NC}"
    fc-cache -fv >/dev/null 2>&1

    # Set improved default fonts
    if confirm_action "Set Noto fonts as system defaults?"; then
        if command -v gsettings &> /dev/null; then
            gsettings set org.gnome.desktop.interface font-name "Noto Sans 11"
            gsettings set org.gnome.desktop.interface document-font-name "Noto Serif 11"
            gsettings set org.gnome.desktop.interface monospace-font-name "Noto Sans Mono 10"
            echo -e "${GREEN}GNOME fonts updated to Noto family${NC}"
        fi

        # For KDE
        if command -v kwriteconfig5 &> /dev/null; then
            kwriteconfig5 --file kdeglobals --group General --key font "Noto Sans,11,-1,5,50,0,0,0,0,0"
            kwriteconfig5 --file kdeglobals --group General --key fixed "Noto Sans Mono,10,-1,5,50,0,0,0,0,0"
            echo -e "${GREEN}KDE fonts updated to Noto family${NC}"
        fi
    fi
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_system_fonts
fi

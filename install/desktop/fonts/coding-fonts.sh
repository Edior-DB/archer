#!/bin/bash

# Coding Fonts Collection Installer
# Specialized programming fonts including iA Writer Mono

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../../..}/install/system/common-funcs.sh"

show_banner "Coding Fonts Installation"

install_coding_fonts() {
    echo -e "${BLUE}Installing coding fonts collection...${NC}"

    # Create temporary directory
    mkdir -p /tmp/archer-fonts/coding
    cd /tmp/archer-fonts/coding

    # iA Writer Mono (from debian-ok example)
    if confirm_action "Install iA Writer Mono font?"; then
        echo -e "${CYAN}Downloading iA Writer Mono...${NC}"
        if wget -O iafonts.zip "https://github.com/iaolo/iA-Fonts/archive/refs/heads/master.zip"; then
            unzip -q iafonts.zip -d iaFonts
            find iaFonts/iA-Fonts-master -name "iAWriterMonoS-*.ttf" -exec cp {} ~/.local/share/fonts/ \;
            echo -e "${GREEN}✓ iA Writer Mono installed${NC}"
            rm -rf iafonts.zip iaFonts
        else
            echo -e "${RED}✗ Failed to download iA Writer Mono${NC}"
        fi
    fi

    # SF Mono (Apple's monospace font)
    if confirm_action "Install SF Mono font (Apple)?"; then
        echo -e "${CYAN}Installing SF Mono from system packages...${NC}"
        if install_with_retries yay otf-apple-sf-mono; then
            echo -e "${GREEN}✓ SF Mono installed from AUR${NC}"
        else
            echo -e "${YELLOW}Attempting manual installation...${NC}"
            # Alternative download method if AUR fails
            if wget -q "https://github.com/supercomputra/SF-Mono-Font/archive/master.zip" -O sf-mono.zip; then
                unzip -q sf-mono.zip
                find SF-Mono-Font-master -name "*.otf" -exec cp {} ~/.local/share/fonts/ \;
                echo -e "${GREEN}✓ SF Mono installed manually${NC}"
                rm -rf sf-mono.zip SF-Mono-Font-master
            else
                echo -e "${RED}✗ Failed to install SF Mono${NC}"
            fi
        fi
    fi

    # Source Code Pro
    if confirm_action "Install Source Code Pro (Adobe)?"; then
        echo -e "${CYAN}Installing Source Code Pro...${NC}"
        if install_with_retries adobe-source-code-pro-fonts; then
            echo -e "${GREEN}✓ Source Code Pro installed from official repos${NC}"
        else
            # Manual installation fallback
            if wget -q "https://github.com/adobe-fonts/source-code-pro/releases/latest/download/source-code-pro-ttf.zip"; then
                unzip -q source-code-pro-ttf.zip
                find . -name "*.ttf" -exec cp {} ~/.local/share/fonts/ \;
                echo -e "${GREEN}✓ Source Code Pro installed manually${NC}"
                rm -rf source-code-pro-ttf.zip TTF
            else
                echo -e "${RED}✗ Failed to install Source Code Pro${NC}"
            fi
        fi
    fi

    # Operator Mono (if available)
    if confirm_action "Install Operator Mono-like alternative (ligatures)?"; then
        echo -e "${CYAN}Installing Operator Mono alternative...${NC}"
        if wget -q "https://github.com/kiliman/operator-mono-lig/releases/latest/download/OperatorMonoLig.zip"; then
            unzip -q OperatorMonoLig.zip
            find . -name "*.otf" -exec cp {} ~/.local/share/fonts/ \;
            echo -e "${GREEN}✓ Operator Mono Ligatures installed${NC}"
            rm -rf OperatorMonoLig.zip *.otf
        else
            echo -e "${RED}✗ Failed to install Operator Mono alternative${NC}"
        fi
    fi

    # Victor Mono (cursive italics)
    if confirm_action "Install Victor Mono (cursive coding font)?"; then
        echo -e "${CYAN}Installing Victor Mono...${NC}"
        if wget -q "https://github.com/rubjo/victor-mono/releases/latest/download/VictorMonoAll.zip"; then
            unzip -q VictorMonoAll.zip -d victor-mono
            find victor-mono -name "*.ttf" -exec cp {} ~/.local/share/fonts/ \;
            echo -e "${GREEN}✓ Victor Mono installed${NC}"
            rm -rf VictorMonoAll.zip victor-mono
        else
            echo -e "${RED}✗ Failed to install Victor Mono${NC}"
        fi
    fi

    # Anonymous Pro
    if confirm_action "Install Anonymous Pro (classic coding font)?"; then
        echo -e "${CYAN}Installing Anonymous Pro...${NC}"
        if install_with_retries ttf-anonymous-pro; then
            echo -e "${GREEN}✓ Anonymous Pro installed from official repos${NC}"
        else
            if wget -q "https://www.marksimonson.com/assets/content/fonts/AnonymousPro-1.002.zip"; then
                unzip -q AnonymousPro-1.002.zip
                find . -name "*.ttf" -exec cp {} ~/.local/share/fonts/ \;
                echo -e "${GREEN}✓ Anonymous Pro installed manually${NC}"
                rm -rf AnonymousPro-1.002.zip AnonymousPro-1.002
            else
                echo -e "${RED}✗ Failed to install Anonymous Pro${NC}"
            fi
        fi
    fi

    echo -e "${GREEN}Coding fonts installation completed!${NC}"

    cd - > /dev/null
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_coding_fonts
fi

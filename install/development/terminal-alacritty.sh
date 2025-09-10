#!/bin/bash

# Alacritty Terminal Emulator Installation Script
# GPU-accelerated, minimal terminal written in Rust

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/..}/install/system/common-funcs.sh"

show_banner "Alacritty Terminal Installation"

install_alacritty() {
    echo -e "${BLUE}Installing Alacritty...${NC}"

    # Install Alacritty
    install_with_retries alacritty

    # Create config directory
    mkdir -p ~/.config/alacritty

    # Create default configuration if it doesn't exist
    if [[ ! -f ~/.config/alacritty/alacritty.toml ]]; then
        echo -e "${YELLOW}Creating default Alacritty configuration...${NC}"
        cat > ~/.config/alacritty/alacritty.toml << 'EOF'
# Alacritty Configuration
# Modern TOML format (Alacritty v0.13+)

[window]
padding = { x = 10, y = 10 }
decorations = "full"
opacity = 0.95
startup_mode = "Windowed"
title = "Alacritty"
dynamic_title = true

[scrolling]
history = 10000
multiplier = 3

[font]
size = 12.0

[font.normal]
family = "JetBrains Mono"
style = "Regular"

[font.bold]
family = "JetBrains Mono"
style = "Bold"

[font.italic]
family = "JetBrains Mono"
style = "Italic"

[colors.primary]
background = "#1e1e2e"
foreground = "#cdd6f4"

[colors.normal]
black = "#45475a"
red = "#f38ba8"
green = "#a6e3a1"
yellow = "#f9e2af"
blue = "#89b4fa"
magenta = "#f5c2e7"
cyan = "#94e2d5"
white = "#bac2de"

[colors.bright]
black = "#585b70"
red = "#f38ba8"
green = "#a6e3a1"
yellow = "#f9e2af"
blue = "#89b4fa"
magenta = "#f5c2e7"
cyan = "#94e2d5"
white = "#a6adc8"

[cursor]
style = { shape = "Block", blinking = "On" }
vi_mode_style = "Block"

[keyboard]
bindings = [
    { key = "V", mods = "Control|Shift", action = "Paste" },
    { key = "C", mods = "Control|Shift", action = "Copy" },
    { key = "Plus", mods = "Control", action = "IncreaseFontSize" },
    { key = "Minus", mods = "Control", action = "DecreaseFontSize" },
    { key = "Key0", mods = "Control", action = "ResetFontSize" },
]
EOF
        echo -e "${GREEN}Default configuration created at ~/.config/alacritty/alacritty.toml${NC}"
    else
        echo -e "${YELLOW}Alacritty configuration already exists, skipping...${NC}"
    fi

    # Set as default terminal (optional)
    if confirm_action "Set Alacritty as default terminal emulator?"; then
        # Update desktop environment terminal preference
        if command -v gsettings &> /dev/null; then
            gsettings set org.gnome.desktop.default-applications.terminal exec 'alacritty'
        fi

        # Create desktop entry if it doesn't exist
        if [[ ! -f ~/.local/share/applications/alacritty.desktop ]]; then
            mkdir -p ~/.local/share/applications
            cat > ~/.local/share/applications/alacritty.desktop << 'EOF'
[Desktop Entry]
Type=Application
TryExec=alacritty
Exec=alacritty
Icon=Alacritty
Terminal=false
Categories=System;TerminalEmulator;
Name=Alacritty
GenericName=Terminal
Comment=A fast, cross-platform, OpenGL terminal emulator
StartupWMClass=Alacritty
EOF
            echo -e "${GREEN}Desktop entry created${NC}"
        fi
    fi

    echo -e "${GREEN}Alacritty installation completed!${NC}"
    echo -e "${CYAN}Configuration: ~/.config/alacritty/alacritty.toml${NC}"
    echo -e "${CYAN}Launch with: alacritty${NC}"
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_alacritty
fi

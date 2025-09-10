#!/bin/bash

# WezTerm Terminal Emulator Installation Script
# Rust-based terminal with advanced features

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/..}/install/system/common-funcs.sh"

show_banner "WezTerm Terminal Installation"

install_wezterm() {
    echo -e "${BLUE}Installing WezTerm...${NC}"

    # Install WezTerm from AUR
    install_with_retries yay wezterm

    # Create config directory
    mkdir -p ~/.config/wezterm

    # Create default configuration if it doesn't exist
    if [[ ! -f ~/.config/wezterm/wezterm.lua ]]; then
        echo -e "${YELLOW}Creating default WezTerm configuration...${NC}"
        cat > ~/.config/wezterm/wezterm.lua << 'EOF'
-- WezTerm Configuration
local wezterm = require 'wezterm'
local config = {}

-- Use config builder for clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- Color scheme
config.color_scheme = 'Catppuccin Mocha'

-- Font configuration
config.font = wezterm.font('JetBrains Mono', { weight = 'Regular' })
config.font_size = 12.0
config.line_height = 1.2

-- Window configuration
config.window_background_opacity = 0.95
config.window_decorations = "RESIZE"
config.window_close_confirmation = 'NeverPrompt'
config.window_padding = {
  left = 10,
  right = 10,
  top = 10,
  bottom = 10,
}

-- Tab bar
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = false
config.use_fancy_tab_bar = true
config.tab_max_width = 32

-- Scrollback
config.scrollback_lines = 10000

-- Cursor
config.default_cursor_style = 'BlinkingBlock'
config.cursor_blink_rate = 800

-- Key bindings
config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1000 }
config.keys = {
  -- Pane splitting
  {
    key = '|',
    mods = 'LEADER|SHIFT',
    action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  {
    key = '-',
    mods = 'LEADER',
    action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
  },

  -- Pane navigation
  {
    key = 'h',
    mods = 'LEADER',
    action = wezterm.action.ActivatePaneDirection 'Left',
  },
  {
    key = 'j',
    mods = 'LEADER',
    action = wezterm.action.ActivatePaneDirection 'Down',
  },
  {
    key = 'k',
    mods = 'LEADER',
    action = wezterm.action.ActivatePaneDirection 'Up',
  },
  {
    key = 'l',
    mods = 'LEADER',
    action = wezterm.action.ActivatePaneDirection 'Right',
  },

  -- Pane resizing
  {
    key = 'H',
    mods = 'LEADER|SHIFT',
    action = wezterm.action.AdjustPaneSize { 'Left', 5 },
  },
  {
    key = 'J',
    mods = 'LEADER|SHIFT',
    action = wezterm.action.AdjustPaneSize { 'Down', 5 },
  },
  {
    key = 'K',
    mods = 'LEADER|SHIFT',
    action = wezterm.action.AdjustPaneSize { 'Up', 5 },
  },
  {
    key = 'L',
    mods = 'LEADER|SHIFT',
    action = wezterm.action.AdjustPaneSize { 'Right', 5 },
  },

  -- Tab management
  {
    key = 'c',
    mods = 'LEADER',
    action = wezterm.action.SpawnTab 'CurrentPaneDomain',
  },
  {
    key = 'x',
    mods = 'LEADER',
    action = wezterm.action.CloseCurrentPane { confirm = true },
  },
  {
    key = 'n',
    mods = 'LEADER',
    action = wezterm.action.ActivateTabRelative(1),
  },
  {
    key = 'p',
    mods = 'LEADER',
    action = wezterm.action.ActivateTabRelative(-1),
  },

  -- Copy/Paste
  {
    key = 'C',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.CopyTo 'Clipboard',
  },
  {
    key = 'V',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.PasteFrom 'Clipboard',
  },

  -- Font size
  {
    key = '=',
    mods = 'CTRL',
    action = wezterm.action.IncreaseFontSize,
  },
  {
    key = '-',
    mods = 'CTRL',
    action = wezterm.action.DecreaseFontSize,
  },
  {
    key = '0',
    mods = 'CTRL',
    action = wezterm.action.ResetFontSize,
  },

  -- Search
  {
    key = 'f',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.Search { CaseSensitiveString = '' },
  },
}

-- Mouse bindings
config.mouse_bindings = {
  -- Right click to paste
  {
    event = { Down = { streak = 1, button = 'Right' } },
    mods = 'NONE',
    action = wezterm.action.PasteFrom 'Clipboard',
  },
}

-- Performance
config.max_fps = 60
config.animation_fps = 1

-- Bell
config.audible_bell = 'Disabled'
config.visual_bell = {
  fade_in_function = 'EaseIn',
  fade_in_duration_ms = 150,
  fade_out_function = 'EaseOut',
  fade_out_duration_ms = 150,
}

-- Hyperlinks
config.hyperlink_rules = {
  -- Linkify things that look like URLs and the host has a TLD name.
  {
    regex = '\\b\\w+://[\\w.-]+\\.[a-z]{2,15}\\S*\\b',
    format = '$0',
  },

  -- linkify email addresses
  {
    regex = [[\b\w+@[\w-]+(\.[\w-]+)+\b]],
    format = 'mailto:$0',
  },

  -- file:// URI
  {
    regex = [[\bfile://\S*\b]],
    format = '$0',
  },

  -- Make task numbers clickable
  {
    regex = [[\b[tT](\d+)\b]],
    format = 'https://example.com/tasks/$1',
  },
}

-- SSH domains (for remote connections)
config.ssh_domains = {
  -- Example SSH domain
  -- {
  --   name = 'my-server',
  --   remote_address = 'my-server.example.com',
  --   username = 'username',
  -- },
}

return config
EOF
        echo -e "${GREEN}Default configuration created at ~/.config/wezterm/wezterm.lua${NC}"
    else
        echo -e "${YELLOW}WezTerm configuration already exists, skipping...${NC}"
    fi

    # Set as default terminal (optional)
    if confirm_action "Set WezTerm as default terminal emulator?"; then
        # Update desktop environment terminal preference
        if command -v gsettings &> /dev/null; then
            gsettings set org.gnome.desktop.default-applications.terminal exec 'wezterm'
        fi

        echo -e "${GREEN}WezTerm set as default terminal${NC}"
    fi

    echo -e "${GREEN}WezTerm installation completed!${NC}"
    echo -e "${CYAN}Configuration: ~/.config/wezterm/wezterm.lua${NC}"
    echo -e "${CYAN}Launch with: wezterm${NC}"
    echo -e "${CYAN}Leader key: Ctrl+A (tmux-style bindings)${NC}"
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_wezterm
fi

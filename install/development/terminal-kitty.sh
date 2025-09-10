#!/bin/bash

# Kitty Terminal Emulator Installation Script
# Fast, feature-rich terminal with GPU acceleration

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/..}/install/system/common-funcs.sh"

show_banner "Kitty Terminal Installation"

install_kitty() {
    echo -e "${BLUE}Installing Kitty...${NC}"

    # Install Kitty
    install_with_retries kitty

    # Create config directory
    mkdir -p ~/.config/kitty

    # Create default configuration if it doesn't exist
    if [[ ! -f ~/.config/kitty/kitty.conf ]]; then
        echo -e "${YELLOW}Creating default Kitty configuration...${NC}"
        cat > ~/.config/kitty/kitty.conf << 'EOF'
# Kitty Terminal Configuration

# Font settings
font_family      JetBrains Mono
bold_font        JetBrains Mono Bold
italic_font      JetBrains Mono Italic
bold_italic_font JetBrains Mono Bold Italic
font_size 12.0

# Cursor
cursor_shape block
cursor_blink_interval 1
cursor_stop_blinking_after 15.0

# Scrollback
scrollback_lines 10000
scrollback_pager less --chop-long-lines --RAW-CONTROL-CHARS +INPUT_LINE_NUMBER

# Mouse
mouse_hide_wait 3.0
url_color #0087bd
url_style curly
open_url_with default
url_prefixes http https file ftp gemini irc gopher mailto news git
detect_urls yes

# Performance tuning
repaint_delay 10
input_delay 3
sync_to_monitor yes

# Window layout
remember_window_size  yes
initial_window_width  640
initial_window_height 400
enabled_layouts *
window_resize_step_cells 2
window_resize_step_lines 2
window_border_width 0.5pt
draw_minimal_borders yes
window_margin_width 0
single_window_margin_width -1
window_padding_width 5
placement_strategy center

# Tab bar
tab_bar_edge bottom
tab_bar_margin_width 0.0
tab_bar_margin_height 0.0 0.0
tab_bar_style powerline
tab_bar_align left
tab_bar_min_tabs 2
tab_switch_strategy previous
tab_fade 0.25 0.5 0.75 1
tab_separator " ┇"
tab_powerline_style angled
tab_activity_symbol none
tab_title_template "{title}{' :{}:'.format(num_windows) if num_windows > 1 else ''}"

# Color scheme (Catppuccin Mocha)
foreground              #CDD6F4
background              #1E1E2E
selection_foreground    #1E1E2E
selection_background    #F5E0DC

# Cursor colors
cursor                  #F5E0DC
cursor_text_color       #1E1E2E

# URL underline color when hovering with mouse
url_color               #F5E0DC

# Kitty window border colors
active_border_color     #B4BEFE
inactive_border_color   #6C7086
bell_border_color       #F9E2AF

# OS Window titlebar colors
wayland_titlebar_color system
macos_titlebar_color system

# Tab bar colors
active_tab_foreground   #11111B
active_tab_background   #CBA6F7
inactive_tab_foreground #CDD6F4
inactive_tab_background #181825
tab_bar_background      #11111B

# Colors for marks (marked text in the terminal)
mark1_foreground #1E1E2E
mark1_background #B4BEFE
mark2_foreground #1E1E2E
mark2_background #CBA6F7
mark3_foreground #1E1E2E
mark3_background #74C7EC

# The 16 terminal colors

# black
color0 #45475A
color8 #585B70

# red
color1 #F38BA8
color9 #F38BA8

# green
color2  #A6E3A1
color10 #A6E3A1

# yellow
color3  #F9E2AF
color11 #F9E2AF

# blue
color4  #89B4FA
color12 #89B4FA

# magenta
color5  #F5C2E7
color13 #F5C2E7

# cyan
color6  #94E2D5
color14 #94E2D5

# white
color7  #BAC2DE
color15 #A6ADC8

# Keyboard shortcuts
kitty_mod ctrl+shift

# Clipboard
map kitty_mod+c copy_to_clipboard
map kitty_mod+v paste_from_clipboard
map kitty_mod+s  paste_from_selection
map shift+insert paste_from_selection
map kitty_mod+o  pass_selection_to_program

# Scrolling
map kitty_mod+up        scroll_line_up
map kitty_mod+k         scroll_line_up
map kitty_mod+down      scroll_line_down
map kitty_mod+j         scroll_line_down
map kitty_mod+page_up   scroll_page_up
map kitty_mod+page_down scroll_page_down
map kitty_mod+home      scroll_home
map kitty_mod+end       scroll_end
map kitty_mod+h         show_scrollback

# Window management
map kitty_mod+enter new_window
map kitty_mod+n new_os_window
map kitty_mod+w close_window
map kitty_mod+] next_window
map kitty_mod+[ previous_window
map kitty_mod+f move_window_forward
map kitty_mod+b move_window_backward
map kitty_mod+` move_window_to_top
map kitty_mod+r start_resizing_window
map kitty_mod+1 first_window
map kitty_mod+2 second_window
map kitty_mod+3 third_window
map kitty_mod+4 fourth_window
map kitty_mod+5 fifth_window
map kitty_mod+6 sixth_window
map kitty_mod+7 seventh_window
map kitty_mod+8 eighth_window
map kitty_mod+9 ninth_window
map kitty_mod+0 tenth_window

# Tab management
map kitty_mod+right next_tab
map kitty_mod+left  previous_tab
map kitty_mod+t     new_tab
map kitty_mod+q     close_tab
map kitty_mod+.     move_tab_forward
map kitty_mod+,     move_tab_backward
map kitty_mod+alt+t set_tab_title

# Font sizes
map kitty_mod+equal     change_font_size all +2.0
map kitty_mod+plus      change_font_size all +2.0
map kitty_mod+kp_add    change_font_size all +2.0
map kitty_mod+minus     change_font_size all -2.0
map kitty_mod+kp_subtract change_font_size all -2.0
map kitty_mod+backspace change_font_size all 0

# Select and act on visible text
map kitty_mod+e kitten hints
map kitty_mod+p>f kitten hints --type path --program -
map kitty_mod+p>shift+f kitten hints --type path
map kitty_mod+p>l kitten hints --type line --program -
map kitty_mod+p>w kitten hints --type word --program -
map kitty_mod+p>h kitten hints --type hash --program -
map kitty_mod+p>n kitten hints --type linenum

# Miscellaneous
map kitty_mod+f11    toggle_fullscreen
map kitty_mod+f10    toggle_maximized
map kitty_mod+u      kitten unicode_input
map kitty_mod+f2     edit_config_file
map kitty_mod+escape kitty_shell window

# Open new splits (windows) with current working directory
map f5 launch --location=hsplit
map f6 launch --location=vsplit

# Switch between splits
map f7 neighboring_window left
map f8 neighboring_window right
map f9 neighboring_window up
map f10 neighboring_window down
EOF
        echo -e "${GREEN}Default configuration created at ~/.config/kitty/kitty.conf${NC}"
    else
        echo -e "${YELLOW}Kitty configuration already exists, skipping...${NC}"
    fi

    # Set as default terminal (optional)
    if confirm_action "Set Kitty as default terminal emulator?"; then
        # Update desktop environment terminal preference
        if command -v gsettings &> /dev/null; then
            gsettings set org.gnome.desktop.default-applications.terminal exec 'kitty'
        fi

        echo -e "${GREEN}Kitty set as default terminal${NC}"
    fi

    echo -e "${GREEN}Kitty installation completed!${NC}"
    echo -e "${CYAN}Configuration: ~/.config/kitty/kitty.conf${NC}"
    echo -e "${CYAN}Launch with: kitty${NC}"
    echo -e "${CYAN}Tip: Use Ctrl+Shift+F2 to edit config in Kitty${NC}"
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_kitty
fi

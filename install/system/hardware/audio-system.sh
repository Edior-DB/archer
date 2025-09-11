#!/bin/bash
# Audio System Installation Script
# Installs and configures PipeWire, ALSA, and audio tools

# ==============================================================================
# CONFIGURATION
# ==============================================================================
TOOL_NAME="Audio System"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
ARCHER_DIR="${ARCHER_DIR:-$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")}"

# Source common functions
source "$ARCHER_DIR/install/system/common-funcs.sh"

# ==============================================================================
# INSTALLATION FUNCTIONS
# ==============================================================================

install_pipewire() {
    log_info "Installing PipeWire audio system..."

    # Install PipeWire and related packages
    local packages=(
        "pipewire"              # Main PipeWire package
        "pipewire-alsa"         # ALSA compatibility
        "pipewire-pulse"        # PulseAudio compatibility
        "pipewire-jack"         # JACK compatibility
        "wireplumber"           # Session manager
        "pipewire-audio"        # Audio support
        "gst-plugin-pipewire"   # GStreamer support
    )

    for package in "${packages[@]}"; do
        if ! pacman -Qi "$package" &>/dev/null; then
            execute_with_progress "sudo pacman -S --noconfirm $package" "Installing $package..."
        fi
    done

    # Install audio tools
    local audio_tools=(
        "pavucontrol"           # PulseAudio volume control
        "easyeffects"           # Audio effects (if available)
        "alsa-utils"            # ALSA utilities
        "pulseaudio-bluetooth"  # Bluetooth audio support
    )

    for tool in "${audio_tools[@]}"; do
        if ! pacman -Qi "$tool" &>/dev/null; then
            execute_with_progress "sudo pacman -S --noconfirm $tool" "Installing $tool..." || log_warning "Failed to install $tool"
        fi
    done

    log_success "PipeWire audio system installed"
}

configure_pipewire() {
    log_info "Configuring PipeWire audio system..."

    # Enable and start PipeWire services for user
    local services=(
        "pipewire.service"
        "pipewire-pulse.service"
        "wireplumber.service"
    )

    for service in "${services[@]}"; do
        execute_with_progress "systemctl --user enable --now $service" "Enabling $service..."
    done

    # Create PipeWire configuration directory
    mkdir -p "$HOME/.config/pipewire"

    # Create basic PipeWire configuration if it doesn't exist
    if [[ ! -f "$HOME/.config/pipewire/pipewire.conf" ]]; then
        cat > "$HOME/.config/pipewire/pipewire.conf" << 'EOF'
# PipeWire Configuration
context.properties = {
    default.clock.rate = 48000
    default.clock.quantum = 1024
    default.clock.min-quantum = 32
    default.clock.max-quantum = 8192
}

context.modules = [
    { name = libpipewire-module-rt
        args = {
            nice.level   = -11
            rt.prio      = 88
            rt.time.soft = 200000
            rt.time.hard = 200000
        }
        flags = [ ifexists nofail ]
    }
    { name = libpipewire-module-protocol-native }
    { name = libpipewire-module-profiler }
    { name = libpipewire-module-metadata }
    { name = libpipewire-module-spa-device-factory }
    { name = libpipewire-module-spa-node-factory }
    { name = libpipewire-module-client-node }
    { name = libpipewire-module-client-device }
    { name = libpipewire-module-portal }
    { name = libpipewire-module-access
        args = {
            access.allowed = [
                { app = "pavucontrol" }
                { app = "easyeffects" }
            ]
        }
    }
    { name = libpipewire-module-adapter }
    { name = libpipewire-module-link-factory }
    { name = libpipewire-module-session-manager }
]
EOF
        log_info "Created PipeWire configuration"
    fi

    # Add user to audio group
    sudo usermod -a -G audio "$(whoami)"
    log_info "Added user to audio group"
}

install_codec_support() {
    log_info "Installing audio codec support..."

    # Install multimedia codecs
    local codecs=(
        "gstreamer"
        "gst-plugins-base"
        "gst-plugins-good"
        "gst-plugins-bad"
        "gst-plugins-ugly"
        "gst-libav"
        "ffmpeg"
    )

    for codec in "${codecs[@]}"; do
        if ! pacman -Qi "$codec" &>/dev/null; then
            execute_with_progress "sudo pacman -S --noconfirm $codec" "Installing $codec..."
        fi
    done

    log_success "Audio codec support installed"
}

setup_audio_aliases() {
    log_info "Setting up audio management aliases..."

    local bashrc="$HOME/.bashrc"
    if [[ -f "$bashrc" ]] && ! grep -q "# Audio aliases" "$bashrc"; then
        cat >> "$bashrc" << 'EOF'

# Audio aliases
alias audio-restart='systemctl --user restart pipewire pipewire-pulse wireplumber'
alias audio-status='systemctl --user status pipewire pipewire-pulse wireplumber'
alias vol='pavucontrol'
alias mixer='alsamixer'
alias audio-test='speaker-test -t wav -c 2'
EOF
        log_info "Added audio aliases to ~/.bashrc"
    fi
}

create_audio_scripts() {
    log_info "Creating audio management scripts..."

    local scripts_dir="$HOME/.local/bin"
    mkdir -p "$scripts_dir"

    # Create audio restart script
    cat > "$scripts_dir/audio-restart" << 'EOF'
#!/bin/bash
# Restart PipeWire audio system

echo "Restarting PipeWire audio system..."

# Stop services
systemctl --user stop pipewire pipewire-pulse wireplumber

# Wait a moment
sleep 2

# Start services
systemctl --user start pipewire pipewire-pulse wireplumber

echo "PipeWire audio system restarted"
echo "Current audio status:"
systemctl --user is-active pipewire pipewire-pulse wireplumber
EOF

    chmod +x "$scripts_dir/audio-restart"

    # Create audio test script
    cat > "$scripts_dir/audio-test" << 'EOF'
#!/bin/bash
# Test audio output

echo "Testing audio output..."
echo "You should hear a test sound in both left and right channels."
echo "Press Ctrl+C to stop the test."

speaker-test -t wav -c 2 -l 1
EOF

    chmod +x "$scripts_dir/audio-test"

    log_info "Created audio management scripts in ~/.local/bin"
}

print_audio_info() {
    echo ""
    echo "=============================================="
    echo "Audio System Ready!"
    echo "=============================================="
    echo ""
    echo "Installed components:"
    echo "  • PipeWire (modern audio server)"
    echo "  • WirePlumber (session manager)"
    echo "  • PulseAudio compatibility layer"
    echo "  • JACK compatibility layer"
    echo "  • Audio codecs and tools"
    echo ""
    echo "Audio management:"
    echo "  pavucontrol             # Volume control GUI"
    echo "  alsamixer               # Terminal mixer"
    echo "  audio-restart           # Restart audio system"
    echo "  audio-test              # Test speakers"
    echo ""
    echo "Service status:"
    if systemctl --user is-active pipewire &>/dev/null; then
        echo "  ✓ PipeWire: Active"
    else
        echo "  ✗ PipeWire: Inactive"
    fi

    if systemctl --user is-active pipewire-pulse &>/dev/null; then
        echo "  ✓ PipeWire-Pulse: Active"
    else
        echo "  ✗ PipeWire-Pulse: Inactive"
    fi

    if systemctl --user is-active wireplumber &>/dev/null; then
        echo "  ✓ WirePlumber: Active"
    else
        echo "  ✗ WirePlumber: Inactive"
    fi

    echo ""
    echo "Configuration: ~/.config/pipewire/"
    echo ""
    echo "Note: If you experience audio issues, run 'audio-restart'"
    echo "      Log out and back in to ensure all services start properly"
    echo ""
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

main() {
    log_info "Starting $TOOL_NAME installation..."

    # Check system requirements
    check_system_requirements

    # Install PipeWire
    install_pipewire || return 1

    # Configure PipeWire
    configure_pipewire

    # Install codec support
    install_codec_support

    # Setup management tools
    setup_audio_aliases
    create_audio_scripts

    # Show information
    print_audio_info

    log_success "$TOOL_NAME installation completed!"
}

# Execute main function
main "$@"

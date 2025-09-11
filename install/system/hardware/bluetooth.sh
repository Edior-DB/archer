#!/bin/bash
# Bluetooth Installation Script
# Installs and configures Bluetooth stack and management tools

# ==============================================================================
# CONFIGURATION
# ==============================================================================
TOOL_NAME="Bluetooth Support"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
ARCHER_DIR="${ARCHER_DIR:-$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")}"

# Source common functions
source "$ARCHER_DIR/install/system/common-funcs.sh"

# ==============================================================================
# INSTALLATION FUNCTIONS
# ==============================================================================

install_bluetooth_stack() {
    log_info "Installing Bluetooth stack..."

    # Install Bluetooth packages
    local packages=(
        "bluez"                 # Bluetooth protocol stack
        "bluez-utils"           # Bluetooth utilities
        "blueman"               # Bluetooth manager GUI
        "pulseaudio-bluetooth"  # Bluetooth audio support
        "bluez-plugins"         # Additional Bluetooth plugins
    )

    for package in "${packages[@]}"; do
        if ! pacman -Qi "$package" &>/dev/null; then
            execute_with_progress "sudo pacman -S --noconfirm $package" "Installing $package..."
        fi
    done

    # Install optional GUI tools
    local gui_tools=(
        "blueberry"             # Alternative Bluetooth manager
    )

    for tool in "${gui_tools[@]}"; do
        if ! pacman -Qi "$tool" &>/dev/null; then
            execute_with_progress "sudo pacman -S --noconfirm $tool" "Installing $tool..." || log_warning "Failed to install $tool (optional)"
        fi
    done

    log_success "Bluetooth stack installed"
}

configure_bluetooth() {
    log_info "Configuring Bluetooth service..."

    # Enable and start Bluetooth service
    execute_with_progress "sudo systemctl enable bluetooth.service" "Enabling Bluetooth service..."
    execute_with_progress "sudo systemctl start bluetooth.service" "Starting Bluetooth service..."

    # Configure Bluetooth main configuration
    local bluetooth_conf="/etc/bluetooth/main.conf"
    if [[ -f "$bluetooth_conf" ]]; then
        # Backup original configuration
        sudo cp "$bluetooth_conf" "$bluetooth_conf.backup"

        # Update configuration for better compatibility
        sudo sed -i 's/^#AutoEnable=false/AutoEnable=true/' "$bluetooth_conf"
        sudo sed -i 's/^#DiscoverableTimeout = 0/DiscoverableTimeout = 180/' "$bluetooth_conf"
        sudo sed -i 's/^#PairableTimeout = 0/PairableTimeout = 180/' "$bluetooth_conf"

        log_info "Updated Bluetooth configuration"
    fi

    # Add user to bluetooth group
    sudo usermod -a -G bluetooth "$(whoami)"
    log_info "Added user to bluetooth group"
}

setup_bluetooth_audio() {
    log_info "Setting up Bluetooth audio support..."

    # Ensure PulseAudio Bluetooth module is loaded
    if command -v pulseaudio &>/dev/null; then
        pactl load-module module-bluetooth-policy 2>/dev/null || true
        pactl load-module module-bluetooth-discover 2>/dev/null || true
    fi

    # Create PulseAudio configuration for Bluetooth
    local pulse_config="$HOME/.config/pulse/default.pa"
    mkdir -p "$HOME/.config/pulse"

    if [[ ! -f "$pulse_config" ]]; then
        cat > "$pulse_config" << 'EOF'
# PulseAudio Configuration for Bluetooth

# Load standard modules
.include /etc/pulse/default.pa

# Bluetooth support
load-module module-bluetooth-policy
load-module module-bluetooth-discover

# Automatic audio switching
load-module module-switch-on-port-available
EOF
        log_info "Created PulseAudio Bluetooth configuration"
    fi
}

create_bluetooth_scripts() {
    log_info "Creating Bluetooth management scripts..."

    local scripts_dir="$HOME/.local/bin"
    mkdir -p "$scripts_dir"

    # Create Bluetooth restart script
    cat > "$scripts_dir/bluetooth-restart" << 'EOF'
#!/bin/bash
# Restart Bluetooth service and reload audio modules

echo "Restarting Bluetooth service..."

# Restart Bluetooth service
sudo systemctl restart bluetooth.service

# Wait for service to start
sleep 2

# Reload Bluetooth audio modules
if command -v pulseaudio &>/dev/null; then
    pactl unload-module module-bluetooth-policy 2>/dev/null || true
    pactl unload-module module-bluetooth-discover 2>/dev/null || true
    pactl load-module module-bluetooth-policy 2>/dev/null || true
    pactl load-module module-bluetooth-discover 2>/dev/null || true
fi

echo "Bluetooth service restarted"
echo "Service status: $(systemctl is-active bluetooth.service)"
EOF

    chmod +x "$scripts_dir/bluetooth-restart"

    # Create Bluetooth scan script
    cat > "$scripts_dir/bluetooth-scan" << 'EOF'
#!/bin/bash
# Scan for Bluetooth devices

echo "Scanning for Bluetooth devices..."
echo "Make sure your device is in pairing mode."
echo "Press Ctrl+C to stop scanning."

bluetoothctl scan on &
SCAN_PID=$!

# Wait for scan to start
sleep 2

echo ""
echo "Available devices:"
bluetoothctl devices

# Keep scanning until interrupted
trap "bluetoothctl scan off; kill $SCAN_PID 2>/dev/null; exit" INT
wait $SCAN_PID
EOF

    chmod +x "$scripts_dir/bluetooth-scan"

    # Create device connection helper
    cat > "$scripts_dir/bluetooth-connect" << 'EOF'
#!/bin/bash
# Connect to a Bluetooth device

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <device_address>"
    echo ""
    echo "Available devices:"
    bluetoothctl devices
    exit 1
fi

DEVICE="$1"

echo "Connecting to device: $DEVICE"

# Trust and pair the device
bluetoothctl trust "$DEVICE"
bluetoothctl pair "$DEVICE"
bluetoothctl connect "$DEVICE"

echo "Connection attempt completed"
echo "Device info:"
bluetoothctl info "$DEVICE"
EOF

    chmod +x "$scripts_dir/bluetooth-connect"

    log_info "Created Bluetooth management scripts in ~/.local/bin"
}

setup_bluetooth_aliases() {
    log_info "Setting up Bluetooth aliases..."

    local bashrc="$HOME/.bashrc"
    if [[ -f "$bashrc" ]] && ! grep -q "# Bluetooth aliases" "$bashrc"; then
        cat >> "$bashrc" << 'EOF'

# Bluetooth aliases
alias bt='bluetoothctl'
alias bt-scan='bluetooth-scan'
alias bt-connect='bluetooth-connect'
alias bt-restart='bluetooth-restart'
alias bt-status='systemctl status bluetooth.service'
alias bt-devices='bluetoothctl devices'
EOF
        log_info "Added Bluetooth aliases to ~/.bashrc"
    fi
}

print_bluetooth_info() {
    echo ""
    echo "=============================================="
    echo "Bluetooth Support Ready!"
    echo "=============================================="
    echo ""
    echo "Installed components:"
    echo "  • BlueZ (Bluetooth protocol stack)"
    echo "  • Blueman (GUI manager)"
    echo "  • Bluetooth audio support"
    echo "  • Management utilities"
    echo ""
    echo "GUI Applications:"
    echo "  blueman-manager         # Main Bluetooth manager"
    echo "  blueman-applet          # System tray applet"
    if command -v blueberry &>/dev/null; then
        echo "  blueberry               # Alternative manager"
    fi
    echo ""
    echo "Command line tools:"
    echo "  bluetoothctl            # Main CLI tool"
    echo "  bluetooth-scan          # Scan for devices"
    echo "  bluetooth-connect       # Connect to device"
    echo "  bluetooth-restart       # Restart service"
    echo ""
    echo "Service status:"
    if systemctl is-active bluetooth.service &>/dev/null; then
        echo "  ✓ Bluetooth: Active"
    else
        echo "  ✗ Bluetooth: Inactive"
    fi

    echo ""
    echo "Quick start:"
    echo "  1. bluetoothctl power on    # Enable Bluetooth"
    echo "  2. bluetooth-scan           # Scan for devices"
    echo "  3. bt-connect <address>     # Connect to device"
    echo ""
    echo "Configuration: /etc/bluetooth/main.conf"
    echo ""
    echo "Note: Restart session to ensure all services work properly"
    echo ""
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

main() {
    log_info "Starting $TOOL_NAME installation..."

    # Check system requirements
    check_system_requirements

    # Install Bluetooth stack
    install_bluetooth_stack || return 1

    # Configure Bluetooth
    configure_bluetooth

    # Setup audio support
    setup_bluetooth_audio

    # Create management scripts
    create_bluetooth_scripts

    # Setup aliases
    setup_bluetooth_aliases

    # Show information
    print_bluetooth_info

    log_success "$TOOL_NAME installation completed!"
}

# Execute main function
main "$@"

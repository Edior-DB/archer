#!/bin/bash
# Printer Support Installation Script
# Installs CUPS printing system and driver support

# ==============================================================================
# CONFIGURATION
# ==============================================================================
TOOL_NAME="Printer Support"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
ARCHER_DIR="${ARCHER_DIR:-$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")}"

# Source common functions
source "$ARCHER_DIR/install/system/common-funcs.sh"

# ==============================================================================
# INSTALLATION FUNCTIONS
# ==============================================================================

install_cups_system() {
    log_info "Installing CUPS printing system..."

    # Install CUPS and basic utilities
    local packages=(
        "cups"                  # Common UNIX Printing System
        "cups-pdf"              # PDF printer
        "system-config-printer" # GUI configuration tool
        "gtk3-print-backends"   # GTK print backends
        "print-manager"         # KDE print manager
    )

    for package in "${packages[@]}"; do
        if ! pacman -Qi "$package" &>/dev/null; then
            execute_with_progress "sudo pacman -S --noconfirm $package" "Installing $package..." || log_warning "Failed to install $package"
        fi
    done

    log_success "CUPS printing system installed"
}

install_printer_drivers() {
    log_info "Installing printer drivers..."

    # Install common printer drivers
    local drivers=(
        "gutenprint"            # High quality drivers
        "foomatic-db-engine"    # Foomatic database engine
        "foomatic-db"           # Foomatic database
        "foomatic-db-ppds"      # Foomatic PPDs
        "foomatic-db-nonfree-ppds"  # Non-free PPDs
        "ghostscript"           # PostScript interpreter
        "gsfonts"               # Standard fonts
    )

    for driver in "${drivers[@]}"; do
        if ! pacman -Qi "$driver" &>/dev/null; then
            execute_with_progress "sudo pacman -S --noconfirm $driver" "Installing $driver..." || log_warning "Failed to install $driver"
        fi
    done

    # Install manufacturer-specific drivers
    local manufacturer_drivers=(
        "hplip"                 # HP printers
        "canon-pixma-ts6050-complete"  # Canon printers (AUR)
        "epson-inkjet-printer-escpr"   # Epson printers
        "brlaser"               # Brother laser printers
    )

    # Install HP drivers (always available)
    if ! pacman -Qi "hplip" &>/dev/null; then
        execute_with_progress "sudo pacman -S --noconfirm hplip" "Installing HP printer drivers..."
    fi

    # Try to install other drivers (may require AUR)
    if command -v yay &>/dev/null; then
        log_info "Installing additional printer drivers from AUR..."
        for driver in "${manufacturer_drivers[@]}"; do
            if [[ "$driver" != "hplip" ]]; then
                execute_with_progress "yay -S --noconfirm $driver" "Installing $driver..." || log_warning "Failed to install $driver from AUR"
            fi
        done
    else
        log_warning "AUR helper not available. Some manufacturer drivers may not be installed."
    fi

    log_success "Printer drivers installed"
}

configure_cups() {
    log_info "Configuring CUPS service..."

    # Enable and start CUPS service
    execute_with_progress "sudo systemctl enable cups.service" "Enabling CUPS service..."
    execute_with_progress "sudo systemctl start cups.service" "Starting CUPS service..."

    # Add user to lp group for printer access
    sudo usermod -a -G lp "$(whoami)"
    log_info "Added user to lp group"

    # Configure CUPS to allow local network discovery
    local cups_conf="/etc/cups/cupsd.conf"
    if [[ -f "$cups_conf" ]]; then
        # Backup original configuration
        sudo cp "$cups_conf" "$cups_conf.backup"

        # Enable printer sharing and discovery
        sudo sed -i 's/^Browsing Off/Browsing On/' "$cups_conf" 2>/dev/null || true
        sudo sed -i 's/^BrowseLocalProtocols none/BrowseLocalProtocols dnssd/' "$cups_conf" 2>/dev/null || true

        log_info "Updated CUPS configuration for network discovery"
    fi

    # Enable Avahi for network printer discovery
    if pacman -Qi avahi &>/dev/null; then
        execute_with_progress "sudo systemctl enable avahi-daemon.service" "Enabling Avahi for network discovery..."
        execute_with_progress "sudo systemctl start avahi-daemon.service" "Starting Avahi service..."
    else
        log_info "Installing Avahi for network printer discovery..."
        execute_with_progress "sudo pacman -S --noconfirm avahi" "Installing Avahi..."
        execute_with_progress "sudo systemctl enable avahi-daemon.service" "Enabling Avahi..."
        execute_with_progress "sudo systemctl start avahi-daemon.service" "Starting Avahi..."
    fi
}

setup_printer_tools() {
    log_info "Setting up printer management tools..."

    # Create printer management scripts
    local scripts_dir="$HOME/.local/bin"
    mkdir -p "$scripts_dir"

    # Create printer status script
    cat > "$scripts_dir/printer-status" << 'EOF'
#!/bin/bash
# Show printer status and available printers

echo "CUPS Service Status:"
systemctl status cups.service --no-pager -l

echo ""
echo "Available Printers:"
lpstat -p

echo ""
echo "Default Printer:"
lpstat -d

echo ""
echo "Print Jobs:"
lpstat -o

echo ""
echo "CUPS Web Interface: http://localhost:631"
EOF

    chmod +x "$scripts_dir/printer-status"

    # Create printer test script
    cat > "$scripts_dir/printer-test" << 'EOF'
#!/bin/bash
# Test print functionality

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 [printer_name]"
    echo ""
    echo "Available printers:"
    lpstat -p
    echo ""
    echo "Default printer:"
    lpstat -d
    exit 1
fi

PRINTER="$1"

echo "Printing test page to: $PRINTER"

# Create a simple test page
echo "This is a test print from Archer setup" | lp -d "$PRINTER"

echo "Test page sent to printer queue"
echo "Check status with: lpstat -o"
EOF

    chmod +x "$scripts_dir/printer-test"

    # Create printer configuration launcher
    cat > "$scripts_dir/printer-config" << 'EOF'
#!/bin/bash
# Launch printer configuration tools

echo "Available printer configuration options:"
echo "1. CUPS Web Interface (browser)"
echo "2. System Config Printer (GUI)"
echo "3. Command line setup"

read -p "Choose option (1-3): " choice

case $choice in
    1)
        echo "Opening CUPS web interface..."
        if command -v xdg-open &>/dev/null; then
            xdg-open http://localhost:631
        else
            echo "Open browser to: http://localhost:631"
        fi
        ;;
    2)
        echo "Launching System Config Printer..."
        if command -v system-config-printer &>/dev/null; then
            system-config-printer &
        else
            echo "System Config Printer not available"
        fi
        ;;
    3)
        echo "Command line printer setup:"
        echo "1. lpinfo -v                  # List available devices"
        echo "2. lpadmin -p <name> -v <uri> # Add printer"
        echo "3. lpoptions -d <name>        # Set default printer"
        ;;
    *)
        echo "Invalid option"
        ;;
esac
EOF

    chmod +x "$scripts_dir/printer-config"

    log_info "Created printer management scripts in ~/.local/bin"
}

setup_printer_aliases() {
    log_info "Setting up printer aliases..."

    local bashrc="$HOME/.bashrc"
    if [[ -f "$bashrc" ]] && ! grep -q "# Printer aliases" "$bashrc"; then
        cat >> "$bashrc" << 'EOF'

# Printer aliases
alias printers='lpstat -p'
alias print-jobs='lpstat -o'
alias print-status='printer-status'
alias print-test='printer-test'
alias print-config='printer-config'
alias cups-web='xdg-open http://localhost:631'
EOF
        log_info "Added printer aliases to ~/.bashrc"
    fi
}

print_printer_info() {
    echo ""
    echo "=============================================="
    echo "Printer Support Ready!"
    echo "=============================================="
    echo ""
    echo "Installed components:"
    echo "  • CUPS printing system"
    echo "  • Common printer drivers"
    echo "  • GUI configuration tools"
    echo "  • Network discovery (Avahi)"
    echo ""
    echo "Configuration tools:"
    echo "  system-config-printer   # GUI configuration"
    echo "  http://localhost:631    # CUPS web interface"
    echo "  printer-config          # Configuration helper"
    echo ""
    echo "Command line tools:"
    echo "  lpstat -p               # List printers"
    echo "  lp -d printer file      # Print file"
    echo "  lpq                     # Show print queue"
    echo "  lprm                    # Remove print job"
    echo ""
    echo "Management scripts:"
    echo "  printer-status          # Show system status"
    echo "  printer-test            # Test printer"
    echo "  printer-config          # Launch config tools"
    echo ""
    echo "Service status:"
    if systemctl is-active cups.service &>/dev/null; then
        echo "  ✓ CUPS: Active"
    else
        echo "  ✗ CUPS: Inactive"
    fi

    if systemctl is-active avahi-daemon.service &>/dev/null; then
        echo "  ✓ Avahi: Active (network discovery)"
    else
        echo "  ✗ Avahi: Inactive"
    fi

    echo ""
    echo "Setup steps:"
    echo "1. Run 'printer-config' to add printers"
    echo "2. Or open web interface at http://localhost:631"
    echo "3. Test with 'printer-test <printer_name>'"
    echo ""
    echo "Note: Log out and back in for group membership to take effect"
    echo ""
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

main() {
    log_info "Starting $TOOL_NAME installation..."

    # Check system requirements
    check_system_requirements

    # Install CUPS system
    install_cups_system || return 1

    # Install printer drivers
    install_printer_drivers

    # Configure CUPS
    configure_cups

    # Setup management tools
    setup_printer_tools

    # Setup aliases
    setup_printer_aliases

    # Show information
    print_printer_info

    log_success "$TOOL_NAME installation completed!"
}

# Execute main function
main "$@"

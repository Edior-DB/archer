#!/bin/bash

# Extras Installation Script
# Install additional software and applications

set -e

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$(dirname "$SCRIPT_DIR")"

# Source common functions
source "$INSTALL_DIR/system/common-funcs.sh"

# Default installations for different modes
install_essential() {
    log_info "Installing essential extra applications..."

    # Essential browsers
    execute_with_progress "Installing Firefox" bash "$SCRIPT_DIR/browsers/firefox-install.sh"
    execute_with_progress "Installing Brave Browser" bash "$SCRIPT_DIR/browsers/brave-install.sh"

    # Basic virtualization
    execute_with_progress "Installing Virtual Machine Manager" bash "$SCRIPT_DIR/virtualization/virt-manager-install.sh"

    log_success "Essential extra applications installed!"
}

install_all() {
    log_info "Installing all extra applications..."

    # All browsers
    install_browsers

    # All virtualization
    install_virtualization

    # All communication tools
    install_communication

    # All utilities
    install_utilities

    log_success "All extra applications installed!"
}

install_custom_selection() {
    local scripts=("$@")

    if [[ ${#scripts[@]} -eq 0 ]]; then
        log_error "No extra scripts specified for custom installation"
        return 1
    fi

    log_info "Installing selected extra applications..."

    local total=${#scripts[@]}
    local current=0

    for script in "${scripts[@]}"; do
        current=$((current + 1))
        local script_path="$SCRIPT_DIR/$script"

        if [[ -f "$script_path" ]]; then
            log_info "[$current/$total] Installing $(basename "$script" .sh | sed 's/-/ /g')..."
            execute_with_progress "bash '$script_path'" "Installing $(basename "$script" .sh)..."
        else
            log_warning "Script not found: $script"
        fi
    done

    log_success "Selected extra applications installed!"
}

# Main installation logic
main() {
    log_info "Starting Extras installation..."

    # Parse command line arguments
    local install_mode="all"
    local custom_scripts=()

    while [[ $# -gt 0 ]]; do
        case $1 in
            --essential)
                install_mode="essential"
                shift
                ;;
            --all)
                install_mode="all"
                shift
                ;;
            --scripts)
                install_mode="custom"
                shift
                # Collect script names until next option or end
                while [[ $# -gt 0 && ! "$1" =~ ^-- ]]; do
                    custom_scripts+=("$1")
                    shift
                done
                ;;
            --help)
                echo "Usage: $0 [--all|--essential|--scripts script1 script2 ...] [--help]"
                echo ""
                echo "Extras installation options:"
                echo "  --all         Install all extra applications (default)"
                echo "  --essential   Install essential extra applications"
                echo "  --scripts     Install specific extra scripts"
                echo "  --help        Show this help message"
                echo ""
                echo "Examples:"
                echo "  $0                 # Install everything"
                echo "  $0 --essential     # Install essential extra applications"
                echo "  $0 --scripts browsers/install.sh virtualization/install.sh"
                exit 0
                ;;
            *)
                log_warning "Unknown option: $1"
                shift
                ;;
        esac
    done

    # Execute installation based on mode
    case "$install_mode" in
        "essential")
            install_essential
            ;;
        "custom")
            install_custom_selection "${custom_scripts[@]}"
            ;;
        "all"|*)
            install_all
            ;;
    esac

    log_info "Extras installation completed!"
}

# Run main function with all arguments
main "$@"

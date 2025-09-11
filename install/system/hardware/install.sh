#!/bin/bash
# Hardware Management installation script
# Provides GPU drivers, audio, bluetooth, and printer support

# ==============================================================================
# CONFIGURATION
# ==============================================================================
COMPONENT_NAME="Hardware Management"
COMPONENT_DIR="$(dirname "$(realpath "$0")")"
ARCHER_DIR="${ARCHER_DIR:-$(dirname "$(dirname "$(dirname "$COMPONENT_DIR")")")}"

# Source common functions
source "$ARCHER_DIR/install/system/common-funcs.sh"

# ==============================================================================
# INSTALLATION FUNCTIONS
# ==============================================================================

install_all_hardware() {
    log_info "Installing all $COMPONENT_NAME components..."

    # Array of all hardware installation scripts in order
    local scripts=(
        "gpu-drivers.sh"
        "audio-system.sh"
        "bluetooth.sh"
        "printer-support.sh"
    )

    local total=${#scripts[@]}
    local current=0

    for script in "${scripts[@]}"; do
        current=$((current + 1))
        local script_path="$COMPONENT_DIR/$script"

        if [[ -f "$script_path" ]]; then
            log_info "[$current/$total] Installing $(basename "$script" .sh | sed 's/-/ /g')..."
            execute_with_progress "bash '$script_path'" "Installing $(basename "$script" .sh)..."
        else
            log_warning "Script not found: $script"
        fi
    done

    log_success "All $COMPONENT_NAME components installed!"
}

install_essential_hardware() {
    log_info "Installing essential $COMPONENT_NAME components..."

    # Array of essential hardware components
    local essential_scripts=(
        "gpu-drivers.sh"
        "audio-system.sh"
    )

    local total=${#essential_scripts[@]}
    local current=0

    for script in "${essential_scripts[@]}"; do
        current=$((current + 1))
        local script_path="$COMPONENT_DIR/$script"

        if [[ -f "$script_path" ]]; then
            log_info "[$current/$total] Installing $(basename "$script" .sh | sed 's/-/ /g')..."
            execute_with_progress "bash '$script_path'" "Installing $(basename "$script" .sh)..."
        else
            log_warning "Script not found: $script"
        fi
    done

    log_success "Essential $COMPONENT_NAME components installed!"
}

install_custom_selection() {
    local scripts=("$@")

    if [[ ${#scripts[@]} -eq 0 ]]; then
        log_error "No hardware scripts specified for custom installation"
        return 1
    fi

    log_info "Installing selected $COMPONENT_NAME components..."

    local total=${#scripts[@]}
    local current=0

    for script in "${scripts[@]}"; do
        current=$((current + 1))
        local script_path="$COMPONENT_DIR/$script"

        if [[ -f "$script_path" ]]; then
            log_info "[$current/$total] Installing $(basename "$script" .sh | sed 's/-/ /g')..."
            execute_with_progress "bash '$script_path'" "Installing $(basename "$script" .sh)..."
        else
            log_warning "Script not found: $script"
        fi
    done

    log_success "Selected $COMPONENT_NAME components installed!"
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

main() {
    log_info "Starting $COMPONENT_NAME installation..."

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
                echo "Hardware management installation options:"
                echo "  --all            Install all hardware components (default)"
                echo "  --essential      Install essential components (GPU, audio)"
                echo "  --scripts        Install specific hardware components"
                echo "  --help           Show this help message"
                echo ""
                echo "Available hardware components:"
                echo "  gpu-drivers.sh      NVIDIA, AMD, Intel graphics drivers"
                echo "  audio-system.sh     PipeWire, ALSA, PulseAudio setup"
                echo "  bluetooth.sh        Bluetooth stack and management"
                echo "  printer-support.sh  CUPS printing system"
                echo ""
                echo "Examples:"
                echo "  $0                                    # Install all hardware"
                echo "  $0 --essential                       # Install GPU and audio"
                echo "  $0 --scripts gpu-drivers.sh bluetooth.sh  # Install specific components"
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
            install_essential_hardware
            ;;
        "custom")
            install_custom_selection "${custom_scripts[@]}"
            ;;
        "all"|*)
            install_all_hardware
            ;;
    esac

    log_info "$COMPONENT_NAME installation completed!"
}

# Execute main function with all arguments
main "$@"

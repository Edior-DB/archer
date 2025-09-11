#!/bin/bash
# Desktop Themes installation script
# Provides Cupertini, Redmondi, and Vanilla themes

# ==============================================================================
# CONFIGURATION
# ==============================================================================
COMPONENT_NAME="Desktop Themes"
COMPONENT_DIR="$(dirname "$(realpath "$0")")"
ARCHER_DIR="${ARCHER_DIR:-$(dirname "$(dirname "$(dirname "$COMPONENT_DIR")")")}"

# Source common functions
source "$ARCHER_DIR/install/system/common-funcs.sh"

# ==============================================================================
# INSTALLATION FUNCTIONS
# ==============================================================================

install_all_themes() {
    log_info "Installing all $COMPONENT_NAME..."

    # Array of all theme installation scripts in order
    local scripts=(
        "cupertini.sh"
        "redmondi.sh"
        "vanilla.sh"
    )

    local total=${#scripts[@]}
    local current=0

    for script in "${scripts[@]}"; do
        current=$((current + 1))
        local script_path="$COMPONENT_DIR/$script"

        if [[ -f "$script_path" ]]; then
            log_info "[$current/$total] Installing $(basename "$script" .sh) theme..."
            execute_with_progress "bash '$script_path'" "Installing $(basename "$script" .sh)..."
        else
            log_warning "Script not found: $script"
        fi
    done

    log_success "All $COMPONENT_NAME installed!"
}

install_essential_themes() {
    log_info "Installing essential $COMPONENT_NAME..."

    # Default to Cupertini theme as essential
    local essential_script="cupertini.sh"
    local script_path="$COMPONENT_DIR/$essential_script"

    if [[ -f "$script_path" ]]; then
        log_info "Installing Cupertini theme (essential)..."
        execute_with_progress "bash '$script_path'" "Installing Cupertini..."
    else
        log_warning "Essential theme script not found: $essential_script"
    fi

    log_success "Essential $COMPONENT_NAME installed!"
}

install_custom_selection() {
    local scripts=("$@")

    if [[ ${#scripts[@]} -eq 0 ]]; then
        log_error "No theme scripts specified for custom installation"
        return 1
    fi

    log_info "Installing selected $COMPONENT_NAME..."

    local total=${#scripts[@]}
    local current=0

    for script in "${scripts[@]}"; do
        current=$((current + 1))
        local script_path="$COMPONENT_DIR/$script"

        if [[ -f "$script_path" ]]; then
            log_info "[$current/$total] Installing $(basename "$script" .sh) theme..."
            execute_with_progress "bash '$script_path'" "Installing $(basename "$script" .sh)..."
        else
            log_warning "Script not found: $script"
        fi
    done

    log_success "Selected $COMPONENT_NAME installed!"
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
                echo "Desktop themes installation options:"
                echo "  --all            Install all themes (default)"
                echo "  --essential      Install essential theme (Cupertini)"
                echo "  --scripts        Install specific themes"
                echo "  --help           Show this help message"
                echo ""
                echo "Available themes:"
                echo "  cupertini.sh     macOS-inspired KDE theme"
                echo "  redmondi.sh      Windows-inspired theme"
                echo "  vanilla.sh       Clean minimal theme"
                echo "  de-installer.sh  Remove themes and restore defaults"
                echo ""
                echo "Examples:"
                echo "  $0                                    # Install all themes"
                echo "  $0 --essential                       # Install Cupertini only"
                echo "  $0 --scripts cupertini.sh vanilla.sh # Install specific themes"
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
            install_essential_themes
            ;;
        "custom")
            install_custom_selection "${custom_scripts[@]}"
            ;;
        "all"|*)
            install_all_themes
            ;;
    esac

    log_info "$COMPONENT_NAME installation completed!"
}

# Execute main function with all arguments
main "$@"

#!/bin/bash
# Font packages installation script
# Provides unopinionated bulk installation of font components

# ==============================================================================
# CONFIGURATION
# ==============================================================================
COMPONENT_NAME="Font Packages"
COMPONENT_DIR="$(dirname "$(realpath "$0")")"
ARCHER_DIR="${ARCHER_DIR:-$(dirname "$(dirname "$(dirname "$COMPONENT_DIR")")")}"

# Source common functions
source "$ARCHER_DIR/install/system/common-funcs.sh"

# ==============================================================================
# INSTALLATION FUNCTIONS
# ==============================================================================

install_all_scripts() {
    log_info "Installing all $COMPONENT_NAME..."

    # Array of all font installation scripts in recommended order
    local scripts=(
        "system-fonts.sh"
        "coding-fonts.sh"
        "google-fonts.sh"
        "microsoft-fonts.sh"
        "apple-fonts.sh"
        "adobe-fonts.sh"
        "nerd-fonts.sh"
    )

    local total=${#scripts[@]}
    local current=0

    for script in "${scripts[@]}"; do
        current=$((current + 1))
        local script_path="$COMPONENT_DIR/$script"

        if [[ -f "$script_path" ]]; then
            log_info "[$current/$total] Installing $(basename "$script" .sh) fonts..."
            execute_with_progress "bash '$script_path'" "Installing $(basename "$script" .sh) fonts..."
        else
            log_warning "Script not found: $script"
        fi
    done

    log_success "All $COMPONENT_NAME installed!"
}

install_essential_scripts() {
    log_info "Installing essential $COMPONENT_NAME..."

    # Array of essential font installation scripts
    local essential_scripts=(
        "system-fonts.sh"
        "coding-fonts.sh"
        "nerd-fonts.sh"
    )

    local total=${#essential_scripts[@]}
    local current=0

    for script in "${essential_scripts[@]}"; do
        current=$((current + 1))
        local script_path="$COMPONENT_DIR/$script"

        if [[ -f "$script_path" ]]; then
            log_info "[$current/$total] Installing $(basename "$script" .sh) fonts..."
            execute_with_progress "bash '$script_path'" "Installing $(basename "$script" .sh) fonts..."
        else
            log_warning "Script not found: $script"
        fi
    done

    log_success "Essential $COMPONENT_NAME installed!"
}

install_custom_selection() {
    local scripts=("$@")

    if [[ ${#scripts[@]} -eq 0 ]]; then
        log_error "No font packages specified for custom installation"
        return 1
    fi

    log_info "Installing selected $COMPONENT_NAME..."

    local total=${#scripts[@]}
    local current=0

    for script in "${scripts[@]}"; do
        current=$((current + 1))
        local script_path="$COMPONENT_DIR/$script"

        if [[ -f "$script_path" ]]; then
            log_info "[$current/$total] Installing $(basename "$script" .sh) fonts..."
            execute_with_progress "bash '$script_path'" "Installing $(basename "$script" .sh) fonts..."
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
                echo "Font package installation options:"
                echo "  --all            Install all font packages (default)"
                echo "  --essential      Install only essential fonts (system, coding, nerd)"
                echo "  --scripts        Install specific font packages"
                echo "  --help           Show this help message"
                echo ""
                echo "Available font packages:"
                echo "  system-fonts.sh     Core system fonts and emoji support"
                echo "  coding-fonts.sh     Monospace fonts for programming"
                echo "  google-fonts.sh     Popular web fonts from Google"
                echo "  microsoft-fonts.sh  Arial, Times New Roman, etc."
                echo "  apple-fonts.sh      SF Pro, Helvetica Neue, etc."
                echo "  adobe-fonts.sh      Source Sans, Source Code Pro"
                echo "  nerd-fonts.sh       Programming fonts with icons"
                echo ""
                echo "Examples:"
                echo "  $0                                    # Install all fonts"
                echo "  $0 --essential                       # Install essential fonts only"
                echo "  $0 --scripts coding-fonts.sh nerd-fonts.sh  # Install specific fonts"
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
            install_essential_scripts
            ;;
        "custom")
            install_custom_selection "${custom_scripts[@]}"
            ;;
        "all"|*)
            install_all_scripts
            ;;
    esac

    log_info "$COMPONENT_NAME installation completed!"
}

# Execute main function with all arguments
main "$@"

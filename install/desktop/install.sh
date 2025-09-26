#!/bin/bash
# Desktop Environment & Themes installation script
# Provides desktop themes, fonts, office tools, and utilities

# ==============================================================================
# CONFIGURATION
# ==============================================================================
COMPONENT_NAME="Desktop Environment & Themes"
COMPONENT_DIR="$(dirname "$(realpath "$0")")"
ARCHER_DIR="${ARCHER_DIR:-$(dirname "$(dirname "$COMPONENT_DIR")")}"

# Source common functions
source "$ARCHER_DIR/install/system/common-funcs.sh"

# ==============================================================================
# INSTALLATION FUNCTIONS
# ==============================================================================

install_all_modules() {
    log_info "Installing all $COMPONENT_NAME modules..."

    # Array of all desktop module directories in order
    local modules=(
        "fonts"
        "themes"
        "office-tools"
        "utilities"
    )

    local total=${#modules[@]}
    local current=0

    for module in "${modules[@]}"; do
        current=$((current + 1))
        local module_path="$COMPONENT_DIR/$module"

        if [[ -d "$module_path" && -f "$module_path/install.sh" ]]; then
            log_info "[$current/$total] Installing $module modules..."
            execute_with_progress "bash '$module_path/install.sh' --all" "Installing $module..."
        else
            log_warning "Module not found: $module"
        fi
    done

    log_success "All $COMPONENT_NAME modules installed!"
}

install_essential_modules() {
    log_info "Installing essential $COMPONENT_NAME modules..."

    # Array of essential desktop components
    local essential_modules=(
        "fonts"         # Essential fonts
        "office-tools"  # Basic productivity
    )

    local total=${#essential_modules[@]}
    local current=0

    for module in "${essential_modules[@]}"; do
        current=$((current + 1))
        local module_path="$COMPONENT_DIR/$module"

        if [[ -d "$module_path" && -f "$module_path/install.sh" ]]; then
            log_info "[$current/$total] Installing essential $module..."
            execute_with_progress "bash '$module_path/install.sh' --essential" "Installing essential $module..."
        else
            log_warning "Module not found: $module"
        fi
    done

    log_success "Essential $COMPONENT_NAME modules installed!"
}

install_custom_selection() {
    local scripts=("$@")

    if [[ ${#scripts[@]} -eq 0 ]]; then
        log_error "No desktop scripts specified for custom installation"
        return 1
    fi

    log_info "Installing selected $COMPONENT_NAME modules..."

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

    log_success "Selected $COMPONENT_NAME modules installed!"
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
                echo "Desktop environment installation options:"
                echo "  --all            Install all desktop modules (default)"
                echo "  --essential      Install essential modules (fonts, office)"
                echo "  --scripts        Install specific module scripts"
                echo "  --help           Show this help message"
                echo ""
                echo "Examples:"
                echo "  $0                                    # Install all modules"
                echo "  $0 --essential                       # Install essential modules"
                echo "  $0 --scripts fonts/install.sh themes/install.sh"
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
            install_essential_modules
            ;;
        "custom")
            install_custom_selection "${custom_scripts[@]}"
            ;;
        "all"|*)
            install_all_modules
            ;;
    esac

    log_info "$COMPONENT_NAME installation completed!"
}

# Execute main function with all arguments
main "$@"

#!/bin/bash
# Standard install.sh template for component categories
# Provides unopinionated bulk installation of component scripts

# ==============================================================================
# CONFIGURATION
# ==============================================================================
COMPONENT_NAME="Component Name"
COMPONENT_DIR="$(dirname "$(realpath "$0")")"
ARCHER_DIR="${ARCHER_DIR:-$(dirname "$(dirname "$(dirname "$COMPONENT_DIR")")")}"

# Source common functions
source "$ARCHER_DIR/install/system/common-funcs.sh"

# ==============================================================================
# INSTALLATION FUNCTIONS
# ==============================================================================

install_all_scripts() {
    log_info "Installing all $COMPONENT_NAME scripts..."

    # Array of all installation scripts in order
    local scripts=(
        "core.sh"
        "extended.sh"
        "optional.sh"
        # Add more scripts as needed
    )

    local total=${#scripts[@]}
    local current=0

    for script in "${scripts[@]}"; do
        current=$((current + 1))
        local script_path="$COMPONENT_DIR/$script"

        if [[ -f "$script_path" ]]; then
            log_info "[$current/$total] Running $script..."
            execute_with_progress "bash '$script_path'" "Executing $script..."
        else
            log_warning "Script not found: $script"
        fi
    done

    log_success "All $COMPONENT_NAME scripts completed!")
}

install_core_only() {
    log_info "Installing core $COMPONENT_NAME components..."

    # Array of core installation scripts only
    local core_scripts=(
        "core.sh"
        # Add only essential scripts
    )

    local total=${#core_scripts[@]}
    local current=0

    for script in "${core_scripts[@]}"; do
        current=$((current + 1))
        local script_path="$COMPONENT_DIR/$script"

        if [[ -f "$script_path" ]]; then
            log_info "[$current/$total] Running $script..."
            execute_with_progress "bash '$script_path'" "Executing $script..."
        else
            log_warning "Script not found: $script"
        fi
    done

    log_success "Core $COMPONENT_NAME components installed!")
}

install_custom_selection() {
    local scripts=("$@")

    if [[ ${#scripts[@]} -eq 0 ]]; then
        log_error "No scripts specified for custom installation"
        return 1
    fi

    log_info "Installing selected $COMPONENT_NAME scripts..."

    local total=${#scripts[@]}
    local current=0

    for script in "${scripts[@]}"; do
        current=$((current + 1))
        local script_path="$COMPONENT_DIR/$script"

        if [[ -f "$script_path" ]]; then
            log_info "[$current/$total] Running $script..."
            execute_with_progress "bash '$script_path'" "Executing $script..."
        else
            log_warning "Script not found: $script"
        fi
    done

    log_success "Selected $COMPONENT_NAME scripts completed!")
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
            --core)
                install_mode="core"
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
                echo "Usage: $0 [--all|--core|--scripts script1 script2 ...] [--help]"
                echo "  --all            Install all scripts (default)"
                echo "  --core           Install only core scripts"
                echo "  --scripts        Install specific scripts"
                echo "  --help           Show this help message"
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
        "core")
            install_core_only
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

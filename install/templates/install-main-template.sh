#!/bin/bash
# Standard install.sh template for main categories
# Provides unopinionated bulk installation of all components

# ==============================================================================
# CONFIGURATION
# ==============================================================================
CATEGORY_NAME="Category Name"
CATEGORY_DIR="$(dirname "$(realpath "$0")")"
ARCHER_DIR="${ARCHER_DIR:-$(dirname "$(dirname "$CATEGORY_DIR")")}"

# Source common functions
source "$ARCHER_DIR/install/system/common-funcs.sh"

# ==============================================================================
# INSTALLATION FUNCTIONS
# ==============================================================================

install_all_components() {
    log_info "Installing all $CATEGORY_NAME components..."

    # Array of all installation scripts in order
    local scripts=(
        "subcategory1/install.sh"
        "subcategory2/install.sh"
        # Add more subcategories as needed
    )

    local total=${#scripts[@]}
    local current=0

    for script in "${scripts[@]}"; do
        current=$((current + 1))
        local script_path="$CATEGORY_DIR/$script"

        if [[ -f "$script_path" ]]; then
            log_info "[$current/$total] Installing $(basename "$(dirname "$script")")..."
            execute_with_progress "bash '$script_path'" "Installing $(basename "$(dirname "$script")")..."
        else
            log_warning "Script not found: $script"
        fi
    done

    log_success "All $CATEGORY_NAME components installed!"
}

install_essential_components() {
    log_info "Installing essential $CATEGORY_NAME components..."

    # Array of essential installation scripts
    local essential_scripts=(
        "essential-component1/install.sh"
        "essential-component2/install.sh"
        # Add essential components only
    )

    local total=${#essential_scripts[@]}
    local current=0

    for script in "${essential_scripts[@]}"; do
        current=$((current + 1))
        local script_path="$CATEGORY_DIR/$script"

        if [[ -f "$script_path" ]]; then
            log_info "[$current/$total] Installing $(basename "$(dirname "$script")")..."
            execute_with_progress "bash '$script_path'" "Installing $(basename "$(dirname "$script")")..."
        else
            log_warning "Script not found: $script"
        fi
    done

    log_success "Essential $CATEGORY_NAME components installed!"
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

main() {
    log_info "Starting $CATEGORY_NAME installation..."

    # Parse command line arguments
    local install_mode="all"

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
            --help)
                echo "Usage: $0 [--all|--essential] [--help]"
                echo "  --all       Install all components (default)"
                echo "  --essential Install only essential components"
                echo "  --help      Show this help message"
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
            install_essential_components
            ;;
        "all"|*)
            install_all_components
            ;;
    esac

    log_info "$CATEGORY_NAME installation completed!"
}

# Execute main function with all arguments
main "$@"

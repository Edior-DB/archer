#!/bin/bash
# Development Tools installation script
# Provides unopinionated bulk installation of all development components

# ==============================================================================
# CONFIGURATION
# ==============================================================================
CATEGORY_NAME="Development Tools"
CATEGORY_DIR="$(dirname "$(realpath "$0")")"
ARCHER_DIR="${ARCHER_DIR:-$(dirname "$(dirname "$CATEGORY_DIR")")}"

# Source common functions
source "$ARCHER_DIR/install/system/common-funcs.sh"

# ==============================================================================
# INSTALLATION FUNCTIONS
# ==============================================================================

install_all_scripts() {
    log_info "Installing all $CATEGORY_NAME..."

    # Array of all installation scripts and subdirectories in order
    local components=(
        "editors/install.sh"
        "terminals/install.sh"
        "system-programming/install.sh"
        "scripting-web/install.sh"
        "numerical-computing/install.sh"
        "devops-mobile/install.sh"
        "database-tools/install.sh"
    )

    local total=${#components[@]}
    local current=0

    for component in "${components[@]}"; do
        current=$((current + 1))
        local component_path="$CATEGORY_DIR/$component"

        if [[ -f "$component_path" ]]; then
            local component_name=$(basename "$(dirname "$component")" | sed 's/-/ /g')
            if [[ "$(basename "$component")" == "install.sh" ]]; then
                log_info "[$current/$total] Installing $component_name..."
            else
                log_info "[$current/$total] Installing $(basename "$component" .sh | sed 's/-/ /g')..."
            fi
            execute_with_progress "bash '$component_path'" "Installing $(basename "$component" .sh)..."
        else
            log_warning "Component not found: $component"
        fi
    done

    log_success "All $CATEGORY_NAME installed!"
}

install_essential_scripts() {
    log_info "Installing essential $CATEGORY_NAME..."

    # Array of essential development components
    local essential_components=(
        "dev-tools.sh"
        "editors/app-vscode.sh"
        "terminals/terminal-kitty.sh"
    )

    local total=${#essential_components[@]}
    local current=0

    for component in "${essential_components[@]}"; do
        current=$((current + 1))
        local component_path="$CATEGORY_DIR/$component"

        if [[ -f "$component_path" ]]; then
            log_info "[$current/$total] Installing $(basename "$component" .sh)..."
            execute_with_progress "bash '$component_path'" "Installing $(basename "$component" .sh)..."
        else
            log_warning "Component not found: $component"
        fi
    done

    log_success "Essential $CATEGORY_NAME installed!"
}

install_custom_selection() {
    local scripts=("$@")

    if [[ ${#scripts[@]} -eq 0 ]]; then
        log_error "No development scripts specified for custom installation"
        return 1
    fi

    log_info "Installing selected $CATEGORY_NAME components..."

    local total=${#scripts[@]}
    local current=0

    for script in "${scripts[@]}"; do
        current=$((current + 1))
        local script_path="$CATEGORY_DIR/$script"

        if [[ -f "$script_path" ]]; then
            log_info "[$current/$total] Installing $(basename "$script" .sh | sed 's/-/ /g')..."
            execute_with_progress "bash '$script_path'" "Installing $(basename "$script" .sh)..."
        else
            log_warning "Script not found: $script"
        fi
    done

    log_success "Selected $CATEGORY_NAME components installed!"
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

main() {
    log_info "Starting $CATEGORY_NAME installation..."

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
                echo "Development tools installation options:"
                echo "  --all         Install all development tools (default)"
                echo "  --essential   Install essential dev environment (dev-tools, VS Code, Kitty)"
                echo "  --scripts     Install specific module scripts"
                echo "  --help        Show this help message"
                echo ""
                echo "Examples:"
                echo "  $0                 # Install everything"
                echo "  $0 --essential     # Install essential development environment"
                echo "  $0 --scripts editors/install.sh terminals/install.sh"
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

    log_info "$CATEGORY_NAME installation completed!"
}

# Execute main function with all arguments
main "$@"

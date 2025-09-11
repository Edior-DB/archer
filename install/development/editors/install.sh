#!/bin/bash
# Code Editors installation script
# Provides unopinionated bulk installation of editor components

# ==============================================================================
# CONFIGURATION
# ==============================================================================
COMPONENT_NAME="Code Editors"
COMPONENT_DIR="$(dirname "$(realpath "$0")")"
ARCHER_DIR="${ARCHER_DIR:-$(dirname "$(dirname "$(dirname "$COMPONENT_DIR")")")}"

# Source common functions
source "$ARCHER_DIR/install/system/common-funcs.sh"

# ==============================================================================
# INSTALLATION FUNCTIONS
# ==============================================================================

install_all_scripts() {
    log_info "Installing all $COMPONENT_NAME..."

    # Array of all editor installation scripts in order
    local scripts=(
        "app-vscode.sh"
        "app-vscodium.sh"
        "editors.sh"
    )

    local total=${#scripts[@]}
    local current=0

    for script in "${scripts[@]}"; do
        current=$((current + 1))
        local script_path="$COMPONENT_DIR/$script"

        if [[ -f "$script_path" ]]; then
            log_info "[$current/$total] Installing $(basename "$script" .sh | sed 's/^app-//' | sed 's/^terminal-//')..."
            execute_with_progress "bash '$script_path'" "Installing $(basename "$script" .sh)..."
        else
            log_warning "Script not found: $script"
        fi
    done

    log_success "All $COMPONENT_NAME installed!"
}

install_vscode_only() {
    log_info "Installing VS Code editors..."

    # Array of VS Code variants
    local vscode_scripts=(
        "app-vscode.sh"
        "app-vscodium.sh"
    )

    local total=${#vscode_scripts[@]}
    local current=0

    for script in "${vscode_scripts[@]}"; do
        current=$((current + 1))
        local script_path="$COMPONENT_DIR/$script"

        if [[ -f "$script_path" ]]; then
            log_info "[$current/$total] Installing $(basename "$script" .sh | sed 's/^app-//')..."
            execute_with_progress "bash '$script_path'" "Installing $(basename "$script" .sh)..."
        else
            log_warning "Script not found: $script"
        fi
    done

    log_success "VS Code editors installed!"
}

install_custom_selection() {
    local scripts=("$@")

    if [[ ${#scripts[@]} -eq 0 ]]; then
        log_error "No editor scripts specified for custom installation"
        return 1
    fi

    log_info "Installing selected $COMPONENT_NAME..."

    local total=${#scripts[@]}
    local current=0

    for script in "${scripts[@]}"; do
        current=$((current + 1))
        local script_path="$COMPONENT_DIR/$script"

        if [[ -f "$script_path" ]]; then
            log_info "[$current/$total] Installing $(basename "$script" .sh | sed 's/^app-//' | sed 's/^terminal-//')..."
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
            --vscode)
                install_mode="vscode"
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
                echo "Usage: $0 [--all|--vscode|--scripts script1 script2 ...] [--help]"
                echo ""
                echo "Code editor installation options:"
                echo "  --all            Install all editors (default)"
                echo "  --vscode         Install VS Code variants only"
                echo "  --scripts        Install specific editor packages"
                echo "  --help           Show this help message"
                echo ""
                echo "Available editor packages:"
                echo "  app-vscode.sh      Microsoft Visual Studio Code"
                echo "  app-vscodium.sh    Open source VSCodium"
                echo "  editors.sh         Additional editors (Vim, Neovim, Emacs, etc.)"
                echo ""
                echo "Examples:"
                echo "  $0                                    # Install all editors"
                echo "  $0 --vscode                          # Install VS Code variants only"
                echo "  $0 --scripts app-vscode.sh editors.sh   # Install specific editors"
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
        "vscode")
            install_vscode_only
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

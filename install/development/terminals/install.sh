#!/bin/bash
# Terminal Emulators installation script
# Provides unopinionated bulk installation of terminal components

# ==============================================================================
# CONFIGURATION
# ==============================================================================
COMPONENT_NAME="Terminal Emulators"
COMPONENT_DIR="$(dirname "$(realpath "$0")")"
ARCHER_DIR="${ARCHER_DIR:-$(dirname "$(dirname "$(dirname "$COMPONENT_DIR")")")}"

# Source common functions
source "$ARCHER_DIR/install/system/common-funcs.sh"

# ==============================================================================
# INSTALLATION FUNCTIONS
# ==============================================================================

install_all_scripts() {
    log_info "Installing all $COMPONENT_NAME..."

    # Array of all terminal installation scripts in order
    local scripts=(
        "terminal-alacritty.sh"
        "terminal-kitty.sh"
        "terminal-wezterm.sh"
        "terminal-hyper.sh"
    )

    local total=${#scripts[@]}
    local current=0

    for script in "${scripts[@]}"; do
        current=$((current + 1))
        local script_path="$COMPONENT_DIR/$script"

        if [[ -f "$script_path" ]]; then
            log_info "[$current/$total] Installing $(basename "$script" .sh | sed 's/^terminal-//')..."
            execute_with_progress "bash '$script_path'" "Installing $(basename "$script" .sh)..."
        else
            log_warning "Script not found: $script"
        fi
    done

    log_success "All $COMPONENT_NAME installed!"
}

install_modern_only() {
    log_info "Installing modern $COMPONENT_NAME..."

    # Array of modern terminal emulators (excluding Hyper)
    local modern_scripts=(
        "terminal-alacritty.sh"
        "terminal-kitty.sh"
        "terminal-wezterm.sh"
    )

    local total=${#modern_scripts[@]}
    local current=0

    for script in "${modern_scripts[@]}"; do
        current=$((current + 1))
        local script_path="$COMPONENT_DIR/$script"

        if [[ -f "$script_path" ]]; then
            log_info "[$current/$total] Installing $(basename "$script" .sh | sed 's/^terminal-//')..."
            execute_with_progress "bash '$script_path'" "Installing $(basename "$script" .sh)..."
        else
            log_warning "Script not found: $script"
        fi
    done

    log_success "Modern $COMPONENT_NAME installed!"
}

install_custom_selection() {
    local scripts=("$@")

    if [[ ${#scripts[@]} -eq 0 ]]; then
        log_error "No terminal scripts specified for custom installation"
        return 1
    fi

    log_info "Installing selected $COMPONENT_NAME..."

    local total=${#scripts[@]}
    local current=0

    for script in "${scripts[@]}"; do
        current=$((current + 1))
        local script_path="$COMPONENT_DIR/$script"

        if [[ -f "$script_path" ]]; then
            log_info "[$current/$total] Installing $(basename "$script" .sh | sed 's/^terminal-//')..."
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
            --modern)
                install_mode="modern"
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
                echo "Usage: $0 [--all|--modern|--scripts script1 script2 ...] [--help]"
                echo ""
                echo "Terminal emulator installation options:"
                echo "  --all            Install all terminals (default)"
                echo "  --modern         Install modern terminals only (exclude Hyper)"
                echo "  --scripts        Install specific terminal packages"
                echo "  --help           Show this help message"
                echo ""
                echo "Available terminal packages:"
                echo "  terminal-alacritty.sh   GPU-accelerated, minimal config"
                echo "  terminal-kitty.sh       Feature-rich with image support"
                echo "  terminal-wezterm.sh     Cross-platform, Rust-based"
                echo "  terminal-hyper.sh       Extensible, Electron-based"
                echo ""
                echo "Examples:"
                echo "  $0                                    # Install all terminals"
                echo "  $0 --modern                          # Install modern terminals only"
                echo "  $0 --scripts terminal-alacritty.sh terminal-kitty.sh  # Install specific terminals"
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
        "modern")
            install_modern_only
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

#!/bin/bash
# System Programming Languages installation script
# Provides unopinionated bulk installation of systems programming languages

# ==============================================================================
# CONFIGURATION
# ==============================================================================
COMPONENT_NAME="System Programming Languages"
COMPONENT_DIR="$(dirname "$(realpath "$0")")"
ARCHER_DIR="${ARCHER_DIR:-$(dirname "$(dirname "$(dirname "$COMPONENT_DIR")")")}"

# Source common functions
source "$ARCHER_DIR/install/system/common-funcs.sh"

# ==============================================================================
# INSTALLATION FUNCTIONS
# ==============================================================================

install_all_scripts() {
    log_info "Installing all $COMPONENT_NAME..."

    # Array of all system programming language installation scripts in order
    local scripts=(
        "cpp-compilers.sh"
        "rust.sh"
        "go.sh"
        "d-lang.sh"
        "nim.sh"
        "zig.sh"
        "v-lang.sh"
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

    log_success "All $COMPONENT_NAME installed!"
}

install_essential_scripts() {
    log_info "Installing essential $COMPONENT_NAME..."

    # Array of essential system programming languages
    local essential_scripts=(
        "cpp-compilers.sh"
        "rust.sh"
        "go.sh"
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

    log_success "Essential $COMPONENT_NAME installed!"
}

install_custom_selection() {
    local scripts=("$@")

    if [[ ${#scripts[@]} -eq 0 ]]; then
        log_error "No language scripts specified for custom installation"
        return 1
    fi

    log_info "Installing selected $COMPONENT_NAME..."

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
                echo "System programming language installation options:"
                echo "  --all            Install all languages (default)"
                echo "  --essential      Install essential languages (C/C++, Rust, Go)"
                echo "  --scripts        Install specific language packages"
                echo "  --help           Show this help message"
                echo ""
                echo "Available language packages:"
                echo "  cpp-compilers.sh C/C++ compilers (GCC and Clang/LLVM)"
                echo "  rust.sh          Rust programming language"
                echo "  go.sh            Go programming language"
                echo "  d-lang.sh        D language (DMD and LDC)"
                echo "  nim.sh           Nim programming language"
                echo "  zig.sh           Zig programming language"
                echo "  v-lang.sh        V programming language"
                echo ""
                echo "Examples:"
                echo "  $0                                    # Install all languages"
                echo "  $0 --essential                       # Install essential languages"
                echo "  $0 --scripts rust.sh go.sh             # Install specific languages"
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

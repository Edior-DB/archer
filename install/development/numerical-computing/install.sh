#!/bin/bash
# Numerical Computing installation script
# Provides unopinionated bulk installation of scientific computing tools

# ==============================================================================
# CONFIGURATION
# ==============================================================================
COMPONENT_NAME="Numerical Computing Tools"
COMPONENT_DIR="$(dirname "$(realpath "$0")")"
ARCHER_DIR="${ARCHER_DIR:-$(dirname "$(dirname "$(dirname "$COMPONENT_DIR")")")}"

# Source common functions
source "$ARCHER_DIR/install/system/common-funcs.sh"

# ==============================================================================
# INSTALLATION FUNCTIONS
# ==============================================================================

install_all_scripts() {
    log_info "Installing all $COMPONENT_NAME..."

    # Array of all scientific computing installation scripts in order
    local scripts=(
        "fortran.sh"
        "julia.sh"
        "r-lang.sh"
        "octave.sh"
        "haskell.sh"
        "anaconda.sh"
        "spack.sh"
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

    # Array of essential scientific computing tools
    local essential_scripts=(
        "julia.sh"
        "r-lang.sh"
        "octave.sh"
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

install_python_science() {
    log_info "Installing Python scientific stack..."

    local python_script="$COMPONENT_DIR/anaconda.sh"
    if [[ -f "$python_script" ]]; then
        execute_with_progress "bash '$python_script'" "Installing Anaconda Python distribution..."
    else
        log_warning "Anaconda script not found"
    fi

    log_success "Python scientific stack installed!"
}

install_custom_selection() {
    local scripts=("$@")

    if [[ ${#scripts[@]} -eq 0 ]]; then
        log_error "No scientific computing scripts specified for custom installation"
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
            --python)
                install_mode="python"
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
                echo "Usage: $0 [--all|--essential|--python|--scripts script1 script2 ...] [--help]"
                echo ""
                echo "Numerical computing installation options:"
                echo "  --all            Install all scientific tools (default)"
                echo "  --essential      Install essential tools (Julia, R, Octave)"
                echo "  --python         Install Python scientific stack (Anaconda)"
                echo "  --scripts        Install specific tool packages"
                echo "  --help           Show this help message"
                echo ""
                echo "Available tool packages:"
                echo "  fortran.sh       Fortran compilers (GFortran + LFortran)"
                echo "  julia.sh         Julia programming language"
                echo "  r-lang.sh        R statistical computing"
                echo "  octave.sh        GNU Octave (MATLAB alternative)"
                echo "  haskell.sh       Haskell programming language"
                echo "  anaconda.sh      Anaconda Python distribution"
                echo "  spack.sh         Spack HPC package manager"
                echo ""
                echo "Examples:"
                echo "  $0                                    # Install all tools"
                echo "  $0 --essential                       # Install essential tools"
                echo "  $0 --python                          # Install Anaconda only"
                echo "  $0 --scripts julia.sh r-lang.sh        # Install specific tools"
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
        "python")
            install_python_science
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

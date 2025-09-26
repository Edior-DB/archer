#!/bin/bash
# System Management installation script
# Provides system-level configuration and hardware management

# ==============================================================================
# CONFIGURATION
# ==============================================================================
COMPONENT_NAME="System Management"
COMPONENT_DIR="$(dirname "$(realpath "$0")")"
ARCHER_DIR="${ARCHER_DIR:-$(dirname "$(dirname "$COMPONENT_DIR")")}"

# Source common functions
source "$COMPONENT_DIR/common-funcs.sh"

# ==============================================================================
# INSTALLATION FUNCTIONS
# ==============================================================================

install_all_modules() {
    log_info "Installing all $COMPONENT_NAME modules..."

    # Array of all system module directories in order
    local modules=(
        "hardware"
        "optimization"
        "security"
        "packages"
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

    # Array of essential system components
    local essential_modules=(
        "hardware"      # GPU drivers, audio
        "packages"      # AUR helpers
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

install_hardware_only() {
    log_info "Installing hardware management modules..."

    local hardware_path="$COMPONENT_DIR/hardware"
    if [[ -d "$hardware_path" && -f "$hardware_path/install.sh" ]]; then
        execute_with_progress "bash '$hardware_path/install.sh' --all" "Installing hardware modules..."
    else
        log_warning "Hardware module not found"
    fi

    log_success "Hardware modules installed!"
}

install_optimization_only() {
    log_info "Installing system optimization modules..."

    local optimization_path="$COMPONENT_DIR/optimization"
    if [[ -d "$optimization_path" && -f "$optimization_path/install.sh" ]]; then
        execute_with_progress "bash '$optimization_path/install.sh' --all" "Installing optimization modules..."
    else
        log_warning "Optimization module not found"
    fi

    log_success "Optimization modules installed!"
}

install_security_only() {
    log_info "Installing security and monitoring modules..."

    local security_path="$COMPONENT_DIR/security"
    if [[ -d "$security_path" && -f "$security_path/install.sh" ]]; then
        execute_with_progress "bash '$security_path/install.sh' --all" "Installing security modules..."
    else
        log_warning "Security module not found"
    fi

    log_success "Security modules installed!"
}

install_packages_only() {
    log_info "Installing package management modules..."

    local packages_path="$COMPONENT_DIR/packages"
    if [[ -d "$packages_path" && -f "$packages_path/install.sh" ]]; then
        execute_with_progress "bash '$packages_path/install.sh' --all" "Installing package management..."
    else
        log_warning "Package management module not found"
    fi

    log_success "Package management modules installed!"
}

install_all_scripts() {
    log_info "Installing all scripts in the system directory..."
    for script in $(find "$COMPONENT_DIR" -name "install.sh" -type f); do
        bash "$script" --all
    done
}

install_custom_selection() {
    log_info "Installing selected scripts in the system directory..."
    for script in "$@"; do
        if [[ -f "$script" ]]; then
            bash "$script"
        else
            log_warning "Script not found: $script"
        fi
    done
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
            --hardware)
                install_mode="hardware"
                shift
                ;;
            --optimization)
                install_mode="optimization"
                shift
                ;;
            --security)
                install_mode="security"
                shift
                ;;
            --packages)
                install_mode="packages"
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
                echo "Usage: $0 [--all|--essential|--hardware|--optimization|--security|--packages|--scripts script1 script2 ...] [--help]"
                echo ""
                echo "System management installation options:"
                echo "  --all            Install all system modules (default)"
                echo "  --essential      Install essential modules (hardware, AUR helpers)"
                echo "  --hardware       Install hardware management (GPU, audio, bluetooth)"
                echo "  --optimization   Install system optimization (performance, power)"
                echo "  --security       Install security & monitoring (firewall, logging)"
                echo "  --packages       Install package management (AUR, Flatpak, cleanup)"
                echo "  --scripts        Install specific module scripts"
                echo "  --help           Show this help message"
                echo ""
                echo "Available modules:"
                echo "  Hardware:     GPU drivers, audio system, bluetooth, printer support"
                echo "  Optimization: Performance tuning, memory/power management, kernels"
                echo "  Security:     Firewall, monitoring, logging, backup solutions"
                echo "  Packages:     AUR helpers, Flatpak, cleanup tools"
                echo ""
                echo "Examples:"
                echo "  $0                                    # Install all modules"
                echo "  $0 --essential                       # Install essential modules"
                echo "  $0 --hardware                        # Install hardware management"
                echo "  $0 --scripts hardware/gpu-drivers.sh packages/aur-helpers.sh"
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
        "hardware")
            install_hardware_only
            ;;
        "optimization")
            install_optimization_only
            ;;
        "security")
            install_security_only
            ;;
        "packages")
            install_packages_only
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

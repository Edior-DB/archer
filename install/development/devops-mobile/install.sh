#!/bin/bash
# DevOps & Mobile installation script
# Provides unopinionated bulk installation of DevOps and mobile development tools

# ==============================================================================
# CONFIGURATION
# ==============================================================================
COMPONENT_NAME="DevOps & Mobile Tools"
COMPONENT_DIR="$(dirname "$(realpath "$0")")"
ARCHER_DIR="${ARCHER_DIR:-$(dirname "$(dirname "$(dirname "$COMPONENT_DIR")")")}"

# Source common functions
source "$ARCHER_DIR/install/system/common-funcs.sh"

# ==============================================================================
# INSTALLATION FUNCTIONS
# ==============================================================================

install_all_scripts() {
    log_info "Installing all $COMPONENT_NAME..."

    # Array of all DevOps and mobile development installation scripts in order
    local scripts=(
        "docker.sh"
        "podman.sh"
        "kubernetes.sh"
        "terraform.sh"
        "ansible.sh"
        "flutter.sh"
        "kotlin.sh"
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

    # Array of essential DevOps tools
    local essential_scripts=(
        "docker.sh"
        "kubernetes.sh"
        "terraform.sh"
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

install_containers() {
    log_info "Installing container tools..."

    local container_scripts=(
        "docker.sh"
        "podman.sh"
        "kubernetes.sh"
    )

    local total=${#container_scripts[@]}
    local current=0

    for script in "${container_scripts[@]}"; do
        current=$((current + 1))
        local script_path="$COMPONENT_DIR/$script"

        if [[ -f "$script_path" ]]; then
            log_info "[$current/$total] Installing $(basename "$script" .sh | sed 's/-/ /g')..."
            execute_with_progress "bash '$script_path'" "Installing $(basename "$script" .sh)..."
        else
            log_warning "Script not found: $script"
        fi
    done

    log_success "Container tools installed!"
}

install_mobile() {
    log_info "Installing mobile development tools..."

    local mobile_scripts=(
        "flutter.sh"
        "kotlin.sh"
    )

    local total=${#mobile_scripts[@]}
    local current=0

    for script in "${mobile_scripts[@]}"; do
        current=$((current + 1))
        local script_path="$COMPONENT_DIR/$script"

        if [[ -f "$script_path" ]]; then
            log_info "[$current/$total] Installing $(basename "$script" .sh | sed 's/-/ /g')..."
            execute_with_progress "bash '$script_path'" "Installing $(basename "$script" .sh)..."
        else
            log_warning "Script not found: $script"
        fi
    done

    log_success "Mobile development tools installed!"
}

install_custom_selection() {
    local scripts=("$@")

    if [[ ${#scripts[@]} -eq 0 ]]; then
        log_error "No DevOps/mobile scripts specified for custom installation"
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
            --containers)
                install_mode="containers"
                shift
                ;;
            --mobile)
                install_mode="mobile"
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
                echo "Usage: $0 [--all|--essential|--containers|--mobile|--scripts script1 script2 ...] [--help]"
                echo ""
                echo "DevOps & mobile development installation options:"
                echo "  --all            Install all tools (default)"
                echo "  --essential      Install essential tools (Docker, Kubernetes, Terraform)"
                echo "  --containers     Install container tools (Docker, Podman, Kubernetes)"
                echo "  --mobile         Install mobile development tools (Flutter, Kotlin)"
                echo "  --scripts        Install specific tool packages"
                echo "  --help           Show this help message"
                echo ""
                echo "Available tool packages:"
                echo "  docker.sh        Docker container platform"
                echo "  podman.sh        Podman container engine"
                echo "  kubernetes.sh    Kubernetes CLI tools"
                echo "  terraform.sh     Terraform infrastructure"
                echo "  ansible.sh       Ansible automation"
                echo "  flutter.sh       Flutter mobile framework"
                echo "  kotlin.sh        Kotlin programming language"
                echo ""
                echo "Examples:"
                echo "  $0                                    # Install all tools"
                echo "  $0 --essential                       # Install essential tools"
                echo "  $0 --containers                      # Install container tools"
                echo "  $0 --mobile                          # Install mobile tools"
                echo "  $0 --scripts docker.sh flutter.sh     # Install specific tools"
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
        "containers")
            install_containers
            ;;
        "mobile")
            install_mobile
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

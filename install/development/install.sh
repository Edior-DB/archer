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

install_all_components() {
    log_info "Installing all $CATEGORY_NAME..."

    # Array of all installation scripts and subdirectories in order
    local components=(
        "dev-tools.sh"
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
}install_essential_components() {
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

install_editors_only() {
    log_info "Installing all editors..."

    local editors_script="$CATEGORY_DIR/editors/install.sh"
    if [[ -f "$editors_script" ]]; then
        execute_with_progress "bash '$editors_script'" "Installing all editors..."
    else
        log_warning "Editors installation script not found"
    fi

    log_success "All editors installed!"
}

install_languages_only() {
    log_info "Installing core programming languages..."

    local languages_scripts=("$CATEGORY_DIR/system-programming/install.sh" "$CATEGORY_DIR/scripting-web/install.sh")
    for script in "${languages_scripts[@]}"; do
        if [[ -f "$script" ]]; then
            execute_with_progress "bash '$script'" "Installing $(basename "$(dirname "$script")" | sed 's/-/ /g')..."
        else
            log_warning "Language installation script not found: $script"
        fi
    done

    log_success "Core programming languages installed!"
}

install_scientific_only() {
    log_info "Installing scientific computing tools..."

    local scientific_scripts=("$CATEGORY_DIR/numerical-computing/install.sh" "$CATEGORY_DIR/database-tools/install.sh")
    for script in "${scientific_scripts[@]}"; do
        if [[ -f "$script" ]]; then
            execute_with_progress "bash '$script'" "Installing $(basename "$(dirname "$script")" | sed 's/-/ /g')..."
        else
            log_warning "Scientific installation script not found: $script"
        fi
    done

    log_success "Scientific computing tools installed!"
}# ==============================================================================
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
            --editors)
                install_mode="editors"
                shift
                ;;
            --terminals)
                install_mode="terminals"
                shift
                ;;
            --languages)
                install_mode="languages"
                shift
                ;;
            --scientific)
                install_mode="scientific"
                shift
                ;;
            --help)
                echo "Usage: $0 [--all|--essential|--editors|--terminals] [--help]"
                echo ""
                echo "Development tools installation options:"
                echo "  --all         Install all development tools (default)"
                echo "  --essential   Install essential dev environment (dev-tools, VS Code, Kitty)"
                echo "  --editors     Install all code editors and IDEs"
                echo "  --terminals   Install all terminal emulators"
                echo "  --help        Show this help message"
                echo ""
                echo "Components included:"
                echo "  dev-tools.sh       General development tools and utilities"
                echo "  editors/           Code editors and IDEs (VS Code, VSCodium, etc.)"
                echo "  terminals/         Terminal emulators (Alacritty, Kitty, WezTerm, Hyper)"
                echo ""
                echo "Examples:"
                echo "  $0                 # Install everything"
                echo "  $0 --essential     # Install essential development environment"
                echo "  $0 --editors       # Install all editors only"
                echo "  $0 --terminals     # Install all terminals only"
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
        "editors")
            install_editors_only
            ;;
        "terminals")
            install_terminals_only
            ;;
        "all"|*)
            install_all_components
            ;;
    esac

    log_info "$CATEGORY_NAME installation completed!"
}

# Execute main function with all arguments
main "$@"

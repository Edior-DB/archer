#!/bin/bash

# Archer Linux Enhancement Suite - Main Installation Script
# Comprehensive system enhancement and software installation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common/install-functions.sh" 2>/dev/null || {
    echo "Warning: install-functions.sh not found, using basic functions"
    basic_install() { sudo pacman -S --needed "$@"; }
    aur_install() { yay -S --needed "$@"; }
}

MODULE_NAME="Archer Linux Enhancement Suite"
MODULE_DESC="Comprehensive system enhancement and software installation"

# Available modules
MODULES=(
    "development"
    "system"
    "desktop"
    "multimedia"
    "network"
    "security"
    "extras"
    "terminal"
)

# Essential components from each module
ESSENTIAL_MODULES=(
    "development"
    "system"
    "desktop"
    "terminal"
)

# Function to install module
install_module() {
    local module="$1"
    local mode="${2:-essential}"

    if [[ -f "$SCRIPT_DIR/$module/install.sh" ]]; then
        echo "Installing $module module ($mode mode)..."
        case "$mode" in
            "essential")
                bash "$SCRIPT_DIR/$module/install.sh" --essential
                ;;
            "all")
                bash "$SCRIPT_DIR/$module/install.sh" --all
                ;;
            *)
                bash "$SCRIPT_DIR/$module/install.sh" "$mode"
                ;;
        esac
    else
        echo "Warning: $module module not found or not implemented yet"
    fi
}

# Function to show help
show_help() {
    cat << EOF
$MODULE_NAME

USAGE:
    $0 [OPTIONS] [MODULES...]

OPTIONS:
    -h, --help          Show this help message
    -e, --essential     Install essential components from all modules
    -a, --all          Install all components from all modules
    -l, --list         List available modules
    -s, --scripts      List all available scripts
    -d, --dry-run      Show what would be installed

MODULES:
    development        Programming languages, IDEs, and dev tools
    system            Hardware drivers and system utilities
    desktop           Themes, fonts, and desktop customization
    multimedia        Media players, content creation, and gaming
    network           WiFi, network tools, and connectivity
    security          Firewall, encryption, and privacy tools
    extras            Browsers, communication, and extra apps
    terminal          Terminal emulators and shell tools

EXAMPLES:
    $0 --essential                    # Install essential components
    $0 --all                         # Install everything (long process)
    $0 development system            # Install specific modules (essential)
    $0 development:all system:all    # Install specific modules (all components)

NOTES:
    - Use 'module:all' to install all components of a specific module
    - Use 'module:essential' or just 'module' for essential components only
    - The --essential mode is recommended for most users
    - The --all mode will install a very large number of packages

EOF
}

# Function to list modules
list_modules() {
    echo "Available modules:"
    for module in "${MODULES[@]}"; do
        if [[ -f "$SCRIPT_DIR/$module/install.sh" ]]; then
            echo "  ✅ $module"
        else
            echo "  ❌ $module (not implemented)"
        fi
    done
}

# Main installation logic
main() {
    echo "=== $MODULE_NAME ==="
    echo "$MODULE_DESC"
    echo

    case "${1:-}" in
        -h|--help)
            show_help
            exit 0
            ;;
        -l|--list)
            list_modules
            exit 0
            ;;
        -s|--scripts)
            echo "Available scripts:"
            find "$SCRIPT_DIR" -name "*.sh" -type f | sort
            exit 0
            ;;
        -d|--dry-run)
            echo "Dry run mode - showing what would be installed:"
            shift
            ;;
        -e|--essential)
            echo "Installing essential components from all modules..."
            for module in "${ESSENTIAL_MODULES[@]}"; do
                install_module "$module" "essential"
            done
            ;;
        -a|--all)
            echo "⚠️  WARNING: This will install ALL components from ALL modules!"
            echo "This may take several hours and use significant disk space."
            echo -n "Continue? (y/N): "
            read -r response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                echo "Installing all components from all modules..."
                for module in "${MODULES[@]}"; do
                    install_module "$module" "all"
                done
            else
                echo "Installation cancelled."
                exit 0
            fi
            ;;
        "")
            show_help
            exit 0
            ;;
        *)
            echo "Installing specified modules..."
            for arg in "$@"; do
                if [[ "$arg" == *":"* ]]; then
                    module="${arg%:*}"
                    mode="${arg#*:}"
                    install_module "$module" "$mode"
                else
                    install_module "$arg" "essential"
                fi
            done
            ;;
    esac

    echo
    echo "✅ Archer Linux Enhancement Suite installation completed!"
    echo
    echo "Summary:"
    echo "- Check individual module logs for detailed information"
    echo "- Some applications may require logout/restart to work properly"
    echo "- Desktop themes and customizations may require session restart"
    echo "- Development tools may need shell restart to update PATH"
    echo
    echo "Enjoy your enhanced Arch Linux system! 🎉"
}

main "$@"

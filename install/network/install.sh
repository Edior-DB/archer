#!/bin/bash

# Network Configuration & Tools Module
# Part of the Archer Linux Enhancement Suite

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../common/install-functions.sh" 2>/dev/null || {
    echo "Warning: install-functions.sh not found, using basic functions"
    basic_install() { sudo pacman -S --needed "$@"; }
    aur_install() { yay -S --needed "$@"; }
}

MODULE_NAME="Network Configuration & Tools"
MODULE_DESC="WiFi setup, network tools, and connectivity"

# Default packages for different modes
ESSENTIAL_ITEMS=(
    "wifi-setup"
    "basic-tools"
)

ALL_ITEMS=(
    "wifi-setup"
    "wifi-drivers"
    "network-monitoring"
    "network-diagnostics"
    "ssh-tools"
    "vpn-clients"
    "firewall-setup"
    "samba-sharing"
    "network-utilities"
)

# Function to install specific component
install_component() {
    case "$1" in
        "wifi-setup")
            echo "Setting up WiFi configuration..."
            [[ -f "$SCRIPT_DIR/wifi/wifi-setup.sh" ]] && bash "$SCRIPT_DIR/wifi/wifi-setup.sh"
            ;;
        "wifi-drivers")
            echo "Installing WiFi drivers..."
            [[ -f "$SCRIPT_DIR/wifi/wifi-install.sh" ]] && bash "$SCRIPT_DIR/wifi/wifi-install.sh"
            ;;
        "network-monitoring")
            echo "Installing network monitoring tools..."
            [[ -f "$SCRIPT_DIR/tools/network-monitoring.sh" ]] && bash "$SCRIPT_DIR/tools/network-monitoring.sh"
            ;;
        "network-diagnostics")
            echo "Installing network diagnostic tools..."
            [[ -f "$SCRIPT_DIR/tools/network-diagnostics.sh" ]] && bash "$SCRIPT_DIR/tools/network-diagnostics.sh"
            ;;
        "ssh-tools")
            echo "Installing SSH tools..."
            [[ -f "$SCRIPT_DIR/tools/ssh-tools.sh" ]] && bash "$SCRIPT_DIR/tools/ssh-tools.sh"
            ;;
        "vpn-clients")
            echo "Installing VPN clients..."
            [[ -f "$SCRIPT_DIR/security/vpn-clients.sh" ]] && bash "$SCRIPT_DIR/security/vpn-clients.sh"
            ;;
        "firewall-setup")
            echo "Setting up firewall..."
            [[ -f "$SCRIPT_DIR/security/firewall-setup.sh" ]] && bash "$SCRIPT_DIR/security/firewall-setup.sh"
            ;;
        "samba-sharing")
            echo "Setting up Samba file sharing..."
            [[ -f "$SCRIPT_DIR/sharing/samba.sh" ]] && bash "$SCRIPT_DIR/sharing/samba.sh"
            ;;
        "basic-tools")
            echo "Installing basic network tools..."
            [[ -f "$SCRIPT_DIR/tools/basic-tools.sh" ]] && bash "$SCRIPT_DIR/tools/basic-tools.sh"
            ;;
        "network-utilities")
            echo "Installing network utilities..."
            [[ -f "$SCRIPT_DIR/tools/network-utilities.sh" ]] && bash "$SCRIPT_DIR/tools/network-utilities.sh"
            ;;
        *)
            echo "Unknown component: $1"
            return 1
            ;;
    esac
}

# Function to show help
show_help() {
    cat << EOF
$MODULE_NAME

USAGE:
    $0 [OPTIONS] [COMPONENTS...]

OPTIONS:
    -h, --help          Show this help message
    -e, --essential     Install essential network tools only
    -a, --all          Install all network components
    -c, --custom       Interactive selection mode
    -s, --scripts      List available component scripts
    -d, --dry-run      Show what would be installed

COMPONENTS:
    wifi-setup         WiFi configuration and setup
    wifi-drivers       WiFi drivers and firmware
    network-monitoring Network monitoring tools (iftop, nethogs, etc.)
    network-diagnostics Network diagnostic tools (nmap, tcpdump, etc.)
    ssh-tools          SSH client/server and related tools
    vpn-clients        VPN clients (OpenVPN, WireGuard, etc.)
    firewall-setup     Firewall configuration (ufw/iptables)
    samba-sharing      Samba file sharing setup
    basic-tools        Basic network utilities
    network-utilities  Advanced network utilities

EXAMPLES:
    $0 --essential                  # Install essential network tools
    $0 --all                       # Install all network components
    $0 wifi-setup ssh-tools        # Install specific components
    $0 --custom                    # Interactive selection

EOF
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
        -s|--scripts)
            echo "Available component scripts:"
            find "$SCRIPT_DIR" -name "*.sh" -type f | sort
            exit 0
            ;;
        -d|--dry-run)
            echo "Dry run mode - showing what would be installed:"
            shift
            ;;
        -e|--essential)
            echo "Installing essential network components..."
            for item in "${ESSENTIAL_ITEMS[@]}"; do
                install_component "$item"
            done
            ;;
        -a|--all)
            echo "Installing all network components..."
            for item in "${ALL_ITEMS[@]}"; do
                install_component "$item"
            done
            ;;
        -c|--custom)
            echo "Interactive selection mode not yet implemented"
            echo "Use: $0 [component1] [component2] ..."
            exit 1
            ;;
        "")
            show_help
            exit 0
            ;;
        *)
            echo "Installing specified components..."
            for component in "$@"; do
                install_component "$component"
            done
            ;;
    esac

    echo
    echo "✅ Network module installation completed!"
    echo
    echo "Note: Some components may require system restart or network service restart"
    echo "WiFi setup requires hardware-specific configuration"
}

main "$@"

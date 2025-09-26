#!/bin/bash

# Security & Privacy Tools Module
# Part of the Archer Linux Enhancement Suite

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../common/install-functions.sh" 2>/dev/null || {
    echo "Warning: install-functions.sh not found, using basic functions"
    basic_install() { sudo pacman -S --needed "$@"; }
    aur_install() { yay -S --needed "$@"; }
}

MODULE_NAME="Security & Privacy Tools"
MODULE_DESC="System security, privacy tools, and encryption"

# Default packages for different modes
ESSENTIAL_ITEMS=(
    "firewall"
    "password-manager"
    "gpg-setup"
    "backup-tools"
)

ALL_ITEMS=(
    "firewall"
    "antivirus"
    "system-hardening"
    "password-manager"
    "gpg-setup"
    "disk-encryption"
    "tor-setup"
    "vpn-tools"
    "privacy-tools"
    "security-audit"
    "penetration-testing"
    "backup-tools"
)

# Function to install specific component
install_component() {
    case "$1" in
        "firewall")
            echo "Setting up firewall..."
            [[ -f "$SCRIPT_DIR/system/firewall.sh" ]] && bash "$SCRIPT_DIR/system/firewall.sh"
            ;;
        "antivirus")
            echo "Installing antivirus tools..."
            [[ -f "$SCRIPT_DIR/system/antivirus.sh" ]] && bash "$SCRIPT_DIR/system/antivirus.sh"
            ;;
        "system-hardening")
            echo "Applying system hardening..."
            [[ -f "$SCRIPT_DIR/system/hardening.sh" ]] && bash "$SCRIPT_DIR/system/hardening.sh"
            ;;
        "password-manager")
            echo "Installing password managers..."
            [[ -f "$SCRIPT_DIR/encryption/password-manager.sh" ]] && bash "$SCRIPT_DIR/encryption/password-manager.sh"
            ;;
        "gpg-setup")
            echo "Setting up GPG..."
            [[ -f "$SCRIPT_DIR/encryption/gpg-setup.sh" ]] && bash "$SCRIPT_DIR/encryption/gpg-setup.sh"
            ;;
        "disk-encryption")
            echo "Setting up disk encryption tools..."
            [[ -f "$SCRIPT_DIR/encryption/disk-encryption.sh" ]] && bash "$SCRIPT_DIR/encryption/disk-encryption.sh"
            ;;
        "tor-setup")
            echo "Installing Tor and Tor Browser..."
            [[ -f "$SCRIPT_DIR/privacy/tor-setup.sh" ]] && bash "$SCRIPT_DIR/privacy/tor-setup.sh"
            ;;
        "vpn-tools")
            echo "Installing VPN tools..."
            [[ -f "$SCRIPT_DIR/privacy/vpn-tools.sh" ]] && bash "$SCRIPT_DIR/privacy/vpn-tools.sh"
            ;;
        "privacy-tools")
            echo "Installing privacy tools..."
            [[ -f "$SCRIPT_DIR/privacy/privacy-tools.sh" ]] && bash "$SCRIPT_DIR/privacy/privacy-tools.sh"
            ;;
        "security-audit")
            echo "Installing security audit tools..."
            [[ -f "$SCRIPT_DIR/analysis/security-audit.sh" ]] && bash "$SCRIPT_DIR/analysis/security-audit.sh"
            ;;
        "penetration-testing")
            echo "Installing penetration testing tools..."
            [[ -f "$SCRIPT_DIR/analysis/penetration-testing.sh" ]] && bash "$SCRIPT_DIR/analysis/penetration-testing.sh"
            ;;
        "backup-tools")
            echo "Installing backup tools..."
            [[ -f "$SCRIPT_DIR/system/backup-tools.sh" ]] && bash "$SCRIPT_DIR/system/backup-tools.sh"
            ;;
        *)
            echo "Unknown component: $1"
            return 1
            ;;
    esac
}

install_all_scripts() {
    log_info "Installing all scripts in the security directory..."
    for script in $(find "$SCRIPT_DIR" -name "install.sh" -type f); do
        bash "$script" --all
    done
}

install_custom_selection() {
    log_info "Installing selected scripts in the security directory..."
    for script in "$@"; do
        if [[ -f "$script" ]]; then
            bash "$script"
        else
            log_warning "Script not found: $script"
        fi
    done
}

# Function to show help
show_help() {
    cat << EOF
$MODULE_NAME

USAGE:
    $0 [OPTIONS] [COMPONENTS...]

OPTIONS:
    -h, --help          Show this help message
    -e, --essential     Install essential security tools only
    -a, --all          Install all security components
    -c, --custom       Interactive selection mode
    -s, --scripts      List available component scripts
    -d, --dry-run      Show what would be installed

COMPONENTS:
    firewall           Firewall setup and configuration
    antivirus          Antivirus and malware protection
    system-hardening   System security hardening
    password-manager   Password managers (Bitwarden, KeePass, etc.)
    gpg-setup          GPG encryption setup
    disk-encryption    Disk encryption tools (LUKS, VeraCrypt)
    tor-setup          Tor browser and network tools
    vpn-tools          VPN clients and tools
    privacy-tools      Privacy and anonymity tools
    security-audit     Security auditing tools
    penetration-testing Penetration testing tools
    backup-tools       Backup and recovery tools

EXAMPLES:
    $0 --essential                     # Install essential security tools
    $0 --all                          # Install all security components
    $0 firewall password-manager       # Install specific components
    $0 --custom                       # Interactive selection

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
            echo "Installing essential security components..."
            for item in "${ESSENTIAL_ITEMS[@]}"; do
                install_component "$item"
            done
            ;;
        -a|--all)
            echo "Installing all security components..."
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
    echo "✅ Security module installation completed!"
    echo
    echo "IMPORTANT SECURITY NOTES:"
    echo "- Review firewall rules and ensure they meet your needs"
    echo "- Configure password managers with strong master passwords"
    echo "- Test backup solutions before relying on them"
    echo "- Keep security tools updated regularly"
    echo "- Some tools may require additional configuration"
}

main "$@"

#!/bin/bash

# Common Functions Library for Archer Scripts
# Shared functions to eliminate code duplication across scripts
# Source this file in other scripts: source "$(dirname "${BASH_SOURCE[0]}")/../system/common-funcs.sh"

# Prevent multiple sourcing
if [[ "${ARCHER_COMMON_FUNCS_LOADED}" == "1" ]]; then
    return 0
fi
ARCHER_COMMON_FUNCS_LOADED=1

# ============================================================================
# COLOR DEFINITIONS
# ============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================================================
# USER INTERFACE FUNCTIONS (GUM-based)
# ============================================================================

# Confirm function using gum
confirm_action() {
    local message="$1"
    gum confirm "$message"
}

# Wait function using gum
wait_for_input() {
    local message="${1:-Press Enter to continue...}"
    gum input --placeholder "$message" --value "" > /dev/null
}

# Input function using gum
get_input() {
    local prompt="$1"
    local placeholder="${2:-}"
    gum input --prompt "$prompt " --placeholder "$placeholder"
}

# Enhanced selection function using gum
select_option() {
    local options=("$@")
    gum choose "${options[@]}"
}

# ============================================================================
# PACKAGE INSTALLATION WITH RETRY LOGIC
# ============================================================================

# Enhanced package installation function with retry logic
# Supports pacstrap, pacman, and AUR helpers (yay/paru)
# Usage: install_with_retries [pacstrap /mnt] package1 package2 ...
#        install_with_retries [yay|paru] package1 package2 ...
#        install_with_retries package1 package2 ...  (defaults to pacman)
install_with_retries() {
    local command_type=""
    local target_dir=""
    local packages=()
    local filtered_packages=()

    # Parse command type and arguments
    if [[ "$1" == "pacstrap" ]]; then
        command_type="pacstrap"
        target_dir="$2"
        shift 2  # Remove 'pacstrap' and target directory from arguments
        packages=("$@")
        # For pacstrap, we can't check if packages are already installed since target is /mnt
        filtered_packages=("${packages[@]}")
    elif [[ "$1" == "yay" || "$1" == "paru" ]]; then
        command_type="$1"
        shift  # Remove AUR helper from arguments
        packages=("$@")
        # Check if packages are already installed for AUR helpers
        for pkg in "${packages[@]}"; do
            if pacman -Q "$pkg" &>/dev/null; then
                echo -e "${GREEN}$pkg is already installed and up-to-date${NC}"
            else
                filtered_packages+=("$pkg")
            fi
        done
    else
        command_type="pacman"
        packages=("$@")
        # Check if packages are already installed for pacman
        for pkg in "${packages[@]}"; do
            if pacman -Q "$pkg" &>/dev/null; then
                echo -e "${GREEN}$pkg is already installed and up-to-date${NC}"
            else
                filtered_packages+=("$pkg")
            fi
        done
    fi

    # If all packages are already installed (except for pacstrap)
    if [[ ${#filtered_packages[@]} -eq 0 && "$command_type" != "pacstrap" ]]; then
        echo -e "${GREEN}All packages are already installed and up-to-date${NC}"
        return 0
    fi

    local retry_count=0
    local max_retries=3

    while [ $retry_count -lt $max_retries ]; do
        echo -e "${CYAN}Installing: ${filtered_packages[*]} - Attempt $((retry_count + 1)) of $max_retries...${NC}"

        local install_success=false
        case "$command_type" in
            "pacstrap")
                if pacstrap "$target_dir" "${filtered_packages[@]}" --noconfirm --needed; then
                    install_success=true
                fi
                ;;
            "yay"|"paru")
                if "$command_type" -S --noconfirm --needed "${filtered_packages[@]}"; then
                    install_success=true
                fi
                ;;
            "pacman")
                if sudo pacman -S --noconfirm --needed "${filtered_packages[@]}"; then
                    install_success=true
                fi
                ;;
        esac

        if [ "$install_success" = true ]; then
            echo -e "${GREEN}Packages installed successfully: ${filtered_packages[*]}${NC}"
            return 0
        fi

        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $max_retries ]; then
            echo -e "${YELLOW}Installation failed, retrying in 3 seconds...${NC}"
            sleep 3
            if [[ "$command_type" == "pacstrap" ]]; then
                pacman -Sy --noconfirm
            elif [[ "$command_type" == "pacman" ]]; then
                sudo pacman -Sy --noconfirm
            else
                # For AUR helpers, update package databases
                "$command_type" -Sy --noconfirm
            fi
        else
            echo -e "${RED}ERROR: Installation failed after $max_retries attempts!${NC}"
            echo -e "${RED}Please check your network connection.${NC}"
            if command -v gum >/dev/null 2>&1 && gum confirm "Would you like to try installing again?"; then
                retry_count=0
                echo -e "${CYAN}Retrying installation...${NC}"
                if [[ "$command_type" == "pacstrap" ]]; then
                    pacman -Sy --noconfirm
                elif [[ "$command_type" == "pacman" ]]; then
                    sudo pacman -Sy --noconfirm
                else
                    "$command_type" -Sy --noconfirm
                fi
            else
                echo -e "${RED}Installation cannot continue without these packages: ${filtered_packages[*]}${NC}"
                return 1  # Use return instead of exit in library functions
            fi
        fi
    done
}

# ============================================================================
# AUR HELPER MANAGEMENT
# ============================================================================

# Install AUR helper (yay) if not present
install_aur_helper() {
    if ! command -v yay &> /dev/null && ! command -v paru &> /dev/null; then
        echo -e "${YELLOW}Installing yay for AUR packages...${NC}"
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        cd /tmp/yay
        makepkg -si --noconfirm
        cd -
        rm -rf /tmp/yay
    fi
}

# Get available AUR helper
get_aur_helper() {
    if command -v paru &> /dev/null; then
        echo "paru"
    elif command -v yay &> /dev/null; then
        echo "yay"
    else
        echo ""
        return 1
    fi
}

# Check if AUR helper is available
check_aur_helper() {
    if ! command -v yay &> /dev/null && ! command -v paru &> /dev/null; then
        echo -e "${RED}AUR helper not found. Please install yay or paru first.${NC}"
        return 1
    fi
    return 0
}

# ============================================================================
# KDE/PLASMA DETECTION AND MANAGEMENT
# ============================================================================

# Check if KDE Plasma is installed
check_kde_installed() {
    if ! pacman -Q plasma-desktop &>/dev/null; then
        echo -e "${RED}KDE Plasma is not installed on this system.${NC}"
        echo -e "${YELLOW}Please re-run the main install.sh script to install KDE Plasma.${NC}"
        return 1
    fi

    # Check if kwriteconfig5 is available
    if ! command -v kwriteconfig5 &> /dev/null; then
        echo -e "${YELLOW}Installing KDE configuration tools...${NC}"
        sudo pacman -S --noconfirm --needed kconfig5

        # Check again after installation
        if ! command -v kwriteconfig5 &> /dev/null; then
            echo -e "${RED}kwriteconfig5 still not found after installing kconfig5${NC}"
            echo -e "${RED}This is required for KDE theme configuration${NC}"
            return 1
        fi
    fi
    return 0
}

# Reset KDE settings to default before applying new theme
reset_kde_settings() {
    echo -e "${BLUE}Resetting KDE settings to defaults...${NC}"

    # Remove existing theme configurations
    kwriteconfig5 --file kdeglobals --group KDE --key LookAndFeelPackage "org.kde.breeze.desktop"
    kwriteconfig5 --file plasmarc --group Theme --key name "default"
    kwriteconfig5 --file kdeglobals --group Icons --key Theme "breeze"
    kwriteconfig5 --file kdeglobals --group General --key cursorTheme "breeze_cursors"

    # Reset fonts to system defaults
    kwriteconfig5 --file kdeglobals --group General --key font ""
    kwriteconfig5 --file kdeglobals --group General --key menuFont ""
    kwriteconfig5 --file kdeglobals --group General --key toolBarFont ""
    kwriteconfig5 --file kdeglobals --group WM --key activeFont ""

    # Reset window decoration
    kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key library "org.kde.kwin.aurorae"
    kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key theme "__aurorae__svg__breeze"

    echo -e "${GREEN}KDE settings reset to defaults!${NC}"
}

# ============================================================================
# SYSTEM UPDATE FUNCTIONS
# ============================================================================

# System update
update_system() {
    echo -e "${BLUE}Updating system...${NC}"
    sudo pacman -Syu --noconfirm
}

# Refresh package databases
refresh_databases() {
    echo -e "${BLUE}Refreshing package databases...${NC}"
    sudo pacman -Sy --noconfirm
}

# ============================================================================
# PACKAGE INSTALLATION HELPERS
# ============================================================================

# Safe package installation with error handling
install_packages() {
    local packages=("$@")
    local failed_packages=()

    for package in "${packages[@]}"; do
        echo -e "${YELLOW}Installing $package...${NC}"
        if ! sudo pacman -S --noconfirm --needed "$package"; then
            failed_packages+=("$package")
            echo -e "${RED}Failed to install $package${NC}"
        fi
    done

    if [ ${#failed_packages[@]} -gt 0 ]; then
        echo -e "${YELLOW}Failed packages: ${failed_packages[*]}${NC}"
        return 1
    fi
    return 0
}

# Install AUR packages with error handling
install_aur_packages() {
    local aur_helper
    if ! aur_helper=$(get_aur_helper); then
        echo -e "${RED}No AUR helper found${NC}"
        return 1
    fi

    local packages=("$@")
    for package in "${packages[@]}"; do
        echo -e "${YELLOW}Installing $package from AUR...${NC}"
        $aur_helper -S --noconfirm --needed "$package" || echo -e "${YELLOW}Could not install $package, skipping...${NC}"
    done
}

# ============================================================================
# BANNER AND DISPLAY FUNCTIONS
# ============================================================================

# Standard script headers
show_banner() {
    local title="$1"
    echo -e "${BLUE}"
    echo "========================================================================="
    echo "                    $title"
    echo "========================================================================="
    echo -e "${NC}"
}

# Show completion message
show_completion() {
    local title="$1"
    local description="$2"
    echo -e "${GREEN}"
    echo "========================================================================="
    echo "                    $title"
    echo "========================================================================="
    echo ""
    echo -e "$description"
    echo ""
    echo -e "${NC}"
}

# ============================================================================
# SYSTEM DETECTION FUNCTIONS
# ============================================================================

# Check if running on Arch Linux
check_arch_system() {
    if [[ ! -f /etc/arch-release ]] && [[ ! -f /etc/os-release ]] && ! command -v pacman >/dev/null 2>&1; then
        echo -e "${RED}This script requires an Arch Linux system.${NC}"
        return 1
    fi
    return 0
}

# Check if user has sudo privileges
check_sudo_privileges() {
    if [[ $EUID -eq 0 ]]; then
        echo -e "${YELLOW}Warning: Running as root. Consider running as regular user with sudo privileges.${NC}"
        return 0
    fi

    # Check if user is in sudo group or wheel group
    if groups | grep -q '\(sudo\|wheel\)'; then
        return 0
    else
        echo -e "${RED}✗ User is not in sudo or wheel group${NC}"
        echo -e "${YELLOW}Please add your user to the wheel group:${NC}"
        echo -e "${CYAN}  su -c 'usermod -aG wheel \$USER'${NC}"
        echo -e "${CYAN}  Then logout and login again${NC}"
        return 1
    fi
}

# Check internet connection
check_internet() {
    echo -e "${BLUE}Checking internet connection...${NC}"
    if ! ping -c 1 8.8.8.8 &> /dev/null; then
        echo -e "${RED}No internet connection detected.${NC}"
        echo -e "${YELLOW}Please ensure you have an active internet connection.${NC}"
        return 1
    fi
    echo -e "${GREEN}Internet connection: OK${NC}"
    return 0
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Enable multilib repository (for 32-bit support, gaming, etc.)
enable_multilib() {
    echo -e "${BLUE}Enabling multilib repository...${NC}"

    if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
        echo -e "${YELLOW}Enabling multilib in pacman.conf...${NC}"
        sudo sed -i '/^#\[multilib\]/,/^#Include/ { s/^#//; }' /etc/pacman.conf
        sudo pacman -Sy
        echo -e "${GREEN}Multilib repository enabled${NC}"
    else
        echo -e "${GREEN}Multilib already enabled${NC}"
    fi
}

# Create desktop autostart entry
create_autostart_entry() {
    local name="$1"
    local exec_command="$2"
    local script_path="$3"

    mkdir -p "$HOME/.config/autostart"
    cat > "$HOME/.config/autostart/${name,,}-setup.desktop" << EOF
[Desktop Entry]
Type=Application
Name=$name Setup
Exec=/bin/bash -c 'sleep 10 && $exec_command && rm "$HOME/.config/autostart/${name,,}-setup.desktop"'
Hidden=false
NoDisplay=false
X-KDE-autostart-after=panel
EOF
}

# Log function for debugging
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    case "$level" in
        "INFO")
            echo -e "${BLUE}[INFO $timestamp]${NC} $message"
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN $timestamp]${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR $timestamp]${NC} $message"
            ;;
        *)
            echo -e "$timestamp $message"
            ;;
    esac
}

# Print success message
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Print warning message
print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Print error message
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Cleanup function to be called on script exit
cleanup() {
    # Clear any leftover input
    while read -r -t 0.1; do true; done 2>/dev/null || true

    # Reset terminal state
    stty sane 2>/dev/null || true
    reset 2>/dev/null || true
}

# Set up cleanup trap
trap cleanup EXIT

echo -e "${CYAN}Common functions library loaded${NC}"

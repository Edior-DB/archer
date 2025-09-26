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
# USER INTERFACE FUNCTIONS (Simple, no dependencies)
# ============================================================================

# Confirm function using simple read
confirm_action() {
    local message="$1"
    echo -n "$message (y/N): "
    read -r response
    case "$response" in
        [yY]|[yY][eE][sS]) return 0 ;;
        *) return 1 ;;
    esac
}

# Wait function using simple read
wait_for_input() {
    local message="${1:-Press Enter to continue...}"
    echo -n "$message"
    read -r
}

# Input function using simple read
get_input() {
    local prompt="$1"
    local placeholder="${2:-}"
    echo -n "$prompt [$placeholder]: "
    read -r input
    echo "${input:-$placeholder}"
}

# Enhanced selection function using simple select
select_option() {
    local options=("$@")
    local PS3="Please select an option: "

    select opt in "${options[@]}"; do
        if [[ -n "$opt" ]]; then
            echo "$opt"
            break
        else
            echo "Invalid selection. Please try again." >&2
        fi
    done
}

# ==========================================================================
# Non-interactive / TUI detection and helper for scripted confirmations
# ==========================================================================
# AUTO_CONFIRM is set when scripts are running in a TUI, CI, or without a tty.
# Scripts can call archer_confirm_or_default("Prompt?", "yes"|"no") which will
# either delegate to confirm_action (interactive) or return the default in
# non-interactive situations.

# If the environment already set AUTO_CONFIRM explicitly, keep it.
# Treat the environment as non-interactive (AUTO_CONFIRM=1) when:
# - user explicitly sets ARCHER_FORCE_AUTO_CONFIRM=1
# - ARCHER_TUI or ARCHER_NONINTERACTIVE or CI are set
# - stdin (fd 0) or stdout (fd 1) are not TTYs (covers TUI output panels)
if [ -z "${AUTO_CONFIRM:-}" ]; then
    if [ "${ARCHER_FORCE_AUTO_CONFIRM:-}" = "1" ] || [ -n "${ARCHER_TUI:-}" ] || [ -n "${ARCHER_NONINTERACTIVE:-}" ] || [ -n "${CI:-}" ] || ! [ -t 0 ] || ! [ -t 1 ]; then
        AUTO_CONFIRM=1
    else
        AUTO_CONFIRM=0
    fi
fi

archer_confirm_or_default() {
    # $1 = prompt string, $2 = default (yes|no) when AUTO_CONFIRM=1
    local prompt="$1"
    local default="${2:-yes}"
    if [ "${AUTO_CONFIRM}" = "1" ]; then
        if [ "${default}" = "yes" ]; then
            return 0
        else
            return 1
        fi
    fi
    # fall back to existing confirm_action
    confirm_action "$prompt"
}

# Provide a safe fallback for check_system_requirements for scripts that call it.
# If a more strict/featureful implementation exists elsewhere (e.g. bin/archer-toml.sh),
# this will not override it.
if ! declare -F check_system_requirements >/dev/null 2>&1; then
check_system_requirements() {
    echo -e "${BLUE}Checking system requirements...${NC}"

    # If not on Arch Linux, warn but don't abort — many installers can still work.
    if [[ ! -f /etc/arch-release ]] && ! command -v pacman >/dev/null 2>&1; then
        echo -e "${YELLOW}Warning: This script is designed for Arch Linux. Some steps may fail on other distros.${NC}"
    fi

    # Ensure gum is available for UI; try to install it non-fatally if possible.
    if ! command -v gum >/dev/null 2>&1; then
        echo -e "${YELLOW}gum utility not found. Some UIs may be limited.${NC}"
        if command -v pacman >/dev/null 2>&1; then
            echo -e "${YELLOW}Attempting to install gum via pacman...${NC}"
            install_with_retries gum || echo -e "${YELLOW}Couldn't install gum automatically; please install it manually.${NC}"
        fi
    fi

    # Basic checks passed (non-fatal)
    echo -e "${GREEN}System requirements check completed (warnings may apply).${NC}"
    return 0
}
fi

# ============================================================================
# TOML MENU SYSTEM FUNCTIONS
# ============================================================================

# Check if Python3 and TOML module are available
check_toml_requirements() {
    # Check for Python 3.11+ with built-in tomllib support
    if ! python3 -c "import tomllib" >/dev/null 2>&1; then
        log_error "Python3 with tomllib is required for TOML menu support"
        log_info "This requires Python 3.11+ which should be available in current Arch Linux"
        log_info "If you're on an older system, install python311 via pacman:"
        log_info "  sudo pacman -S python3"
        log_info "Or update your system:"
        log_info "  sudo pacman -Syu"
        return 1
    fi

    # Check Python version to ensure 3.11+
    local python_version
    python_version=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
    local required_version="3.11"

    if [[ "$(printf '%s
' "$required_version" "$python_version" | sort -V | head -n1)" != "$required_version" ]]; then
        log_error "Python 3.11+ is required for built-in TOML support (found: $python_version)"
        log_info "Please update Python via pacman:"
        log_info "  sudo pacman -S python"
        return 1
    fi

    log_debug "TOML requirements satisfied (Python $python_version with built-in tomllib)"
    return 0
}

# Parse TOML menu configuration
parse_menu_toml() {
    local toml_file="$1"
    local script_dir="$(dirname "${BASH_SOURCE[0]}")"
    local temp_script="/tmp/archer_toml_$$"

    if [[ ! -f "$toml_file" ]]; then
        echo -e "${RED}TOML file not found: $toml_file${NC}"
        return 1
    fi

    # Ensure TOML requirements are met
    if ! check_toml_requirements; then
        return 1
    fi

    # Parse TOML using external Python script and source the output
    if python3 "$script_dir/parse_toml.py" "$toml_file" > "$temp_script" 2>/dev/null; then
        source "$temp_script"
        rm -f "$temp_script"
        return 0
    else
        rm -f "$temp_script"
        return 1
    fi
}



# Discover TOML menus in directory
discover_toml_menus() {
    local base_dir="$1"
    local menus=()

    if [[ ! -d "$base_dir" ]]; then
        return 1
    fi

    for dir in "$base_dir"/*; do
        if [[ -d "$dir" && -f "$dir/menu.toml" ]]; then
            menus+=("$(basename "$dir")")
        fi
    done

    printf '%s\n' "${menus[@]}"
}

# Execute installation commands directly (no gum dependency)
execute_command() {
    local title="$1"
    local command="$2"
    shift 2
    local args=("$@")

    echo -e "${BLUE}$title${NC}"

    if [[ "$ARCHER_VERBOSE" == "true" ]]; then
        echo -e "${CYAN}Command: $command ${args[*]}${NC}"
    fi

    eval "$command" "${args[@]}"
}

# Backward compatibility alias for execute_with_progress
execute_with_progress() {
    local command="$1"
    local title="$2"
    shift 2
    local args=("$@")

    echo -e "${BLUE}$title${NC}"

    if [[ "$ARCHER_VERBOSE" == "true" ]]; then
        echo -e "${CYAN}Command: $command ${args[*]}${NC}"
    fi

    eval "$command" "${args[@]}"
}

# Execute custom action from TOML
execute_custom_action() {
    local action_name="$1"
    local toml_file="$2"
    local menu_path="$3"

    # Parse the TOML file using external script
    local script_dir="$(dirname "${BASH_SOURCE[0]}")"
    local temp_script="/tmp/archer_quick_actions_$$"

    if ! python3 "$script_dir/parse_toml.py" "$toml_file" > "$temp_script" 2>/dev/null; then
        echo -e "${RED}Failed to parse TOML file for quick actions${NC}"
        rm -f "$temp_script"
        wait_for_input
        return 1
    fi

    # Source the parsed variables
    source "$temp_script"
    rm -f "$temp_script"

    # Check if quick actions are available
    if [[ "$QUICK_ACTIONS_AVAILABLE" != "true" ]]; then
        echo -e "${RED}No quick actions available in this menu${NC}"
        wait_for_input
        return 1
    fi

    # Find the action by name
    local action_found=false
    local action_command=""
    for ((i=0; i<QUICK_ACTIONS_COUNT; i++)); do
        local var_name="QUICK_ACTION_$i"
        local action_data="${!var_name}"
        if [[ -n "$action_data" ]]; then
            local name="${action_data%%|*}"
            local rest="${action_data#*|}"
            local description="${rest%%|*}"
            local command="${rest#*|}"

            if [[ "$name" == "$action_name" ]]; then
                action_found=true
                action_command="$command"
                break
            fi
        fi
    done

    if [[ "$action_found" != "true" ]]; then
        echo -e "${RED}Custom action '$action_name' not found${NC}"
        wait_for_input
        return 1
    fi

    echo -e "${BLUE}Executing custom action: $action_name${NC}"
    echo -e "${CYAN}Command: $action_command${NC}"

    # Execute the command
    if [[ "$ARCHER_VERBOSE" == "true" ]]; then
        echo -e "${CYAN}Running: $action_command${NC}"
    fi

    if eval "$action_command"; then
        echo -e "${GREEN}✓ Custom action completed successfully${NC}"
    else
        echo -e "${RED}✗ Custom action failed${NC}"
    fi

    wait_for_input "Press Enter to return to menu..."
}

# Navigate to TOML-based menu
navigate_to_toml_menu() {
    local menu_path="$1"
    local menu_file="$menu_path/menu.toml"

    if [[ -f "$menu_file" ]]; then
        show_toml_menu "$menu_file" "$menu_path"
    else
        echo -e "${RED}Menu not found: $menu_path${NC}"
        wait_for_input "Press Enter to return to previous menu..."
        return 1
    fi
}

# Display and handle TOML-based menu
show_toml_menu() {
    local toml_file="$1"
    local menu_path="$2"

    # Parse TOML configuration
    if ! parse_menu_toml "$toml_file"; then
        echo -e "${RED}Failed to parse menu configuration${NC}"
        wait_for_input
        return 1
    fi

    while true; do
        clear
        show_menu_breadcrumb "$menu_path"

        echo -e "${BLUE}${MENU_ICON} ${MENU_NAME}${NC}"
        echo -e "${CYAN}${MENU_DESCRIPTION}${NC}"
        echo ""

        # Build options array from parsed TOML
        local menu_options=()
        local option_actions=()
        local option_targets=()
        local option_keys=()

        # Extract options from environment variables set by parse_menu_toml
        for var in $(compgen -v OPTION_); do
            local key="${var#OPTION_}"
            local value="${!var}"
            IFS='|' read -r display action target <<< "$value"
            menu_options+=("$display")
            option_actions+=("$action")
            option_targets+=("$target")
            option_keys+=("$key")
        done

        # Add standard navigation options
        menu_options+=("🔙 Back to Previous Menu")
        option_actions+=("back")
        option_targets+=("")
        option_keys+=("back")

        menu_options+=("🚪 Exit Archer")
        option_actions+=("exit")
        option_targets+=("")
        option_keys+=("exit")

        if [[ ${#menu_options[@]} -eq 0 ]]; then
            echo -e "${RED}No menu options found${NC}"
            wait_for_input
            return 1
        fi

        # Use select_option() from common-funcs.sh (simple selection)
        local selection=$(select_option "${menu_options[@]}")
        local choice_index=-1

        # Find selected option index
        for i in "${!menu_options[@]}"; do
            if [[ "${menu_options[$i]}" == "$selection" ]]; then
                choice_index=$i
                break
            fi
        done

        if [[ $choice_index -eq -1 ]]; then
            continue
        fi

        # Handle selection based on action type
        local action="${option_actions[$choice_index]}"
        local target="${option_targets[$choice_index]}"
        local key="${option_keys[$choice_index]}"

        case "$action" in
            "submenu")
                # Remove leading ./ if present and navigate to submenu
                local submenu_path="${target#./}"
                if [[ "$submenu_path" == /* ]]; then
                    navigate_to_toml_menu "$submenu_path"
                else
                    navigate_to_toml_menu "$menu_path/$submenu_path"
                fi
                ;;
            "script")
                # Remove leading ./ if present and execute script
                local script_path="${target#./}"
                if [[ "$script_path" == /* ]]; then
                    execute_installer "$script_path" "$menu_path"
                else
                    execute_installer "$menu_path/$script_path" "$menu_path"
                fi
                ;;
            "multiselect")
                echo -e "${YELLOW}Multiselect functionality not yet implemented${NC}"
                wait_for_input "Press Enter to continue..."
                ;;
            "install")
                if confirm_action "Proceed with installation of $target?"; then
                    execute_installer "$menu_path/$target" "$menu_path"
                fi
                ;;
            "custom")
                if confirm_action "Execute custom action: $target?"; then
                    execute_custom_action "$target" "$toml_file" "$menu_path"
                fi
                ;;
            "back")
                return 0
                ;;
            "exit")
                if confirm_action "Exit Archer?"; then
                    exit 0
                fi
                ;;
            *)
                echo -e "${RED}Unknown action: $action${NC}"
                wait_for_input
                ;;
        esac
    done
}

# Execute installation script and return to menu
execute_installer() {
    local script_path="$1"
    local menu_path="$2"

    if [[ -f "$script_path" ]]; then
        local script_name=$(basename "$script_path")

        if execute_with_progress "Installing $script_name..." bash "$script_path"; then
            echo -e "${GREEN}✓ Installation completed successfully${NC}"
        else
            echo -e "${RED}✗ Installation failed${NC}"
            if confirm_action "Would you like to retry this installation?"; then
                execute_installer "$script_path" "$menu_path"
                return
            fi
        fi

        wait_for_input "Press Enter to return to menu..."
    else
        echo -e "${RED}Script not found: $script_path${NC}"
        wait_for_input
    fi
}

# Show breadcrumb navigation
show_menu_breadcrumb() {
    local current_path="$1"
    local relative_path="${current_path#${ARCHER_DIR}/install/}"

    if [[ "$relative_path" != "." && -n "$relative_path" ]]; then
        echo -e "${CYAN}📍 Location: ${relative_path//\// → }${NC}"
        echo ""
    fi
}

# Build main TOML menu
build_main_toml_menu() {
    local install_dir="${ARCHER_DIR}/install"
    local menus
    menus=($(discover_toml_menus "$install_dir"))
    local menu_options=()

    for menu in "${menus[@]}"; do
        # Parse TOML to get metadata
        if parse_menu_toml "$install_dir/$menu/menu.toml"; then
            menu_options+=("${MENU_ICON} ${MENU_NAME}")
        else
            menu_options+=("📁 $menu")
        fi
    done

    # Add exit option
    menu_options+=("🚪 Exit Archer")

    # Use select_option() from common-funcs.sh (simple selection)
    echo -e "${BLUE}Archer - System Management & Customization${NC}"
    echo -e "${CYAN}Select a category to configure:${NC}"
    echo ""

    local selection=$(select_option "${menu_options[@]}")

    if [[ "$selection" == "🚪 Exit Archer" ]]; then
        return 1
    fi

    # Find corresponding menu and navigate
    local menu_index=0
    for i in "${!menu_options[@]}"; do
        if [[ "${menu_options[$i]}" == "$selection" ]]; then
            menu_index=$i
            break
        fi
    done

    if [[ $menu_index -lt ${#menus[@]} ]]; then
        local selected_menu="${menus[$menu_index]}"
        navigate_to_toml_menu "${install_dir}/${selected_menu}"
    fi
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

# Convenience logging functions
log_info() {
    log_message "INFO" "$1"
}

log_warn() {
    log_message "WARN" "$1"
}

log_warning() {
    log_message "WARN" "$1"
}

log_error() {
    log_message "ERROR" "$1"
}

log_debug() {
    if [[ "${ARCHER_DEBUG:-false}" == "true" ]]; then
        echo -e "${PURPLE}[DEBUG $(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
    fi
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

# =============================================================================
# MISE (VERSION MANAGER) FUNCTIONS
# =============================================================================

# Setup and activate Mise for the current session
setup_mise() {
    log_info "Setting up Mise for current session..."

    # Check if Mise is installed
    if ! command -v mise &> /dev/null; then
        log_info "Mise not found. Installing Mise first..."
        if ! install_with_retries mise; then
            log_info "Installing Mise via curl..."
            curl https://mise.run | sh

            # Add to bashrc if not already present
            if [[ -f ~/.bashrc ]] && ! grep -q 'mise activate' ~/.bashrc; then
                echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc
                log_info "Added Mise activation to ~/.bashrc"
            fi
        fi
    fi

    # Ensure mise is in PATH
    if [[ -f ~/.local/bin/mise ]] && ! command -v mise &> /dev/null; then
        export PATH="$HOME/.local/bin:$PATH"
    fi

    # Activate mise for current session
    if command -v mise &> /dev/null; then
        eval "$(mise activate bash)" 2>/dev/null || true
        log_info "Mise activated for current session"
        return 0
    else
        log_warning "Failed to setup Mise"
        return 1
    fi
}

# Install and set global tool via Mise
install_mise_tool() {
    local tool="$1"
    local version="${2:-latest}"

    if [[ -z "$tool" ]]; then
        log_error "Tool name is required for install_mise_tool"
        return 1
    fi

    log_info "Installing $tool@$version via Mise..."

    # Ensure Mise is set up
    setup_mise || return 1

    # Install the tool
    if mise install "$tool@$version"; then
        log_info "Setting $tool@$version as global default..."
        mise use -g "$tool@$version"

        # Refresh mise activation to make tool immediately available
        eval "$(mise activate bash)" 2>/dev/null || true

        # Add current session path
        if [[ -d "$HOME/.local/share/mise/installs/$tool" ]]; then
            export PATH="$HOME/.local/share/mise/installs/$tool/latest/bin:$PATH"
        fi

        return 0
    else
        log_error "Failed to install $tool via Mise"
        return 1
    fi
}

# Verify tool is available after Mise installation
verify_mise_tool() {
    local tool="$1"
    local command_name="${2:-$tool}"

    if [[ -z "$tool" ]]; then
        log_error "Tool name is required for verify_mise_tool"
        return 1
    fi

    # Refresh mise activation
    eval "$(mise activate bash)" 2>/dev/null || true

    # Check if command is available
    if command -v "$command_name" &>/dev/null; then
        local version=$($command_name --version 2>/dev/null | head -1 || echo "Available")
        echo -e "${GREEN}✓ $tool installed and available: $version${NC}"
        return 0
    else
        log_warning "$tool installed via Mise but not immediately available"
        log_info "Run 'source ~/.bashrc' or start a new terminal session to use $tool"
        return 1
    fi
}

# =============================================================================
# CLEANUP AND INITIALIZATION
# =============================================================================

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

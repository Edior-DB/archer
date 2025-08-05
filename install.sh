#!/bin/bash

# Archer - Arch Linux Home PC Transformation Suite
# Main installer script

set -e


# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Repository configuration
REPO_URL="https://github.com/Edior-DB/archer.git"
REPO_RAW_URL="https://raw.githubusercontent.com/Edior-DB/archer/master"
ARCHER_HOME="$HOME/.local/share/archer"

# Set installation directory based on environment
if grep -q "archiso" /proc/cmdline 2>/dev/null; then
    # Live ISO - use script directory
    INSTALL_DIR="$SCRIPT_DIR/install"
else
    # Installed system - use cloned repository
    INSTALL_DIR="$ARCHER_HOME/install"
fi

# Logo
show_logo() {
    echo -e "${BLUE}"
    cat << "EOF"
 █████╗ ██████╗  ██████╗██╗  ██╗███████╗██████╗
██╔══██╗██╔══██╗██╔════╝██║  ██║██╔════╝██╔══██╗
███████║██████╔╝██║     ███████║█████╗  ██████╔╝
██╔══██║██╔══██╗██║     ██╔══██║██╔══╝  ██╔══██╗
██║  ██║██║  ██║╚██████╗██║  ██║███████╗██║  ██║
╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝

    Arch Linux Home PC Transformation Suite
EOF
    echo -e "${NC}"
}

# Note: This script can be run as root (required for Live ISO installation)
# or as regular user (for post-installation setup)

# Check if Arch Linux or Live ISO
check_arch() {
    # Skip check if in test mode
    if [[ "$TEST_MODE" == "true" ]]; then
        echo -e "${YELLOW}TEST MODE: Skipping Arch Linux detection${NC}"
        echo -e "${CYAN}Running on $(lsb_release -d 2>/dev/null | cut -f2 || echo "Unknown system")${NC}"
        return 0
    fi

    if [[ ! -f /etc/arch-release ]] && [[ ! -f /etc/hostname ]] || ! grep -q "archiso" /proc/cmdline 2>/dev/null && [[ ! -f /etc/arch-release ]]; then
        echo -e "${RED}This script is designed for Arch Linux only.${NC}"
        echo -e "${YELLOW}Run from Arch Linux Live ISO for fresh installation, or from installed Arch Linux system.${NC}"
        echo -e "${CYAN}For testing on other systems, use: $0 --test${NC}"
        exit 1
    fi
}

# Check internet connection
check_internet() {
    # Skip in test mode
    if [[ "$TEST_MODE" == "true" ]]; then
        echo -e "${CYAN}TEST MODE: Skipping internet check${NC}"
        return 0
    fi

    echo -e "${BLUE}Checking internet connection...${NC}"
    if ! ping -c 1 8.8.8.8 &> /dev/null; then
        echo -e "${RED}No internet connection detected.${NC}"
        echo -e "${YELLOW}Please ensure you have an active internet connection.${NC}"
        echo -e "${YELLOW}You can use the WiFi setup script: ./install/network/wifi-setup.sh${NC}"
        exit 1
    fi
    echo -e "${GREEN}Internet connection: OK${NC}"
}

# Update system (only if not in Live ISO)
update_system() {
    # Skip in test mode
    if [[ "$TEST_MODE" == "true" ]]; then
        echo -e "${CYAN}TEST MODE: Skipping system update${NC}"
        return 0
    fi

    # Check if we're running from Live ISO
    if grep -q "archiso" /proc/cmdline 2>/dev/null; then
        echo -e "${YELLOW}Running from Live ISO - skipping system update${NC}"
        echo -e "${CYAN}System update will be performed after installation${NC}"
        return 0
    fi

    # Only update if we're on an installed system
    if [[ -f /etc/arch-release ]] && [[ ! -f /run/archiso/bootmnt ]]; then
        echo -e "${BLUE}Updating system packages...${NC}"
        sudo pacman -Syu --noconfirm
    else
        echo -e "${YELLOW}System update skipped - not on installed Arch system${NC}"
    fi
}

# Install git if not present
ensure_git() {
    # Skip package installation in test mode
    if [[ "$TEST_MODE" == "true" ]]; then
        echo -e "${CYAN}TEST MODE: Skipping package installation${NC}"
        echo -e "${YELLOW}Would check and install: git, curl${NC}"
        return 0
    fi

    local packages_to_install=()

    if ! command -v git &> /dev/null; then
        packages_to_install+=("git")
    fi

    if ! command -v curl &> /dev/null; then
        packages_to_install+=("curl")
    fi

    if [[ ${#packages_to_install[@]} -gt 0 ]]; then
        echo -e "${YELLOW}Installing required packages: ${packages_to_install[*]}${NC}"

        # Use different approach for Live ISO vs installed system
        if grep -q "archiso" /proc/cmdline 2>/dev/null; then
            # Live ISO - install without confirmation and update sync
            pacman -Sy "${packages_to_install[@]}" --noconfirm
        else
            # Installed system - use sudo
            sudo pacman -S --noconfirm "${packages_to_install[@]}"
        fi
    fi
}

# Fetch script from GitHub for Live ISO
fetch_script_from_github() {
    local script_path="$1"
    local temp_file="/tmp/$(basename "$script_path")"

    echo -e "${CYAN}Fetching script from GitHub: $script_path${NC}"

    # Convert install/ path to raw GitHub URL
    local github_url="$REPO_RAW_URL/$script_path"

    if curl -fsSL "$github_url" -o "$temp_file"; then
        chmod +x "$temp_file"
        echo "$temp_file"
    else
        echo -e "${RED}Failed to fetch script from GitHub${NC}"
        return 1
    fi
}

# Setup repository for installed systems
setup_archer_repo() {
    echo -e "${BLUE}Setting up Archer repository...${NC}"

    # Always remove existing directory for clean clone
    if [[ -d "$ARCHER_HOME" ]]; then
        echo -e "${YELLOW}Removing existing repository for clean clone...${NC}"
        rm -rf "$ARCHER_HOME"
    fi

    # Create parent directory if it doesn't exist
    mkdir -p "$(dirname "$ARCHER_HOME")"

    # Clone repository
    echo -e "${CYAN}Cloning Archer repository to $ARCHER_HOME...${NC}"
    git clone "$REPO_URL" "$ARCHER_HOME" || {
        echo -e "${RED}Failed to clone repository!${NC}"
        echo -e "${YELLOW}Please check your internet connection and try again.${NC}"
        exit 1
    }

    # Set up environment variable in ~/.bashrc
    local bashrc="$HOME/.bashrc"
    if ! grep -q "ARCHER_HOME" "$bashrc" 2>/dev/null; then
        echo -e "${CYAN}Adding ARCHER_HOME to ~/.bashrc...${NC}"
        echo "" >> "$bashrc"
        echo "# Archer - Arch Linux Transformation Suite" >> "$bashrc"
        echo "export ARCHER_HOME=\"$ARCHER_HOME\"" >> "$bashrc"
        echo "export PATH=\"\$ARCHER_HOME/bin:\$PATH\"" >> "$bashrc"

        echo -e "${GREEN}✓ Environment variables added to ~/.bashrc${NC}"
        echo -e "${YELLOW}Note: Run 'source ~/.bashrc' or restart your shell to load the environment${NC}"
    else
        echo -e "${CYAN}ARCHER_HOME already configured in ~/.bashrc${NC}"
    fi

    # Make scripts executable
    find "$ARCHER_HOME" -name "*.sh" -type f -exec chmod +x {} \; 2>/dev/null || true

    echo -e "${GREEN}✓ Archer repository setup completed${NC}"
}

# System optimization functions (inspired by Chris Titus Tech's LinUtil)
# Source: https://github.com/ChrisTitusTech/linutil
setup_system_optimizations() {
    echo -e "${BLUE}Setting up system optimization utilities...${NC}"
    echo -e "${CYAN}Individual scripts adapted from Chris Titus Tech's LinUtil collection${NC}"
    echo -e "${CYAN}Original source: https://github.com/ChrisTitusTech/linutil${NC}"
    echo -e "${GREEN}System optimization tools ready!${NC}"
}

# Setup archer command in PATH
setup_archer_command() {
    echo -e "${BLUE}Setting up Archer post-installation tool...${NC}"

    # Use different paths based on environment
    local archer_script
    if grep -q "archiso" /proc/cmdline 2>/dev/null; then
        echo -e "${YELLOW}Skipping archer command setup on Live ISO${NC}"
        return 0
    else
        archer_script="$ARCHER_HOME/bin/archer.sh"
    fi

    local target_dir="/usr/local/bin"
    local target_file="$target_dir/archer"

    if [[ -f "$archer_script" ]]; then
        # Make archer.sh executable
        chmod +x "$archer_script"

        # Create symlink in /usr/local/bin
        if [[ ! -f "$target_file" ]]; then
            sudo ln -s "$archer_script" "$target_file" 2>/dev/null || {
                echo -e "${YELLOW}Creating local archer command...${NC}"
                # Create a wrapper script
                sudo tee "$target_file" > /dev/null << EOF
#!/bin/bash
exec "$archer_script" "\$@"
EOF
                sudo chmod +x "$target_file"
            }
        fi

        echo -e "${GREEN}✓ 'archer' command installed successfully${NC}"
        echo -e "${CYAN}Usage: archer [--gaming|--development|--multimedia]${NC}"
        echo -e "${CYAN}Or simply: archer (for interactive menu)${NC}"
    else
        echo -e "${YELLOW}Warning: archer.sh not found at $archer_script${NC}"
        echo -e "${YELLOW}Repository may not be properly set up${NC}"
    fi
}

# Show main menu
show_menu() {
    clear
    show_logo
    echo -e "${CYAN}===============================================${NC}"
    echo -e "${CYAN}        Arch Linux Fresh Installation        ${NC}"
    echo -e "${CYAN}===============================================${NC}"
    echo ""

    # Check if running as root on Live ISO
    if grep -q "archiso" /proc/cmdline 2>/dev/null && [[ "$EUID" -eq 0 ]]; then
        echo -e "${RED}Running as ROOT on Live ISO${NC}"
        echo -e "${YELLOW}Security restriction: Only base system installation allowed${NC}"
        echo ""
        echo -e "${GREEN}Available Options:${NC}"
        echo "  1) Fresh Arch Linux Installation (arch-server-setup.sh)"
        echo ""
        echo -e "${CYAN}After installation:${NC}"
        echo -e "${CYAN} • Reboot and login as your new user${NC}"
        echo -e "${CYAN} • Run this installer again for additional setup${NC}"
        echo ""
        echo " 0) Exit"
    else
        echo -e "${GREEN}Core Installation (Run from Live ISO):${NC}"
        echo "  1) Fresh Arch Linux Installation"
        echo "  2) Post-Installation Setup (Essential packages, AUR)"
        echo "  3) GPU Drivers Installation"
        echo "  4) Desktop Environment Installation"
        echo "  5) WiFi Setup (if needed)"
        echo ""
        echo -e "${YELLOW}Quick Installation Profiles:${NC}"
        echo "  6) Complete Base System (1+2+3+4+5)"
        echo "  7) Gaming Ready System (Base + Gaming optimizations)"
        echo "  8) Developer Workstation (Base + Dev tools)"
        echo ""
        echo -e "${CYAN}Post-Installation Management:${NC}"
        echo "  9) Launch Archer Post-Installation Tool"
        echo ""
        echo " 0) Exit"
    fi

    echo ""
    echo -e "${CYAN}===============================================${NC}"

    if grep -q "archiso" /proc/cmdline 2>/dev/null && [[ "$EUID" -eq 0 ]]; then
        echo -e "${YELLOW}Note: Additional features available after user login${NC}"
    else
        echo -e "${YELLOW}Note: After base installation, use 'archer' command${NC}"
        echo -e "${YELLOW}for additional software and customizations.${NC}"
    fi
}

# Execute script safely
run_script() {
    local script_path="$1"
    local script_name="$(basename "$script_path")"
    local actual_script_path="$script_path"

    # In test mode, just show what would be executed
    if [[ "$TEST_MODE" == "true" ]]; then
        echo -e "${CYAN}TEST MODE: Would execute $script_name${NC}"
        echo -e "${YELLOW}Script path: $script_path${NC}"
        echo -e "${YELLOW}In real execution, this would run the actual installation script${NC}"
        read -p "Press Enter to continue..."
        return 0
    fi

    # Security check: On Live ISO (root), only allow arch-server-setup.sh
    if grep -q "archiso" /proc/cmdline 2>/dev/null && [[ "$EUID" -eq 0 ]]; then
        if [[ "$script_name" != "arch-server-setup.sh" ]]; then
            echo -e "${RED}Security restriction: Running as root on Live ISO${NC}"
            echo -e "${YELLOW}Only 'arch-server-setup.sh' can be executed as root${NC}"
            echo -e "${CYAN}After base installation, login as your new user to continue${NC}"
            read -p "Press Enter to continue..."
            return 1
        fi

        # Fetch arch-server-setup.sh from GitHub for Live ISO
        echo -e "${CYAN}Fetching arch-server-setup.sh from GitHub...${NC}"
        local github_url="$REPO_RAW_URL/install/system/arch-server-setup.sh"
        local temp_file="/tmp/arch-server-setup.sh"

        if curl -fsSL "$github_url" -o "$temp_file"; then
            chmod +x "$temp_file"
            actual_script_path="$temp_file"
        else
            echo -e "${RED}Failed to fetch arch-server-setup.sh from GitHub${NC}"
            echo -e "${YELLOW}Please check your internet connection${NC}"
            read -p "Press Enter to continue..."
            return 1
        fi
    else
        # Installed system or non-root - use existing logic
        if grep -q "archiso" /proc/cmdline 2>/dev/null; then
            # Live ISO - fetch script from GitHub
            if [[ ! -f "$script_path" ]]; then
                # Convert full path to relative path from repository root
                local relative_path="${script_path#$SCRIPT_DIR/}"
                actual_script_path=$(fetch_script_from_github "$relative_path")

                if [[ $? -ne 0 ]] || [[ ! -f "$actual_script_path" ]]; then
                    echo -e "${RED}Failed to fetch script: $script_name${NC}"
                    echo -e "${YELLOW}This feature requires internet connection${NC}"
                    read -p "Press Enter to continue..."
                    return 1
                fi
            fi
        fi
    fi

    if [[ -f "$actual_script_path" ]]; then
        echo -e "${BLUE}Running $script_name...${NC}"
        chmod +x "$actual_script_path"

        # Special handling for arch-server-setup.sh completion
        if [[ "$script_name" == "arch-server-setup.sh" ]]; then
            set -x  # Enable tracing for arch-server-setup.sh
            "$actual_script_path"
            local exit_code=$?
            set +x  # Disable tracing after arch-server-setup.sh

            if [[ $exit_code -eq 0 ]]; then
                echo -e "${GREEN}$script_name completed successfully!${NC}"
                echo -e "${CYAN}=== IMPORTANT: Next Steps ===${NC}"
                echo -e "${YELLOW}1. Reboot your system: reboot${NC}"
                echo -e "${YELLOW}2. Login as your newly created user${NC}"
                echo -e "${YELLOW}3. Run this installer again as your user for additional setup${NC}"
                echo -e "${CYAN}================================${NC}"
            else
                echo -e "${RED}$script_name failed with exit code $exit_code${NC}"
            fi
        else
            "$actual_script_path"
            echo -e "${GREEN}$script_name completed successfully!${NC}"
        fi

        read -p "Press Enter to continue..."
    else
        echo -e "${RED}Script not found: $script_path${NC}"
        echo -e "${YELLOW}This feature is coming soon!${NC}"
        read -p "Press Enter to continue..."
    fi
}

# Profile installations for base system
install_base_profile() {
    local profile="$1"

    echo -e "${YELLOW}This will install the base system with $profile optimizations.${NC}"
    echo -e "${YELLOW}After reboot, use 'archer' command for additional software. Continue? (y/N)${NC}"
    read -r confirm

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        # Base installation steps
        run_script "$INSTALL_DIR/system/arch-server-setup.sh"
        echo -e "${YELLOW}System may need to reboot. Continue with post-install? (y/N)${NC}"
        read -r continue_install

        if [[ "$continue_install" =~ ^[Yy]$ ]]; then
            run_script "$INSTALL_DIR/system/post-install.sh"
            run_script "$INSTALL_DIR/system/gpu-drivers.sh"
            run_script "$INSTALL_DIR/desktop/de-installer.sh"
            setup_archer_command

            case "$profile" in
                "gaming")
                    echo -e "${GREEN}Base system installed for gaming!${NC}"
                    echo -e "${CYAN}Next steps after reboot:${NC}"
                    echo -e "${CYAN}  1. Run: archer --gaming${NC}"
                    echo -e "${CYAN}  2. Or: archer (interactive menu)${NC}"
                    ;;
                "developer")
                    echo -e "${GREEN}Base system installed for development!${NC}"
                    echo -e "${CYAN}Next steps after reboot:${NC}"
                    echo -e "${CYAN}  1. Run: archer --development${NC}"
                    echo -e "${CYAN}  2. Or: archer (interactive menu)${NC}"
                    ;;
            esac
        fi

        echo -e "${GREEN}Base installation completed!${NC}"
        echo -e "${YELLOW}Reboot recommended before continuing with 'archer' command${NC}"
    fi
}

# Launch archer post-installation tool
launch_archer() {
    # Use different paths based on environment
    local archer_script
    if grep -q "archiso" /proc/cmdline 2>/dev/null; then
        archer_script="$SCRIPT_DIR/bin/archer.sh"
    else
        archer_script="$ARCHER_HOME/bin/archer.sh"
    fi

    if [[ -f "$archer_script" ]]; then
        echo -e "${BLUE}Launching Archer post-installation tool...${NC}"
        chmod +x "$archer_script"
        exec "$archer_script" "$@"
    else
        echo -e "${RED}Archer post-installation tool not found!${NC}"
        echo -e "${YELLOW}Expected location: $archer_script${NC}"
    fi
}

# Handle command line arguments
handle_args() {
    case "$1" in
        "--test")
            export TEST_MODE="true"
            echo -e "${CYAN}TEST MODE ENABLED${NC}"
            echo -e "${YELLOW}Script will run in test mode - no actual system changes will be made${NC}"
            sleep 2
            return 0
            ;;
        "--install")
            run_script "$INSTALL_DIR/system/arch-server-setup.sh"
            exit 0
            ;;
        "--base")
            install_base_profile "base"
            exit 0
            ;;
        "--gaming")
            install_base_profile "gaming"
            exit 0
            ;;
        "--developer")
            install_base_profile "developer"
            exit 0
            ;;
        "--desktop")
            run_script "$INSTALL_DIR/desktop/de-installer.sh"
            exit 0
            ;;
        "--gpu")
            run_script "$INSTALL_DIR/system/gpu-drivers.sh"
            exit 0
            ;;
        "--wifi")
            run_script "$INSTALL_DIR/network/wifi-setup.sh"
            exit 0
            ;;
        "--archer")
            launch_archer "${@:2}"
            exit 0
            ;;
        "--help"|"-h")
            show_logo
            echo "Usage: $0 [option]"
            echo ""
            echo "Base Installation Options:"
            echo "  --install              Fresh Arch Linux installation (run from Live ISO)"
            echo "  --base                 Complete base system setup"
            echo "  --gaming               Gaming-ready base system"
            echo "  --developer            Developer-ready base system"
            echo "  --desktop              Desktop environment only"
            echo "  --gpu                  GPU drivers only"
            echo "  --wifi                 WiFi setup only"
            echo ""
            echo "Post-Installation:"
            echo "  --archer               Launch post-installation tool"
            echo ""
            echo "Testing:"
            echo "  --test                 Run in test mode (bypass Arch Linux checks)"
            echo "  --help, -h             Show this help"
            echo ""
            echo "Run without arguments for interactive mode."
            echo "After base installation, use 'archer' command for additional software."
            exit 0
            ;;
    esac
}

# Main execution
main() {
    # Handle command line arguments first
    if [[ $# -gt 0 ]]; then
        handle_args "$@"
    fi

    # Initial checks
    check_arch
    check_internet

    # Show environment info
    if grep -q "archiso" /proc/cmdline 2>/dev/null; then
        echo -e "${CYAN}Environment: Running from Live ISO${NC}"
        echo -e "${YELLOW}Ready for fresh Arch Linux installation${NC}"
    else
        echo -e "${CYAN}Environment: Running from installed Arch system${NC}"
        echo -e "${YELLOW}Ready for post-installation configuration${NC}"
    fi
    echo ""

    update_system
    ensure_git

    # Setup repository on installed systems
    if ! grep -q "archiso" /proc/cmdline 2>/dev/null; then
        setup_archer_repo
    fi

    # Interactive menu
    while true; do
        show_menu

        # Adjust prompt based on environment
        if grep -q "archiso" /proc/cmdline 2>/dev/null && [[ "$EUID" -eq 0 ]]; then
            read -p "Select an option [0-1]: " choice
        else
            read -p "Select an option [0-9]: " choice
        fi

        case $choice in
            1)
                run_script "$INSTALL_DIR/system/arch-server-setup.sh"
                ;;
            2)
                # Block if running as root on Live ISO
                if grep -q "archiso" /proc/cmdline 2>/dev/null && [[ "$EUID" -eq 0 ]]; then
                    echo -e "${RED}Option not available as root on Live ISO${NC}"
                    echo -e "${YELLOW}Please complete base installation first${NC}"
                    read -p "Press Enter to continue..."
                else
                    run_script "$INSTALL_DIR/system/post-install.sh"
                    setup_archer_command
                fi
                ;;
            3)
                # Block if running as root on Live ISO
                if grep -q "archiso" /proc/cmdline 2>/dev/null && [[ "$EUID" -eq 0 ]]; then
                    echo -e "${RED}Option not available as root on Live ISO${NC}"
                    echo -e "${YELLOW}Please complete base installation first${NC}"
                    read -p "Press Enter to continue..."
                else
                    run_script "$INSTALL_DIR/system/gpu-drivers.sh"
                fi
                ;;
            4)
                # Block if running as root on Live ISO
                if grep -q "archiso" /proc/cmdline 2>/dev/null && [[ "$EUID" -eq 0 ]]; then
                    echo -e "${RED}Option not available as root on Live ISO${NC}"
                    echo -e "${YELLOW}Please complete base installation first${NC}"
                    read -p "Press Enter to continue..."
                else
                    run_script "$INSTALL_DIR/desktop/de-installer.sh"
                fi
                ;;
            5)
                # Block if running as root on Live ISO
                if grep -q "archiso" /proc/cmdline 2>/dev/null && [[ "$EUID" -eq 0 ]]; then
                    echo -e "${RED}Option not available as root on Live ISO${NC}"
                    echo -e "${YELLOW}Please complete base installation first${NC}"
                    read -p "Press Enter to continue..."
                else
                    run_script "$INSTALL_DIR/network/wifi-setup.sh"
                fi
                ;;
            6)
                # Block if running as root on Live ISO
                if grep -q "archiso" /proc/cmdline 2>/dev/null && [[ "$EUID" -eq 0 ]]; then
                    echo -e "${RED}Option not available as root on Live ISO${NC}"
                    echo -e "${YELLOW}Please complete base installation first${NC}"
                    read -p "Press Enter to continue..."
                else
                    install_base_profile "base"
                fi
                ;;
            7)
                # Block if running as root on Live ISO
                if grep -q "archiso" /proc/cmdline 2>/dev/null && [[ "$EUID" -eq 0 ]]; then
                    echo -e "${RED}Option not available as root on Live ISO${NC}"
                    echo -e "${YELLOW}Please complete base installation first${NC}"
                    read -p "Press Enter to continue..."
                else
                    install_base_profile "gaming"
                fi
                ;;
            8)
                # Block if running as root on Live ISO
                if grep -q "archiso" /proc/cmdline 2>/dev/null && [[ "$EUID" -eq 0 ]]; then
                    echo -e "${RED}Option not available as root on Live ISO${NC}"
                    echo -e "${YELLOW}Please complete base installation first${NC}"
                    read -p "Press Enter to continue..."
                else
                    install_base_profile "developer"
                fi
                ;;
            9)
                # Block if running as root on Live ISO
                if grep -q "archiso" /proc/cmdline 2>/dev/null && [[ "$EUID" -eq 0 ]]; then
                    echo -e "${RED}Option not available as root on Live ISO${NC}"
                    echo -e "${YELLOW}Please complete base installation first${NC}"
                    read -p "Press Enter to continue..."
                else
                    launch_archer
                fi
                ;;
            0)
                echo -e "${GREEN}Thank you for using Archer!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Run main function with all arguments
main "$@"

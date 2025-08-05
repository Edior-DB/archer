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
INSTALL_DIR="$SCRIPT_DIR/install"

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
    if [[ ! -f /etc/arch-release ]] && [[ ! -f /etc/hostname ]] || ! grep -q "archiso" /proc/cmdline 2>/dev/null && [[ ! -f /etc/arch-release ]]; then
        echo -e "${RED}This script is designed for Arch Linux only.${NC}"
        echo -e "${YELLOW}Run from Arch Linux Live ISO for fresh installation, or from installed Arch Linux system.${NC}"
        exit 1
    fi
}

# Check internet connection
check_internet() {
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
    if ! command -v git &> /dev/null; then
        echo -e "${YELLOW}Installing git...${NC}"

        # Use different approach for Live ISO vs installed system
        if grep -q "archiso" /proc/cmdline 2>/dev/null; then
            # Live ISO - install without confirmation and update sync
            pacman -Sy git --noconfirm
        else
            # Installed system - use sudo
            sudo pacman -S --noconfirm git
        fi
    fi
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

    local archer_script="$SCRIPT_DIR/bin/archer.sh"
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
        echo -e "${YELLOW}Warning: archer.sh not found, skipping PATH setup${NC}"
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
    echo ""
    echo -e "${CYAN}===============================================${NC}"
    echo -e "${YELLOW}Note: After base installation, use 'archer' command${NC}"
    echo -e "${YELLOW}for additional software and customizations.${NC}"
}

# Execute script safely
run_script() {
    local script_path="$1"
    local script_name="$(basename "$script_path")"

    if [[ -f "$script_path" ]]; then
        echo -e "${BLUE}Running $script_name...${NC}"
        chmod +x "$script_path"
        "$script_path"
        echo -e "${GREEN}$script_name completed successfully!${NC}"
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
    local archer_script="$SCRIPT_DIR/bin/archer.sh"

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

    # Interactive menu
    while true; do
        show_menu
        read -p "Select an option [0-9]: " choice

        case $choice in
            1) run_script "$INSTALL_DIR/system/arch-server-setup.sh" ;;
            2)
                run_script "$INSTALL_DIR/system/post-install.sh"
                setup_archer_command
                ;;
            3) run_script "$INSTALL_DIR/system/gpu-drivers.sh" ;;
            4) run_script "$INSTALL_DIR/desktop/de-installer.sh" ;;
            5) run_script "$INSTALL_DIR/network/wifi-setup.sh" ;;
            6) install_base_profile "base" ;;
            7) install_base_profile "gaming" ;;
            8) install_base_profile "developer" ;;
            9) launch_archer ;;
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

#!/bin/bash

# WiFi Setup Script for Arch Linux
# This script helps set up WiFi connections using NetworkManager

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/../system}/common-funcs.sh"

# Logo
echo -ne "
${BLUE}-------------------------------------------------------------------------
 ██╗    ██╗██╗███████╗██╗    ███████╗███████╗████████╗██╗   ██╗██████╗
 ██║    ██║██║██╔════╝██║    ██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗
 ██║ █╗ ██║██║█████╗  ██║    ███████╗█████╗     ██║   ██║   ██║██████╔╝
 ██║███╗██║██║██╔══╝  ██║    ╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝
 ╚███╔███╔╝██║██║     ██║    ███████║███████╗   ██║   ╚██████╔╝██║
  ╚══╝╚══╝ ╚═╝╚═╝     ╚═╝    ╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝

                    Arch Linux WiFi Setup Script
-------------------------------------------------------------------------${NC}
"

# Root check
root_check() {
    if [[ "$(id -u)" != "0" ]]; then
        echo -e "${RED}ERROR! This script must be run under the 'root' user!${NC}"
        exit 1
    fi
}

# Check if NetworkManager is installed
check_networkmanager() {
    if ! command -v nmcli &> /dev/null; then
        echo -e "${YELLOW}NetworkManager not found. Installing...${NC}"
        pacman -S --noconfirm networkmanager
        systemctl enable NetworkManager
        systemctl start NetworkManager
        sleep 2
    else
        echo -e "${GREEN}NetworkManager is already installed.${NC}"
        # Make sure NetworkManager is running
        if ! systemctl is-active --quiet NetworkManager; then
            echo -e "${YELLOW}Starting NetworkManager...${NC}"
            systemctl start NetworkManager
            sleep 2
        fi
    fi
}

# Check if WiFi adapter is available
check_wifi_adapter() {
    if ! nmcli radio wifi | grep -q "enabled"; then
        echo -e "${YELLOW}Enabling WiFi radio...${NC}"
        nmcli radio wifi on
        sleep 2
    fi

    # Check if we have any WiFi devices
    wifi_devices=$(nmcli device status | grep wifi | head -1 | awk '{print $1}')
    if [[ -z "$wifi_devices" ]]; then
        echo -e "${RED}ERROR! No WiFi adapter found!${NC}"
        echo -e "${YELLOW}Please check if your WiFi driver is installed properly.${NC}"
        exit 1
    fi

    echo -e "${GREEN}WiFi adapter found: $wifi_devices${NC}"
}

# Scan for available networks
scan_networks() {
    echo -e "${BLUE}Scanning for available WiFi networks...${NC}"
    nmcli device wifi rescan
    sleep 3

    # Display available networks
    echo -e "${BLUE}Available WiFi Networks:${NC}"
    nmcli device wifi list
    echo ""
}

# Select WiFi network
select_network() {
    while true; do
        read -p "Enter the SSID (network name) you want to connect to: " SSID
        if [[ -n "$SSID" ]]; then
            # Check if the SSID exists in the scan results
            if nmcli device wifi list | grep -q "$SSID"; then
                break
            else
                echo -e "${YELLOW}Network '$SSID' not found in scan results. Please try again.${NC}"
                echo -e "${YELLOW}You can still proceed if you're sure the network exists.${NC}"
                read -p "Do you want to proceed anyway? (y/n): " proceed
                if [[ "$proceed" =~ ^[Yy]$ ]]; then
                    break
                fi
            fi
        else
            echo -e "${RED}Please enter a valid SSID.${NC}"
        fi
    done
}

# Get network password
get_password() {
    # Check if the network is open (no security)
    security=$(nmcli device wifi list | grep "$SSID" | head -1 | awk '{print $7}')

    if [[ "$security" == "--" ]]; then
        echo -e "${GREEN}Network '$SSID' is open (no password required).${NC}"
        PASSWORD=""
    else
        while true; do
            read -s -p "Enter password for '$SSID': " PASSWORD
            echo ""
            if [[ -n "$PASSWORD" ]]; then
                read -s -p "Confirm password: " PASSWORD_CONFIRM
                echo ""
                if [[ "$PASSWORD" == "$PASSWORD_CONFIRM" ]]; then
                    break
                else
                    echo -e "${RED}Passwords do not match. Please try again.${NC}"
                fi
            else
                echo -e "${RED}Password cannot be empty for secured networks.${NC}"
            fi
        done
    fi
}

# Connect to WiFi network
connect_wifi() {
    echo -e "${BLUE}Connecting to '$SSID'...${NC}"

    if [[ -z "$PASSWORD" ]]; then
        # Connect to open network
        nmcli device wifi connect "$SSID"
    else
        # Connect to secured network
        nmcli device wifi connect "$SSID" password "$PASSWORD"
    fi

    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}Successfully connected to '$SSID'!${NC}"

        # Show connection details
        echo -e "${BLUE}Connection Details:${NC}"
        nmcli connection show --active | grep "$SSID"

        # Test internet connectivity
        echo -e "${BLUE}Testing internet connectivity...${NC}"
        if ping -c 1 8.8.8.8 &> /dev/null; then
            echo -e "${GREEN}Internet connection is working!${NC}"
        else
            echo -e "${YELLOW}Connected to WiFi but internet may not be available.${NC}"
        fi
    else
        echo -e "${RED}Failed to connect to '$SSID'.${NC}"
        echo -e "${YELLOW}Please check your SSID and password and try again.${NC}"
        return 1
    fi
}

# Show current connections
show_connections() {
    echo -e "${BLUE}Current WiFi Connections:${NC}"
    nmcli connection show
    echo ""
    echo -e "${BLUE}Active Connections:${NC}"
    nmcli connection show --active
}

# Forget a network
forget_network() {
    echo -e "${BLUE}Saved WiFi Networks:${NC}"
    nmcli connection show | grep wifi
    echo ""

    read -p "Enter the name of the connection to forget (or press Enter to skip): " connection_name
    if [[ -n "$connection_name" ]]; then
        nmcli connection delete "$connection_name"
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}Successfully forgot network '$connection_name'.${NC}"
        else
            echo -e "${RED}Failed to forget network '$connection_name'.${NC}"
        fi
    fi
}

# Interactive menu
interactive_menu() {
    while true; do
        echo -e "${BLUE}
-------------------------------------------------------------------------
                          WiFi Management Menu
-------------------------------------------------------------------------${NC}"
        echo "1. Scan and connect to a new network"
        echo "2. Show current connections"
        echo "3. Forget a saved network"
        echo "4. Disconnect from current WiFi"
        echo "5. Enable/Disable WiFi"
        echo "6. Exit"
        echo ""
        read -p "Please select an option (1-6): " choice

        case $choice in
            1)
                scan_networks
                select_network
                get_password
                connect_wifi
                ;;
            2)
                show_connections
                ;;
            3)
                forget_network
                ;;
            4)
                echo -e "${BLUE}Disconnecting from WiFi...${NC}"
                nmcli device disconnect "$(nmcli device status | grep wifi | head -1 | awk '{print $1}')"
                echo -e "${GREEN}Disconnected from WiFi.${NC}"
                ;;
            5)
                current_status=$(nmcli radio wifi)
                if [[ "$current_status" == "enabled" ]]; then
                    nmcli radio wifi off
                    echo -e "${YELLOW}WiFi disabled.${NC}"
                else
                    nmcli radio wifi on
                    echo -e "${GREEN}WiFi enabled.${NC}"
                fi
                ;;
            6)
                echo -e "${GREEN}Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                ;;
        esac

        echo ""
        read -p "Press Enter to continue..."
        clear
    done
}

# Main execution
main() {
    root_check

    # Check if running in chroot environment
    if [[ -f /mnt/etc/arch-release ]]; then
        echo -e "${YELLOW}Detected chroot environment. This script should be run after booting into the installed system.${NC}"
        echo -e "${YELLOW}You can copy this script to the new system and run it after installation.${NC}"
        read -p "Do you want to continue anyway? (y/n): " continue_chroot
        if [[ ! "$continue_chroot" =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi

    check_networkmanager
    check_wifi_adapter

    # Check if command line arguments are provided
    if [[ $# -eq 0 ]]; then
        # Interactive mode
        interactive_menu
    else
        # Command line mode
        case "$1" in
            "scan")
                scan_networks
                ;;
            "connect")
                if [[ -z "$2" ]]; then
                    echo -e "${RED}Usage: $0 connect <SSID> [password]${NC}"
                    exit 1
                fi
                SSID="$2"
                PASSWORD="$3"
                connect_wifi
                ;;
            "status")
                show_connections
                ;;
            "help"|"-h"|"--help")
                echo "Usage: $0 [command] [arguments]"
                echo ""
                echo "Commands:"
                echo "  scan                    - Scan for available networks"
                echo "  connect <SSID> [pass]   - Connect to a network"
                echo "  status                  - Show connection status"
                echo "  help                    - Show this help"
                echo ""
                echo "Run without arguments for interactive mode."
                ;;
            *)
                echo -e "${RED}Unknown command: $1${NC}"
                echo "Use '$0 help' for usage information."
                exit 1
                ;;
        esac
    fi
}

# Run the main function with all arguments
main "$@"

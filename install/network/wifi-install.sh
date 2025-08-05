#!/bin/bash

# Simple WiFi Connection Script for Arch Linux Installation
# Use this during Arch Linux installation from the live ISO

echo "=== Arch Linux Installation WiFi Setup ==="
echo ""

# Check if we're in the live environment
if [[ ! -f /usr/bin/pacstrap ]]; then
    echo "Warning: This script is designed for the Arch Linux live environment."
fi

# Function to connect using iwctl (iwd)
connect_with_iwctl() {
    echo "Using iwctl (iwd) for WiFi connection..."
    echo ""

    # List available devices
    echo "Available WiFi devices:"
    iwctl device list
    echo ""

    read -p "Enter your WiFi device name (usually wlan0): " device
    if [[ -z "$device" ]]; then
        device="wlan0"
    fi

    # Scan for networks
    echo "Scanning for networks..."
    iwctl station "$device" scan
    sleep 3

    # Show available networks
    echo "Available networks:"
    iwctl station "$device" get-networks
    echo ""

    read -p "Enter the network name (SSID): " ssid

    # Connect to the network
    echo "Connecting to $ssid..."
    iwctl station "$device" connect "$ssid"

    # Check connection
    echo "Checking connection..."
    sleep 3
    if ping -c 1 8.8.8.8 &> /dev/null; then
        echo "✓ Successfully connected to WiFi!"
        echo "IP Address: $(ip addr show "$device" | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)"
    else
        echo "✗ Connection failed or no internet access"
        return 1
    fi
}

# Function to connect using NetworkManager (if available)
connect_with_nmcli() {
    echo "Using NetworkManager for WiFi connection..."

    # Enable WiFi
    nmcli radio wifi on
    sleep 2

    # Scan for networks
    echo "Scanning for networks..."
    nmcli device wifi rescan
    sleep 3

    # Show available networks
    echo "Available networks:"
    nmcli device wifi list
    echo ""

    read -p "Enter the network name (SSID): " ssid
    read -s -p "Enter the password (leave empty for open networks): " password
    echo ""

    # Connect to the network
    if [[ -z "$password" ]]; then
        nmcli device wifi connect "$ssid"
    else
        nmcli device wifi connect "$ssid" password "$password"
    fi

    # Check connection
    if [[ $? -eq 0 ]]; then
        echo "✓ Successfully connected to WiFi!"
        echo "Connection details:"
        nmcli connection show --active | head -1
    else
        echo "✗ Connection failed"
        return 1
    fi
}

# Main execution
echo "Choose WiFi connection method:"
echo "1. iwctl (iwd) - Default for Arch ISO"
echo "2. NetworkManager (nmcli)"
echo ""

read -p "Select method (1 or 2): " method

case "$method" in
    1)
        connect_with_iwctl
        ;;
    2)
        if command -v nmcli &> /dev/null; then
            connect_with_nmcli
        else
            echo "NetworkManager not available. Installing..."
            pacman -Sy networkmanager
            systemctl start NetworkManager
            connect_with_nmcli
        fi
        ;;
    *)
        echo "Invalid selection. Using iwctl (default)..."
        connect_with_iwctl
        ;;
esac

echo ""
echo "WiFi setup complete!"
echo "You can now proceed with the Arch Linux installation."

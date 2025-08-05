# WiFi Setup Scripts for Arch Linux

This directory contains WiFi setup scripts for different stages of Arch Linux installation and usage.

## Scripts Overview

### 1. `wifi-install.sh` - Installation Time WiFi Setup
**Use this during Arch Linux installation from the live ISO**

- Designed for use in the Arch Linux live environment
- Supports both `iwctl` (iwd) and NetworkManager
- Simple and straightforward for getting online during installation

**Usage:**
```bash
./wifi-install.sh
```

### 2. `wifi-setup.sh` - Post-Installation WiFi Management
**Use this after Arch Linux is installed and running**

- Full-featured WiFi management script
- Interactive menu system
- Command-line options available
- Requires NetworkManager

**Usage:**

Interactive mode:
```bash
sudo ./wifi-setup.sh
```

Command-line mode:
```bash
sudo ./wifi-setup.sh scan                    # Scan for networks
sudo ./wifi-setup.sh connect "MyWiFi" "pass" # Connect to network
sudo ./wifi-setup.sh status                  # Show connection status
sudo ./wifi-setup.sh help                    # Show help
```

## When to Use Each Script

### During Installation (Live ISO)
Use `wifi-install.sh`:
1. Boot from Arch Linux ISO
2. Run `./wifi-install.sh`
3. Follow the prompts to connect to WiFi
4. Proceed with installation

### After Installation
Use `wifi-setup.sh`:
1. Boot into your installed Arch Linux system
2. Run `sudo ./wifi-setup.sh`
3. Use the interactive menu or command-line options

## Features

### wifi-install.sh Features:
- ✅ Works with Arch Linux live ISO
- ✅ Supports iwctl (iwd) - default on Arch ISO
- ✅ Supports NetworkManager (if installed)
- ✅ Simple network scanning and connection
- ✅ Connection verification

### wifi-setup.sh Features:
- ✅ Interactive menu system
- ✅ Network scanning and connection
- ✅ View saved connections
- ✅ Forget/delete saved networks
- ✅ Enable/disable WiFi radio
- ✅ Connection status and details
- ✅ Internet connectivity testing
- ✅ Command-line interface
- ✅ Colored output for better readability

## Requirements

### For wifi-install.sh:
- Arch Linux live ISO environment
- iwd (pre-installed on Arch ISO) or NetworkManager

### For wifi-setup.sh:
- Installed Arch Linux system
- NetworkManager (will be installed automatically if missing)
- Root privileges

## Troubleshooting

### Common Issues:

1. **No WiFi adapter found**
   - Check if your WiFi driver is installed
   - Run `lspci | grep -i network` to see your network hardware
   - Install appropriate drivers for your WiFi card

2. **NetworkManager not working**
   - Make sure NetworkManager service is running: `systemctl status NetworkManager`
   - Start the service: `systemctl start NetworkManager`
   - Enable for boot: `systemctl enable NetworkManager`

3. **Can't connect to network**
   - Verify SSID and password are correct
   - Check if the network uses special authentication (WPA-Enterprise, etc.)
   - Try connecting manually with `nmcli` or `iwctl`

4. **Connected but no internet**
   - Check DNS settings: `cat /etc/resolv.conf`
   - Try different DNS servers: `echo 'nameserver 8.8.8.8' > /etc/resolv.conf`
   - Check routing: `ip route show`

### Manual Commands:

If the scripts don't work, you can try these manual commands:

**Using iwctl:**
```bash
iwctl device list
iwctl station wlan0 scan
iwctl station wlan0 get-networks
iwctl station wlan0 connect "YourSSID"
```

**Using NetworkManager:**
```bash
nmcli device wifi list
nmcli device wifi connect "YourSSID" password "YourPassword"
nmcli connection show
```

## Integration with Main Installer

The `wifi-install.sh` script can be integrated into the main `arch-server-setup.sh` installer by adding a WiFi setup step before the mirror setup phase.

## License

These scripts are provided as-is for educational and practical use with Arch Linux installation and management.

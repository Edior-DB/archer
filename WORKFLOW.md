# Archer Installation Workflow

## Overview

Archer now uses a two-phase installation approach to handle reboots gracefully and provide a better user experience:

1. **Phase 1: Base Installation** (`install.sh`) - Run from Live ISO
2. **Phase 2: Post-Installation** (`archer` command) - Run after reboot

## Phase 1: Base Installation (Live ISO)

The main `install.sh` script focuses on essential system setup that may require reboots:

### Core Components
- ✅ Fresh Arch Linux installation (LUKS encryption, base system)
- ✅ Post-installation setup (AUR, essential packages)
- ✅ GPU drivers with virtualization detection
- ✅ Desktop environment installation
- ✅ WiFi setup (if needed)

### Live ISO Optimizations
- **No System Updates**: Skips `pacman -Syu` when running from Live ISO (read-only environment)
- **Direct Package Installation**: Uses `pacman` directly instead of `sudo pacman` in Live ISO
- **Environment Detection**: Automatically detects Live ISO vs installed system
- **Proper Git Installation**: Handles git installation correctly for Live ISO environment

### Virtualization Support
The GPU driver installer now detects virtualization environments:
- **VirtIO/QEMU/KVM**: Installs qemu-guest-agent, spice-vdagent, xf86-video-qxl
- **VMware**: Installs open-vm-tools, xf86-input-vmmouse, xf86-video-vmware
- **VirtualBox**: Installs virtualbox-guest-utils, kernel modules

### Installation Profiles
- `--gaming`: Base system + gaming optimizations
- `--developer`: Base system + development tools
- `--base`: Minimal desktop system

## Phase 2: Post-Installation Management

After base installation and reboot, the `archer` command provides:

### Hardware Management
- **GPU Driver Management**: Re-detect and install optimal drivers (perfect for hardware upgrades)
- **WiFi Setup**: Network configuration and driver installation
- **Sudo Privilege Checking**: Ensures user has proper permissions before proceeding

### Software Features
- Gaming setup (Steam, Lutris, Wine, emulators)
- Development environment (languages, editors, containers)
- Multimedia workstation (media apps, codecs, themes)
- Security tools and privacy applications
- Office suites and productivity tools
- System optimizations and tweaks

### Usage
```bash
archer                    # Interactive menu with hardware management
archer --gpu             # GPU drivers (hardware upgrades)
archer --wifi            # WiFi setup and network drivers
archer --gaming          # Complete gaming setup
archer --development     # Complete dev environment
archer --multimedia      # Complete multimedia setup
```

### Hardware Upgrade Support
The `archer` tool is specifically designed to handle:
- 🔧 **GPU upgrades**: Automatically detects new graphics cards and installs appropriate drivers
- 📡 **WiFi hardware**: Configures new WiFi cards and network adapters
- 🛠️ **Driver issues**: Re-runs hardware detection to fix driver problems
- 🖥️ **Virtualization**: Detects VM environments and installs guest tools

## Benefits of This Approach

1. **Reboot Handling**: Base installation can reboot safely
2. **Modular**: Core system separate from applications
3. **User Experience**: Cleaner progression from ISO to desktop
4. **Virtualization Aware**: Detects and optimizes for virtual environments
5. **Focused Installation**: Each phase has clear responsibilities

## File Structure

```
archer/
├── install.sh           # Main installer (Phase 1)
├── bin/
│   └── archer.sh        # Post-installation tool (Phase 2)
├── install/
│   ├── system/          # Core system scripts
│   ├── desktop/         # Desktop environments
│   ├── multimedia/      # Gaming, media, codecs
│   ├── development/     # Dev tools and languages
│   ├── security/        # Security and privacy
│   └── network/         # Network configuration
└── configs/             # Configuration files
```

## Workflow Summary

1. **Boot Arch Live ISO**
2. **Run installer**: `./install.sh --gaming` (or preferred profile)
3. **Reboot into installed system**
4. **Complete setup**: `archer --gaming` (installs remaining software)
5. **Enjoy your customized Arch system!**

This approach ensures a smooth installation experience while maintaining the comprehensive feature set of the Archer suite.

# Archer - Arch Linux Installation Suite

A comprehensive Arch Linux installation and post-installation management suite with three distinct components.

## Architecture

### 1. `install.sh` - Main Entry Point
**Smart environment detection and guidance**
- Detects your current environment (Live ISO, installed Arch, or other)
- Provides appropriate commands for your situation
- Routes you to the correct installer

**Usage:**
```bash
curl -fsSL https://raw.githubusercontent.com/Edior-DB/archer/master/install.sh | bash
```

### 2. `install-system.sh` - Live ISO System Installer
**Fresh Arch Linux installation from Live ISO**
- Complete guided installation process
- User account creation
- Disk partitioning (btrfs, ext4, LUKS encryption)
- Bootloader configuration
- Basic system setup

**Usage (Live ISO only):**
```bash
curl -fsSL https://raw.githubusercontent.com/Edior-DB/archer/master/install-system.sh | bash
```

### 3. `install-archer.sh` - Post-Installation Setup
**Development environment setup on installed Arch**
- Updates system packages
- Installs development tools and libraries
- GPU drivers installation
- WiFi support setup
- AUR helper (yay) installation
- Creates `archer` command alias

**Usage (Installed Arch only):**
```bash
curl -fsSL https://raw.githubusercontent.com/Edior-DB/archer/master/install-archer.sh | bash
```

### 4. `bin/archer.sh` - Main Management Menu
**Comprehensive system customization and management**
- Hardware drivers (GPU, WiFi)
- Desktop environments (GNOME, KDE)
- Development tools
- Gaming setup
- Office applications
- System utilities

**Usage (After install-archer.sh):**
```bash
archer
# or directly:
~/archer/bin/archer.sh
```

## Complete Installation Workflow

1. **Boot Arch Linux Live ISO** as root
2. **Run system installer:**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/Edior-DB/archer/master/install-system.sh | bash
   ```
3. **Reboot and login** as your created user
4. **Run post-installation setup:**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/Edior-DB/archer/master/install-archer.sh | bash
   ```
5. **Use archer command** for additional customization:
   ```bash
   archer
   ```

## Quick Start

Just run the main script - it will detect your environment and guide you:
```bash
curl -fsSL https://raw.githubusercontent.com/Edior-DB/archer/master/install.sh | bash
```

## Features

### System Installation
- **Modern Interface**: Uses gum for better UX when available
- **Multiple Filesystems**: btrfs, ext4, LUKS encryption support
- **Hardware Detection**: Automatic GPU drivers, microcode installation
- **Optimized Setup**: Parallel downloads, compilation optimization

### Post-Installation
- **Development Ready**: Full development toolchain
- **Hardware Support**: GPU drivers, WiFi setup
- **AUR Integration**: yay AUR helper installation
- **Modern CLI**: gum-powered interactive menus

### Management Tools
- **Hardware Management**: Easy driver updates and hardware changes
- **Desktop Environments**: One-click DE installation
- **Gaming Setup**: Steam, Lutris, Wine configuration
- **Development Environment**: Complete dev stack setup

## Directory Structure

```
archer/
├── install.sh              # Main entry point
├── install-system.sh       # Live ISO system installer
├── install-archer.sh       # Post-installation setup
├── bin/
│   └── archer.sh           # Main management menu
└── install/                # Individual installation modules
    ├── desktop/            # Desktop environments
    ├── development/        # Dev tools and languages
    ├── multimedia/         # Gaming and media apps
    ├── network/            # Network and WiFi setup
    ├── system/             # System utilities and drivers
    └── extras/             # Additional tools
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on Arch Linux
5. Submit a pull request

## License

MIT License - See LICENSE file for details

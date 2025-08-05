# Archer - Arch Linux Installation Suite

A comprehensive Arch Linux installation and post-installation management suite with three distinct components.

## 🎯 Project Overview

**Archer** provides a complete Arch Linux installation workflow from Live ISO to fully configured system:

1. **`install-system.sh`**: Fresh Arch installation from Live ISO
2. **`install-archer.sh`**: Post-installation development environment setup
3. **`archer`**: System management and customization menu

## 🚀 Quick Start

### Smart Installer (Detects Environment)
```bash
curl -fsSL https://raw.githubusercontent.com/Edior-DB/archer/master/install.sh | bash
```

### Direct Installation Routes

**Fresh Installation (Live ISO only):**
```bash
curl -fsSL https://raw.githubusercontent.com/Edior-DB/archer/master/install-system.sh | bash
```

**Post-Installation Setup (Installed Arch only):**
```bash
curl -fsSL https://raw.githubusercontent.com/Edior-DB/archer/master/install-archer.sh | bash
```

### Alternative Methods

**Git Clone (Most Reliable):**
```bash
pacman -Sy git --noconfirm  # If needed
git clone https://github.com/Edior-DB/archer.git
cd archer
./install-system.sh  # On Live ISO
# OR
./install-archer.sh  # On installed Arch
./install.sh
```

**Quick Installation Profiles:**
```bash
./install.sh --gaming     # Gaming-ready system
./install.sh --developer  # Developer workstation
./install.sh --base       # Minimal desktop system
## Complete Installation Workflow

1. **Boot Arch Linux Live ISO** as root
2. **Fresh Installation:**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/Edior-DB/archer/master/install-system.sh | bash
   ```
3. **Reboot and login** as your created user
4. **Post-Installation Setup:**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/Edior-DB/archer/master/install-archer.sh | bash
   ```
5. **System Management:**
   ```bash
   archer  # Main menu for customization
   ```

## 📁 Architecture

### Core Scripts
- **`install.sh`** - Smart entry point with environment detection
- **`install-system.sh`** - Fresh Arch installation (Live ISO only)
- **`install-archer.sh`** - Post-installation setup (installed Arch only)
- **`bin/archer.sh`** - Main system management menu

### Installation Modules

```
archer/
├── install-system.sh           # Fresh Arch installation from Live ISO
├── install-archer.sh           # Post-installation development setup
├── install.sh                  # Smart entry point with environment detection
├── bin/
│   └── archer.sh              # Main system management menu
└── install/                   # Modular installation components
    ├── desktop/               # Desktop environments & office tools
    ├── development/           # Programming languages & dev tools
    ├── multimedia/            # Gaming, media applications
    ├── network/               # WiFi setup & network configuration
    ├── system/                # Hardware drivers & system utilities
    └── extras/                # Additional tools & customizations
```

## 🎯 Features

### System Installation (`install-system.sh`)
- **Modern Interface**: gum-powered interactive menus
- **Multiple Filesystems**: btrfs, ext4, LUKS encryption
- **Hardware Detection**: Automatic GPU drivers, microcode
- **Optimized Setup**: Parallel downloads, compilation tuning

### Post-Installation (`install-archer.sh`)
- **Development Ready**: Complete toolchain (gcc, python, node, etc.)
- **Hardware Support**: GPU drivers, WiFi configuration
- **AUR Integration**: yay AUR helper installation
- **Modern CLI**: Enhanced terminal experience

### Management System (`archer`)
- **Hardware Management**: Perfect for upgrades and driver issues
- **Desktop Environments**: GNOME, KDE one-click installation
- **Gaming Setup**: Steam, Lutris, Wine configuration
- **Development Profiles**: Complete dev environment setup
│   │   └── codecs.sh               # Audio/video codecs
│   ├── security/        # Security and privacy
│   │   ├── firewall.sh            # UFW/iptables setup
│   │   ├── privacy.sh             # Privacy tools
│   │   └── backup.sh              # Backup solutions
│   └── extras/          # Additional utilities
│       ├── flatpak.sh             # Flatpak setup
│       ├── aur-helper.sh          # AUR helper installation
│       └── personal-tweaks.sh     # Personal customizations
├── configs/             # Configuration files and dotfiles
├── scripts/             # Utility scripts
├── docs/               # Documentation
└── install.sh          # Main installer script
```

## 🛠 Features

### Core Installation
- ✅ **Base System**: Automated Arch Linux installation with encryption support
- ✅ **Network Setup**: WiFi configuration and network optimization
- ✅ **Post-Install**: Essential packages and system configuration

### Desktop Environment
- 🔄 **Multiple DEs**: Support for GNOME, KDE, XFCE, i3wm, Hyprland
- 🎨 **Theming**: Custom themes and icon packs
- 📱 **Applications**: Essential desktop applications

### Development Environment
- 💻 **Languages**: Python, Node.js, Rust, Go, Java support
- 🔧 **Tools**: Git, Docker, VS Code, terminal emulators
- ⚡ **Shell**: Zsh with Oh My Zsh and useful plugins

### Multimedia & Gaming
- 🎵 **Audio/Video**: Media players, codecs, editing tools
- 🎮 **Gaming**: Steam, Lutris, gaming optimizations
- 📺 **Streaming**: OBS, streaming tools

### Security & Privacy
- 🔒 **Security**: Firewall, antivirus, security tools
- 🕵️ **Privacy**: VPN clients, Tor, privacy-focused apps
- 💾 **Backup**: Automated backup solutions

## 🎛 Usage Modes

### 1. Interactive Mode (Recommended)
```bash
./install.sh
```
Interactive menu system for selective installation.

### 2. Full Installation
```bash
./install.sh --full
```
Installs everything for a complete home PC setup.

### 3. Selective Installation
```bash
./install.sh --desktop      # Desktop environment only
./install.sh --development  # Development tools only
./install.sh --gaming       # Gaming setup only
```

### 4. Custom Profile
```bash
./install.sh --profile developer    # Developer workstation
./install.sh --profile gaming       # Gaming rig
./install.sh --profile multimedia   # Media center
```

## 🔧 Integration with LinUtil

This project integrates with and extends [Chris Titus' LinUtil](https://github.com/ChrisTitusTech/linutil):

- Uses LinUtil for common system tweaks
- Adds Arch-specific optimizations
- Provides additional customization options
- Maintains compatibility with LinUtil workflows

## � Troubleshooting

### Installation Issues

### Installation Issues

**Error 400/404/Connection issues when downloading from Live ISO:**

The most common cause is network/DNS configuration in Live ISO environments.

```bash
# Solution 1: Use the robust installer (handles network issues automatically)
curl -fsSL https://raw.githubusercontent.com/Edior-DB/archer/master/quick-install.sh | bash

# Solution 2: Manual DNS fix
echo "nameserver 1.1.1.1" >> /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf
curl -fsSL https://raw.githubusercontent.com/Edior-DB/archer/master/install.sh | bash

# Solution 3: Git clone method (most reliable)
pacman -Sy git --noconfirm
git clone https://github.com/Edior-DB/archer.git
cd archer && ./install.sh

# Solution 4: Test network connectivity first
ping -c 3 8.8.8.8          # Test internet
ping -c 3 github.com        # Test DNS
```

**Other common Live ISO issues:**
```bash
# Ensure you're root
whoami  # should return 'root'

# Check available space
df -h

# Verify Arch Live ISO
cat /proc/cmdline | grep archiso
```

**Network connectivity issues:**
```bash
# Check network
ping -c 3 8.8.8.8

# Setup WiFi in Live ISO
iwctl
[iwd]# device list
[iwd]# station wlan0 scan
[iwd]# station wlan0 get-networks
[iwd]# station wlan0 connect "YOUR_NETWORK"
```

**Permission denied errors:**
```bash
# Ensure you're running as root in Live ISO
whoami  # should return 'root'

# If not root:
sudo -i
```

### Post-Installation Issues

**"archer" command not found:**
```bash
# Manually add to PATH
export PATH="/usr/local/bin:$PATH"

# Or run directly
/usr/local/bin/archer
```

**Sudo privilege errors:**
```bash
# Add user to wheel group
su -c 'usermod -aG wheel $USER'
# Logout and login again
```

## �📋 Requirements

- Fresh Arch Linux installation (minimal/server)
- Internet connection
- Root/sudo access
- At least 20GB free disk space

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **[Chris Titus Tech](https://github.com/ChrisTitusTech)** - The core system installer (`install-system.sh`) is based on his excellent [ArchTitus](https://github.com/ChrisTitusTech/ArchTitus) project
- [Arch Linux](https://archlinux.org/) community for the amazing distribution
- All contributors and testers who make this project better

## 📞 Support

- 📖 [Documentation](docs/)
- 🐛 [Issues](https://github.com/Edior-DB/archer/issues)
- 💬 [Discussions](https://github.com/Edior-DB/archer/discussions)

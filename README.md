# Archer - Arch Linux Home PC Transformation Suite

Transform your vanilla Arch Linux from Live ISO into a fully-featured home PC with gaming, development, and multimedia capabilities.

## 🎯 Project Overview

**Archer** is a comprehensive installation suite that takes you from Arch Linux Live ISO to a complete home PC setup. The installation is split into two phases:

1. **Base Installation** (`install.sh`): Core system setup from Live ISO - handles OS installation, GPU drivers, desktop environment, and WiFi
2. **Post-Installation** (`archer` command): Additional software, customizations, and specialized setups

This design handles reboots gracefully and provides a better user experience.

## 🚀 Quick Start

### Phase 1: Base Installation (Run from Live ISO)

Download and run the main installer:
```bash
curl -fsSL https://raw.githubusercontent.com/Edior-DB/archer/master/install.sh | bash
```

Or clone and run manually:
```bash
git clone https://github.com/Edior-DB/archer.git
cd archer
./install.sh
```

**Quick Installation Profiles:**
```bash
./install.sh --gaming     # Gaming-ready system
./install.sh --developer  # Developer workstation
./install.sh --base       # Minimal desktop system
```

### Phase 2: Post-Installation (After Reboot)

After base installation and reboot, use the `archer` command:
```bash
archer                    # Interactive menu
archer --gaming          # Complete gaming setup
archer --development     # Complete dev environment
archer --multimedia      # Complete multimedia setup
```

**Hardware Management (Perfect for Upgrades):**
```bash
archer --gpu             # Re-detect and install GPU drivers
archer --wifi            # WiFi setup and network configuration
```

**Note:** The `archer` command includes sudo privilege checking and is perfect for:
- 🔧 **Hardware upgrades** (new GPU, WiFi card)
- 🛠️ **Driver issues** (GPU driver problems, network issues)
- 📦 **Additional software** (gaming, development, multimedia)
- ⚙️ **System optimization** (performance tweaks, security)

## 📁 Project Structure

```
archer/
├── install/
│   ├── system/          # Core system installation and setup
│   │   ├── arch-server-setup.sh    # Base Arch installation
│   │   ├── post-install.sh         # Post-installation essentials
│   │   └── system-tweaks.sh        # System optimizations
│   ├── network/         # Network configuration
│   │   ├── wifi-setup.sh           # WiFi management
│   │   └── wifi-install.sh         # Installation-time WiFi
│   ├── desktop/         # Desktop environment setup
│   │   ├── de-installer.sh         # Desktop environment installer
│   │   ├── themes.sh               # Theme and customization
│   │   └── applications.sh         # Essential applications
│   ├── terminal/        # Terminal and CLI tools
│   │   ├── shell-setup.sh          # Shell configuration (zsh, oh-my-zsh)
│   │   ├── terminal-apps.sh        # CLI applications
│   │   └── dotfiles.sh             # Dotfiles management
│   ├── development/     # Development environment
│   │   ├── dev-tools.sh            # Programming languages & tools
│   │   ├── editors.sh              # Code editors (VS Code, Vim, etc.)
│   │   └── containers.sh           # Docker, Podman setup
│   ├── multimedia/      # Media and entertainment
│   │   ├── media-apps.sh           # Media players, editors
│   │   ├── gaming.sh               # Gaming setup (Steam, etc.)
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

## 📋 Requirements

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

- [Chris Titus Tech](https://github.com/ChrisTitusTech) for LinUtil inspiration
- [Arch Linux](https://archlinux.org/) community
- All contributors and testers

## 📞 Support

- 📖 [Documentation](docs/)
- 🐛 [Issues](https://github.com/Edior-DB/archer/issues)
- 💬 [Discussions](https://github.com/Edior-DB/archer/discussions)

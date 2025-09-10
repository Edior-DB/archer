# Archer Development Context & Guidelines

## Project Overview
**Archer** is a comprehensive Arch Linux post-installation automation suite designed to transform a fresh Arch Linux installation into a fully customized desktop environment.

## Development Environment
- **Development Platform**: Debian-based system (NOT Arch Linux)
- **Target Platform**: Arch Linux systems
- **Repository**: https://github.com/Edior-DB/archer
- **Branch**: master

## Critical Development Notes

### ⚠️ Platform Awareness
- **DO NOT** run Arch-specific commands (pacman, yay, etc.) on the development machine
- **DO NOT** assume development machine has Arch Linux tools
- Scripts are designed FOR Arch Linux but developed ON Debian/Ubuntu
- Use syntax checking (`bash -n`) instead of execution testing during development

### 🏗️ Architecture Overview
```
archer/
├── bin/archer.sh              # Main menu system
├── install/                   # Installation scripts
│   ├── desktop/              # Desktop environment & themes
│   │   ├── fonts/           # Font collection installers
│   │   └── office-tools/    # Office suite installers
│   ├── development/         # Development tools & editors
│   ├── multimedia/          # Gaming & media applications
│   ├── network/            # Network & WiFi setup
│   ├── system/             # System utilities & drivers
│   └── extras/             # Additional applications
└── .archer-prompts/        # Development documentation
```

## Core Principles

### 🎯 Smart Package Management
- **Prevent Reinstallations**: Use `install_with_retries()` function with `--needed` flag
- **Pre-installation Checks**: Always check if packages are already installed with `pacman -Q`
- **AUR Detection**: Automatically detect official vs AUR packages
- **Error Handling**: Implement proper fallbacks and user confirmations

### 🔧 Modular Design
- **Separation of Concerns**: Each script has a specific purpose
- **Reusability**: Scripts can be called independently or from profiles
- **Configuration Management**: Separate installation from configuration
- **User Choice**: Always provide confirmation prompts for optional components

### 📱 User Experience
- **Interactive Menus**: Use `gum` for modern CLI interactions where available
- **Clear Feedback**: Provide colored output and progress indicators
- **Error Recovery**: Graceful handling of failures with retry options
- **Documentation**: Include usage instructions in script output

## Script Development Standards

### 🛠️ Required Elements
```bash
#!/bin/bash
set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/..}/install/system/common-funcs.sh"

show_banner "Script Purpose"

# Check if AUR helper is available
if ! check_aur_helper; then
    echo -e "${RED}AUR helper not found. Please run post-install.sh first.${NC}"
    exit 1
fi
```

### 🎨 Function Patterns
- **install_with_retries**: For all package installations
- **confirm_action**: For user confirmations
- **get_input**: For user input with defaults
- **show_banner**: For script headers

### 🔍 Testing Protocol
1. **Syntax Validation**: `bash -n script.sh`
2. **Permission Check**: `chmod +x script.sh`
3. **Common Function Import**: Verify `common-funcs.sh` sourcing
4. **Error Handling**: Test with invalid inputs
5. **Documentation**: Verify script completion messages

## Current Feature Status

### ✅ Implemented Features
- **Smart Package Management**: Prevents reinstallations across categories
- **Modular Terminal System**: 4 customizable terminal emulators with configs
- **Comprehensive Font Collections**: 7 specialized font installers
- **Development Tools**: Languages, editors, and development environment
- **Desktop Themes**: Cupertini (macOS-like), Redmondi (Windows-like), Vanilla (KDE default)

### 🚧 Menu Structure (16 Options)
1. GPU Drivers Installation
2. WiFi Setup & Network Configuration
3. Firefox Browser Installation
4. Brave Browser Installation
5. Virt-Manager Installation
6. Development Tools & Languages
7. Code Editors & IDEs
8. Gaming Setup (Steam, Lutris, Wine)
9. Multimedia Applications
10. Office Suite Installation
11. Font Collections
12. AUR Helper Setup
13. System Utilities ⚠️ **MISSING SCRIPT**
14. Complete Gaming Workstation (Profile)
15. Complete Development Environment (Profile)
16. Complete Multimedia Setup (Profile)

### ❌ Missing Components
- `system-utilities.sh` - System monitoring and maintenance tools
- Several profile dependency scripts (see archer.sh `install_profile` function)

## Development Workflow

### 📝 Adding New Features
1. **Create Script**: Follow naming convention (`feature-name.sh`)
2. **Implement Standards**: Use required elements and patterns
3. **Test Syntax**: Validate with `bash -n`
4. **Update Menu**: Add to `archer.sh` if needed
5. **Document Changes**: Update this context file
6. **Commit & Push**: Use descriptive commit messages

### 🔄 Profile Dependencies
Profile scripts call multiple individual scripts. Ensure all dependencies exist:
- **Gaming Profile**: gaming.sh, codecs.sh, applications.sh, system-tweaks.sh
- **Development Profile**: shell-setup.sh, dev-tools.sh, editors.sh, containers.sh, flatpak.sh
- **Multimedia Profile**: media-apps.sh, codecs.sh, applications.sh, themes.sh

## Future Expansion Guidelines

### 📦 Package Categories
- **Official Repos**: Use `pacman` with `install_with_retries`
- **AUR Packages**: Auto-detect and use available AUR helper
- **Flatpak/Snap**: Separate dedicated installers
- **Manual Installs**: Provide fallback methods

### 🎨 Theme Development
- **Backup System**: Always backup existing configurations
- **Desktop Integration**: Support GNOME, KDE, and other DEs
- **Modularity**: Separate theme components for flexibility
- **Reset Options**: Provide easy way to restore defaults

### 🔧 Tool Integration
- **Configuration Files**: Include sensible defaults
- **Plugin Systems**: Auto-install essential plugins/extensions
- **Desktop Files**: Ensure proper application menu integration
- **PATH Management**: Handle shell configuration updates

---

*This document should be updated as the project evolves. Keep it current with architectural changes and new features.*

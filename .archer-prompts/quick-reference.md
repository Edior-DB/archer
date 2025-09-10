# Quick Reference Guide

## 🚀 Essential Commands

### Development Workflow
```bash
# Syntax validation
bash -n /path/to/script.sh

# Make executable
chmod +x /path/to/script.sh

# Find all scripts
find /home/giorgil/archer/install -name "*.sh" | sort

# Check git status
git status

# Commit and push
git add .
git commit -m "descriptive message"
git push origin master
```

### Testing Scripts
```bash
# Check script structure
head -20 script.sh

# Validate common function sourcing
grep -n "common-funcs.sh" script.sh

# Check for install_with_retries usage
grep -n "install_with_retries" script.sh

# Verify error handling
grep -n "set -e" script.sh
```

## 📦 Package Installation Patterns

### Standard Installation
```bash
# Correct way
install_with_retries pacman package-name

# Wrong way (don't do this)
sudo pacman -S package-name
```

### AUR Installation
```bash
# Correct way (auto-detects AUR)
install_with_retries yay aur-package

# Function handles both official and AUR
install_with_retries pacman package-name  # Will try AUR if not in official repos
```

### User Confirmation
```bash
if confirm_action "Install package X?"; then
    install_with_retries pacman package-x
    echo -e "${GREEN}Package X installed!${NC}"
fi
```

## 🎨 Color Codes
```bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
```

## 📁 Directory Structure
```
/home/giorgil/archer/
├── bin/archer.sh              # Main menu
├── install/
│   ├── desktop/
│   │   ├── fonts/            # Font installers
│   │   └── office-tools/     # Office applications
│   ├── development/          # Dev tools & editors
│   ├── multimedia/           # Gaming & media
│   ├── network/             # WiFi & networking
│   ├── system/              # System utilities
│   └── extras/              # Additional apps
└── .archer-prompts/         # Documentation
```

## 🔧 Common Functions (from common-funcs.sh)
```bash
install_with_retries()        # Smart package installation
confirm_action()              # User confirmation prompt
get_input()                   # User input with default
show_banner()                 # Script header display
check_aur_helper()           # Verify AUR helper availability
```

## 📋 Menu Option Status
```
✅  1. GPU Drivers Installation
✅  2. WiFi Setup & Network Configuration
✅  3. Firefox Browser Installation
✅  4. Brave Browser Installation
✅  5. Virt-Manager Installation
✅  6. Development Tools & Languages
✅  7. Code Editors & IDEs
✅  8. Gaming Setup
✅  9. Multimedia Applications
✅ 10. Office Suite Installation
✅ 11. Font Collections
✅ 12. AUR Helper Setup
❌ 13. System Utilities (MISSING)
❌ 14. Gaming Profile (MISSING DEPS)
❌ 15. Development Profile (MISSING DEPS)
❌ 16. Multimedia Profile (MISSING DEPS)
```

## 🚨 Development Reminders
- **Platform**: Developing ON Debian FOR Arch Linux
- **Testing**: Use `bash -n` syntax checking, not execution
- **Packages**: Always use `install_with_retries()`
- **Users**: Include confirmation prompts
- **Colors**: Use established color scheme
- **Errors**: Handle gracefully with fallbacks

# Archer Project Assistant Instructions

## 🤖 AI Assistant Guidelines

### Primary Objectives
When working on the Archer project, your role is to:
1. **Maintain Code Quality**: Follow established patterns and standards
2. **Preserve Architecture**: Respect the modular design principles
3. **Ensure Compatibility**: All scripts must work on target Arch Linux systems
4. **Document Changes**: Update context files when making significant modifications

### 🚨 Critical Reminders

#### Development Environment
- **You are developing ON Debian/Ubuntu, FOR Arch Linux**
- **NEVER execute Arch commands** (`pacman`, `yay`, `paru`) on development machine
- **Use syntax checking** (`bash -n script.sh`) instead of execution testing
- **Test scripts conceptually**, not by running them

#### Code Patterns
- **Always use `install_with_retries()`** instead of direct `pacman`/`yay` calls
- **Include user confirmations** for all installations
- **Source common functions** from `common-funcs.sh`
- **Follow the established script template** (see development-context.md)

#### Package Management Philosophy
- **Prevent Reinstallations**: Check if packages exist before installing
- **Smart AUR Detection**: Let functions handle official vs AUR packages automatically
- **Error Handling**: Provide fallbacks and retry mechanisms
- **User Choice**: Always ask before installing optional components

### 🛠️ Common Tasks & Patterns

#### Creating New Installation Scripts
```bash
#!/bin/bash
set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/..}/install/system/common-funcs.sh"

show_banner "Feature Name Installation"

# Check AUR helper availability
if ! check_aur_helper; then
    echo -e "${RED}AUR helper not found. Please run post-install.sh first.${NC}"
    exit 1
fi

# Main installation function
install_feature() {
    echo -e "${BLUE}Installing feature components...${NC}"

    if confirm_action "Install feature X?"; then
        install_with_retries pacman package-name
        echo -e "${GREEN}Feature X installed!${NC}"
    fi
}

# Main execution
main() {
    echo -e "${YELLOW}Welcome to Feature Installation!${NC}"

    if ! confirm_action "Continue with installation?"; then
        echo -e "${YELLOW}Installation cancelled.${NC}"
        exit 0
    fi

    install_feature

    echo -e "${GREEN}Feature installation completed!${NC}"
    read -p "Press Enter to continue..."
}

main
```

#### Adding Menu Options
1. **Add menu display**: Update `show_menu()` function
2. **Add option array**: Update `options` array in main menu
3. **Add case handler**: Update case statement with script path
4. **Update validation**: Adjust input validation range if needed

#### Validation Checklist
Before submitting changes:
- [ ] Syntax check: `bash -n script.sh`
- [ ] Executable permissions: `chmod +x script.sh`
- [ ] Common functions imported correctly
- [ ] Uses `install_with_retries` for packages
- [ ] Includes user confirmations
- [ ] Follows color scheme (RED, GREEN, YELLOW, BLUE, CYAN, NC)
- [ ] Provides completion message
- [ ] Updates menu if needed

### 📋 Current Project Status

#### Working Components
- ✅ Smart package management system
- ✅ Modular terminal emulator installation
- ✅ Comprehensive font collection system
- ✅ Development tools installation
- ✅ Desktop theme switching (Cupertini, Redmondi, Vanilla)
- ✅ Main menu system with 16 options

#### Missing Components
- ❌ `system-utilities.sh` (option 13)
- ❌ Multiple profile dependency scripts (options 14-16)

#### Immediate Priorities
1. Create missing `system-utilities.sh` script
2. Audit and create missing profile dependency scripts
3. Test complete workflow from menu to installation
4. Update documentation as needed

### 🎯 Quality Standards

#### Script Requirements
- **Error Handling**: Use `set -e` and proper error checking
- **User Experience**: Clear prompts and colored output
- **Modularity**: Functions should be reusable
- **Documentation**: Include usage instructions in output
- **Compatibility**: Work across different Arch Linux setups

#### Commit Standards
- **Descriptive Messages**: Explain what was added/changed and why
- **Logical Grouping**: Group related changes in single commits
- **Testing Notes**: Mention validation performed
- **Breaking Changes**: Clearly indicate if changes affect existing functionality

### 🔄 Maintenance Tasks

#### Regular Updates Needed
- Monitor AUR package name changes
- Update language/tool version preferences
- Refresh theme components when upstream changes
- Validate package availability and dependencies
- Update documentation with new features

#### Architecture Improvements
- Consider adding configuration file support
- Implement logging system for troubleshooting
- Add rollback capabilities for failed installations
- Create automated testing framework
- Develop installation verification system

---

**Remember**: You're building a production-ready system that others will rely on. Every script should be robust, user-friendly, and maintainable.

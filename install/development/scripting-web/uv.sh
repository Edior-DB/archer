#!/bin/bash
# UV Python Package Manager Installation
# Fast Python package manager and dependency resolver

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/../..}/install/system/common-funcs.sh"

show_banner "UV Python Package Manager"

echo -e "${BLUE}UV - An extremely fast Python package installer and resolver${NC}"
echo -e "${YELLOW}UV is written in Rust and is designed to be a drop-in replacement for pip${NC}"
echo -e "${YELLOW}Key features:${NC}"
echo -e "  • 10-100x faster than pip"
echo -e "  • Drop-in replacement for pip and pip-tools"
echo -e "  • Support for Python environments and requirements.txt"
echo -e "  • Zero configuration required"
echo ""

if ! archer_confirm_or_default "Install UV Python package manager?"; then
    echo -e "${YELLOW}UV installation cancelled.${NC}"
    exit 0
fi

# Check if UV is already installed
if command -v uv &> /dev/null; then
    echo -e "${GREEN}UV is already installed${NC}"
    uv --version
    if ! archer_confirm_or_default "Reinstall UV?"; then
        echo -e "${YELLOW}Keeping existing UV installation.${NC}"
        exit 0
    fi
fi

echo -e "${BLUE}Installing UV via official installer...${NC}"

# Install UV using the official installer
if curl -LsSf https://astral.sh/uv/install.sh | sh; then
    echo -e "${GREEN}✓ UV installed successfully!${NC}"

    # Add to PATH if not already there
    if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
        echo -e "${YELLOW}Adding UV to PATH in ~/.bashrc...${NC}"
        echo '' >> ~/.bashrc
        echo '# UV Python package manager' >> ~/.bashrc
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
        echo -e "${GREEN}✓ PATH updated in ~/.bashrc${NC}"
    fi

    # Source the new PATH for current session
    export PATH="$HOME/.local/bin:$PATH"

    echo -e "${GREEN}
=========================================================================
                        UV Installation Complete!
=========================================================================

UV has been installed successfully!

Key commands:
  uv pip install <package>     # Install packages (faster than pip)
  uv pip list                  # List installed packages
  uv pip freeze               # Output installed packages in requirements format
  uv pip compile requirements.in  # Generate requirements.txt from .in file
  uv pip sync requirements.txt    # Install exact versions from requirements.txt

Usage examples:
  uv pip install requests      # Install a package
  uv pip install -r requirements.txt  # Install from requirements file
  uv pip install --upgrade pip        # Upgrade pip itself

Next steps:
- Restart your terminal or run 'source ~/.bashrc' to update PATH
- Try 'uv --version' to verify installation
- Use 'uv pip' as a drop-in replacement for 'pip'
- Create requirements.in files and use 'uv pip compile' for dependency management

Documentation: https://github.com/astral-sh/uv
${NC}"

else
    echo -e "${RED}✗ Failed to install UV${NC}"
    echo -e "${YELLOW}You can try installing manually:${NC}"
    echo -e "${CYAN}  curl -LsSf https://astral.sh/uv/install.sh | sh${NC}"
    exit 1
fi

wait_for_input

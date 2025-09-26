#!/bin/bash
# Node.js Installation via Mise
# JavaScript runtime for server-side development

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/../..}/install/system/common-funcs.sh"

show_banner "Node.js Installation"

echo -e "${BLUE}Node.js - JavaScript runtime built on Chrome's V8 JavaScript engine${NC}"
echo -e "${YELLOW}Installing via Mise for better version management${NC}"
echo ""

# if ! confirm_action "Install Node.js via Mise?"; then
#     echo -e "${YELLOW}Node.js installation cancelled.${NC}"
#     exit 0
# fi

# Setup Mise and install Node.js
setup_mise || {
    echo -e "${RED}Failed to setup Mise. Trying system package manager...${NC}"
    if install_with_retries nodejs npm; then
        echo -e "${GREEN}✓ Node.js installed via system package manager!${NC}"
        exit 0
    else
        echo -e "${RED}✗ Failed to install Node.js${NC}"
        exit 1
    fi
}

echo -e "${BLUE}Installing Node.js via Mise...${NC}"

if install_mise_tool nodejs latest; then
    # Verify installation
    if verify_mise_tool nodejs node; then
        echo -e "${GREEN}✓ Node.js is ready to use!${NC}"
    else
        echo -e "${YELLOW}⚠ Node.js installed but requires shell restart${NC}"
    fi

    # Configure npm to avoid sudo requirements for global packages
    if command -v npm &> /dev/null; then
        echo -e "${CYAN}Configuring npm for user-local global packages...${NC}"
        npm config set prefix ~/.local
        echo -e "${YELLOW}Global npm packages will be installed to ~/.local/bin${NC}"
        echo -e "${YELLOW}Make sure ~/.local/bin is in your PATH${NC}"

        # Add to PATH if not already there
        if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
            echo -e "${GREEN}✓ ~/.local/bin added to PATH in ~/.bashrc${NC}"
        fi
    fi

    # Show versions
    node_version=$(node --version 2>/dev/null || echo "Run 'source ~/.bashrc' to activate")
    npm_version=$(npm --version 2>/dev/null || echo "Run 'source ~/.bashrc' to activate")

    echo -e "${GREEN}
=========================================================================
                        Node.js Installation Complete!
=========================================================================

Installed versions:
  Node.js: $node_version
  npm: $npm_version

Key commands:
  node --version              # Check Node.js version
  npm --version              # Check npm version
  npm install <package>      # Install package locally
  npm install -g <package>   # Install package globally
  npm init                   # Initialize new Node.js project
  npx <package>             # Run package without installing

Global packages location: ~/.local/bin/
Project-local packages: ./node_modules/

Next steps:
- Restart your terminal or run 'source ~/.bashrc'
- Use 'mise use nodejs@20' in project directories for specific versions
- Try 'npm init' to create a new Node.js project
- Install global tools: 'npm install -g typescript nodemon'

Version management with Mise:
  mise install nodejs@18     # Install specific version
  mise use nodejs@18         # Use version in current project
  mise ls nodejs             # List available versions
${NC}"

else
    echo -e "${RED}✗ Failed to install Node.js via Mise${NC}"
    echo -e "${YELLOW}Trying fallback installation via pacman...${NC}"
    if install_with_retries nodejs npm; then
        echo -e "${GREEN}✓ Node.js installed via pacman${NC}"
    else
        echo -e "${RED}✗ Failed to install Node.js${NC}"
        exit 1
    fi
fi

wait_for_input

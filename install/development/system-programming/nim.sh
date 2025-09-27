#!/bin/bash
# Nim Programming Language Installation
# Efficient, expressive, elegant programming language

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/../..}/install/system/common-funcs.sh"

show_banner "Nim Programming Language"

echo -e "${BLUE}Nim - Efficient, expressive, elegant${NC}"
echo -e "${YELLOW}Installing via Mise for better version management${NC}"
echo ""

if ! archer_confirm_or_default "Install Nim via Mise?"; then
  echo -e "${YELLOW}Nim installation cancelled.${NC}"
  return 0
fi

# Check if Mise is installed
if ! command -v mise &> /dev/null; then
    echo -e "${YELLOW}Mise not found. Installing Mise first...${NC}"
    if ! install_with_retries mise; then
        echo -e "${YELLOW}Installing Mise via curl...${NC}"
        curl https://mise.run | sh
        echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc
        eval "$(~/.local/bin/mise activate bash)"
    fi
fi

# Initialize mise for current session
eval "$(mise activate bash)" 2>/dev/null || true

echo -e "${BLUE}Installing Nim via Mise...${NC}"

if mise plugin add nim && mise install nim@latest; then
    echo -e "${GREEN}✓ Nim installed successfully!${NC}"

    # Show version
    nim_version=$(nim --version 2>/dev/null | head -1 || echo "Not available")

    echo -e "${GREEN}
=========================================================================
                        Nim Installation Complete!
=========================================================================

Installed version:
  $nim_version

Key commands:
  nim --version            # Check Nim version
  nim c app.nim           # Compile to executable
  nim c -r app.nim        # Compile and run
  nim js app.nim          # Compile to JavaScript
  nim cpp app.nim         # Compile to C++
  nimble init             # Initialize new project
  nimble build            # Build project
  nimble install <pkg>    # Install package

Package manager (Nimble):
  nimble search <term>     # Search packages
  nimble list              # List installed packages
  nimble upgrade           # Upgrade packages

Project structure:
  myproject/
  ├── myproject.nimble     # Project configuration
  ├── src/                 # Source files
  │   └── myproject.nim   # Main module
  └── tests/              # Test files

Hello World example:
  echo 'echo \"Hello, Nim!\"' > hello.nim
  nim c -r hello.nim

Language features:
- Python-like syntax with C-like performance
- Compile-time execution
- Memory management (GC, manual, or ARC/ORC)
- Macro system for metaprogramming
- Cross-platform compilation
- Multiple backends (C, C++, JavaScript, LLVM)

Next steps:
- Restart your terminal or run 'source ~/.bashrc'
- Try 'nimble init myproject' to create a new project
- Use 'mise use nim@1.6.14' in project directories for specific versions

Documentation: https://nim-lang.org/docs/
Package registry: https://nimble.directory/
${NC}"

else
    echo -e "${RED}✗ Failed to install Nim via Mise${NC}"
    echo -e "${YELLOW}Trying fallback installation via pacman...${NC}"
    if install_with_retries nim; then
        echo -e "${GREEN}✓ Nim installed via pacman${NC}"
  else
    echo -e "${RED}✗ Failed to install Nim${NC}"
    archer_die "Failed to install Nim via pacman fallback"
  fi
fi

wait_for_input

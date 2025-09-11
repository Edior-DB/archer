#!/bin/bash
# LDC (LLVM-based D Compiler) Installation
# High-performance D compiler based on LLVM backend

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/../..}/install/system/common-funcs.sh"

show_banner "LDC (LLVM D Compiler)"

echo -e "${BLUE}LDC - LLVM-based D compiler for high performance${NC}"
echo -e "${YELLOW}Installing LDC with development tools${NC}"
echo ""

if ! confirm_action "Install LDC (LLVM D Compiler)?"; then
    echo -e "${YELLOW}LDC installation cancelled.${NC}"
    exit 0
fi

echo -e "${BLUE}Installing LDC and D development tools...${NC}"

# LDC and D tools packages - prioritize AUR for newer LDC
aur_packages=("ldc")    # Newer LDC from AUR
pacman_packages=("dtools" "dub" "llvm")  # Supporting tools from official repos

# Try AUR first for newer LDC
if install_with_retries yay "${aur_packages[@]}"; then
    echo -e "${GREEN}✓ LDC installed from AUR!${NC}"

    # Install supporting tools from pacman
    if install_with_retries "${pacman_packages[@]}"; then
        echo -e "${GREEN}✓ LDC development tools installed!${NC}"
    else
        echo -e "${YELLOW}Warning: Could not install some supporting tools${NC}"
    fi
else
    echo -e "${YELLOW}AUR installation failed, trying pacman fallback...${NC}"
    # Fallback to pacman (older but stable LDC)
    if install_with_retries ldc "${pacman_packages[@]}"; then
        echo -e "${GREEN}✓ LDC installed from pacman (may be older version)!${NC}"
    else
        echo -e "${RED}✗ Failed to install LDC from both AUR and pacman${NC}"
        exit 1
    fi
fi

    # Show versions
    ldc_version=$(ldc2 --version 2>/dev/null | head -1 || echo "Not available")
    dub_version=$(dub --version 2>/dev/null || echo "Not available")

    echo -e "${GREEN}
=========================================================================
                        LDC Installation Complete!
=========================================================================

Installed version:
  $ldc_version
  DUB: $dub_version

Key commands:
  ldc2 app.d              # Compile with LDC (optimized)
  ldc2 -O3 app.d          # Maximum optimization
  ldc2 -g app.d           # Debug build
  ldc2 -betterC app.d     # Compile without D runtime
  dub init myproject      # Create new D project
  dub build               # Build current project
  dub run                 # Build and run
  dub test                # Run tests

LDC-specific features:
  ldc2 -flto=full app.d   # Link-time optimization
  ldc2 -mcpu=native app.d # Optimize for current CPU
  ldc2 -mtriple=...       # Cross-compilation

Package manager (DUB):
  dub add <package>        # Add dependency
  dub search <term>        # Search packages
  dub upgrade              # Upgrade dependencies

Example project structure:
  myproject/
  ├── dub.json             # Project configuration
  ├── source/              # Source files
  │   └── app.d           # Main application
  └── tests/              # Unit tests

Hello World example:
  echo 'import std.stdio; void main() { writeln(\"Hello from LDC!\"); }' > hello.d
  ldc2 hello.d && ./hello

Performance optimization:
  ldc2 -O3 -release -flto=full -mcpu=native app.d    # Maximum performance

Cross-compilation examples:
  ldc2 -mtriple=x86_64-pc-windows-msvc app.d        # Windows
  ldc2 -mtriple=aarch64-linux-gnu app.d             # ARM64 Linux

Why LDC?
- LLVM backend provides excellent optimization
- Better performance than DMD for production code
- Cross-compilation support
- Compatible with DMD frontend
- Active development and community

Documentation: https://wiki.dlang.org/LDC
D Language: https://dlang.org/
Package registry: https://code.dlang.org/
${NC}"

else
    echo -e "${RED}✗ Failed to install LDC${NC}"
    exit 1
fi

wait_for_input

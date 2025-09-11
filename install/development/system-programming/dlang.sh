#!/bin/bash
# DMD (D Reference Compiler) Installation
# Reference implementation of the D programming language

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/../..}/install/system/common-funcs.sh"

show_banner "DMD (D Reference Compiler)"

echo -e "${BLUE}DMD - D language reference compiler${NC}"
echo -e "${YELLOW}Installing DMD with D tools and package manager${NC}"
echo ""

if ! confirm_action "Install DMD (D Reference Compiler)?"; then
    echo -e "${YELLOW}DMD installation cancelled.${NC}"
    exit 0
fi

echo -e "${BLUE}Installing DMD and D development tools...${NC}"

# DMD and D tools packages - use AUR for modern DMD v2
aur_packages=("dlang")  # DMD v2 from AUR
pacman_packages=("dtools" "dub")  # D tools from official repos

# Install DMD v2 from AUR first
if install_with_retries yay "${aur_packages[@]}"; then
    echo -e "${GREEN}✓ DMD v2 (dlang) installed from AUR!${NC}"

    # Install D tools from pacman
    if install_with_retries "${pacman_packages[@]}"; then
        echo -e "${GREEN}✓ D development tools installed!${NC}"
    else
        echo -e "${YELLOW}Warning: Could not install some D tools, but DMD v2 is available${NC}"
    fi
else
    echo -e "${RED}✗ Failed to install DMD v2 from AUR${NC}"
    echo -e "${YELLOW}Note: DMD v2 requires AUR access. Install yay or paru first.${NC}"
    echo -e "${YELLOW}Pacman only has DMD v1 which is outdated.${NC}"
    exit 1
fi

    # Show versions
    dmd_version=$(dmd --version 2>/dev/null | head -1 || echo "Not available")
    dub_version=$(dub --version 2>/dev/null || echo "Not available")

    echo -e "${GREEN}
=========================================================================
                        DMD Installation Complete!
=========================================================================

Installed version:
  $dmd_version
  DUB: $dub_version

Key commands:
  dmd app.d                # Compile with DMD
  dmd -run app.d          # Compile and run directly
  dmd -g app.d            # Debug build
  dmd -O app.d            # Optimized build
  dub init myproject      # Create new D project
  dub build               # Build current project
  dub run                 # Build and run
  dub test                # Run tests

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
  echo 'import std.stdio; void main() { writeln(\"Hello, D!\"); }' > hello.d
  dmd hello.d && ./hello

Why DMD?
- Reference implementation with latest language features
- Fast compilation for development
- Official D compiler from D Language Foundation
- Best compatibility with D language specifications
- Excellent for learning and development

For production builds, consider LDC for better optimization.

Documentation: https://dlang.org/
Package registry: https://code.dlang.org/
${NC}"

else
    echo -e "${RED}✗ Failed to install DMD${NC}"
    exit 1
fi

wait_for_input

#!/bin/bash
# Zig Programming Language Installation
# General-purpose programming language and toolchain for maintaining robust, optimal, and reusable software

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/../..}/install/system/common-funcs.sh"

show_banner "Zig Programming Language"

echo -e "${BLUE}Zig - General-purpose programming language${NC}"
echo -e "${YELLOW}Installing via Mise for better version management${NC}"
echo ""

if ! confirm_action "Install Zig via Mise?"; then
    echo -e "${YELLOW}Zig installation cancelled.${NC}"
    exit 0
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

echo -e "${BLUE}Installing Zig via Mise...${NC}"

if mise install zig@latest; then
    echo -e "${GREEN}✓ Zig installed successfully!${NC}"

    # Show version
    zig_version=$(zig version 2>/dev/null || echo "Not available")

    echo -e "${GREEN}
=========================================================================
                        Zig Installation Complete!
=========================================================================

Installed version:
  $zig_version

Key commands:
  zig version             # Check Zig version
  zig run file.zig        # Run Zig file directly
  zig build-exe file.zig  # Build executable
  zig build-lib file.zig  # Build library
  zig test file.zig       # Run tests
  zig fmt file.zig        # Format code
  zig init-exe            # Initialize executable project
  zig init-lib            # Initialize library project
  zig build               # Build project with build.zig

Cross compilation:
  zig build-exe -target x86_64-windows file.zig    # Windows 64-bit
  zig build-exe -target aarch64-linux file.zig     # ARM64 Linux
  zig build-exe -target wasm32-wasi file.zig       # WebAssembly

Project structure:
  myproject/
  ├── build.zig           # Build configuration
  ├── src/
  │   └── main.zig       # Main source file
  └── zig-out/           # Build output

Hello World example:
  echo 'const std = @import(\"std\"); pub fn main() void { std.debug.print(\"Hello, Zig!\\\n\", .{}); }' > hello.zig
  zig run hello.zig

Language features:
- No hidden memory allocations
- No undefined behavior
- Compile-time code execution
- Manual memory management with safety
- C interoperability without FFI
- Cross-compilation out of the box
- Built-in testing framework
- Comptime (compile-time) programming

Cross-compilation targets:
  zig targets             # List all supported targets

Next steps:
- Restart your terminal or run 'source ~/.bashrc'
- Try 'zig init-exe myproject' to create a new project
- Use 'mise use zig@0.11.0' in project directories for specific versions

Documentation: https://ziglang.org/documentation/
Learn: https://ziglearn.org/
${NC}"

else
    echo -e "${RED}✗ Failed to install Zig via Mise${NC}"
    echo -e "${YELLOW}Trying fallback installation via pacman...${NC}"
    if install_with_retries zig; then
        echo -e "${GREEN}✓ Zig installed via pacman${NC}"
    else
        echo -e "${RED}✗ Failed to install Zig${NC}"
        exit 1
    fi
fi

wait_for_input

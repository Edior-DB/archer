#!/bin/bash
# V Language Installation
# Simple, fast, safe, compiled language for developing maintainable software

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/../..}/install/system/common-funcs.sh"

show_banner "V Programming Language"

echo -e "${BLUE}V Language - Simple, fast, safe, compiled${NC}"
echo -e "${YELLOW}Installing from source (manual build)${NC}"
echo ""

if ! archer_confirm_or_default "Install V language?"; then
  echo -e "${YELLOW}V language installation cancelled.${NC}"
  exit 0
fi

# Install dependencies
echo -e "${BLUE}Installing build dependencies...${NC}"
dependencies=(
    "git"
    "gcc"
    "make"
)

if ! install_with_retries "${dependencies[@]}"; then
    echo -e "${RED}✗ Failed to install dependencies${NC}"
    exit 1
fi

echo -e "${BLUE}Cloning and building V language...${NC}"

# Create temporary directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

if sudo git clone --depth=1 https://github.com/vlang/v /opt/vlang; then

    sudo chown -R "$USER":"$USER" /opt/vlang
    sudo chgroup -R "$USER" /opt/vlang

    cd /opt/vlang

    echo -e "${BLUE}Building V compiler...${NC}"
    if make; then
        echo -e "${BLUE}Installing V to /usr/local/bin...${NC}"
        if sudo v symlink; then
            echo -e "${GREEN}✓ V language installed successfully!${NC}"
        else
            echo -e "${RED}✗ Failed to install V binary${NC}"
            cd ~ && rm -rf "$TEMP_DIR"
            exit 1
        fi
    else
        echo -e "${RED}✗ Failed to build V compiler${NC}"
        cd ~ && rm -rf "$TEMP_DIR"
        exit 1
    fi
else
    echo -e "${RED}✗ Failed to clone V repository${NC}"
    cd ~ && rm -rf "$TEMP_DIR"
    exit 1
fi

# Cleanup
cd ~ && rm -rf "$TEMP_DIR"

# Show version and information
v_version=$(v version 2>/dev/null || echo "Not available")

echo -e "${GREEN}
=========================================================================
                        V Language Installation Complete!
=========================================================================

Installed version:
  $v_version

Key commands:
  v version               # Check V version
  v run file.v           # Run V file directly
  v file.v               # Compile to executable
  v -prod file.v         # Production build (optimized)
  v -shared file.v       # Compile to shared library
  v new myproject        # Create new project
  v test .               # Run tests
  v fmt .                # Format code

Project structure:
  myproject/
  ├── v.mod              # Module file
  ├── main.v             # Main file
  └── src/               # Source files

Hello World example:
  echo 'fn main() { println(\"Hello, V!\") }' > hello.v
  v run hello.v

Language features:
- No null, no undefined behavior, no variable shadowing
- Immutable variables by default
- Pure functions by default
- Compile-time memory management (no GC)
- Fast compilation (< 1s for most programs)
- Cross compilation
- Built-in testing framework
- Hot code reloading

Module management:
  v install <module>      # Install module
  v update               # Update modules
  v list                 # List installed modules

Documentation: https://vlang.io/
Modules: https://vpm.vlang.io/
${NC}"

wait_for_input

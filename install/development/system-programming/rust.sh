#!/bin/bash
# Rust Programming Language Installation
# Memory-safe systems programming language

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/../..}/install/system/common-funcs.sh"

show_banner "Rust Programming Language"

echo -e "${BLUE}Rust - A language empowering everyone to build reliable and efficient software${NC}"
echo -e "${YELLOW}Installing via Mise for better version management${NC}"
echo ""

if ! confirm_action "Install Rust via Mise?"; then
    echo -e "${YELLOW}Rust installation cancelled.${NC}"
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

echo -e "${BLUE}Installing Rust via Mise...${NC}"

if mise install rust@latest; then
    echo -e "${GREEN}✓ Rust installed successfully!${NC}"

    # Show versions
    rustc_version=$(rustc --version 2>/dev/null || echo "Not available")
    cargo_version=$(cargo --version 2>/dev/null || echo "Not available")

    echo -e "${GREEN}
=========================================================================
                        Rust Installation Complete!
=========================================================================

Installed versions:
  Rust compiler: $rustc_version
  Cargo package manager: $cargo_version

Key commands:
  rustc --version           # Check Rust compiler version
  cargo --version          # Check Cargo version
  cargo new my_project     # Create new Rust project
  cargo build              # Build current project
  cargo run                # Build and run current project
  cargo test               # Run tests
  cargo install <crate>    # Install Rust package globally

Useful global tools to install:
  cargo install cargo-edit       # Add 'cargo add' command
  cargo install cargo-watch      # Auto-rebuild on file changes
  cargo install cargo-expand     # Show macro expansions
  cargo install ripgrep          # Fast grep alternative
  cargo install fd-find          # Fast find alternative
  cargo install bat              # Better cat with syntax highlighting

Next steps:
- Restart your terminal or run 'source ~/.bashrc'
- Try 'cargo new hello_world && cd hello_world && cargo run'
- Use 'mise use rust@1.75' in project directories for specific versions
- Explore the Rust ecosystem at crates.io

Version management with Mise:
  mise install rust@1.75     # Install specific version
  mise use rust@1.75         # Use version in current project
  mise ls rust               # List available versions

Documentation: https://doc.rust-lang.org/
${NC}"

else
    echo -e "${RED}✗ Failed to install Rust via Mise${NC}"
    echo -e "${YELLOW}Trying fallback installation via rustup...${NC}"
    if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; then
        source ~/.cargo/env
        echo -e "${GREEN}✓ Rust installed via rustup${NC}"
        echo 'source ~/.cargo/env' >> ~/.bashrc
    else
        echo -e "${RED}✗ Failed to install Rust${NC}"
        exit 1
    fi
fi

wait_for_input

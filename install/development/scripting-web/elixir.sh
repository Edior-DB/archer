#!/usr/bin/env bash
# Elixir Programming Language Installation
# Dynamic, functional language for building maintainable applications

set -euo pipefail

# Source common functions
source "${ARCHER_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}/install/system/common-funcs.sh"

show_banner "Elixir Programming Language"

echo -e "${BLUE}Elixir - Dynamic, functional language built on Erlang VM${NC}"
echo -e "${YELLOW}Installing Erlang and Elixir via Mise for better version management${NC}"
echo

if ! archer_confirm_or_default "Install Elixir and Erlang via Mise?"; then
  echo -e "${YELLOW}Elixir installation cancelled.${NC}"
  return 0
fi

# Ensure mise is available
if ! command -v mise &>/dev/null; then
  echo -e "${YELLOW}Mise not found. Installing Mise...${NC}"
  if ! install_with_retries mise; then
    echo -e "${YELLOW}Falling back to curl installer for Mise...${NC}"
    if ! curl -fsSL https://mise.run | sh; then
      archer_die "Failed to install Mise"
    fi
    if [ -f "${HOME}/.local/bin/mise" ]; then
      eval "$(~/.local/bin/mise activate bash)" || true
    fi
  fi
fi

# Try to activate mise for current session
eval "$(mise activate bash)" 2>/dev/null || true

echo -e "${BLUE}Installing Erlang (required for Elixir)...${NC}"

if ! mise install erlang@latest; then
  echo -e "${YELLOW}Failed to install Erlang with Mise, trying system package manager...${NC}"
  if ! install_with_retries erlang; then
    archer_die "Failed to install Erlang required for Elixir"
  fi
else
  mise use -g erlang@latest || true
fi

echo -e "${BLUE}Installing Elixir...${NC}"

if ! mise install elixir@latest; then
  echo -e "${YELLOW}Failed to install Elixir with Mise, trying system package manager...${NC}"
  if install_with_retries elixir; then
    echo -e "${GREEN}✓ Elixir installed via system package manager!${NC}"
  else
    archer_die "Failed to install Elixir"
  fi
else
  echo -e "${GREEN}✓ Elixir installed successfully!${NC}"
  mise use -g elixir@latest || true
fi

# Show versions and status
erlang_version=$(erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell 2>/dev/null || echo "Not available")
elixir_version=$(elixir --version 2>/dev/null | head -n1 || echo "Not available")
hex_status="Available with mix"
if command -v mix &>/dev/null; then
  hex_status="Available"
fi

cat <<EOF
${GREEN}
=====================================================================
                      Elixir Installation Complete!
=====================================================================

Installed versions:
  Erlang/OTP: $erlang_version
  $elixir_version
  Hex package manager: $hex_status

Key commands:
  elixir script.exs          # Run Elixir script
  iex                        # Interactive Elixir shell
  mix new project_name       # Create new Mix project
  mix deps.get               # Install dependencies
  mix compile                # Compile project
  mix test                   # Run tests
  mix run                    # Run application

For more info see: https://elixir-lang.org/
EOF

echo
if archer_confirm_or_default "Install Phoenix web framework?"; then
  echo -e "${BLUE}Installing Phoenix framework...${NC}"
  if mix archive.install hex phx_new --force; then
    echo -e "${GREEN}✓ Phoenix framework installed successfully!${NC}"
    echo -e "${YELLOW}Create a new Phoenix app with: mix phx.new my_app${NC}"
  else
    echo -e "${YELLOW}Failed to install Phoenix via mix archive. You can install it manually later.${NC}"
  fi
fi

wait_for_input

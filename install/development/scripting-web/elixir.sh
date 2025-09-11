#!/bin/bash
# Elixir Programming Language Installation
# Dynamic, functional language for building maintainable applications

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/../..}/install/system/common-funcs.sh"

show_banner "Elixir Programming Language"

echo -e "${BLUE}Elixir - Dynamic, functional language built on Erlang VM${NC}"
echo -e "${YELLOW}Installing Erlang and Elixir via Mise for better version management${NC}"
echo ""

if ! confirm_action "Install Elixir and Erlang via Mise?"; then
    echo -e "${YELLOW}Elixir installation cancelled.${NC}"
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

# Install Erlang first (required for Elixir)
echo -e "${BLUE}Installing Erlang (required for Elixir)...${NC}"

if mise install erlang@latest; then
    echo -e "${GREEN}✓ Erlang installed successfully!${NC}"
    mise use -g erlang@latest
else
    echo -e "${RED}✗ Failed to install Erlang${NC}"
    echo -e "${YELLOW}Trying system package manager...${NC}"
    if ! install_with_retries erlang; then
        echo -e "${RED}Failed to install Erlang. Cannot proceed with Elixir installation.${NC}"
        exit 1
    fi
fi

# Install Elixir
echo -e "${BLUE}Installing Elixir...${NC}"

if mise install elixir@latest; then
    echo -e "${GREEN}✓ Elixir installed successfully!${NC}"
    mise use -g elixir@latest

    # Show version and information
    erlang_version=$(erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell 2>/dev/null || echo "Not available")
    elixir_version=$(elixir --version 2>/dev/null | grep "Elixir" || echo "Not available")
    hex_status="Available with mix"

    # Check if mix is available (should come with Elixir)
    if command -v mix &>/dev/null; then
        hex_status="Available"
    fi

    echo -e "${GREEN}
=========================================================================
                        Elixir Installation Complete!
=========================================================================

Installed versions:
  Erlang/OTP: $erlang_version
  $elixir_version
  Hex package manager: $hex_status

Key commands:
  elixir script.exs          # Run Elixir script
  iex                        # Interactive Elixir shell
  mix new project_name       # Create new Mix project
  mix deps.get              # Install dependencies
  mix compile               # Compile project
  mix test                  # Run tests
  mix run                   # Run application

Mix (Elixir build tool):
  mix new myapp             # Create new application
  mix new myapp --sup       # Create with supervisor tree
  mix deps.get              # Install dependencies
  mix compile               # Compile code
  mix test                  # Run tests
  mix run -e \"Code.here\"    # Execute code
  mix phx.new webapp        # Create Phoenix web app (after installing)

Hex (Package manager):
  mix hex.info              # Hex information
  mix deps.get              # Install dependencies from mix.exs
  mix hex.docs              # Generate docs

Common Elixir files:
  mix.exs                   # Project configuration
  lib/                      # Library code
  test/                     # Test files
  config/                   # Configuration files
  .exs                      # Elixir script files
  .ex                       # Elixir module files

Hello World example:
  echo 'IO.puts \"Hello, Elixir World!\"' > hello.exs
  elixir hello.exs

Mix project example:
  mix new hello_world
  cd hello_world
  mix compile
  mix run -e \"HelloWorld.hello\"

IEx (Interactive Elixir) examples:
  iex> 1 + 2
  iex> \"Hello\" <> \" World\"
  iex> [1, 2, 3] |> Enum.map(&(&1 * 2))
  iex> h Enum.map          # Help for functions

Phoenix web framework:
  mix archive.install hex phx_new
  mix phx.new my_web_app
  cd my_web_app
  mix deps.get
  mix phx.server

Elixir strengths:
  - Fault-tolerant systems
  - Concurrent programming
  - Real-time applications
  - Distributed systems
  - Web applications with Phoenix
  - IoT and embedded systems

OTP (Open Telecom Platform):
  - Actor model with processes
  - Supervisor trees for fault tolerance
  - GenServer for stateful processes
  - GenStage for data pipelines

Popular libraries:
  - Phoenix: Web framework
  - Ecto: Database wrapper
  - Plug: Web application interface
  - GenStage: Data processing pipelines
  - Broadway: Data ingestion

Elixir configuration:
  - Use 'mise use erlang@26.0 elixir@1.15.0' for specific versions
  - Environment variables in config files
  - Use .tool-versions file for project-specific versions

Documentation: https://elixir-lang.org/
Package repository: https://hex.pm/
Phoenix framework: https://phoenixframework.org/
${NC}"

    # Suggest Phoenix installation
    echo ""
    if confirm_action "Install Phoenix web framework?"; then
        echo -e "${BLUE}Installing Phoenix framework...${NC}"
        mix archive.install hex phx_new --force
        echo -e "${GREEN}✓ Phoenix framework installed successfully!${NC}"
        echo -e "${YELLOW}Create a new Phoenix app with: mix phx.new my_app${NC}"
    fi

else
    echo -e "${RED}✗ Failed to install Elixir via Mise${NC}"
    echo -e "${YELLOW}Trying system package manager...${NC}"

    if install_with_retries elixir; then
        echo -e "${GREEN}✓ Elixir installed via system package manager!${NC}"
    else
        echo -e "${RED}✗ Failed to install Elixir${NC}"
        echo -e "${YELLOW}You can try manual installation from https://elixir-lang.org/install.html${NC}"
        exit 1
    fi
fi

wait_for_input

#!/bin/bash
# Julia Programming Language Installation
# High-performance scientific computing language

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/../..}/install/system/common-funcs.sh"

show_banner "Julia Programming Language"

echo -e "${BLUE}Julia - High-performance dynamic programming language for technical computing${NC}"
echo -e "${YELLOW}Trying installation via Mise, with fallback to official installer${NC}"
echo ""

if ! archer_confirm_or_default "Install Julia programming language?"; then
  echo -e "${YELLOW}Julia installation cancelled.${NC}"
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

echo -e "${BLUE}Installing Julia via Mise...${NC}"

if mise plugin add julia && mise install julia@latest; then
    echo -e "${GREEN}✓ Julia installed successfully via Mise!${NC}"
    julia_source="Mise"
else
    echo -e "${YELLOW}Mise installation failed, trying official installer...${NC}"
    if curl -fsSL https://install.julialang.org | sh; then
        echo -e "${GREEN}✓ Julia installed via official installer!${NC}"
        julia_source="Official Installer"
        # Add to PATH
        export PATH="$HOME/.juliaup/bin:$PATH"
        echo 'export PATH="$HOME/.juliaup/bin:$PATH"' >> ~/.bashrc
    else
        echo -e "${RED}✗ Failed to install Julia${NC}"
        exit 1
    fi
fi

# Show version
julia_version=$(julia --version 2>/dev/null || echo "Not available")

echo -e "${GREEN}
=========================================================================
                        Julia Installation Complete!
=========================================================================

Installation method: $julia_source
Installed version: $julia_version

Key commands:
  julia                    # Start Julia REPL
  julia script.jl          # Run Julia script
  julia -e \"println('Hello')\"  # Execute Julia code

Package management:
  julia> ]                 # Enter package mode
  pkg> add Package         # Install package
  pkg> status              # List installed packages
  pkg> update              # Update packages

Popular packages to try:
  Plots.jl                 # Plotting library
  DataFrames.jl            # Data manipulation
  CSV.jl                   # CSV file handling
  HTTP.jl                  # HTTP client/server
  BenchmarkTools.jl        # Performance benchmarking

Example usage:
  julia> using Pkg
  julia> Pkg.add(\"Plots\")
  julia> using Plots
  julia> plot(sin, 0, 2π)

Next steps:
- Restart your terminal or run 'source ~/.bashrc'
- Try the Julia REPL: type 'julia'
- Explore packages at juliahub.com
- Learn Julia at julialang.org/learning/

REPL tips:
  ? help                   # Enter help mode
  ; shell                  # Enter shell mode
  ] pkg                    # Enter package mode
  Ctrl+D                   # Exit Julia

Documentation: https://docs.julialang.org/
${NC}"

wait_for_input

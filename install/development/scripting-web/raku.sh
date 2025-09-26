#!/bin/bash
# Raku Programming Language Installation
# Modern, gradually typed language (formerly Perl 6)

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/../..}/install/system/common-funcs.sh"

show_banner "Raku Programming Language"

echo -e "${BLUE}Raku - Modern, gradually typed programming language${NC}"
echo -e "${YELLOW}Installing via Mise (if available) or system package manager${NC}"
echo ""

# if ! confirm_action "Install Raku?"; then
#     echo -e "${YELLOW}Raku installation cancelled.${NC}"
#     exit 0
# fi

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

echo -e "${BLUE}Attempting to install Raku via Mise...${NC}"

# Try Mise first
raku_installed=false

# Add Raku plugin if not already added
if ! mise plugin list | grep -q raku; then
    echo -e "${YELLOW}Adding Raku plugin to Mise...${NC}"
    if mise plugin add raku; then
        echo -e "${GREEN}✓ Raku plugin added successfully${NC}"
    else
        echo -e "${YELLOW}Raku plugin not available in Mise, trying system installation...${NC}"
    fi
fi

if mise plugin list | grep -q raku && mise install raku@latest; then
    echo -e "${GREEN}✓ Raku installed via Mise successfully!${NC}"
    mise use -g raku@latest
    raku_installed=true
else
    echo -e "${YELLOW}Mise installation failed, trying system package manager...${NC}"

    # Try system package manager
    if install_with_retries rakudo; then
        echo -e "${GREEN}✓ Raku (Rakudo) installed via system package manager!${NC}"
        raku_installed=true
    else
        echo -e "${YELLOW}System installation failed, trying AUR...${NC}"
        if install_with_retries yay rakudo; then
            echo -e "${GREEN}✓ Raku (Rakudo) installed via AUR!${NC}"
            raku_installed=true
        fi
    fi
fi

if [ "$raku_installed" = true ]; then
    # Show version and information
    raku_version=$(raku --version 2>/dev/null | head -1 || echo "Not available")
    zef_status="Not installed"

    # Check if zef (Raku package manager) is available
    if command -v zef &>/dev/null; then
        zef_status=$(zef --version 2>/dev/null || echo "Available")
    fi

    echo -e "${GREEN}
=========================================================================
                        Raku Installation Complete!
=========================================================================

Installed version:
  $raku_version
  Zef (package manager): $zef_status

Key commands:
  raku script.raku           # Run Raku script
  raku -e 'say \"Hello\"'     # Execute one-liner
  raku -c script.raku        # Check syntax
  raku --doc script.raku     # Extract documentation

Alternative commands:
  perl6 script.p6            # Legacy name (if available)
  rakudo script.raku         # Direct interpreter call

Zef (Raku package manager):
  zef install Module::Name   # Install module
  zef search pattern         # Search for modules
  zef list --installed       # List installed modules
  zef update                 # Update installed modules

Common Raku files:
  script.raku               # Modern extension
  script.rakumod            # Module file
  script.p6                 # Legacy extension
  META6.json                # Project metadata

Hello World example:
  echo 'say \"Hello, Raku World!\";' > hello.raku
  raku hello.raku

Raku features showcase:
  # Gradual typing
  my Int \$number = 42;
  my Str \$text = \"Hello\";

  # Unicode support
  say \"π ≈ \"; say π;

  # Pattern matching
  given \$value {
      when Int { say \"It's an integer\" }
      when Str { say \"It's a string\" }
  }

  # Concurrent programming
  my \$promise = start { expensive-computation() };
  say await \$promise;

Advanced features:
  - Gradual typing system
  - Built-in concurrency primitives
  - Powerful regex and grammar system
  - Unicode support throughout
  - Multiple dispatch
  - Roles and mixins

Popular use cases:
  - Text processing and parsing
  - Concurrent applications
  - Scientific computing
  - Web development
  - System administration

Raku vs Perl:
  - Raku is the successor to Perl
  - More modern syntax and features
  - Better Unicode and concurrency support
  - Gradual typing system
  - Both languages coexist independently

Documentation: https://docs.raku.org/
Package repository: https://raku.land/
${NC}"

    # Suggest zef installation if not available
    if ! command -v zef &>/dev/null; then
        echo ""
        echo -e "${YELLOW}Note: Zef package manager should be included with Raku installation${NC}"
        echo -e "${YELLOW}If zef is not available, you may need to install it separately${NC}"
    fi

else
    echo -e "${RED}✗ Failed to install Raku${NC}"
    echo -e "${YELLOW}Raku installation can be complex. You can try:${NC}"
    echo -e "${CYAN}1. Manual installation from https://rakudo.org/downloads${NC}"
    echo -e "${CYAN}2. Using rakubrew: curl https://rakubrew.org/install-on-perl.sh | sh${NC}"
    echo -e "${CYAN}3. Docker: docker run -it rakudo/star${NC}"
    exit 1
fi

wait_for_input

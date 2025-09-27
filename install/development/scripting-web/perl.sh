#!/bin/bash
# Perl Programming Language Installation
# Practical Extraction and Reporting Language

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/../..}/install/system/common-funcs.sh"

show_banner "Perl Programming Language"

echo -e "${BLUE}Perl - Practical text processing and system administration language${NC}"
echo -e "${YELLOW}Installing via Mise for better version management${NC}"
echo ""

if ! archer_confirm_or_default "Install Perl via Mise?"; then
  echo -e "${YELLOW}Perl installation cancelled.${NC}"
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

echo -e "${BLUE}Installing Perl via Mise...${NC}"

# Add Perl plugin if not already added
if ! mise plugin list | grep -q perl; then
    echo -e "${YELLOW}Adding Perl plugin to Mise...${NC}"
    mise plugin add perl
fi

if mise install perl@latest; then
    echo -e "${GREEN}✓ Perl installed successfully!${NC}"

    # Set as global default
    mise use -g perl@latest

    # Show version and information
    perl_version=$(perl --version 2>/dev/null | grep "This is perl" | head -1 || echo "Not available")
    cpan_status="Available"

    # Check if cpanm is available
    if command -v cpanm &>/dev/null; then
        cpan_status="cpanm available"
    fi

    echo -e "${GREEN}
=========================================================================
                        Perl Installation Complete!
=========================================================================

Installed version:
  $perl_version
  CPAN: $cpan_status

Key commands:
  perl -v                    # Check Perl version
  perl script.pl             # Run Perl script
  perl -e 'print \"Hello\"'   # Execute one-liner
  perl -c script.pl          # Check syntax
  perl -d script.pl          # Debug script

CPAN (Perl package manager):
  cpan Module::Name          # Install module via CPAN
  cpanm Module::Name         # Install via cpanminus (faster)
  perl -MCPAN -e shell       # CPAN shell

Common Perl files:
  script.pl                  # Perl script
  .pm                        # Perl module
  Makefile.PL               # Build configuration

Hello World example:
  echo 'print \"Hello, Perl World!\\n\";' > hello.pl
  perl hello.pl

Useful one-liners:
  perl -pe 's/old/new/g' file.txt        # Replace text
  perl -lane 'print \$F[0]' file.txt      # Print first column
  perl -e 'print join(\"\\n\", 1..10)'    # Print numbers 1-10
  perl -pi -e 's/foo/bar/g' *.txt        # Replace in multiple files

Popular modules:
  - DBI: Database interface
  - Moose: Modern object-oriented programming
  - Catalyst: Web framework
  - Template Toolkit: Template processing
  - DateTime: Date and time handling

Text processing strengths:
  - Regular expressions
  - File handling
  - System administration
  - Bioinformatics
  - Log analysis

Perl configuration:
  - Use 'mise use perl@5.38.0' for specific versions
  - PERL5LIB environment variable for module paths
  - Use .tool-versions file for project-specific versions

Install cpanminus for easier module installation:
  curl -L https://cpanmin.us | perl - --sudo App::cpanminus

Documentation: https://perldoc.perl.org/
Package repository: https://metacpan.org/
${NC}"

    # Suggest cpanminus installation
    if ! command -v cpanm &>/dev/null; then
        echo ""
  if archer_confirm_or_default "Install cpanminus (faster CPAN client)?"; then
            echo -e "${BLUE}Installing cpanminus...${NC}"
            curl -L https://cpanmin.us | perl - --sudo App::cpanminus
            echo -e "${GREEN}✓ cpanminus installed successfully!${NC}"
        fi
    fi

else
  echo -e "${RED}✗ Failed to install Perl via Mise${NC}"
  echo -e "${YELLOW}Note: System Perl is usually pre-installed on Linux systems${NC}"
  echo -e "${YELLOW}You can check with: perl --version${NC}"
  archer_die "Failed to install Perl via Mise"
fi

wait_for_input

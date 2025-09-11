#!/bin/bash
# LFortran Modern Compiler Installation Script
# Installs LFortran - a modern, fast Fortran compiler

# ==============================================================================
# CONFIGURATION
# ==============================================================================
TOOL_NAME="LFortran Modern Compiler"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
ARCHER_DIR="${ARCHER_DIR:-$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")}"

# Source common functions
source "$ARCHER_DIR/install/system/common-funcs.sh"

# ==============================================================================
# INSTALLATION FUNCTIONS
# ==============================================================================

install_lfortran() {
    log_info "Installing LFortran (modern Fortran compiler)..."

    # Important warning about build time
    echo ""
    echo -e "${YELLOW}⚠️  IMPORTANT BUILD TIME WARNING ⚠️${NC}"
    echo -e "${YELLOW}LFortran installation may take 20-45 minutes or longer.${NC}"
    echo -e "${YELLOW}This is due to bison parser generation during the build process,${NC}"
    echo -e "${YELLOW}which can exceed time limits and appear to hang. This is normal.${NC}"
    echo -e "${YELLOW}Please be patient - the installation will complete successfully.${NC}"
    echo ""

    if ! confirm_action "Continue with LFortran installation (this will take a long time)?"; then
        log_info "LFortran installation cancelled by user"
        return 1
    fi

    # Check if LFortran is already installed
    if command -v lfortran &>/dev/null; then
        local version=$(lfortran --version 2>/dev/null | head -n 1 || echo "LFortran")
        log_info "LFortran already installed: $version"
        return 0
    fi

    # Check if AUR helper is available
    if command -v yay &>/dev/null; then
        log_info "Installing LFortran from AUR using yay..."
        echo -e "${CYAN}📝 Note: Build process starting - this will take considerable time...${NC}"
        install_with_retries yay lfortran-git
    elif command -v paru &>/dev/null; then
        log_info "Installing LFortran from AUR using paru..."
        echo -e "${CYAN}📝 Note: Build process starting - this will take considerable time...${NC}"
        install_with_retries paru lfortran-git
    else
        log_warning "LFortran requires an AUR helper (yay or paru)."
        log_info "Please install yay or paru first, then run this script again."
        return 1
    fi

    # Verify installation
    if command -v lfortran &>/dev/null; then
        local version=$(lfortran --version 2>/dev/null | head -n 1 || echo "LFortran")
        echo -e "${GREEN}✓ LFortran installed successfully: $version${NC}"
    else
        log_error "LFortran installation failed"
        return 1
    fi
}

setup_lfortran_environment() {
    log_info "Setting up LFortran development environment..."

    # Create example LFortran project structure
    local example_dir="$HOME/lfortran-projects"
    if [[ ! -d "$example_dir" ]]; then
        mkdir -p "$example_dir/hello-world"

        # Create simple hello world example optimized for LFortran
        cat > "$example_dir/hello-world/hello.f90" << 'EOF'
program hello
    implicit none
    print *, 'Hello from LFortran!'
    print *, 'LFortran is a modern, fast Fortran compiler'
end program hello
EOF

        # Create a more advanced example
        cat > "$example_dir/hello-world/advanced.f90" << 'EOF'
program advanced_example
    implicit none
    integer, parameter :: n = 10
    real :: numbers(n)
    integer :: i

    ! Initialize array
    do i = 1, n
        numbers(i) = real(i) * 2.5
    end do

    ! Print results
    print *, 'LFortran Advanced Example:'
    do i = 1, n
        print '(A, I2, A, F6.2)', 'numbers(', i, ') = ', numbers(i)
    end do
end program advanced_example
EOF

        # Create Makefile for LFortran
        cat > "$example_dir/hello-world/Makefile" << 'EOF'
FC = lfortran
FCFLAGS = -O2

all: hello advanced

hello: hello.f90
	$(FC) $(FCFLAGS) -o hello hello.f90

advanced: advanced.f90
	$(FC) $(FCFLAGS) -o advanced advanced.f90

clean:
	rm -f hello advanced

.PHONY: all clean
EOF

        log_info "Created LFortran example project in $example_dir/hello-world"
    fi

    # Add LFortran-specific aliases to bashrc if not present
    local bashrc="$HOME/.bashrc"
    if [[ -f "$bashrc" ]] && ! grep -q "# LFortran aliases" "$bashrc"; then
        cat >> "$bashrc" << 'EOF'

# LFortran aliases
alias lfc='lfortran -O2'
alias lfrun='lfortran -O2 -o temp && ./temp && rm temp'
EOF
        log_info "Added LFortran aliases to ~/.bashrc"
    fi
}

print_lfortran_info() {
    echo ""
    echo "=============================================="
    echo "LFortran Modern Compiler Ready!"
    echo "=============================================="
    echo ""
    echo "Installed compiler:"
    if command -v lfortran &>/dev/null; then
        echo "  • LFortran: $(lfortran --version 2>/dev/null | head -n 1 || echo 'Available')"
    fi
    echo ""
    echo "LFortran features:"
    echo "  • Fast compilation and execution"
    echo "  • Modern Fortran standards support"
    echo "  • Interactive shell (coming soon)"
    echo "  • LLVM-based backend"
    echo "  • Cross-platform compatibility"
    echo ""
    echo "Build time information:"
    echo "  • LFortran requires extensive compilation from source"
    echo "  • Parser generation with bison can take 20-45+ minutes"
    echo "  • This is a one-time cost - subsequent usage is very fast"
    echo "  • Build complexity is due to modern LLVM integration"
    echo ""
    echo "Quick start:"
    echo "  lfortran -o hello hello.f90   # Compile Fortran program"
    echo "  lfc hello.f90                 # Using alias"
    echo "  lfrun hello.f90               # Compile and run (alias)"
    echo ""
    echo "Example project: ~/lfortran-projects/hello-world"
    echo "  cd ~/lfortran-projects/hello-world && make"
    echo ""
    echo "LFortran vs GFortran:"
    echo "  • LFortran: Modern, fast compilation, LLVM-based"
    echo "  • GFortran: Mature, stable, GNU compiler collection"
    echo "  • Both can coexist and serve different purposes"
    echo ""
    echo "Documentation: https://lfortran.org/"
    echo "GitHub: https://github.com/lfortran/lfortran"
    echo ""
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

main() {
    log_info "Starting $TOOL_NAME installation..."

    # Check system requirements
    check_system_requirements

    # Install LFortran
    install_lfortran || return 1

    # Setup development environment
    setup_lfortran_environment

    # Show information
    print_lfortran_info

    echo -e "${GREEN}✓ $TOOL_NAME installation completed!${NC}"
}

# Execute main function
main "$@"

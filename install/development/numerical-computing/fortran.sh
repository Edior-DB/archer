#!/bin/bash
# Fortran Compilers Installation Script
# Installs GFortran and LFortran for Fortran development

# ==============================================================================
# CONFIGURATION
# ==============================================================================
TOOL_NAME="Fortran Compilers"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
ARCHER_DIR="${ARCHER_DIR:-$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")}"

# Source common functions
source "$ARCHER_DIR/install/system/common-funcs.sh"

# ==============================================================================
# INSTALLATION FUNCTIONS
# ==============================================================================

install_gfortran() {
    log_info "Installing GFortran compiler..."

    # Install GNU Fortran compiler
    if ! pacman -Qi gcc-fortran &>/dev/null; then
        echo -e "${BLUE}Installing GFortran...${NC}"
        install_with_retries gcc-fortran
    else
        log_info "GFortran already installed"
    fi

    # Verify installation
    if command -v gfortran &>/dev/null; then
        local version=$(gfortran --version | head -n 1)
        log_success "GFortran installed: $version"
    else
        log_error "Failed to install GFortran"
        return 1
    fi
}

install_lfortran() {
    log_info "Installing LFortran (modern Fortran compiler)..."

    # Check if available in AUR or install from source
    if command -v yay &>/dev/null; then
        echo -e "${BLUE}Installing LFortran from AUR...${NC}"
        install_with_retries yay lfortran
    else
        log_warning "LFortran requires AUR helper. Installing GFortran only."
        return 0
    fi

    # Verify installation
    if command -v lfortran &>/dev/null; then
        local version=$(lfortran --version 2>/dev/null | head -n 1 || echo "LFortran installed")
        log_success "LFortran installed: $version"
    else
        log_warning "LFortran installation may have failed, but GFortran is available"
    fi
}

setup_fortran_environment() {
    log_info "Setting up Fortran development environment..."

    # Create example Fortran project structure
    local example_dir="$HOME/fortran-projects"
    if [[ ! -d "$example_dir" ]]; then
        mkdir -p "$example_dir/hello-world"

        # Create simple hello world example
        cat > "$example_dir/hello-world/hello.f90" << 'EOF'
program hello
    implicit none
    write(*,*) 'Hello, World!'
end program hello
EOF

        # Create Makefile
        cat > "$example_dir/hello-world/Makefile" << 'EOF'
FC = gfortran
FCFLAGS = -O2 -Wall

hello: hello.f90
	$(FC) $(FCFLAGS) -o hello hello.f90

clean:
	rm -f hello

.PHONY: clean
EOF

        log_info "Created example Fortran project in $example_dir/hello-world"
    fi

    # Add helpful aliases to bashrc if not present
    local bashrc="$HOME/.bashrc"
    if [[ -f "$bashrc" ]] && ! grep -q "# Fortran aliases" "$bashrc"; then
        cat >> "$bashrc" << 'EOF'

# Fortran aliases
alias fcompile='gfortran -O2 -Wall'
alias frun='gfortran -O2 -Wall -o temp && ./temp && rm temp'
EOF
        log_info "Added Fortran aliases to ~/.bashrc"
    fi
}

print_fortran_info() {
    echo ""
    echo "=============================================="
    echo "Fortran Development Environment Ready!"
    echo "=============================================="
    echo ""
    echo "Installed compilers:"
    if command -v gfortran &>/dev/null; then
        echo "  • GFortran: $(gfortran --version | head -n 1)"
    fi
    if command -v lfortran &>/dev/null; then
        echo "  • LFortran: $(lfortran --version 2>/dev/null | head -n 1 || echo 'Available')"
    fi
    echo ""
    echo "Quick start:"
    echo "  gfortran -o hello hello.f90   # Compile Fortran program"
    echo "  fcompile hello.f90            # Using alias"
    echo "  frun hello.f90                # Compile and run (alias)"
    echo ""
    echo "Example project: ~/fortran-projects/hello-world"
    echo "  cd ~/fortran-projects/hello-world && make"
    echo ""
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

main() {
    log_info "Starting $TOOL_NAME installation..."

    # Check system requirements
    check_system_requirements

    # Install Fortran compilers
    install_gfortran || return 1
    install_lfortran  # This may fail gracefully

    # Setup development environment
    setup_fortran_environment

    # Show information
    print_fortran_info

    log_success "$TOOL_NAME installation completed!"
}

# Execute main function
main "$@"

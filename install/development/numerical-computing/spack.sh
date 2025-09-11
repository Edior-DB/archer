#!/bin/bash
# Spack HPC Package Manager Installation Script
# Installs Spack for scientific high-performance computing packages

# ==============================================================================
# CONFIGURATION
# ==============================================================================
TOOL_NAME="Spack HPC Package Manager"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
ARCHER_DIR="${ARCHER_DIR:-$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")}"

# Source common functions
source "$ARCHER_DIR/install/system/common-funcs.sh"

# ==============================================================================
# INSTALLATION FUNCTIONS
# ==============================================================================

install_spack_dependencies() {
    log_info "Installing Spack dependencies..."

    # Install required system packages
    local packages=(
        "git"              # Version control
        "python"           # Python runtime
        "python-pip"       # Python package manager
        "curl"             # Download tool
        "gcc"              # GNU compiler collection
        "make"             # Build system
        "patch"            # Patch utility
        "gawk"             # GNU awk
        "file"             # File type detection
        "which"            # Command location
        "environment-modules"  # Environment modules
    )

    for package in "${packages[@]}"; do
        if ! pacman -Qi "$package" &>/dev/null; then
            execute_with_progress "sudo pacman -S --noconfirm $package" "Installing $package..."
        fi
    done
}

install_spack() {
    log_info "Installing Spack package manager..."

    local spack_dir="$HOME/spack"

    # Check if Spack is already installed
    if [[ -d "$spack_dir" ]]; then
        log_info "Spack directory already exists, updating..."
        cd "$spack_dir"
        execute_with_progress "git pull" "Updating Spack..."
    else
        # Clone Spack repository
        execute_with_progress "git clone -c feature.manyFiles=true https://github.com/spack/spack.git '$spack_dir'" "Cloning Spack repository..."
    fi

    # Verify installation
    if [[ -f "$spack_dir/bin/spack" ]]; then
        log_success "Spack cloned successfully"
    else
        log_error "Failed to install Spack"
        return 1
    fi
}

setup_spack_environment() {
    log_info "Setting up Spack environment..."

    local spack_dir="$HOME/spack"

    # Add Spack to shell environment
    local bashrc="$HOME/.bashrc"
    if [[ -f "$bashrc" ]] && ! grep -q "# Spack environment" "$bashrc"; then
        cat >> "$bashrc" << EOF

# Spack environment
export SPACK_ROOT="$spack_dir"
source "\$SPACK_ROOT/share/spack/setup-env.sh"

# Spack aliases
alias spack-env='spack env activate'
alias spack-list='spack list'
alias spack-find='spack find'
alias spack-install='spack install'
EOF
        log_info "Added Spack environment to ~/.bashrc"
    fi

    # Source Spack for current session
    export SPACK_ROOT="$spack_dir"
    source "$spack_dir/share/spack/setup-env.sh"

    # Create Spack configuration directory
    mkdir -p "$HOME/.spack"

    # Create basic Spack configuration
    if [[ ! -f "$HOME/.spack/config.yaml" ]]; then
        cat > "$HOME/.spack/config.yaml" << 'EOF'
config:
  # Locations where different types of files should be written
  install_tree:
    root: $spack/opt/spack

  # Temporary locations Spack can try to use for builds
  build_stage:
    - $tempdir/$user/spack-stage
    - $spack/var/spack/stage

  # Cache directory for downloaded source code
  source_cache: $spack/var/spack/cache

  # Cache directory for build dependencies
  misc_cache: $spack/var/spack/cache

  # Number of jobs to use when building
  build_jobs: 8

  # Use ccache for compilation caching
  ccache: true
EOF
        log_info "Created Spack configuration: ~/.spack/config.yaml"
    fi
}

install_common_packages() {
    log_info "Installing common HPC packages with Spack..."

    # Source Spack environment
    local spack_dir="$HOME/spack"
    export SPACK_ROOT="$spack_dir"
    source "$spack_dir/share/spack/setup-env.sh"

    # List of essential HPC packages
    local packages=(
        "cmake"            # Build system
        "openmpi"          # MPI implementation
        "hdf5"             # HDF5 data format
        "netcdf-c"         # NetCDF library
        "fftw"             # Fast Fourier Transform
        "boost"            # C++ libraries
        "eigen"            # Linear algebra library
    )

    log_info "Installing essential packages (this may take a while)..."
    for package in "${packages[@]}"; do
        log_info "Installing $package..."
        execute_with_progress "spack install $package" "Installing $package..." || log_warning "Failed to install $package"
    done
}

create_spack_environments() {
    log_info "Creating Spack environments..."

    # Source Spack environment
    local spack_dir="$HOME/spack"
    export SPACK_ROOT="$spack_dir"
    source "$spack_dir/share/spack/setup-env.sh"

    # Create environments directory
    local env_dir="$HOME/spack-environments"
    mkdir -p "$env_dir"

    # Create computational environment
    cd "$env_dir"
    if [[ ! -d "computational" ]]; then
        spack env create computational
        spack env activate computational

        # Add packages to environment
        spack add cmake openmpi hdf5 netcdf-c fftw boost eigen

        # Create environment file
        cat > "$env_dir/computational.yaml" << 'EOF'
# Computational Environment
spack:
  specs:
    - cmake
    - openmpi
    - hdf5+mpi
    - netcdf-c+mpi
    - fftw+mpi
    - boost+mpi
    - eigen
  view: true
  concretizer:
    unify: true
EOF

        spack env deactivate
        log_info "Created computational environment"
    fi

    # Create data science environment
    if [[ ! -d "datascience" ]]; then
        spack env create datascience
        spack env activate datascience

        # Add data science packages
        spack add python py-numpy py-scipy py-matplotlib py-pandas hdf5 netcdf-c

        spack env deactivate
        log_info "Created data science environment"
    fi
}

create_example_project() {
    log_info "Creating Spack example project..."

    local projects_dir="$HOME/spack-projects"
    mkdir -p "$projects_dir/hello-mpi"

    # Create example MPI program
    cat > "$projects_dir/hello-mpi/hello_mpi.c" << 'EOF'
#include <mpi.h>
#include <stdio.h>

int main(int argc, char** argv) {
    MPI_Init(NULL, NULL);

    int world_size;
    MPI_Comm_size(MPI_COMM_WORLD, &world_size);

    int world_rank;
    MPI_Comm_rank(MPI_COMM_WORLD, &world_rank);

    printf("Hello from processor %d out of %d processors\n",
           world_rank, world_size);

    MPI_Finalize();
    return 0;
}
EOF

    # Create Makefile
    cat > "$projects_dir/hello-mpi/Makefile" << 'EOF'
CC = mpicc
CFLAGS = -Wall -O2

hello_mpi: hello_mpi.c
	$(CC) $(CFLAGS) -o hello_mpi hello_mpi.c

clean:
	rm -f hello_mpi

run: hello_mpi
	mpirun -np 4 ./hello_mpi

.PHONY: clean run
EOF

    # Create build script
    cat > "$projects_dir/hello-mpi/build.sh" << 'EOF'
#!/bin/bash
# Build script using Spack environment

# Activate computational environment
spack env activate computational

# Build the program
make

echo "Build completed! Run with: make run"
EOF

    chmod +x "$projects_dir/hello-mpi/build.sh"

    log_info "Created example MPI project: $projects_dir/hello-mpi"
}

print_spack_info() {
    echo ""
    echo "=============================================="
    echo "Spack HPC Package Manager Ready!"
    echo "=============================================="
    echo ""

    # Source Spack for version check
    local spack_dir="$HOME/spack"
    if [[ -f "$spack_dir/bin/spack" ]]; then
        export SPACK_ROOT="$spack_dir"
        source "$spack_dir/share/spack/setup-env.sh" 2>/dev/null

        echo "Installed components:"
        echo "  • Spack: $(spack --version 2>/dev/null || echo 'Available')"
        echo "  • Location: $spack_dir"
    fi

    echo ""
    echo "Quick start:"
    echo "  spack list                 # List available packages"
    echo "  spack install <package>    # Install a package"
    echo "  spack find                 # List installed packages"
    echo "  spack load <package>       # Load package into environment"
    echo ""
    echo "Environments:"
    echo "  spack env activate computational  # Activate computational env"
    echo "  spack env activate datascience    # Activate data science env"
    echo "  spack env list                    # List environments"
    echo ""
    echo "Example project: ~/spack-projects/hello-mpi"
    echo "  cd ~/spack-projects/hello-mpi && ./build.sh"
    echo ""
    echo "Common packages available:"
    echo "  • OpenMPI (message passing)"
    echo "  • HDF5 (data storage)"
    echo "  • NetCDF (scientific data)"
    echo "  • FFTW (fast Fourier transforms)"
    echo "  • Boost (C++ libraries)"
    echo ""
    echo "Note: Restart your terminal or run 'source ~/.bashrc' to use spack commands"
    echo ""
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

main() {
    log_info "Starting $TOOL_NAME installation..."

    # Check system requirements
    check_system_requirements

    # Install dependencies
    install_spack_dependencies

    # Install Spack
    install_spack || return 1

    # Setup environment
    setup_spack_environment

    # Install common packages
    install_common_packages

    # Create environments
    create_spack_environments

    # Create example project
    create_example_project

    # Show information
    print_spack_info

    log_success "$TOOL_NAME installation completed!"
}

# Execute main function
main "$@"

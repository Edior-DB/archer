#!/bin/bash

# Development Tools Installation Script
# Installs programming languages, tools, and development environment
# Following modern language management practices (2025)

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/..}/install/system/common-funcs.sh"

show_banner "Development Tools Installation"

# Check if AUR helper is available
if ! check_aur_helper; then
    echo -e "${RED}AUR helper not found. Please run post-install.sh first.${NC}"
    exit 1
fi

# Programming Languages Selection
select_languages() {
    echo -e "${BLUE}Select programming language categories to install:${NC}"
    echo "1. System Programming (C/C++, Rust, Go, Nim, D, Zig, V)"
    echo "2. Numerical Computing (Fortran, Julia, R, Octave, Haskell, Anaconda)"
    echo "3. Scripting & Web (Node.js, Ruby, PHP, Perl, Raku, Elixir, TypeScript)"
    echo "4. DevOps/Mobile (Docker, Kubernetes, Dart/Flutter, Kotlin)"
    echo "5. Database Tools (SQL clients, Docker databases)"
    echo "6. All categories"
    echo "0. Skip language installation"
    echo ""

    lang_choice=$(get_input "Enter your choice (1-6, or multiple separated by spaces):" "1 2 3")

    # Install Mise first (required for many language installations)
    install_mise

    # Install selected categories
    if [[ "$lang_choice" == *"1"* ]] || [[ "$lang_choice" == "6" ]]; then
        install_system_programming
    fi

    if [[ "$lang_choice" == *"2"* ]] || [[ "$lang_choice" == "6" ]]; then
        install_numerical_computing
    fi

    if [[ "$lang_choice" == *"3"* ]] || [[ "$lang_choice" == "6" ]]; then
        install_scripting_web
    fi

    if [[ "$lang_choice" == *"4"* ]] || [[ "$lang_choice" == "6" ]]; then
        install_devops_mobile
    fi

    if [[ "$lang_choice" == *"5"* ]] || [[ "$lang_choice" == "6" ]]; then
        install_database_tools
    fi
}

# Install Mise for language management
install_mise() {
    echo -e "${BLUE}Installing Mise (language version manager)...${NC}"

    if command -v mise &> /dev/null; then
        echo -e "${GREEN}Mise is already installed${NC}"
        return
    fi

    # Install mise via package manager or curl
    if ! pacman -Q mise &>/dev/null; then
        if ! install_with_retries mise; then
            curl https://mise.run | sh
            echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc
        fi
    else
        echo -e "${GREEN}Mise is already installed${NC}"
    fi

    # Initialize mise for current session
    eval "$(mise activate bash)"

    echo -e "${GREEN}Mise installed successfully!${NC}"
}

# System Programming Languages
install_system_programming() {
    echo -e "${BLUE}Installing System Programming languages...${NC}"

    # C/C++ with both GCC and Clang (LLVM)
    if confirm_action "Install C/C++ compilers (GCC + Clang/LLVM)?"; then
        packages=(
            "gcc" "glibc" "make" "cmake" "ninja"
            "clang" "llvm" "lld"
        )

        install_with_retries "${packages[@]}"
    fi

    # D language: both DMD and LDC (LLVM)
    if confirm_action "Install D language compilers (DMD + LDC)?"; then
        install_with_retries yay dmd ldc
    fi

    # Install via Mise
    echo -e "${YELLOW}Installing languages via Mise...${NC}"

    if confirm_action "Install Rust via Mise?"; then
        mise plugin add rust && mise install rust@latest
    fi

    if confirm_action "Install Go via Mise?"; then
        mise plugin add go && mise install go@latest
    fi

    if confirm_action "Install Nim via Mise?"; then
        mise plugin add nim && mise install nim@latest
    fi

    if confirm_action "Install Zig via Mise?"; then
        mise plugin add zig && mise install zig@latest
    fi

    # V language (manual install)
    if confirm_action "Install V language?"; then
        cd /tmp
        git clone https://github.com/vlang/v
        cd v && make
        sudo cp v /usr/local/bin/
        cd ~ && rm -rf /tmp/v
    fi

    echo -e "${GREEN}System programming languages installed!${NC}"
}

# Numerical Computing / Scientific
install_numerical_computing() {
    echo -e "${BLUE}Installing Numerical Computing tools...${NC}"

    # Fortran: GFortran and LFortran
    if confirm_action "Install Fortran compilers (GFortran + LFortran)?"; then
        packages=(
            "gcc-fortran"
            "openblas" "lapack"
        )

        install_with_retries "${packages[@]}"

        # Install LFortran from AUR
        install_with_retries yay lfortran-git
    fi

    # R statistical computing
    if confirm_action "Install R statistical computing?"; then
        install_with_retries r
    fi

    # Octave (MATLAB alternative)
    if confirm_action "Install Octave (MATLAB alternative)?"; then
        install_with_retries octave
    fi

    # Haskell
    if confirm_action "Install Haskell (GHC + Cabal + Stack)?"; then
        install_with_retries ghc cabal-install stack
    fi

    # Julia via Mise or official installer
    if confirm_action "Install Julia programming language?"; then
        mise plugin add julia && mise install julia@latest || {
            echo -e "${YELLOW}Installing Julia via official installer...${NC}"
            curl -fsSL https://install.julialang.org | sh
        }
    fi

    # Spack package manager for scientific computing
    if confirm_action "Install Spack package manager for HPC/scientific computing?"; then
        cd /opt
        sudo git clone -c feature.manyFiles=true https://github.com/spack/spack.git
        sudo chown -R $USER:$USER /opt/spack
        echo -e "${GREEN}Spack installed to /opt/spack${NC}"
        echo -e "${YELLOW}Add this to your shell profile to use Spack:${NC}"
        echo -e "${CYAN}export SPACK_ROOT=/opt/spack${NC}"
        echo -e "${CYAN}source \$SPACK_ROOT/share/spack/setup-env.sh${NC}"

        # Optionally add to bashrc
        if confirm_action "Add Spack to your ~/.bashrc automatically?"; then
            echo "" >> ~/.bashrc
            echo "# Spack package manager" >> ~/.bashrc
            echo "export SPACK_ROOT=/opt/spack" >> ~/.bashrc
            echo "source \$SPACK_ROOT/share/spack/setup-env.sh" >> ~/.bashrc
            echo -e "${GREEN}Spack configuration added to ~/.bashrc${NC}"
        fi
    fi

    # Anaconda for Python scientific computing
    if confirm_action "Install Anaconda for Python scientific computing?"; then
        install_with_retries yay anaconda || {
            echo -e "${YELLOW}Installing Anaconda via official installer...${NC}"
            cd /tmp
            wget https://repo.anaconda.com/archive/Anaconda3-2025.09-Linux-x86_64.sh
            bash Anaconda3-2025.09-Linux-x86_64.sh -b
            echo 'export PATH="$HOME/anaconda3/bin:$PATH"' >> ~/.bashrc
        }
    fi

    echo -e "${GREEN}Numerical computing tools installed!${NC}"
}

# Scripting & Web Programming
install_scripting_web() {
    echo -e "${BLUE}Installing Scripting & Web Programming languages...${NC}"

    # Note: Python managed via Anaconda, shells already installed during main setup

    # Install via Mise
    echo -e "${YELLOW}Installing languages via Mise...${NC}"
    mise plugin add nodejs && mise install nodejs@latest
    mise plugin add ruby && mise install ruby@latest
    mise plugin add php && mise install php@latest
    mise plugin add perl && mise install perl@latest

    # Raku (community plugin)
    mise plugin add raku && mise install raku@latest || echo -e "${YELLOW}Raku plugin not available${NC}"

    # Elixir/Erlang
    mise plugin add erlang && mise install erlang@latest
    mise plugin add elixir && mise install elixir@latest

    # TypeScript via npm (after Node.js)
    if command -v npm &> /dev/null; then
        npm install -g typescript ts-node
    fi

    # System packages for web development
    install_with_retries lua luarocks

    echo -e "${GREEN}Scripting & web programming languages installed!${NC}"
}

# DevOps/Mobile Development
install_devops_mobile() {
    echo -e "${BLUE}Installing DevOps/Mobile development tools...${NC}"

    # DevOps tools
    packages=(
        "docker" "docker-compose" "podman"
        "kubectl" "helm" "terraform"
        "ansible"
    )

    # Try pacman first, fallback to AUR
    for package in "${packages[@]}"; do
        if ! pacman -Q "$package" &>/dev/null; then
            if pacman -Si "$package" &>/dev/null; then
                install_with_retries "$package"
            else
                install_with_retries yay "$package"
            fi
        else
            echo -e "${GREEN}$package is already installed${NC}"
        fi
    done

    # Enable Docker service
    sudo systemctl enable docker
    sudo usermod -aG docker $USER

    # Mobile development
    if confirm_action "Install Flutter/Dart?"; then
        mise plugin add flutter && mise install flutter@latest
    fi

    if confirm_action "Install Kotlin?"; then
        install_with_retries yay kotlin
    fi

    echo -e "${GREEN}DevOps/Mobile tools installed!${NC}"
}

# Database Tools
install_database_tools() {
    echo -e "${BLUE}Installing Database tools...${NC}"

    # SQL clients
    install_with_retries sqlite postgresql-libs mariadb-clients

    # Offer Docker-based database installation
    if confirm_action "Set up databases via Docker containers?"; then
        setup_docker_databases
    else
        # Traditional installation
        setup_native_databases
    fi

    echo -e "${GREEN}Database tools installed!${NC}"
}

# Development tools
install_dev_tools() {
    echo -e "${BLUE}Installing development tools...${NC}"

    # Version control and tools
    dev_packages=(
        "git"
        "git-lfs"
        "github-cli"
        "tig"
        "diff-so-fancy"

        # Build tools
        "cmake"
        "ninja"
        "meson"
        "autoconf"
        "automake"
        "libtool"

        # Databases
        "sqlite"
        "postgresql"
        "mariadb"
        "redis"

        # Network tools
        "curl"
        "wget"
        "httpie"
        "postman-bin"

        # Text processing
        "jq"
        "yq"
        "ripgrep"
        "fd"
        "bat"
        "exa"

        # Monitoring
        "htop"
        "btop"
        "glances"

        # Terminal multiplexer
        "tmux"
        "screen"
    )

    for package in "${dev_packages[@]}"; do
        if pacman -Si "$package" &> /dev/null; then
            sudo pacman -S --noconfirm "$package"
        else
            yay -S --noconfirm "$package" || echo -e "${YELLOW}Failed to install $package${NC}"
        fi
    done
}

# Database setup
setup_docker_databases() {
    echo -e "${BLUE}Setting up Docker-based databases...${NC}"

    # Create docker-compose.yml for databases
    mkdir -p ~/dev-databases
    cat > ~/dev-databases/docker-compose.yml << 'EOF'
version: '3.8'
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: devdb
      POSTGRES_USER: devuser
      POSTGRES_PASSWORD: devpass
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  mariadb:
    image: mariadb:10.11
    environment:
      MYSQL_ROOT_PASSWORD: rootpass
      MYSQL_DATABASE: devdb
      MYSQL_USER: devuser
      MYSQL_PASSWORD: devpass
    ports:
      - "3306:3306"
    volumes:
      - mariadb_data:/var/lib/mysql

  redis:
    image: redis:7
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  mariadb_data:
  redis_data:
EOF

    echo -e "${GREEN}Docker database setup created in ~/dev-databases/${NC}"
    echo -e "${YELLOW}Run 'cd ~/dev-databases && docker-compose up -d' to start databases${NC}"
}

setup_native_databases() {
    echo -e "${BLUE}Setting up native databases...${NC}"

    if confirm_action "Initialize PostgreSQL?"; then
        install_with_retries postgresql
        sudo -u postgres initdb -D /var/lib/postgres/data
        sudo systemctl enable postgresql
        sudo systemctl start postgresql
        echo -e "${GREEN}PostgreSQL initialized and started${NC}"
    fi

    if confirm_action "Initialize MariaDB?"; then
        install_with_retries mariadb
        sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
        sudo systemctl enable mariadb
        sudo systemctl start mariadb
        echo -e "${GREEN}MariaDB initialized and started${NC}"
        echo -e "${YELLOW}Run 'sudo mysql_secure_installation' to secure MariaDB${NC}"
    fi

    if confirm_action "Enable Redis?"; then
        install_with_retries redis
        sudo systemctl enable redis
        sudo systemctl start redis
        echo -e "${GREEN}Redis enabled and started${NC}"
    fi
}

# IDE and editors (additional to the main editors script)
install_dev_editors() {
    echo -e "${BLUE}Installing additional development editors...${NC}"

    editors=(
        "neovim"
        "emacs"
        "sublime-text-4"
        "jetbrains-toolbox"
    )

    for editor in "${editors[@]}"; do
        if confirm_action "Install $editor?"; then
            if pacman -Si "$editor" &> /dev/null; then
                install_with_retries "$editor"
            else
                install_with_retries yay "$editor"
            fi
        fi
    done

    # VS Code and VSCodium using dedicated scripts
    if confirm_action "Install Visual Studio Code?"; then
        bash "${ARCHER_DIR}/install/development/app-vscode.sh"
    fi

    if confirm_action "Install VSCodium (open-source VS Code)?"; then
        bash "${ARCHER_DIR}/install/development/app-vscodium.sh"
    fi
}

# Git configuration
configure_git() {
    echo -e "${BLUE}Configuring Git...${NC}"

    git_username=$(get_input "Enter your Git username:" "johndoe")
    git_email=$(get_input "Enter your Git email:" "john@example.com")

    if [[ -n "$git_username" && -n "$git_email" ]]; then
        git config --global user.name "$git_username"
        git config --global user.email "$git_email"
        git config --global init.defaultBranch main
        git config --global core.editor nano
        git config --global pull.rebase false

        echo -e "${GREEN}Git configured successfully!${NC}"
    else
        echo -e "${YELLOW}Skipping Git configuration${NC}"
    fi
}

# Main execution
main() {
    echo -e "${YELLOW}This script will install development tools and programming languages.${NC}"
    if ! confirm_action "Continue with development tools installation?"; then
        echo -e "${YELLOW}Installation cancelled.${NC}"
        exit 0
    fi

    # Update system first
    sudo pacman -Syu --noconfirm

    # Install development tools
    install_dev_tools

    # Select and install programming languages
    select_languages

    # Configure Git
    configure_git

    # Setup database tools
    install_database_tools

    # Install additional editors
    install_dev_editors

    echo -e "${GREEN}
=========================================================================
                    Development Environment Setup Complete!
=========================================================================

Installed tools:
- Mise (language version manager)
- System Programming: C/C++ (GCC+Clang), Rust, Go, Nim, D (DMD+LDC), Zig, V
- Numerical Computing: Fortran (GFortran+LFortran), Julia, R, Octave, Haskell
- Scripting & Web: Node.js, Ruby, PHP, Perl, Raku, Elixir, TypeScript, Lua
- DevOps/Mobile: Docker, Kubernetes, Ansible, Terraform, Flutter/Dart, Kotlin
- Database tools and clients
- Scientific Python via Anaconda (if selected)

Language management:
- Use 'mise' to manage language versions per project
- Python scientific computing via Anaconda
- System Python for system scripts only

Next steps:
- Restart your terminal or run 'source ~/.bashrc'
- Run 'mise --help' to learn about language management
- Set up project-specific language versions with '.tool-versions' files
- Configure your preferred code editor
- For databases: check ~/dev-databases/ if Docker option was selected

${NC}"

    wait_for_input
}

# Run main function
main

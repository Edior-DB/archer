#!/bin/bash

# Development Tools Installation Script
# Installs programming languages, tools, and development environment
# Following modern language management practices (2025)

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/..}/install/system/common-funcs.sh"

# Interactive selection function using gum
select_option() {
    local options=("$@")
    gum choose "${options[@]}"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --reset)
            echo -e "${YELLOW}Resetting development tools installation state...${NC}"
            rm -f "$ARCHER_DIR/.archer-dev-state"
            echo -e "${GREEN}State reset complete.${NC}"
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --reset    Reset installation state and start fresh"
            echo "  --help     Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

show_banner "Development Tools Installation"

# Check if AUR helper is available
if ! check_aur_helper; then
    echo -e "${RED}AUR helper not found. Please run post-install.sh first.${NC}"
    exit 1
fi

# Programming Languages Selection
select_languages() {
    echo -e "${BLUE}Select programming language categories to install:${NC}"

    options=(
        "1) System Programming (C/C++, Rust, Go, Nim, D, Zig, V)"
        "2) Numerical Computing (Fortran, Julia, R, Octave, Haskell, Anaconda)"
        "3) Scripting & Web (Node.js, Ruby, PHP, Perl, Raku, Elixir, TypeScript)"
        "4) DevOps/Mobile (Docker, Kubernetes, Dart/Flutter, Kotlin)"
        "5) Database Tools (SQL clients, Docker databases)"
        "6) All categories"
        "0) Skip language installation"
    )

    selection_error=false
    choice=""
    if selection=$(select_option "${options[@]}") && [[ -n "$selection" ]]; then
        choice=$(echo "$selection" | cut -d')' -f1)
        echo -e "${GREEN}Your selection: ${selection}${NC}"
    else
        # Fallback: use gum input for manual entry
        choice=$(gum input --placeholder "Select an option [0-6]: " --width=20)
        if ! [[ "$choice" =~ ^[0-6]+$ ]]; then
            selection_error=true
        fi
    fi

    if [[ "$selection_error" == true ]] || [[ -z "$choice" ]]; then
        gum style --foreground="#ff0000" "Invalid selection. Please try again."
        sleep 2
        select_languages
        return
    fi

    # Install Mise first (required for many language installations)
    install_mise

    # Install selected categories
    if [[ "$choice" == *"1"* ]] || [[ "$choice" == "6" ]]; then
        install_system_programming
    fi

    if [[ "$choice" == *"2"* ]] || [[ "$choice" == "6" ]]; then
        install_numerical_computing
    fi

    if [[ "$choice" == *"3"* ]] || [[ "$choice" == "6" ]]; then
        install_scripting_web
    fi

    if [[ "$choice" == *"4"* ]] || [[ "$choice" == "6" ]]; then
        install_devops_mobile
    fi

    if [[ "$choice" == *"5"* ]] || [[ "$choice" == "6" ]]; then
        install_database_tools
    fi

    if [[ "$choice" == "0" ]]; then
        echo -e "${YELLOW}Skipping language installation.${NC}"
        return
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
        mise install rust@latest
    fi

    if confirm_action "Install Go via Mise?"; then
        mise install go@latest
    fi

    if confirm_action "Install Nim via Mise?"; then
        mise plugin add nim && mise install nim@latest
    fi

    if confirm_action "Install Zig via Mise?"; then
        mise install zig@latest
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

    # Fortran: GFortran (fast install)
    if confirm_action "Install GFortran compiler?"; then
        packages=(
            "gcc-fortran"
            "openblas" "lapack"
        )

        install_with_retries "${packages[@]}"
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
    if confirm_action "Install Anaconda for Python scientific computing? (WARNING: Large download, 15-30 minutes)"; then
        install_with_retries yay anaconda || {
            echo -e "${YELLOW}Installing Anaconda via official installer...${NC}"
            cd /tmp
            wget https://repo.anaconda.com/archive/Anaconda3-2025.09-Linux-x86_64.sh
            bash Anaconda3-2025.09-Linux-x86_64.sh -b
            echo 'export PATH="$HOME/anaconda3/bin:$PATH"' >> ~/.bashrc
        }
    fi

    # LFortran (separate due to long compilation time)
    if confirm_action "Install LFortran compiler? (WARNING: Compilation takes 20-45 minutes)"; then
        echo -e "${YELLOW}Installing LFortran from AUR (this will take a while)...${NC}"
        install_with_retries yay lfortran-git
    fi

    echo -e "${GREEN}Numerical computing tools installed!${NC}"
}

# Scripting & Web Programming
install_scripting_web() {
    echo -e "${BLUE}Installing Scripting & Web Programming languages...${NC}"

    # Note: Python managed via Anaconda, shells already installed during main setup

    # Install via Mise
    echo -e "${YELLOW}Installing languages via Mise...${NC}"

    if confirm_action "Install Node.js via Mise?"; then
        mise install nodejs@latest

        # Configure npm to avoid sudo requirements for global packages
        if command -v npm &> /dev/null; then
            echo -e "${CYAN}Configuring npm for user-local global packages...${NC}"
            npm config set prefix ~/.local
            echo -e "${YELLOW}Global npm packages will be installed to ~/.local/bin${NC}"
            echo -e "${YELLOW}Make sure ~/.local/bin is in your PATH${NC}"
        fi
    fi

    if confirm_action "Install Ruby via Mise?"; then
        mise install ruby@latest
    fi

    if confirm_action "Install PHP via Mise?"; then
        # Install PHP dependencies first
        echo -e "${YELLOW}Installing PHP dependencies...${NC}"
        install_with_retries gd
        mise install php@latest
    fi

    if confirm_action "Install Perl via Mise?"; then
        mise plugin add perl && mise install perl@latest
    fi

    # Raku (community plugin)
    if confirm_action "Install Raku (Perl 6) via Mise?"; then
        mise plugin add raku && mise install raku@latest || echo -e "${YELLOW}Raku plugin not available${NC}"
    fi

    # Elixir/Erlang
    if confirm_action "Install Elixir/Erlang via Mise?"; then
        mise install erlang@latest
        mise install elixir@latest
    fi

    # TypeScript via npm (after Node.js)
    if confirm_action "Install TypeScript globally via npm?" && command -v npm &> /dev/null; then
        echo -e "${CYAN}Installing TypeScript and ts-node globally...${NC}"

        # Check if npm is configured with user prefix
        npm_prefix=$(npm config get prefix 2>/dev/null || echo "")

        if [[ "$npm_prefix" == *"$HOME"* ]]; then
            # npm is configured for user installation
            echo -e "${YELLOW}Installing to user directory: $npm_prefix${NC}"
            npm install -g typescript ts-node
            echo -e "${GREEN}✓ TypeScript installed to user directory${NC}"
        else
            # Try npm install without sudo first (if npm is properly configured)
            if npm install -g typescript ts-node 2>/dev/null; then
                echo -e "${GREEN}✓ TypeScript installed successfully${NC}"
            else
                # If it fails, try with sudo
                echo -e "${YELLOW}Permission denied, trying with sudo...${NC}"
                if sudo npm install -g typescript ts-node; then
                    echo -e "${GREEN}✓ TypeScript installed with sudo${NC}"
                else
                    echo -e "${RED}✗ Failed to install TypeScript globally${NC}"
                    echo -e "${YELLOW}You can install it locally in your project with: npm install typescript ts-node${NC}"
                fi
            fi
        fi
    fi

    # UV - Python package manager
    if confirm_action "Install UV (fast Python package manager)?"; then
        echo -e "${YELLOW}Installing UV via official installer...${NC}"
        curl -LsSf https://astral.sh/uv/install.sh | sh
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
        echo -e "${GREEN}UV installed! Restart your terminal or run 'source ~/.bashrc'${NC}"
    fi

    # System packages for web development
    if confirm_action "Install Lua and LuaRocks?"; then
        install_with_retries lua luarocks
    fi

    echo -e "${GREEN}Scripting & web programming languages installed!${NC}"
}

# DevOps/Mobile Development
install_devops_mobile() {
    echo -e "${BLUE}Installing DevOps/Mobile development tools...${NC}"

    # DevOps tools
    if confirm_action "Install container and orchestration tools (Docker, Podman, Kubernetes)?"; then
        container_packages=("docker" "docker-compose" "podman" "kubectl" "helm")

        # Try pacman first, fallback to AUR
        for package in "${container_packages[@]}"; do
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
    fi

    # Infrastructure as Code tools
    if confirm_action "Install Infrastructure as Code tools (Terraform, Ansible)?"; then
        iac_packages=("terraform" "ansible")

        for package in "${iac_packages[@]}"; do
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
    fi

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
    if confirm_action "Install SQL clients (SQLite, PostgreSQL libs, MariaDB clients)?"; then
        install_with_retries sqlite postgresql-libs mariadb-clients
    fi

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

    # Check what's already installed
    installed_packages=()
    if command -v git &> /dev/null; then installed_packages+=("Git"); fi
    if command -v cmake &> /dev/null; then installed_packages+=("CMake"); fi
    if command -v curl &> /dev/null; then installed_packages+=("curl"); fi
    if command -v wget &> /dev/null; then installed_packages+=("wget"); fi
    if command -v jq &> /dev/null; then installed_packages+=("jq"); fi
    if command -v htop &> /dev/null; then installed_packages+=("htop"); fi
    if command -v tmux &> /dev/null; then installed_packages+=("tmux"); fi

    if [[ ${#installed_packages[@]} -gt 0 ]]; then
        echo -e "${GREEN}Already installed: ${installed_packages[*]}${NC}"
        if ! confirm_action "Install additional development tools?"; then
            echo -e "${YELLOW}Skipping development tools installation.${NC}"
            return
        fi
    fi

    # Version control and tools
    if confirm_action "Install version control tools (Git, GitHub CLI, etc.)?"; then
        git_packages=("git" "git-lfs" "github-cli" "tig" "diff-so-fancy")
        install_with_retries "${git_packages[@]}"
    fi

    # Build tools
    if confirm_action "Install build tools (CMake, Ninja, Meson, Autotools)?"; then
        build_packages=("cmake" "ninja" "meson" "autoconf" "automake" "libtool")
        install_with_retries "${build_packages[@]}"
    fi

    # Network tools
    if confirm_action "Install network/API tools (curl, wget, HTTPie, Postman)?"; then
        network_packages=("curl" "wget" "httpie")
        install_with_retries "${network_packages[@]}"
        # Postman might be AUR only
        install_with_retries yay postman-bin
    fi

    # Text processing tools
    if confirm_action "Install modern text processing tools (ripgrep, fd, bat, jq)?"; then
        text_packages=("jq" "yq" "ripgrep" "fd" "bat" "exa")
        install_with_retries "${text_packages[@]}"
    fi

    # System monitoring
    if confirm_action "Install system monitoring tools (htop, btop, glances)?"; then
        monitor_packages=("htop" "btop" "glances")
        install_with_retries "${monitor_packages[@]}"
    fi

    # Terminal multiplexers
    if confirm_action "Install terminal multiplexers (tmux, screen)?"; then
        terminal_packages=("tmux" "screen")
        install_with_retries "${terminal_packages[@]}"
    fi

    # Modern terminal emulators
    if confirm_action "Install modern terminal emulators?"; then
        if confirm_action "Install Alacritty (GPU-accelerated, minimal terminal)?"; then
            bash "${ARCHER_DIR}/install/development/terminal-alacritty.sh"
        fi

        if confirm_action "Install Kitty (fast, feature-rich terminal)?"; then
            bash "${ARCHER_DIR}/install/development/terminal-kitty.sh"
        fi

        if confirm_action "Install WezTerm (Rust-based terminal with advanced features)?"; then
            bash "${ARCHER_DIR}/install/development/terminal-wezterm.sh"
        fi

        if confirm_action "Install Hyper (Electron-based terminal with plugins)?"; then
            bash "${ARCHER_DIR}/install/development/terminal-hyper.sh"
        fi
    fi
}

# Database setup
setup_docker_databases() {
    echo -e "${BLUE}Setting up Docker-based databases...${NC}"

    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}Docker is not installed. Installing Docker first...${NC}"
        if confirm_action "Install Docker for database containers?"; then
            install_with_retries docker docker-compose
            sudo systemctl enable docker
            sudo systemctl start docker
            sudo usermod -aG docker $USER
            echo -e "${YELLOW}You may need to log out and back in for Docker group permissions${NC}"
        else
            echo -e "${RED}Docker is required for database containers. Skipping database setup.${NC}"
            return 1
        fi
    fi

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

    # Check if Git is already configured
    git_user=$(git config --global user.name 2>/dev/null || echo "")
    git_email=$(git config --global user.email 2>/dev/null || echo "")

    if [[ -n "$git_user" && -n "$git_email" ]]; then
        echo -e "${GREEN}Git already configured:${NC}"
        echo -e "  Name: $git_user"
        echo -e "  Email: $git_email"
        if ! confirm_action "Reconfigure Git settings?"; then
            echo -e "${YELLOW}Keeping existing Git configuration.${NC}"
            return
        fi
    fi

    git_username=$(get_input "Enter your Git username:" "${git_user:-johndoe}")
    git_email_input=$(get_input "Enter your Git email:" "${git_email:-john@example.com}")

    if [[ -n "$git_username" && -n "$git_email_input" ]]; then
        git config --global user.name "$git_username"
        git config --global user.email "$git_email_input"
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

    # Check for existing installations
    STATE_FILE="$ARCHER_DIR/.archer-dev-state"

    # Show current state if exists
    if [[ -f "$STATE_FILE" ]]; then
        echo -e "${CYAN}Previous installation detected:${NC}"
        cat "$STATE_FILE"
        echo ""
        if confirm_action "Skip already completed sections?"; then
            SKIP_COMPLETED=true
        else
            SKIP_COMPLETED=false
        fi
    else
        SKIP_COMPLETED=false
        mkdir -p "$(dirname "$STATE_FILE")"
        echo "# Archer Development Tools Installation State" > "$STATE_FILE"
        echo "# Generated on $(date)" >> "$STATE_FILE"
    fi

    if ! confirm_action "Continue with development tools installation?"; then
        echo -e "${YELLOW}Installation cancelled.${NC}"
        exit 0
    fi

    # Update system first
    sudo pacman -Syu --noconfirm

    # Install development tools (with state awareness)
    if [[ "$SKIP_COMPLETED" == "false" ]] || ! grep -q "dev_tools_installed=true" "$STATE_FILE"; then
        install_dev_tools
        echo "dev_tools_installed=true" >> "$STATE_FILE"
    else
        echo -e "${GREEN}Development tools already installed, skipping...${NC}"
    fi

    # Select and install programming languages
    select_languages

    # Configure Git (only if not already configured)
    if [[ "$SKIP_COMPLETED" == "false" ]] || ! grep -q "git_configured=true" "$STATE_FILE"; then
        configure_git
        echo "git_configured=true" >> "$STATE_FILE"
    else
        echo -e "${GREEN}Git already configured, skipping...${NC}"
    fi

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

State file: $STATE_FILE
Run with --reset to clear installation state

${NC}"

    wait_for_input
}

# Run main function
main

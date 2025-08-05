#!/bin/bash

# Development Tools Installation Script
# Installs programming languages, tools, and development environment

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Confirm function using gum
confirm_action() {
    local message="$1"
    gum confirm "$message"
}

# Wait function using gum
wait_for_input() {
    local message="${1:-Press Enter to continue...}"
    gum input --placeholder "$message" --value "" > /dev/null
}

# Input function using gum
get_input() {
    local prompt="$1"
    local placeholder="${2:-}"
    gum input --prompt "$prompt " --placeholder "$placeholder"
}

echo -e "${BLUE}
=========================================================================
                    Development Tools Installation
=========================================================================
${NC}"

# Check if yay is installed
if ! command -v yay &> /dev/null; then
    echo -e "${RED}yay AUR helper not found. Please run post-install.sh first.${NC}"
    exit 1
fi

# Programming Languages Selection
select_languages() {
    echo -e "${BLUE}Select programming languages to install:${NC}"
    echo "1. Python (recommended)"
    echo "2. Node.js & npm"
    echo "3. Rust"
    echo "4. Go"
    echo "5. Java (OpenJDK)"
    echo "6. C/C++ (already installed with base-devel)"
    echo "7. PHP"
    echo "8. Ruby"
    echo "9. All of the above"
    echo "0. Skip language installation"
    echo ""

    lang_choice=$(get_input "Enter your choice (1-9, or multiple separated by spaces):" "1 2 3")

    # Install selected languages
    if [[ "$lang_choice" == *"1"* ]] || [[ "$lang_choice" == "9" ]]; then
        install_python
    fi

    if [[ "$lang_choice" == *"2"* ]] || [[ "$lang_choice" == "9" ]]; then
        install_nodejs
    fi

    if [[ "$lang_choice" == *"3"* ]] || [[ "$lang_choice" == "9" ]]; then
        install_rust
    fi

    if [[ "$lang_choice" == *"4"* ]] || [[ "$lang_choice" == "9" ]]; then
        install_go
    fi

    if [[ "$lang_choice" == *"5"* ]] || [[ "$lang_choice" == "9" ]]; then
        install_java
    fi

    if [[ "$lang_choice" == *"7"* ]] || [[ "$lang_choice" == "9" ]]; then
        install_php
    fi

    if [[ "$lang_choice" == *"8"* ]] || [[ "$lang_choice" == "9" ]]; then
        install_ruby
    fi
}

# Python installation
install_python() {
    echo -e "${BLUE}Installing Python development environment...${NC}"

    packages=(
        "python"
        "python-pip"
        "python-pipenv"
        "python-virtualenv"
        "python-poetry"
        "ipython"
        "jupyter-notebook"
    )

    for package in "${packages[@]}"; do
        sudo pacman -S --noconfirm "$package" || echo -e "${YELLOW}$package not available in repos${NC}"
    done

    # Popular Python packages
    echo -e "${YELLOW}Installing popular Python packages...${NC}"
    pip install --user --upgrade pip setuptools wheel
    pip install --user requests numpy pandas matplotlib flask django fastapi

    echo -e "${GREEN}Python environment installed!${NC}"
}

# Node.js installation
install_nodejs() {
    echo -e "${BLUE}Installing Node.js development environment...${NC}"

    sudo pacman -S --noconfirm nodejs npm yarn

    # Global npm packages
    echo -e "${YELLOW}Installing useful global npm packages...${NC}"
    npm install -g @angular/cli create-react-app vue-cli typescript ts-node nodemon eslint prettier

    echo -e "${GREEN}Node.js environment installed!${NC}"
}

# Rust installation
install_rust() {
    echo -e "${BLUE}Installing Rust development environment...${NC}"

    sudo pacman -S --noconfirm rustup
    rustup install stable
    rustup default stable
    rustup component add rust-src rust-analyzer clippy rustfmt

    echo -e "${GREEN}Rust environment installed!${NC}"
}

# Go installation
install_go() {
    echo -e "${BLUE}Installing Go development environment...${NC}"

    sudo pacman -S --noconfirm go

    # Set up Go environment
    echo 'export GOPATH=$HOME/go' >> ~/.bashrc
    echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.bashrc

    echo -e "${GREEN}Go environment installed!${NC}"
}

# Java installation
install_java() {
    echo -e "${BLUE}Installing Java development environment...${NC}"

    sudo pacman -S --noconfirm jdk-openjdk openjdk-doc gradle maven

    echo -e "${GREEN}Java environment installed!${NC}"
}

# PHP installation
install_php() {
    echo -e "${BLUE}Installing PHP development environment...${NC}"

    sudo pacman -S --noconfirm php php-apache composer

    echo -e "${GREEN}PHP environment installed!${NC}"
}

# Ruby installation
install_ruby() {
    echo -e "${BLUE}Installing Ruby development environment...${NC}"

    sudo pacman -S --noconfirm ruby rubygems
    gem install bundler rails

    echo -e "${GREEN}Ruby environment installed!${NC}"
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
setup_databases() {
    echo -e "${BLUE}Setting up databases...${NC}"

    if confirm_action "Initialize PostgreSQL?"; then
        sudo -u postgres initdb -D /var/lib/postgres/data
        sudo systemctl enable postgresql
        sudo systemctl start postgresql
        echo -e "${GREEN}PostgreSQL initialized and started${NC}"
    fi

    if confirm_action "Initialize MariaDB?"; then
        sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
        sudo systemctl enable mariadb
        sudo systemctl start mariadb
        echo -e "${GREEN}MariaDB initialized and started${NC}"
        echo -e "${YELLOW}Run 'sudo mysql_secure_installation' to secure MariaDB${NC}"
    fi

    if confirm_action "Enable Redis?"; then
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
                sudo pacman -S "$editor"
            else
                yay -S "$editor" || echo -e "${YELLOW}Failed to install $editor${NC}"
            fi
        fi
    done
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

    # Setup databases
    setup_databases

    # Install additional editors
    install_dev_editors

    echo -e "${GREEN}
=========================================================================
                    Development Environment Setup Complete!
=========================================================================

Installed tools:
- Version control (Git, GitHub CLI)
- Build tools (CMake, Ninja, Meson)
- Text processing tools (jq, ripgrep, bat)
- Database systems (PostgreSQL, MariaDB, Redis)
- Terminal tools (tmux, htop, btop)

Programming languages and their package managers have been installed
based on your selections.

Next steps:
- Restart your terminal or run 'source ~/.bashrc'
- Configure your preferred code editor
- Set up your development projects
- Consider running the editors installation script

${NC}"

    wait_for_input
}

# Run main function
main

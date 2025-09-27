#!/bin/bash

# Code Editors & IDEs Installation Script
# Comprehensive editor installation with configuration options
# Part of Archer - Arch Linux Development Environment

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/..}/install/system/common-funcs.sh"

show_banner "Code Editors & IDEs Installation"

# Check if AUR helper is available
if ! check_aur_helper; then
    echo -e "${RED}AUR helper not found. Please run post-install.sh first.${NC}"
    archer_die "AUR helper not found"
fi

# Visual Studio Code installation with extensions
install_vscode() {
    echo -e "${BLUE}Installing Visual Studio Code...${NC}"

    if archer_confirm_or_default "Install Visual Studio Code (Microsoft official)?"; then
        install_with_retries yay visual-studio-code-bin

    if archer_confirm_or_default "Install common VS Code extensions?"; then
            echo -e "${YELLOW}Installing popular extensions...${NC}"

            # Essential extensions
            extensions=(
                "ms-python.python"
                "ms-vscode.cpptools"
                "rust-lang.rust-analyzer"
                "golang.go"
                "ms-vscode.vscode-typescript-next"
                "ms-vscode.vscode-json"
                "redhat.vscode-yaml"
                "ms-vscode.hexeditor"
                "ms-vscode.vscode-eslint"
                "ms-vscode.vscode-prettier"
                "gitpod.gitpod-desktop"
                "ms-vscode.remote-ssh"
                "ms-vscode.remote-containers"
                "ms-vscode-remote.remote-wsl"
                "ms-toolsai.jupyter"
                "ms-vscode.makefile-tools"
                "ms-vscode.cmake-tools"
                "twxs.cmake"
                "vadimcn.vscode-lldb"
                "ms-vscode.vscode-serial-monitor"
            )

            for ext in "${extensions[@]}"; do
                code --install-extension "$ext" 2>/dev/null || echo "Failed to install $ext"
            done

            echo -e "${GREEN}VS Code extensions installed!${NC}"
        fi

        echo -e "${GREEN}Visual Studio Code installation completed!${NC}"
    fi
}

# VSCodium installation (open-source alternative)
install_vscodium() {
    echo -e "${BLUE}Installing VSCodium (Open Source VS Code)...${NC}"

    if archer_confirm_or_default "Install VSCodium?"; then
        install_with_retries pacman vscodium

    if archer_confirm_or_default "Install common VSCodium extensions?"; then
            echo -e "${YELLOW}Installing extensions for VSCodium...${NC}"

            # Extensions compatible with VSCodium
            extensions=(
                "ms-python.python"
                "rust-lang.rust-analyzer"
                "golang.go"
                "vadimcn.vscode-lldb"
                "ms-vscode.hexeditor"
            )

            for ext in "${extensions[@]}"; do
                codium --install-extension "$ext" 2>/dev/null || echo "Failed to install $ext"
            done

            echo -e "${GREEN}VSCodium extensions installed!${NC}"
        fi

        echo -e "${GREEN}VSCodium installation completed!${NC}"
    fi
}

# Neovim installation with configuration
install_neovim() {
    echo -e "${BLUE}Installing Neovim...${NC}"

    if archer_confirm_or_default "Install Neovim?"; then
        install_with_retries pacman neovim

        # Install additional tools for Neovim
    if archer_confirm_or_default "Install Neovim development tools (LSP, tree-sitter, etc.)?"; then
            echo -e "${YELLOW}Installing Neovim development tools...${NC}"

            nvim_tools=(
                "tree-sitter"
                "ripgrep"
                "fd"
                "nodejs"
                "npm"
                "python-pip"
                "python-pynvim"
                "lua"
                "luarocks"
            )

            for tool in "${nvim_tools[@]}"; do
                install_with_retries pacman "$tool"
            done

            # Install LSP servers via npm
            if command -v npm &> /dev/null; then
                echo -e "${YELLOW}Installing LSP servers...${NC}"
                npm install -g \
                    typescript-language-server \
                    bash-language-server \
                    vscode-langservers-extracted \
                    pyright \
                    lua-language-server 2>/dev/null || echo "Some LSP servers failed to install"
            fi

            echo -e "${GREEN}Neovim development tools installed!${NC}"
        fi

    if archer_confirm_or_default "Install popular Neovim configuration (LazyVim)?"; then
            echo -e "${YELLOW}Installing LazyVim configuration...${NC}"

            # Backup existing config if it exists
            if [ -d "$HOME/.config/nvim" ]; then
                mv "$HOME/.config/nvim" "$HOME/.config/nvim.bak.$(date +%s)"
                echo -e "${YELLOW}Existing Neovim config backed up${NC}"
            fi

            # Install LazyVim
            git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
            rm -rf "$HOME/.config/nvim/.git"

            echo -e "${GREEN}LazyVim configuration installed!${NC}"
            echo -e "${BLUE}Run 'nvim' to complete the setup${NC}"
        fi

        echo -e "${GREEN}Neovim installation completed!${NC}"
    fi
}

# Vim installation with configuration
install_vim() {
    echo -e "${BLUE}Installing Vim...${NC}"

    if archer_confirm_or_default "Install Vim?"; then
        install_with_retries pacman vim

    if archer_confirm_or_default "Install Vim plugins manager (vim-plug)?"; then
            echo -e "${YELLOW}Installing vim-plug...${NC}"

            curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
                https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

            # Create basic vimrc with some useful plugins
            if archer_confirm_or_default "Create basic .vimrc with popular plugins?"; then
                cat > "$HOME/.vimrc" << 'EOF'
" Basic Vim Configuration with Plugins
call plug#begin('~/.vim/plugged')

" File explorer
Plug 'preservim/nerdtree'

" Fuzzy finder
Plug 'ctrlpvim/ctrlp.vim'

" Status line
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" Git integration
Plug 'tpope/vim-fugitive'

" Syntax highlighting
Plug 'sheerun/vim-polyglot'

" Auto pairs
Plug 'jiangmiao/auto-pairs'

" Color schemes
Plug 'morhetz/gruvbox'
Plug 'dracula/vim', { 'as': 'dracula' }

call plug#end()

" Basic settings
set number
set relativenumber
set tabstop=4
set shiftwidth=4
set expandtab
set autoindent
set smartindent
set hlsearch
set incsearch
set ignorecase
set smartcase
set wildmenu
set cursorline
set laststatus=2
set encoding=utf-8

" Color scheme
colorscheme gruvbox
set background=dark

" NERDTree settings
map <C-n> :NERDTreeToggle<CR>

" Key mappings
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>wq :wq<CR>
EOF
                echo -e "${GREEN}Basic .vimrc created! Run 'vim +PlugInstall' to install plugins${NC}"
            fi
        fi

        echo -e "${GREEN}Vim installation completed!${NC}"
    fi
}

# Emacs installation
install_emacs() {
    echo -e "${BLUE}Installing Emacs...${NC}"

    if archer_confirm_or_default "Install Emacs?"; then
        install_with_retries pacman emacs

    if archer_confirm_or_default "Install Doom Emacs configuration?"; then
            echo -e "${YELLOW}Installing Doom Emacs...${NC}"

            # Install dependencies
            install_with_retries pacman git ripgrep

            # Backup existing config
            if [ -d "$HOME/.emacs.d" ]; then
                mv "$HOME/.emacs.d" "$HOME/.emacs.d.bak.$(date +%s)"
                echo -e "${YELLOW}Existing Emacs config backed up${NC}"
            fi

            # Install Doom Emacs
            git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.emacs.d
            ~/.emacs.d/bin/doom install

            echo -e "${GREEN}Doom Emacs installed!${NC}"
            echo -e "${BLUE}Add ~/.emacs.d/bin to your PATH to use 'doom' command${NC}"
        fi

        echo -e "${GREEN}Emacs installation completed!${NC}"
    fi
}

# Sublime Text installation
install_sublime() {
    echo -e "${BLUE}Installing Sublime Text...${NC}"

    if archer_confirm_or_default "Install Sublime Text 4?"; then
        install_with_retries yay sublime-text-4

    if archer_confirm_or_default "Install Package Control for Sublime Text?"; then
            echo -e "${YELLOW}Package Control will be installed on first Sublime Text launch${NC}"
            echo -e "${BLUE}Use Ctrl+Shift+P -> 'Install Package Control' after first launch${NC}"
        fi

        echo -e "${GREEN}Sublime Text installation completed!${NC}"
    fi
}

# JetBrains IDEs installation
install_jetbrains() {
    echo -e "${BLUE}Installing JetBrains IDEs...${NC}"

    # JetBrains Toolbox
    if archer_confirm_or_default "Install JetBrains Toolbox (IDE manager)?"; then
        install_with_retries yay jetbrains-toolbox
        echo -e "${GREEN}JetBrains Toolbox installed!${NC}"
        echo -e "${BLUE}Use Toolbox to install specific IDEs (IntelliJ, PyCharm, etc.)${NC}"
    fi

    # Individual IDEs
    if archer_confirm_or_default "Install individual JetBrains IDEs?"; then
        echo -e "${YELLOW}Available JetBrains IDEs:${NC}"
        echo "1. IntelliJ IDEA Community"
        echo "2. PyCharm Community"
        echo "3. WebStorm (requires license)"
        echo "4. PhpStorm (requires license)"
        echo "5. CLion (requires license)"
        echo "6. DataGrip (requires license)"

        ide_choice=$(get_input "Enter IDE numbers separated by spaces (1-6):" "1 2")

        if [[ "$ide_choice" == *"1"* ]]; then
            install_with_retries pacman intellij-idea-community-edition
        fi

        if [[ "$ide_choice" == *"2"* ]]; then
            install_with_retries pacman pycharm-community-edition
        fi

        if [[ "$ide_choice" == *"3"* ]]; then
            install_with_retries yay webstorm
        fi

        if [[ "$ide_choice" == *"4"* ]]; then
            install_with_retries yay phpstorm
        fi

        if [[ "$ide_choice" == *"5"* ]]; then
            install_with_retries yay clion
        fi

        if [[ "$ide_choice" == *"6"* ]]; then
            install_with_retries yay datagrip
        fi

        echo -e "${GREEN}Selected JetBrains IDEs installed!${NC}"
    fi
}

# Atom installation (legacy support)
install_atom() {
    echo -e "${BLUE}Installing Atom (Legacy Editor)...${NC}"
    echo -e "${YELLOW}Note: Atom has been sunset by GitHub. Consider VS Code or VSCodium instead.${NC}"

    if archer_confirm_or_default "Install Atom anyway?"; then
        install_with_retries yay atom-editor-bin
        echo -e "${GREEN}Atom installation completed!${NC}"
    fi
}

# Code editors
install_code_editors() {
    echo -e "${BLUE}Installing other code editors...${NC}"

    # Gedit (simple)
    if archer_confirm_or_default "Install Gedit (simple text editor)?"; then
        install_with_retries pacman gedit
    fi

    # Kate (KDE)
    if archer_confirm_or_default "Install Kate (KDE advanced text editor)?"; then
        install_with_retries pacman kate
    fi

    # Mousepad (lightweight)
    if archer_confirm_or_default "Install Mousepad (lightweight editor)?"; then
        install_with_retries pacman mousepad
    fi

    # CudaText
    if archer_confirm_or_default "Install CudaText (cross-platform editor)?"; then
        install_with_retries yay cudatext-qt5-bin
    fi

    # Notepadqq (Notepad++ clone)
    if archer_confirm_or_default "Install Notepadqq (Notepad++ clone)?"; then
        install_with_retries yay notepadqq
    fi
}

# Specialized IDEs
install_specialized_ides() {
    echo -e "${BLUE}Installing specialized IDEs...${NC}"

    # Qt Creator
    if archer_confirm_or_default "Install Qt Creator (C++/Qt development)?"; then
        install_with_retries pacman qtcreator
    fi

    # Code::Blocks
    if archer_confirm_or_default "Install Code::Blocks (C/C++ IDE)?"; then
        install_with_retries pacman codeblocks
    fi

    # Eclipse
    if archer_confirm_or_default "Install Eclipse IDE?"; then
        install_with_retries yay eclipse-java
    fi

    # NetBeans
    if archer_confirm_or_default "Install Apache NetBeans?"; then
        install_with_retries yay netbeans
    fi

    # Arduino IDE
    if archer_confirm_or_default "Install Arduino IDE?"; then
        install_with_retries pacman arduino
    fi

    # Bluefish (web development)
    if archer_confirm_or_default "Install Bluefish (web development editor)?"; then
        install_with_retries pacman bluefish
    fi
}

# Main installation menu
main() {
    echo -e "${YELLOW}Welcome to the Code Editors & IDEs installation script!${NC}"
    echo -e "${BLUE}This script provides comprehensive editor installation options.${NC}"
    echo ""
    echo -e "${CYAN}Available editor categories:${NC}"
    echo "1. Modern Editors (VS Code, VSCodium, Sublime Text)"
    echo "2. Terminal Editors (Neovim, Vim, Emacs)"
    echo "3. JetBrains IDEs (IntelliJ, PyCharm, WebStorm, etc.)"
    echo "4. Simple Code Editors (Gedit, Kate, Mousepad, etc.)"
    echo "5. Specialized IDEs (Qt Creator, Eclipse, Arduino, etc.)"
    echo "6. All categories (selective installation)"
    echo "0. Custom selection"
    echo ""

    choice=$(get_input "Select installation type (0-6):" "1")

    case "$choice" in
        "1")
            install_vscode
            install_vscodium
            install_sublime
            ;;
        "2")
            install_neovim
            install_vim
            install_emacs
            ;;
        "3")
            install_jetbrains
            ;;
        "4")
            install_code_editors
            ;;
        "5")
            install_specialized_ides
            ;;
        "6")
            echo -e "${BLUE}Installing all editor categories (with confirmations)...${NC}"
            install_vscode
            install_vscodium
            install_sublime
            install_neovim
            install_vim
            install_emacs
            install_jetbrains
            install_code_editors
            install_specialized_ides
            ;;
        "0")
            echo -e "${BLUE}Custom selection mode...${NC}"
            echo -e "${YELLOW}Choose editors to install:${NC}"

            install_vscode
            install_vscodium
            install_neovim
            install_vim
            install_emacs
            install_sublime
            install_jetbrains
            install_atom
            install_code_editors
            install_specialized_ides
            ;;
        *)
            echo -e "${RED}Invalid choice. Running custom selection...${NC}"
            install_vscode
            install_vscodium
            install_neovim
            install_vim
            install_emacs
            install_sublime
            install_jetbrains
            ;;
    esac

    echo -e "${GREEN}
=========================================================================
                    Code Editors & IDEs Installation Complete!
=========================================================================

📝 Installed Editors Summary:
- Check individual confirmations above for what was installed
- Modern editors with extension support
- Terminal-based editors with configurations
- Professional IDEs for various languages
- Simple text editors for quick editing

🚀 Next Steps:
1. Launch your preferred editor to complete any initial setup
2. Install language-specific extensions/plugins as needed
3. Configure editor preferences and themes
4. Set up version control integration (Git)

💡 Pro Tips:
- VS Code: Use Ctrl+Shift+X to browse extensions
- Neovim: Run 'nvim' if LazyVim was installed
- Vim: Run 'vim +PlugInstall' if plugins were configured
- Emacs: Use 'doom sync' if Doom Emacs was installed
- JetBrains: Use Toolbox to manage IDE installations

🎉 Happy coding with your new development environment!

${NC}"

    read -p "Press Enter to continue..."
}

# Run main function
main

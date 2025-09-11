#!/bin/bash
# Haskell Programming Language Installation Script
# Installs GHC, Cabal, and Stack for Haskell development

# ==============================================================================
# CONFIGURATION
# ==============================================================================
TOOL_NAME="Haskell Programming Language"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
ARCHER_DIR="${ARCHER_DIR:-$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")}"

# Source common functions
source "$ARCHER_DIR/install/system/common-funcs.sh"

# ==============================================================================
# INSTALLATION FUNCTIONS
# ==============================================================================

install_haskell_base() {
    log_info "Installing Haskell compiler and tools..."

    # Install Haskell components
    local packages=(
        "ghc"              # Glasgow Haskell Compiler
        "cabal-install"    # Cabal package manager
        "stack"            # Haskell Tool Stack
        "haskell-language-server"  # LSP server
    )

    for package in "${packages[@]}"; do
        if ! pacman -Qi "$package" &>/dev/null; then
            execute_with_progress "sudo pacman -S --noconfirm $package" "Installing $package..."
        fi
    done

    # Verify installation
    if command -v ghc &>/dev/null; then
        local version=$(ghc --version)
        log_success "GHC installed: $version"
    else
        log_error "Failed to install GHC"
        return 1
    fi

    if command -v cabal &>/dev/null; then
        local cabal_version=$(cabal --version | head -n 1)
        log_success "Cabal installed: $cabal_version"
    fi

    if command -v stack &>/dev/null; then
        local stack_version=$(stack --version | head -n 1)
        log_success "Stack installed: $stack_version"
    fi
}

setup_cabal() {
    log_info "Setting up Cabal package manager..."

    # Update Cabal package list
    execute_with_progress "cabal update" "Updating Cabal package list..."

    # Configure Cabal
    local cabal_config="$HOME/.cabal/config"
    if [[ ! -f "$cabal_config" ]]; then
        cabal user-config init
        log_info "Created Cabal configuration"
    fi

    # Install essential development tools
    local essential_packages=(
        "hlint"            # Haskell linter
        "hoogle"           # Haskell search engine
        "stylish-haskell"  # Code formatter
    )

    for package in "${essential_packages[@]}"; do
        execute_with_progress "cabal install $package" "Installing $package..."
    done
}

setup_stack() {
    log_info "Setting up Stack build tool..."

    # Setup Stack (creates ~/.stack/)
    if [[ ! -d "$HOME/.stack" ]]; then
        execute_with_progress "stack setup" "Setting up Stack environment..."
    fi

    # Update Stack package index
    execute_with_progress "stack update" "Updating Stack package index..."
}

create_haskell_projects() {
    log_info "Creating Haskell project templates..."

    local haskell_projects="$HOME/haskell-projects"
    mkdir -p "$haskell_projects"

    # Create a simple Cabal project
    local cabal_project="$haskell_projects/hello-cabal"
    if [[ ! -d "$cabal_project" ]]; then
        mkdir -p "$cabal_project/src"

        # Create cabal file
        cat > "$cabal_project/hello-cabal.cabal" << 'EOF'
cabal-version:      2.4
name:               hello-cabal
version:            0.1.0.0
synopsis:           A simple Haskell project
license:            BSD-3-Clause
author:             Your Name
maintainer:         your.email@example.com
category:           Example
build-type:         Simple

executable hello-cabal
    main-is:          Main.hs
    hs-source-dirs:   src
    build-depends:    base ^>=4.14
    default-language: Haskell2010
EOF

        # Create main source file
        cat > "$cabal_project/src/Main.hs" << 'EOF'
module Main where

main :: IO ()
main = do
    putStrLn "Hello, Haskell!"
    putStrLn "This is a Cabal project."

    -- Demonstrate some basic Haskell features
    let numbers = [1..10]
    putStrLn $ "Numbers: " ++ show numbers
    putStrLn $ "Sum: " ++ show (sum numbers)
    putStrLn $ "Even numbers: " ++ show (filter even numbers)
EOF

        log_info "Created Cabal project: $cabal_project"
    fi

    # Create a Stack project
    local stack_project="$haskell_projects/hello-stack"
    if [[ ! -d "$stack_project" ]]; then
        cd "$haskell_projects"
        execute_with_progress "stack new hello-stack" "Creating Stack project template..."

        # Customize the main file
        cat > "$stack_project/app/Main.hs" << 'EOF'
module Main where

import Lib

main :: IO ()
main = do
    putStrLn "Hello, Stack!"
    putStrLn "This demonstrates Stack project structure."
    someFunc

    -- Demonstrate list comprehensions
    let squares = [x^2 | x <- [1..5]]
    putStrLn $ "Squares: " ++ show squares

    -- Pattern matching example
    let describe n
          | n < 0     = "negative"
          | n == 0    = "zero"
          | n < 10    = "small positive"
          | otherwise = "large positive"

    mapM_ (\x -> putStrLn $ show x ++ " is " ++ describe x) [(-1), 0, 5, 15]
EOF

        log_info "Created Stack project: $stack_project"
    fi
}

setup_haskell_environment() {
    log_info "Setting up Haskell development environment..."

    # Add Cabal and Stack binaries to PATH
    local bashrc="$HOME/.bashrc"
    if [[ -f "$bashrc" ]] && ! grep -q "# Haskell environment" "$bashrc"; then
        cat >> "$bashrc" << 'EOF'

# Haskell environment
export PATH="$HOME/.cabal/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# Haskell aliases
alias ghci='ghci -Wall'
alias haskell-docs='hoogle server --local --port=8080'
EOF
        log_info "Added Haskell environment to ~/.bashrc"
    fi

    # Create GHCi configuration for better REPL experience
    local ghci_conf="$HOME/.ghci"
    if [[ ! -f "$ghci_conf" ]]; then
        cat > "$ghci_conf" << 'EOF'
-- GHCi configuration file
-- Enables useful extensions and imports

:set prompt "λ> "
:set prompt-cont "λ| "

-- Useful language extensions
:set -XOverloadedStrings
:set -XTypeApplications
:set -XScopedTypeVariables

-- Enable multi-line input
:set +m

-- Show types
:set +t

-- Helpful commands
:def hlint \x -> return $ ":! hlint " ++ x
:def hoogle \x -> return $ ":! hoogle search --count=10 " ++ x

-- Welcome message
:def welcome \_ -> return "putStrLn \"Welcome to GHCi! Type :? for help.\""
EOF
        log_info "Created GHCi configuration: ~/.ghci"
    fi
}

print_haskell_info() {
    echo ""
    echo "=============================================="
    echo "Haskell Development Environment Ready!"
    echo "=============================================="
    echo ""
    echo "Installed components:"
    if command -v ghc &>/dev/null; then
        echo "  • GHC: $(ghc --version | cut -d' ' -f8)"
    fi
    if command -v cabal &>/dev/null; then
        echo "  • Cabal: $(cabal --version | head -n 1 | cut -d' ' -f3)"
    fi
    if command -v stack &>/dev/null; then
        echo "  • Stack: $(stack --version | cut -d' ' -f2 | cut -d',' -f1)"
    fi
    echo ""
    echo "Quick start:"
    echo "  ghci                       # Start Haskell REPL"
    echo "  ghc Main.hs                # Compile Haskell file"
    echo "  cabal run                  # Run Cabal project"
    echo "  stack build && stack exec hello-stack  # Build and run Stack project"
    echo ""
    echo "Development tools:"
    echo "  hlint file.hs              # Lint Haskell code"
    echo "  hoogle search \"map\"        # Search for functions"
    echo "  stylish-haskell file.hs    # Format code"
    echo ""
    echo "Example projects:"
    echo "  ~/haskell-projects/hello-cabal  (Cabal project)"
    echo "  ~/haskell-projects/hello-stack  (Stack project)"
    echo ""
    echo "Useful GHCi commands:"
    echo "  :type expr                 # Show type of expression"
    echo "  :info name                 # Show information about name"
    echo "  :browse Module             # Show module contents"
    echo ""
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

main() {
    log_info "Starting $TOOL_NAME installation..."

    # Check system requirements
    check_system_requirements

    # Install Haskell base system
    install_haskell_base || return 1

    # Setup package managers
    setup_cabal
    setup_stack

    # Create project templates
    create_haskell_projects

    # Setup development environment
    setup_haskell_environment

    # Show information
    print_haskell_info

    log_success "$TOOL_NAME installation completed!"
}

# Execute main function
main "$@"

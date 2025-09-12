#!/bin/bash
#
# Archer Linux Enhancement Suite - Shell Wrapper
# This script provides a convenient way to launch the Python-based Archer tool
#

# Set up environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARCHER_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
export ARCHER_DIR

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if python3 is available
check_python() {
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}Error: python3 is not installed or not in PATH${NC}"
        echo -e "${YELLOW}Please install Python 3 before running Archer${NC}"
        echo "On Arch Linux: sudo pacman -S python"
        exit 1
    fi
}

# Function to check if textual is available
check_textual() {
    if ! python3 -c "import textual" 2>/dev/null; then
        echo -e "${RED}Error: textual is not installed${NC}"
        echo -e "${YELLOW}Please install textual before running Archer TUI${NC}"
        echo "On Arch Linux: sudo pacman -S python-textual"
        exit 1
    fi
}

# Function to show help
show_help() {
    cat << 'HELP'
Archer Linux Enhancement Suite

USAGE:
    archer.sh [OPTIONS]

OPTIONS:
    --debug, -d     Show discovered menu structure and exit
    --help, -h      Show this help message
    --version, -v   Show version information
    --check         Check system requirements
    --classic       Use the classic GUM-based interface (archer-old.sh)

EXAMPLES:
    archer.sh                 # Start the TUI interface (default)
    archer.sh --classic       # Use the classic GUM-based interface
    archer.sh --debug         # Debug: show menu structure
    archer.sh --check         # Check if all dependencies are installed

ENVIRONMENT:
    ARCHER_DIR              # Override the Archer installation directory

For more information, visit: https://github.com/Edior-DB/archer
HELP
}

# Function to show version
show_version() {
    echo "Archer Linux Enhancement Suite"
    echo "TUI Implementation with Textual Framework"
    echo
    echo "Repository: https://github.com/Edior-DB/archer"
    echo "License: MIT"
}

# Function to check system requirements
check_requirements() {
    echo -e "${BLUE}Checking Archer system requirements...${NC}"
    echo

    # Check Python
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
        echo -e "${GREEN}✓ Python 3 found:${NC} $PYTHON_VERSION"
    else
        echo -e "${RED}✗ Python 3 not found${NC}"
        return 1
    fi

    # Check Textual for TUI
    if python3 -c "import textual" 2>/dev/null; then
        echo -e "${GREEN}✓ textual found${NC}"
    else
        echo -e "${RED}✗ textual not found${NC}"
        echo -e "${YELLOW}  Install with: sudo pacman -S python-textual${NC}"
        return 1
    fi

    # Check gum for classic interface
    if command -v gum &> /dev/null; then
        echo -e "${GREEN}✓ gum found${NC}"
    else
        echo -e "${YELLOW}~ gum not found (classic interface unavailable)${NC}"
    fi

    # Check Archer directory
    if [[ -d "$ARCHER_DIR" ]]; then
        echo -e "${GREEN}✓ Archer directory found:${NC} $ARCHER_DIR"
    else
        echo -e "${RED}✗ Archer directory not found:${NC} $ARCHER_DIR"
        return 1
    fi

    # Check TUI script
    TUI_SCRIPT="$ARCHER_DIR/bin/archer-tui.py"
    if [[ -f "$TUI_SCRIPT" ]]; then
        echo -e "${GREEN}✓ Archer TUI script found${NC}"
    else
        echo -e "${RED}✗ Archer TUI script not found:${NC} $TUI_SCRIPT"
        return 1
    fi

    # Check Classic script
    CLASSIC_SCRIPT="$ARCHER_DIR/bin/archer-old.sh"
    if [[ -f "$CLASSIC_SCRIPT" ]]; then
        echo -e "${GREEN}✓ Archer Classic script found${NC}"
    else
        echo -e "${YELLOW}~ Archer Classic script not found (optional)${NC}"
    fi

    echo
    echo -e "${GREEN}All requirements satisfied!${NC}"
    return 0
}

# Main script logic
main() {
    # Parse command line arguments
    case "${1:-}" in
        --help|-h)
            show_help
            exit 0
            ;;
        --version|-v)
            show_version
            exit 0
            ;;
        --check)
            check_requirements
            exit $?
            ;;
        --debug|-d)
            check_python
            check_textual
            cd "$ARCHER_DIR"
            exec python3 bin/archer-tui.py --debug
            ;;
        --classic)
            # Use classic GUM-based interface
            cd "$ARCHER_DIR"
            exec ./bin/archer-old.sh
            ;;
        "")
            # No arguments - run TUI by default
            check_python
            check_textual
            cd "$ARCHER_DIR"
            exec python3 bin/archer-tui.py
            ;;
        *)
            echo -e "${RED}Error: Unknown option '$1'${NC}"
            echo "Use 'archer.sh --help' for usage information"
            exit 1
            ;;
    esac
}

# Trap Ctrl+C to provide a clean exit message
trap 'echo -e "\n${YELLOW}Archer interrupted by user${NC}"; exit 130' INT

# Run main function with all arguments
main "$@"

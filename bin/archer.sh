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

# Function to check if python-rich is available
check_rich() {
    if ! python3 -c "import rich" 2>/dev/null; then
        echo -e "${RED}Error: python-rich is not installed${NC}"
        echo -e "${YELLOW}Please install python-rich before running Archer${NC}"
        echo "On Arch Linux: sudo pacman -S python-rich"

        echo "Or via pip: pip3 install rich"
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

EXAMPLES:
    archer.sh                 # Start the interactive menu
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
    echo "Python Implementation with Rich UI"
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

    # Check Rich
    if python3 -c "import rich" 2>/dev/null; then
        echo -e "${GREEN}✓ python-rich found${NC}"
    else
        echo -e "${RED}✗ python-rich not found${NC}"
        return 1
    fi

    # Check Archer directory
    if [[ -d "$ARCHER_DIR" ]]; then
        echo -e "${GREEN}✓ Archer directory found:${NC} $ARCHER_DIR"
    else
        echo -e "${RED}✗ Archer directory not found:${NC} $ARCHER_DIR"
        return 1
    fi

    # Check Python script
    PYTHON_SCRIPT="$ARCHER_DIR/bin/archer.py"
    if [[ -f "$PYTHON_SCRIPT" ]]; then
        echo -e "${GREEN}✓ Archer Python script found${NC}"
    else
        echo -e "${RED}✗ Archer Python script not found:${NC} $PYTHON_SCRIPT"
        return 1
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
            check_rich
            cd "$ARCHER_DIR"
            exec python3 bin/archer.py --debug
            ;;
        "")
            # No arguments - run normally
            check_python
            check_rich
            cd "$ARCHER_DIR"
            exec python3 bin/archer.py
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

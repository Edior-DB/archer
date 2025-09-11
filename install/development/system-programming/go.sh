#!/bin/bash
# Go Programming Language Installation
# Simple, reliable, efficient language by Google

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/../..}/install/system/common-funcs.sh"

show_banner "Go Programming Language"

echo -e "${BLUE}Go - Build simple, reliable, and efficient software${NC}"
echo -e "${YELLOW}Installing via Mise for better version management${NC}"
echo ""

if ! confirm_action "Install Go via Mise?"; then
    echo -e "${YELLOW}Go installation cancelled.${NC}"
    exit 0
fi

# Check if Mise is installed
if ! command -v mise &> /dev/null; then
    echo -e "${YELLOW}Mise not found. Installing Mise first...${NC}"
    if ! install_with_retries mise; then
        echo -e "${YELLOW}Installing Mise via curl...${NC}"
        curl https://mise.run | sh
        echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc
        eval "$(~/.local/bin/mise activate bash)"
    fi
fi

# Initialize mise for current session
eval "$(mise activate bash)" 2>/dev/null || true

echo -e "${BLUE}Installing Go via Mise...${NC}"

if mise install go@latest; then
    echo -e "${GREEN}✓ Go installed successfully!${NC}"

    # Show version
    go_version=$(go version 2>/dev/null || echo "Not available")

    echo -e "${GREEN}
=========================================================================
                        Go Installation Complete!
=========================================================================

Installed version:
  $go_version

Key commands:
  go version               # Check Go version
  go mod init myproject    # Initialize new Go module
  go build                 # Build current package
  go run main.go          # Build and run Go program
  go test                 # Run tests
  go get <package>        # Download and install packages
  go install <package>    # Install packages globally

Useful packages to try:
  go install github.com/gorilla/mux  # Web router
  go install github.com/gin-gonic/gin # Web framework
  go install github.com/spf13/cobra  # CLI applications

Project structure:
  myproject/
  ├── go.mod              # Module definition
  ├── main.go             # Main application
  └── internal/           # Internal packages

Next steps:
- Restart your terminal or run 'source ~/.bashrc'
- Try 'go mod init hello && echo \"package main\" > main.go'
- Use 'mise use go@1.21' in project directories for specific versions
- Explore packages at pkg.go.dev

Version management with Mise:
  mise install go@1.21     # Install specific version
  mise use go@1.21         # Use version in current project
  mise ls go               # List available versions

Documentation: https://golang.org/doc/
${NC}"

else
    echo -e "${RED}✗ Failed to install Go via Mise${NC}"
    echo -e "${YELLOW}Trying fallback installation via pacman...${NC}"
    if install_with_retries go; then
        echo -e "${GREEN}✓ Go installed via pacman${NC}"
    else
        echo -e "${RED}✗ Failed to install Go${NC}"
        exit 1
    fi
fi

wait_for_input

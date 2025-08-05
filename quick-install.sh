#!/bin/bash

# Archer Quick Installer - Network-Aware Download Script
# This script handles common Live ISO network issues

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Archer Installation Network Setup${NC}"
echo "=================================="

# Function to test network connectivity
test_network() {
    echo -e "${BLUE}Testing network connectivity...${NC}"

    # Test basic connectivity
    if ping -c 1 8.8.8.8 &>/dev/null; then
        echo -e "${GREEN}✓ Internet connectivity: OK${NC}"
    else
        echo -e "${RED}✗ No internet connectivity${NC}"
        echo -e "${YELLOW}Please ensure you have network access before continuing.${NC}"
        exit 1
    fi

    # Test DNS resolution
    if ping -c 1 github.com &>/dev/null; then
        echo -e "${GREEN}✓ DNS resolution: OK${NC}"
    else
        echo -e "${YELLOW}⚠ DNS resolution issues detected${NC}"
        echo -e "${BLUE}Attempting to fix DNS...${NC}"

        # Backup existing resolv.conf
        cp /etc/resolv.conf /etc/resolv.conf.backup 2>/dev/null || true

        # Add reliable DNS servers
        cat > /etc/resolv.conf << EOF
nameserver 1.1.1.1
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF

        # Test again
        if ping -c 1 github.com &>/dev/null; then
            echo -e "${GREEN}✓ DNS fixed successfully${NC}"
        else
            echo -e "${RED}✗ DNS issues persist${NC}"
            echo -e "${YELLOW}Falling back to git clone method...${NC}"
            return 1
        fi
    fi

    return 0
}

# Function to download via curl
download_curl() {
    echo -e "${BLUE}Downloading installer via curl...${NC}"

    local url="https://raw.githubusercontent.com/Edior-DB/archer/master/install.sh"
    local temp_file="/tmp/archer_install.sh"

    # Try multiple curl methods
    local methods=(
        "curl -fsSL"
        "curl -fsSL --ipv4"
        "curl -fsSL --retry 3"
        "curl -fsSL --connect-timeout 10"
    )

    for method in "${methods[@]}"; do
        echo -e "${YELLOW}Trying: $method${NC}"
        if $method "$url" -o "$temp_file" 2>/dev/null; then
            echo -e "${GREEN}✓ Download successful${NC}"
            chmod +x "$temp_file"
            exec "$temp_file" "$@"
        fi
    done

    echo -e "${RED}✗ All curl methods failed${NC}"
    return 1
}

# Function to download via git
download_git() {
    echo -e "${BLUE}Downloading installer via git clone...${NC}"

    # Install git if not available
    if ! command -v git &>/dev/null; then
        echo -e "${YELLOW}Installing git...${NC}"
        pacman -Sy git --noconfirm
    fi

    local temp_dir="/tmp/archer_$(date +%s)"

    if git clone https://github.com/Edior-DB/archer.git "$temp_dir"; then
        echo -e "${GREEN}✓ Git clone successful${NC}"
        cd "$temp_dir"
        exec ./install.sh "$@"
    else
        echo -e "${RED}✗ Git clone failed${NC}"
        return 1
    fi
}

# Main execution
main() {
    echo -e "${BLUE}Starting Archer installation...${NC}"
    echo ""

    # Test network first
    if test_network; then
        # Try curl method first
        if ! download_curl "$@"; then
            echo -e "${YELLOW}Curl method failed, trying git clone...${NC}"
            download_git "$@"
        fi
    else
        # Network/DNS issues, use git clone
        download_git "$@"
    fi
}

# Check if running as root (required for Live ISO)
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}This script must be run as root (you are in Live ISO, right?)${NC}"
    echo -e "${YELLOW}Try: sudo $0 $@${NC}"
    exit 1
fi

main "$@"

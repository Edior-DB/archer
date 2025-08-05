#!/bin/bash

# Post-Installation Setup Script
# Installs essential packages and sets up AUR helper

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

echo -e "${BLUE}
=========================================================================
                    Post-Installation Setup
=========================================================================
${NC}"

# Update system
echo -e "${BLUE}Updating system packages...${NC}"
sudo pacman -Syu --noconfirm

# Essential packages
echo -e "${BLUE}Installing essential packages...${NC}"
essential_packages=(
    # System utilities
    "base-devel"
    "linux-headers"
    "dkms"
    "curl"
    "wget"
    "git"
    "vim"
    "nano"
    "htop"
    "btop"
    "neofetch"
    "tree"
    "unzip"
    "zip"
    "tar"
    "rsync"

    # Network tools
    "networkmanager"
    "network-manager-applet"
    "wireless_tools"
    "wpa_supplicant"
    "openssh"

    # Audio
    "pipewire"
    "pipewire-alsa"
    "pipewire-pulse"
    "pipewire-jack"
    "wireplumber"

    # Fonts
    "ttf-dejavu"
    "ttf-liberation"
    "noto-fonts"
    "noto-fonts-emoji"

    # Archive tools
    "p7zip"
    "unrar"

    # System monitoring
    "lm_sensors"
    "smartmontools"

    # File systems
    "ntfs-3g"
    "exfat-utils"

    # Development basics
    "gcc"
    "make"
    "cmake"
    "pkg-config"
)

for package in "${essential_packages[@]}"; do
    if ! pacman -Qi "$package" &> /dev/null; then
        echo -e "${YELLOW}Installing $package...${NC}"
        sudo pacman -S --noconfirm "$package"
    else
        echo -e "${GREEN}$package already installed${NC}"
    fi
done

# Install AUR helper (yay)
if ! command -v yay &> /dev/null; then
    echo -e "${BLUE}Installing yay AUR helper...${NC}"
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd /
    rm -rf /tmp/yay
    echo -e "${GREEN}yay installed successfully!${NC}"
else
    echo -e "${GREEN}yay already installed${NC}"
fi

# Enable essential services
echo -e "${BLUE}Enabling essential services...${NC}"

services=(
    "NetworkManager"
    "bluetooth"
    "sshd"
)

for service in "${services[@]}"; do
    if systemctl list-unit-files | grep -q "$service.service"; then
        echo -e "${YELLOW}Enabling $service...${NC}"
        sudo systemctl enable "$service"
    fi
done

# Set up user directories
echo -e "${BLUE}Setting up user directories...${NC}"
if command -v xdg-user-dirs-update &> /dev/null; then
    xdg-user-dirs-update
else
    sudo pacman -S --noconfirm xdg-user-dirs
    xdg-user-dirs-update
fi

# Configure pacman
echo -e "${BLUE}Configuring pacman...${NC}"
sudo sed -i 's/#Color/Color/' /etc/pacman.conf
sudo sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 10/' /etc/pacman.conf
sudo sed -i '/^#\[multilib\]/,/^#Include/ { s/^#//; }' /etc/pacman.conf

# Update package database after enabling multilib
sudo pacman -Sy

# Install additional useful AUR packages
echo -e "${BLUE}Installing useful AUR packages...${NC}"

aur_packages=(
    "google-chrome"
    "visual-studio-code-bin"
    "discord"
    "spotify"
    "timeshift"
    "timeshift-autosnap"
)

echo -e "${YELLOW}The following AUR packages are recommended:${NC}"
for package in "${aur_packages[@]}"; do
    echo "  - $package"
done

if confirm_action "Install recommended AUR packages?"; then
    for package in "${aur_packages[@]}"; do
        echo -e "${YELLOW}Installing $package...${NC}"
        yay -S --noconfirm "$package" || echo -e "${RED}Failed to install $package${NC}"
    done
fi

# Create useful aliases
echo -e "${BLUE}Setting up useful aliases...${NC}"
cat >> ~/.bashrc << 'EOF'

# Archer aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias update='sudo pacman -Syu'
alias install='sudo pacman -S'
alias search='pacman -Ss'
alias remove='sudo pacman -R'
alias autoremove='sudo pacman -Rns $(pacman -Qtdq)'
alias yayupdate='yay -Syu'
alias yayinstall='yay -S'
alias yaysearch='yay -Ss'
alias cleanup='sudo pacman -Rns $(pacman -Qtdq); sudo pacman -Sc'
alias mirrors='sudo reflector --latest 20 --sort rate --save /etc/pacman.d/mirrorlist'
alias fastmirrors='sudo reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist'

# System info
alias sysinfo='neofetch'
alias diskspace='df -h'
alias meminfo='free -h'
alias cpuinfo='lscpu'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gps='git push'
alias gpl='git pull'
alias gd='git diff'
alias gl='git log --oneline'

EOF

# Set up automatic mirror updates
echo -e "${BLUE}Setting up automatic mirror updates...${NC}"
if ! pacman -Qi reflector &> /dev/null; then
    sudo pacman -S --noconfirm reflector
fi

sudo systemctl enable reflector.timer

# Configure reflector
sudo tee /etc/xdg/reflector/reflector.conf > /dev/null << 'EOF'
--save /etc/pacman.d/mirrorlist
--protocol https
--country 'United States,Canada,Germany,France,United Kingdom'
--latest 20
--sort rate
EOF

echo -e "${GREEN}
=========================================================================
                    Post-Installation Setup Complete!
=========================================================================

Essential packages installed:
- Base development tools
- Network management
- Audio system (PipeWire)
- Essential fonts
- Archive tools
- System monitoring tools

AUR helper (yay) installed and configured.
Useful aliases added to ~/.bashrc
Automatic mirror updates configured.

Next steps:
- Reboot to ensure all services are running
- Run other Archer scripts for desktop environment, development tools, etc.
- Consider running 'source ~/.bashrc' to load new aliases

${NC}"

wait_for_input

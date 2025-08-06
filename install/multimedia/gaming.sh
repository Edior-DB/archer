#!/bin/bash

# Gaming Package Installation Script
# Part of Archer - Arch Linux Home PC Transformation Suite

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/../system}/common-funcs.sh"

show_banner "Gaming Setup for Arch Linux"

# Check if AUR helper is available
if ! check_aur_helper; then
    echo -e "${RED}AUR helper not found. Please run post-install.sh first.${NC}"
    exit 1
fi

# Install gaming platforms
install_gaming_platforms() {
    echo -e "${BLUE}Installing gaming platforms...${NC}"

    # Steam
    if confirm_action "Install Steam?"; then
        echo -e "${YELLOW}Installing Steam...${NC}"
        sudo pacman -S --noconfirm steam
        echo -e "${GREEN}Steam installed!${NC}"
    fi

    # Lutris
    if confirm_action "Install Lutris (Game manager for Wine, emulators, etc.)?"; then
        echo -e "${YELLOW}Installing Lutris...${NC}"
        sudo pacman -S --noconfirm lutris
        echo -e "${GREEN}Lutris installed!${NC}"
    fi

    # Heroic Games Launcher (Epic Games, GOG)
    if confirm_action "Install Heroic Games Launcher (Epic Games & GOG)?"; then
        echo -e "${YELLOW}Installing Heroic Games Launcher...${NC}"
        yay -S --noconfirm heroic-games-launcher-bin
        echo -e "${GREEN}Heroic Games Launcher installed!${NC}"
    fi

    # GameHub (Steam, GOG, Humble Bundle)
    if confirm_action "Install GameHub (Multi-platform game manager)?"; then
        echo -e "${YELLOW}Installing GameHub...${NC}"
        yay -S --noconfirm gamehub
        echo -e "${GREEN}GameHub installed!${NC}"
    fi
}

# Install Wine and related tools
install_wine() {
    echo -e "${BLUE}Installing Wine and Windows compatibility layer...${NC}"

    # Wine
    if ! confirm_action "Install Wine (Windows compatibility layer)?"; then
        echo -e "${YELLOW}Skipping Wine installation${NC}"
        return
    fi

    echo -e "${YELLOW}Installing Wine and dependencies...${NC}"

    # Wine packages
    wine_packages=(
        "wine"
        "wine-gecko"
        "wine-mono"
        "winetricks"
        "lib32-gnutls"
        "lib32-libxcomposite"
        "lib32-libxinerama"
        "lib32-ncurses"
        "lib32-opencl-icd-loader"
        "lib32-v4l-utils"
        "libpulse"
        "lib32-libpulse"
        "alsa-plugins"
        "lib32-alsa-plugins"
    )

    for package in "${wine_packages[@]}"; do
        sudo pacman -S --noconfirm "$package" || echo -e "${YELLOW}Failed to install $package${NC}"
    done

    # Bottles (Modern Wine prefix manager)
    if confirm_action "Install Bottles (Modern Wine prefix manager)?"; then
    if [[ "$install_bottles" =~ ^[Nn]$ ]]; then
        echo -e "${YELLOW}Skipping Bottles installation${NC}"
    else
        echo -e "${YELLOW}Installing Bottles...${NC}"
        yay -S --noconfirm bottles
        echo -e "${GREEN}Bottles installed!${NC}"
        echo -e "${BLUE}Bottles provides a modern, user-friendly interface for managing Wine prefixes${NC}"
    fi

    # PlayOnLinux (Alternative Wine frontend)
    read -p "Install PlayOnLinux (Alternative Wine frontend)? (y/N): " install_pol
    if [[ "$install_pol" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Installing PlayOnLinux...${NC}"
        yay -S --noconfirm playonlinux
        echo -e "${GREEN}PlayOnLinux installed!${NC}"
    fi

    echo -e "${GREEN}Wine setup completed!${NC}"
    echo -e "${BLUE}Tip: Use 'winecfg' to configure Wine, or use Bottles for a GUI experience${NC}"
}

# Install gaming-related libraries and drivers
install_gaming_libraries() {
    echo -e "${BLUE}Installing gaming libraries and drivers...${NC}"

    # Graphics drivers
    echo -e "${YELLOW}Installing graphics drivers and libraries...${NC}"

    # Vulkan support
    vulkan_packages=(
        "vulkan-icd-loader"
        "lib32-vulkan-icd-loader"
        "vulkan-tools"
    )

    # Detect GPU and install appropriate drivers
    gpu_info=$(lspci | grep -E "VGA|3D|Display")

    if echo "$gpu_info" | grep -qi nvidia; then
        echo -e "${BLUE}NVIDIA GPU detected${NC}"
        vulkan_packages+=("nvidia-utils" "lib32-nvidia-utils")

        # Install NVIDIA drivers if not present
        if ! pacman -Qi nvidia &> /dev/null && ! pacman -Qi nvidia-lts &> /dev/null; then
            read -p "Install NVIDIA drivers? (Y/n): " install_nvidia
            if [[ ! "$install_nvidia" =~ ^[Nn]$ ]]; then
                if pacman -Qi linux-lts &> /dev/null; then
                    sudo pacman -S --noconfirm nvidia-lts
                else
                    sudo pacman -S --noconfirm nvidia
                fi
            fi
        fi
    elif echo "$gpu_info" | grep -qi amd; then
        echo -e "${BLUE}AMD GPU detected${NC}"
        vulkan_packages+=("amdvlk" "lib32-amdvlk" "mesa" "lib32-mesa")
    elif echo "$gpu_info" | grep -qi intel; then
        echo -e "${BLUE}Intel GPU detected${NC}"
        vulkan_packages+=("vulkan-intel" "lib32-vulkan-intel" "mesa" "lib32-mesa")
    fi

    # Install Vulkan packages
    for package in "${vulkan_packages[@]}"; do
        sudo pacman -S --noconfirm "$package" || echo -e "${YELLOW}Failed to install $package${NC}"
    done

    # Gaming libraries
    echo -e "${YELLOW}Installing gaming libraries...${NC}"
    gaming_libs=(
        "lib32-alsa-lib"
        "lib32-alsa-plugins"
        "lib32-freetype2"
        "lib32-glibc"
        "lib32-libpulse"
        "lib32-openal"
        "lib32-mesa"
        "lib32-fontconfig"
        "lib32-libxcursor"
        "lib32-libxrandr"
        "lib32-libxinerama"
        "lib32-libxi"
        "lib32-sdl2"
    )

    for lib in "${gaming_libs[@]}"; do
        sudo pacman -S --noconfirm "$lib" || echo -e "${YELLOW}Failed to install $lib${NC}"
    done
}

# Install emulators
install_emulators() {
    echo -e "${BLUE}Installing game emulators...${NC}"

    emulators=(
        "RetroArch (Multi-system emulator)"
        "PCSX2 (PlayStation 2)"
        "Dolphin (GameCube/Wii)"
        "RPCS3 (PlayStation 3)"
        "Cemu (Wii U)"
        "melonDS (Nintendo DS)"
        "mGBA (Game Boy Advance)"
    )

    echo -e "${YELLOW}Available emulators:${NC}"
    for i, emulator in "${emulators[@]}"; do
        echo "  $((i+1)). $emulator"
    done

    read -p "Install emulators? Enter numbers separated by spaces (e.g., 1 3 4) or 'all' for all, 'none' to skip: " emulator_choice

    case "$emulator_choice" in
        "none"|"")
            echo -e "${YELLOW}Skipping emulator installation${NC}"
            ;;
        "all")
            sudo pacman -S --noconfirm retroarch retroarch-assets-xmb retroarch-assets-ozone
            yay -S --noconfirm pcsx2 dolphin-emu rpcs3-bin cemu melonds-git mgba-qt
            ;;
        *)
            if [[ "$emulator_choice" == *"1"* ]]; then
                sudo pacman -S --noconfirm retroarch retroarch-assets-xmb retroarch-assets-ozone
            fi
            if [[ "$emulator_choice" == *"2"* ]]; then
                yay -S --noconfirm pcsx2
            fi
            if [[ "$emulator_choice" == *"3"* ]]; then
                sudo pacman -S --noconfirm dolphin-emu
            fi
            if [[ "$emulator_choice" == *"4"* ]]; then
                yay -S --noconfirm rpcs3-bin
            fi
            if [[ "$emulator_choice" == *"5"* ]]; then
                yay -S --noconfirm cemu
            fi
            if [[ "$emulator_choice" == *"6"* ]]; then
                yay -S --noconfirm melonds-git
            fi
            if [[ "$emulator_choice" == *"7"* ]]; then
                sudo pacman -S --noconfirm mgba-qt
            fi
            ;;
    esac
}

# Gaming optimizations
apply_gaming_optimizations() {
    echo -e "${BLUE}Applying gaming optimizations...${NC}"

    # Gamemode (CPU governor and process priority optimization)
    read -p "Install GameMode (automatic CPU optimization for games)? (Y/n): " install_gamemode
    if [[ ! "$install_gamemode" =~ ^[Nn]$ ]]; then
        sudo pacman -S --noconfirm gamemode lib32-gamemode
        echo -e "${GREEN}GameMode installed! Games will automatically optimize CPU performance${NC}"
    fi

    # MangoHud (Gaming overlay for monitoring)
    read -p "Install MangoHud (FPS and system monitoring overlay)? (Y/n): " install_mangohud
    if [[ ! "$install_mangohud" =~ ^[Nn]$ ]]; then
        sudo pacman -S --noconfirm mangohud lib32-mangohud
        echo -e "${GREEN}MangoHud installed! Use 'mangohud %command%' in Steam launch options${NC}"
    fi

    # GOverlay (MangoHud GUI configuration)
    read -p "Install GOverlay (GUI for MangoHud configuration)? (y/N): " install_goverlay
    if [[ "$install_goverlay" =~ ^[Yy]$ ]]; then
        yay -S --noconfirm goverlay-bin
        echo -e "${GREEN}GOverlay installed!${NC}"
    fi

    # Gaming kernel optimizations
    read -p "Apply kernel optimizations for gaming? (Y/n): " apply_kernel_opts
    if [[ ! "$apply_kernel_opts" =~ ^[Nn]$ ]]; then
        echo -e "${YELLOW}Applying kernel optimizations...${NC}"

        # Create gaming sysctl configuration
        sudo tee /etc/sysctl.d/99-gaming.conf > /dev/null << 'EOF'
# Gaming optimizations
vm.max_map_count = 2147483642
kernel.sched_autogroup_enabled = 0
EOF

        echo -e "${GREEN}Kernel optimizations applied! (Will take effect after reboot)${NC}"
    fi
}

# Install additional gaming tools
install_gaming_tools() {
    echo -e "${BLUE}Installing additional gaming tools...${NC}"

    # Discord
    read -p "Install Discord? (Y/n): " install_discord
    if [[ ! "$install_discord" =~ ^[Nn]$ ]]; then
        yay -S --noconfirm discord
        echo -e "${GREEN}Discord installed!${NC}"
    fi

    # OBS Studio for streaming
    read -p "Install OBS Studio (for game streaming/recording)? (Y/n): " install_obs
    if [[ ! "$install_obs" =~ ^[Nn]$ ]]; then
        sudo pacman -S --noconfirm obs-studio
        echo -e "${GREEN}OBS Studio installed!${NC}"
    fi

    # Steam Tinker Launch (Advanced Steam tool)
    read -p "Install Steam Tinker Launch (Advanced Steam tweaking tool)? (y/N): " install_stl
    if [[ "$install_stl" =~ ^[Yy]$ ]]; then
        yay -S --noconfirm steam-tinker-launch
        echo -e "${GREEN}Steam Tinker Launch installed!${NC}"
    fi
}

# Main execution
main() {
    echo -e "${YELLOW}This script will set up a complete gaming environment on Arch Linux.${NC}"
    echo -e "${BLUE}This includes Steam, Lutris, Wine, Bottles, emulators, and gaming optimizations.${NC}"
    echo ""
    read -p "Continue with gaming setup? (Y/n): " continue_install

    if [[ "$continue_install" =~ ^[Nn]$ ]]; then
        echo -e "${YELLOW}Gaming setup cancelled.${NC}"
        exit 0
    fi

    # Update system first
    sudo pacman -Syu --noconfirm

    # Run installation steps
    enable_multilib
    install_gaming_libraries
    install_gaming_platforms
    install_wine
    install_emulators
    apply_gaming_optimizations
    install_gaming_tools

    echo -e "${GREEN}
=========================================================================
                        Gaming Setup Complete!
=========================================================================

🎮 Gaming Platforms Installed:
- Steam (if selected)
- Lutris (if selected)
- Heroic Games Launcher (if selected)

🍷 Wine & Windows Compatibility:
- Wine with all dependencies
- Bottles for easy prefix management
- Winetricks for additional Windows components

🎯 Gaming Optimizations:
- GameMode for automatic CPU optimization
- MangoHud for performance monitoring
- Vulkan drivers for your GPU
- Gaming-specific kernel optimizations

🕹️ Emulators (if selected):
- RetroArch for classic consoles
- Modern system emulators (PS2, PS3, Wii, etc.)

📋 Next Steps:
1. Reboot to ensure all optimizations take effect
2. Open Steam and enable Proton for Windows games
3. Use Bottles to create Wine prefixes for Windows applications
4. Configure Lutris for non-Steam games
5. Launch games with 'mangohud %command%' for monitoring

🎊 Happy Gaming on Arch Linux!

${NC}"

    read -p "Press Enter to continue..."
}

# Run main function
main

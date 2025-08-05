#!/bin/bash

# GPU Driver Detection and Installation Script for Arch Linux
# Automatically detects GPU hardware and installs optimal drivers

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}
=========================================================================
                    GPU Driver Detection & Installation
=========================================================================
${NC}"

# Global variables
DETECTED_GPUS=()
RECOMMENDED_DRIVERS=()
NVIDIA_DETECTED=false
AMD_DETECTED=false
INTEL_DETECTED=false

# Check if running kernel is LTS
check_kernel_version() {
    local current_kernel=$(uname -r)
    if [[ "$current_kernel" == *"lts"* ]]; then
        echo -e "${GREEN}LTS kernel detected: $current_kernel${NC}"
        return 0
    else
        echo -e "${YELLOW}Standard kernel detected: $current_kernel${NC}"
        return 1
    fi
}

# Detect all GPUs in the system
detect_gpus() {
    echo -e "${BLUE}Detecting GPU hardware...${NC}"

    # Get detailed GPU information
    local gpu_info=$(lspci -nn | grep -E "VGA|3D|Display")

    if [[ -z "$gpu_info" ]]; then
        echo -e "${RED}No GPU detected! This might be a headless system.${NC}"
        exit 1
    fi

    echo -e "${CYAN}Detected GPU(s):${NC}"
    echo "$gpu_info"
    echo ""

    # Parse GPU information
    while IFS= read -r line; do
        DETECTED_GPUS+=("$line")

        # Check for NVIDIA
        if echo "$line" | grep -qi "nvidia\|geforce\|quadro\|tesla"; then
            NVIDIA_DETECTED=true
            echo -e "${GREEN}✓ NVIDIA GPU detected${NC}"
        fi

        # Check for AMD
        if echo "$line" | grep -qi "amd\|ati\|radeon\|rx \|vega\|navi"; then
            AMD_DETECTED=true
            echo -e "${GREEN}✓ AMD GPU detected${NC}"
        fi

        # Check for Intel
        if echo "$line" | grep -qi "intel.*graphics\|intel.*display\|intel.*uhd\|intel.*iris"; then
            INTEL_DETECTED=true
            echo -e "${GREEN}✓ Intel GPU detected${NC}"
        fi
    done <<< "$gpu_info"

    echo ""
}

# Check for virtualization environment
check_virtualization() {
    echo -e "${BLUE}Checking for virtualization environment...${NC}"

    local virt_detected=false
    local virt_type=""

    # Check for common virtualization indicators
    if lspci | grep -qi "virtio\|vmware\|virtualbox\|qemu\|bochs"; then
        virt_detected=true

        if lspci | grep -qi "virtio"; then
            virt_type="VirtIO (QEMU/KVM)"
        elif lspci | grep -qi "vmware"; then
            virt_type="VMware"
        elif lspci | grep -qi "virtualbox"; then
            virt_type="VirtualBox"
        fi
    fi

    # Check systemd-detect-virt if available
    if command -v systemd-detect-virt &> /dev/null; then
        local detected_virt=$(systemd-detect-virt 2>/dev/null || echo "none")
        if [[ "$detected_virt" != "none" ]]; then
            virt_detected=true
            virt_type="$detected_virt"
        fi
    fi

    # Check DMI information
    if [[ -r /sys/class/dmi/id/product_name ]]; then
        local product_name=$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "")
        if echo "$product_name" | grep -qi "virtual\|vmware\|qemu\|kvm\|virtualbox"; then
            virt_detected=true
            if [[ -z "$virt_type" ]]; then
                virt_type="$product_name"
            fi
        fi
    fi

    if [[ "$virt_detected" == true ]]; then
        echo -e "${YELLOW}⚠ Virtualization detected: $virt_type${NC}"
        echo -e "${CYAN}Recommended virtualization enhancements:${NC}"

        case "$virt_type" in
            *"virtio"*|*"qemu"*|*"kvm"*)
                echo "  • qemu-guest-agent - Better host-guest communication"
                echo "  • spice-vdagent - Enhanced display and clipboard integration"
                echo "  • xf86-video-qxl - Optimized graphics driver for SPICE"
                ;;
            *"vmware"*)
                echo "  • open-vm-tools - VMware guest utilities"
                echo "  • xf86-input-vmmouse - Enhanced mouse integration"
                echo "  • xf86-video-vmware - VMware graphics driver"
                ;;
            *"virtualbox"*)
                echo "  • virtualbox-guest-utils - VirtualBox guest additions"
                echo "  • virtualbox-guest-modules-arch - Kernel modules for VBox"
                ;;
        esac

        echo ""
        echo -e "${YELLOW}Would you like to install virtualization enhancements? (y/N)${NC}"
        read -r install_virt

        if [[ "$install_virt" =~ ^[Yy]$ ]]; then
            install_virtualization_tools "$virt_type"
        fi

        return 0  # Return success to indicate virtualization detected
    else
        echo -e "${GREEN}✓ Running on physical hardware${NC}"
        return 1  # Return failure to indicate no virtualization
    fi
}

# Install virtualization tools
install_virtualization_tools() {
    local virt_type="$1"

    echo -e "${BLUE}Installing virtualization enhancements...${NC}"

    case "$virt_type" in
        *"virtio"*|*"qemu"*|*"kvm"*)
            sudo pacman -S --noconfirm qemu-guest-agent spice-vdagent
            # Enable guest agent
            sudo systemctl enable qemu-guest-agent
            sudo systemctl start qemu-guest-agent

            # Install QXL driver if X11 is available
            if command -v X &> /dev/null; then
                sudo pacman -S --noconfirm xf86-video-qxl
            fi
            ;;
        *"vmware"*)
            sudo pacman -S --noconfirm open-vm-tools
            sudo systemctl enable vmtoolsd
            sudo systemctl start vmtoolsd

            # Install VMware-specific drivers
            if command -v X &> /dev/null; then
                sudo pacman -S --noconfirm xf86-input-vmmouse xf86-video-vmware
            fi
            ;;
        *"virtualbox"*)
            sudo pacman -S --noconfirm virtualbox-guest-utils
            sudo systemctl enable vboxservice
            sudo systemctl start vboxservice

            # Load VirtualBox modules
            sudo modprobe vboxguest vboxsf vboxvideo
            ;;
    esac

    echo -e "${GREEN}✓ Virtualization tools installed${NC}"
    echo -e "${YELLOW}Note: You may need to reboot for full functionality${NC}"
}

# Get detailed NVIDIA GPU information
get_nvidia_details() {
    local gpu_line="$1"
    local gpu_id=$(echo "$gpu_line" | grep -o '\[.*\]' | tail -1 | tr -d '[]' | cut -d: -f2)

    # Common NVIDIA GPU families and their recommended drivers
    case "$gpu_id" in
        # RTX 40 series (Ada Lovelace)
        2684|2685|2687|2688|2689|268a|268b|268e|268f)
            echo "RTX 40 Series (Ada Lovelace) - Latest proprietary driver recommended"
            ;;
        # RTX 30 series (Ampere)
        220*|221*|222*|223*|224*|225*)
            echo "RTX 30 Series (Ampere) - Proprietary driver recommended"
            ;;
        # RTX 20 series (Turing)
        1e0*|1e8*|1f0*|1f5*)
            echo "RTX 20/GTX 16 Series (Turing) - Proprietary driver recommended"
            ;;
        # GTX 10 series (Pascal)
        1b0*|1b8*|1c0*|1c2*|1c6*|1c8*|1d0*)
            echo "GTX 10 Series (Pascal) - Proprietary driver recommended"
            ;;
        # GTX 900 series (Maxwell 2.0)
        13c*|13d*|13f*|174*)
            echo "GTX 900 Series (Maxwell 2.0) - Proprietary driver (legacy support ending soon)"
            ;;
        # GTX 700/600 series (Kepler)
        0fc*|0fd*|0fe*|0ff*|100*|101*|102*|103*|104*|105*|106*|107*|108*|109*|118*|119*|11a*|11b*|11c*)
            echo "GTX 700/600 Series (Kepler) - Legacy driver (nvidia-470xx-dkms)"
            ;;
        *)
            echo "Unknown NVIDIA GPU - Will attempt latest driver"
            ;;
    esac
}

# Analyze NVIDIA drivers and make recommendations
analyze_nvidia_drivers() {
    echo -e "${BLUE}Analyzing NVIDIA GPU(s)...${NC}"

    local legacy_required=false
    local modern_gpu=false

    for gpu in "${DETECTED_GPUS[@]}"; do
        if echo "$gpu" | grep -qi "nvidia\|geforce\|quadro"; then
            echo -e "${CYAN}Analyzing: ${gpu}${NC}"
            local details=$(get_nvidia_details "$gpu")
            echo "  → $details"

            # Check if legacy driver is needed
            if echo "$details" | grep -qi "legacy\|kepler"; then
                legacy_required=true
            else
                modern_gpu=true
            fi
        fi
    done

    # Determine best driver strategy
    if [[ "$legacy_required" == true && "$modern_gpu" == true ]]; then
        echo -e "${YELLOW}⚠️  Mixed NVIDIA GPUs detected (legacy + modern)${NC}"
        echo -e "${YELLOW}   This configuration may require manual driver selection.${NC}"
        RECOMMENDED_DRIVERS+=("nvidia-mixed")
    elif [[ "$legacy_required" == true ]]; then
        echo -e "${BLUE}→ Legacy NVIDIA driver recommended${NC}"
        RECOMMENDED_DRIVERS+=("nvidia-legacy")
    else
        echo -e "${BLUE}→ Latest NVIDIA driver recommended${NC}"
        RECOMMENDED_DRIVERS+=("nvidia-latest")
    fi

    echo ""
}

# Analyze AMD drivers
analyze_amd_drivers() {
    echo -e "${BLUE}Analyzing AMD GPU(s)...${NC}"

    for gpu in "${DETECTED_GPUS[@]}"; do
        if echo "$gpu" | grep -qi "amd\|ati\|radeon"; then
            echo -e "${CYAN}Analyzing: ${gpu}${NC}"

            # Check for older AMD/ATI cards that need legacy drivers
            if echo "$gpu" | grep -qi "r600\|r700\|evergreen\|northern islands"; then
                echo "  → Legacy AMD/ATI card - Open source driver (mesa)"
                RECOMMENDED_DRIVERS+=("amd-legacy")
            else
                echo "  → Modern AMD card - AMDGPU driver recommended"
                RECOMMENDED_DRIVERS+=("amd-modern")
            fi
        fi
    done

    echo ""
}

# Analyze Intel drivers
analyze_intel_drivers() {
    echo -e "${BLUE}Analyzing Intel GPU(s)...${NC}"

    for gpu in "${DETECTED_GPUS[@]}"; do
        if echo "$gpu" | grep -qi "intel"; then
            echo -e "${CYAN}Analyzing: ${gpu}${NC}"
            echo "  → Intel integrated graphics - Open source driver recommended"
            RECOMMENDED_DRIVERS+=("intel-modern")
        fi
    done

    echo ""
}

# Install NVIDIA drivers
install_nvidia_drivers() {
    local driver_type="$1"
    local is_lts=$(check_kernel_version && echo "true" || echo "false")

    echo -e "${BLUE}Installing NVIDIA drivers...${NC}"

    case "$driver_type" in
        "nvidia-latest")
            if [[ "$is_lts" == "true" ]]; then
                echo -e "${YELLOW}Installing NVIDIA LTS drivers...${NC}"
                sudo pacman -S --noconfirm nvidia-lts nvidia-utils lib32-nvidia-utils nvidia-settings
            else
                echo -e "${YELLOW}Installing NVIDIA standard drivers...${NC}"
                sudo pacman -S --noconfirm nvidia nvidia-utils lib32-nvidia-utils nvidia-settings
            fi

            # Install additional NVIDIA packages
            sudo pacman -S --noconfirm nvidia-prime opencl-nvidia lib32-opencl-nvidia
            ;;

        "nvidia-legacy")
            echo -e "${YELLOW}Installing legacy NVIDIA drivers (470xx)...${NC}"
            # Check if AUR helper is available
            if command -v yay &> /dev/null; then
                yay -S --noconfirm nvidia-470xx-dkms nvidia-470xx-utils lib32-nvidia-470xx-utils nvidia-470xx-settings
            else
                echo -e "${RED}AUR helper required for legacy NVIDIA drivers. Please install yay first.${NC}"
                return 1
            fi
            ;;

        "nvidia-mixed")
            echo -e "${YELLOW}Mixed NVIDIA GPU configuration detected.${NC}"
            echo -e "${YELLOW}Please choose driver manually:${NC}"
            echo "1. Latest driver (for modern GPUs)"
            echo "2. Legacy driver (for older GPUs)"
            read -p "Enter choice [1-2]: " choice

            case "$choice" in
                1) install_nvidia_drivers "nvidia-latest" ;;
                2) install_nvidia_drivers "nvidia-legacy" ;;
                *) echo -e "${RED}Invalid choice${NC}"; return 1 ;;
            esac
            ;;
    esac

    # Configure NVIDIA
    configure_nvidia
}

# Configure NVIDIA settings
configure_nvidia() {
    echo -e "${BLUE}Configuring NVIDIA...${NC}"

    # Enable nvidia-drm modeset (required for Wayland)
    if ! grep -q "nvidia-drm.modeset=1" /etc/default/grub; then
        echo -e "${YELLOW}Enabling NVIDIA DRM modeset...${NC}"
        sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/&nvidia-drm.modeset=1 /' /etc/default/grub
        sudo grub-mkconfig -o /boot/grub/grub.cfg
    fi

    # Add NVIDIA modules to mkinitcpio
    if ! grep -q "nvidia" /etc/mkinitcpio.conf; then
        echo -e "${YELLOW}Adding NVIDIA modules to initramfs...${NC}"
        sudo sed -i 's/MODULES=(/&nvidia nvidia_modeset nvidia_uvm nvidia_drm/' /etc/mkinitcpio.conf
        sudo mkinitcpio -P
    fi

    # Create Xorg configuration if using Xorg
    if [[ -d /etc/X11/xorg.conf.d ]]; then
        echo -e "${YELLOW}Creating Xorg configuration...${NC}"
        sudo tee /etc/X11/xorg.conf.d/20-nvidia.conf > /dev/null << 'EOF'
Section "Device"
    Identifier "NVIDIA Card"
    Driver "nvidia"
    VendorName "NVIDIA Corporation"
    Option "NoLogo" "true"
    Option "UseEDID" "false"
    Option "ConnectedMonitor" "DFP"
EndSection
EOF
    fi

    echo -e "${GREEN}NVIDIA configuration completed!${NC}"
}

# Install AMD drivers
install_amd_drivers() {
    local driver_type="$1"

    echo -e "${BLUE}Installing AMD drivers...${NC}"

    case "$driver_type" in
        "amd-modern")
            echo -e "${YELLOW}Installing modern AMD drivers...${NC}"
            sudo pacman -S --noconfirm mesa lib32-mesa xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon

            # Install additional AMD packages
            sudo pacman -S --noconfirm libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau lib32-mesa-vdpau
            ;;

        "amd-legacy")
            echo -e "${YELLOW}Installing legacy AMD drivers...${NC}"
            sudo pacman -S --noconfirm mesa lib32-mesa xf86-video-ati
            ;;
    esac

    echo -e "${GREEN}AMD drivers installed!${NC}"
}

# Install Intel drivers
install_intel_drivers() {
    echo -e "${BLUE}Installing Intel drivers...${NC}"

    # Intel graphics packages
    intel_packages=(
        "mesa"
        "lib32-mesa"
        "vulkan-intel"
        "lib32-vulkan-intel"
        "libva-intel-driver"
        "lib32-libva-intel-driver"
        "intel-media-driver"
        "libvdpau-va-gl"
        "lib32-libvdpau-va-gl"
    )

    for package in "${intel_packages[@]}"; do
        sudo pacman -S --noconfirm "$package" || echo -e "${YELLOW}Failed to install $package${NC}"
    done

    echo -e "${GREEN}Intel drivers installed!${NC}"
}

# Install Vulkan support
install_vulkan() {
    echo -e "${BLUE}Installing Vulkan support...${NC}"

    # Common Vulkan packages
    sudo pacman -S --noconfirm vulkan-icd-loader lib32-vulkan-icd-loader vulkan-tools

    echo -e "${GREEN}Vulkan support installed!${NC}"
}

# Display installation summary
show_summary() {
    echo -e "${GREEN}
=========================================================================
                        GPU Driver Installation Summary
=========================================================================
${NC}"

    echo -e "${CYAN}Detected GPUs:${NC}"
    for gpu in "${DETECTED_GPUS[@]}"; do
        echo "  • $gpu"
    done
    echo ""

    echo -e "${CYAN}Installed Drivers:${NC}"
    if [[ "$NVIDIA_DETECTED" == true ]]; then
        echo "  • NVIDIA: Proprietary drivers with Vulkan support"
    fi
    if [[ "$AMD_DETECTED" == true ]]; then
        echo "  • AMD: Mesa drivers with Vulkan support"
    fi
    if [[ "$INTEL_DETECTED" == true ]]; then
        echo "  • Intel: Mesa drivers with Vulkan support"
    fi
    echo ""

    echo -e "${CYAN}Next Steps:${NC}"
    echo "  1. Reboot the system to load new drivers"
    echo "  2. Test graphics with: glxinfo | grep 'OpenGL renderer'"
    echo "  3. Test Vulkan with: vulkaninfo | grep 'deviceName'"
    if [[ "$NVIDIA_DETECTED" == true ]]; then
        echo "  4. Configure NVIDIA settings with: nvidia-settings"
    fi
    echo ""

    echo -e "${YELLOW}⚠️  Important: A reboot is required for GPU drivers to take effect!${NC}"
}

# Main installation flow
main() {
    echo -e "${YELLOW}This script will detect your GPU(s) and install optimal drivers.${NC}"
    echo -e "${BLUE}Supported: NVIDIA (proprietary), AMD (AMDGPU/Mesa), Intel (Mesa)${NC}"
    echo ""

    read -p "Continue with GPU driver installation? (Y/n): " continue_install
    if [[ "$continue_install" =~ ^[Nn]$ ]]; then
        echo -e "${YELLOW}GPU driver installation cancelled.${NC}"
        exit 0
    fi

    # Update system first
    echo -e "${BLUE}Updating system packages...${NC}"
    sudo pacman -Syu --noconfirm

    # Detect hardware
    detect_gpus

    # Check for virtualization and handle accordingly
    if check_virtualization; then
        echo -e "${CYAN}Virtualization detected - GPU driver installation may differ${NC}"
        echo -e "${YELLOW}Note: Virtual GPUs may not require dedicated drivers${NC}"
        echo ""
    fi

    # Analyze each GPU type
    if [[ "$NVIDIA_DETECTED" == true ]]; then
        analyze_nvidia_drivers
    fi

    if [[ "$AMD_DETECTED" == true ]]; then
        analyze_amd_drivers
    fi

    if [[ "$INTEL_DETECTED" == true ]]; then
        analyze_intel_drivers
    fi

    # Show recommendations
    echo -e "${CYAN}Driver Installation Plan:${NC}"
    for driver in "${RECOMMENDED_DRIVERS[@]}"; do
        echo "  → $driver"
    done
    echo ""

    read -p "Proceed with installation? (Y/n): " proceed
    if [[ "$proceed" =~ ^[Nn]$ ]]; then
        echo -e "${YELLOW}Installation cancelled.${NC}"
        exit 0
    fi

    # Install drivers
    for driver in "${RECOMMENDED_DRIVERS[@]}"; do
        case "$driver" in
            nvidia-*) install_nvidia_drivers "$driver" ;;
            amd-*) install_amd_drivers "$driver" ;;
            intel-*) install_intel_drivers ;;
        esac
    done

    # Install Vulkan support
    install_vulkan

    # Show summary
    show_summary

    read -p "Press Enter to continue..."
}

# Run main function
main

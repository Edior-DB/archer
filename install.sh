#!/bin/bash

# Archer - Arch Linux Home PC Transformation Suite
# Main installer script

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Repository configuration
REPO_RAW_URL="https://raw.githubusercontent.com/Edior-DB/archer/master"

# Enhanced input function using gum if available
get_user_confirmation() {
    local prompt="$1"
    local default="${2:-N}"

    if command -v gum >/dev/null 2>&1; then
        # Use gum for better UX
        if gum confirm "$prompt"; then
            echo "y"
        else
            echo "n"
        fi
    else
        # Fallback to standard read
        echo -e "${YELLOW}$prompt (y/N)${NC}"
        echo -n "> "
        read -r response
        echo "${response:-$default}"
    fi
}

# Enhanced menu selection using gum if available
get_menu_selection() {
    local title="$1"
    shift
    local options=("$@")

    if command -v gum >/dev/null 2>&1; then
        # Use gum for better menu UX
        gum choose --header="$title" "${options[@]}"
    else
        # Fallback to traditional menu
        echo -e "${CYAN}$title${NC}"
        for i in "${!options[@]}"; do
            echo "  $((i+1))) ${options[$i]}"
        done
        echo ""
        echo -n "Select an option: "
        read -r choice

        # Convert number to option text
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -gt 0 ] && [ "$choice" -le "${#options[@]}" ]; then
            echo "${options[$((choice-1))]}"
        else
            echo "Invalid"
        fi
    fi
}

# Logo
show_logo() {
    clear
    echo -e "${BLUE}"
    cat << "LOGOEOF"
 █████╗ ██████╗  ██████╗██╗  ██╗███████╗██████╗
██╔══██╗██╔══██╗██╔════╝██║  ██║██╔════╝██╔══██╗
███████║██████╔╝██║     ███████║█████╗  ██████╔╝
██╔══██║██╔══██╗██║     ██╔══██║██╔══╝  ██╔══██╗
██║  ██║██║  ██║╚██████╗██║  ██║███████╗██║  ██║
╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝

    Arch Linux Home PC Transformation Suite
LOGOEOF
    echo -e "${NC}"

    # Show test mode if enabled
    if [[ "$TEST_MODE" == "true" ]]; then
        echo -e "${YELLOW}TEST MODE - Running on $(lsb_release -d 2>/dev/null | cut -f2 || echo "Non-Arch system")${NC}"
    fi
}

# Show Live ISO installation prompt
show_livecd_prompt() {
    show_logo
    echo -e "${CYAN}===============================================${NC}"
    echo -e "${CYAN}        Arch Linux Fresh Installation        ${NC}"
    echo -e "${CYAN}===============================================${NC}"
    echo ""
    echo -e "${RED}Running as ROOT on Live ISO${NC}"
    echo -e "${YELLOW}Ready to install Arch Linux to your system${NC}"
    echo ""
    echo -e "${GREEN}This will:${NC}"
    echo -e "${GREEN} • Guide you through disk partitioning${NC}"
    echo -e "${GREEN} • Install base Arch Linux system${NC}"
    echo -e "${GREEN} • Create user account${NC}"
    echo -e "${GREEN} • Configure bootloader and services${NC}"
    echo ""
    echo -e "${CYAN}After installation:${NC}"
    echo -e "${CYAN} • Reboot and login as your new user${NC}"
    echo -e "${CYAN} • Run this installer again for additional setup${NC}"
    echo ""
    echo -e "${CYAN}===============================================${NC}"
}

# Show main menu
show_menu() {
    show_logo
    echo -e "${CYAN}===============================================${NC}"
    echo -e "${CYAN}        Arch Linux Fresh Installation        ${NC}"
    echo -e "${CYAN}===============================================${NC}"
    echo ""

    echo -e "${GREEN}Core Installation (Run from Live ISO):${NC}"
    echo "  1) Fresh Arch Linux Installation"
    echo "  2) Post-Installation Setup (Essential packages, AUR)"
    echo "  3) GPU Drivers Installation"
    echo "  4) Desktop Environment Installation"
    echo "  5) WiFi Setup (if needed)"
    echo ""
    echo -e "${YELLOW}Quick Installation Profiles:${NC}"
    echo "  6) Complete Base System (1+2+3+4+5)"
    echo "  7) Gaming Ready System (Base + Gaming optimizations)"
    echo "  8) Developer Workstation (Base + Dev tools)"
    echo ""
    echo -e "${CYAN}Post-Installation Management:${NC}"
    echo "  9) Launch Archer Post-Installation Tool"
    echo ""
    echo " 0) Exit"

    echo ""
    echo -e "${CYAN}===============================================${NC}"
    echo -e "${YELLOW}Note: After base installation, use 'archer' command${NC}"
    echo -e "${YELLOW}for additional software and customizations.${NC}"
}

# Arch Linux Installation Functions

# Background checks
background_checks() {
    # Skip all checks in test mode
    if [[ "$TEST_MODE" == "true" ]]; then
        echo -e "${YELLOW}TEST MODE: Skipping background checks${NC}"
        return 0
    fi

    # Root check
    if [[ "$(id -u)" != "0" ]]; then
        echo -e "${RED}ERROR! This script must be run under the 'root' user!${NC}"
        exit 1
    fi

    # Arch check
    if [[ ! -e /etc/arch-release ]]; then
        echo -e "${RED}ERROR! This script must be run in Arch Linux!${NC}"
        exit 1
    fi

    # Pacman check
    if [[ -f /var/lib/pacman/db.lck ]]; then
        echo -e "${RED}ERROR! Pacman is blocked.${NC}"
        echo -e "${YELLOW}If not running remove /var/lib/pacman/db.lck.${NC}"
        exit 1
    fi

    # Docker check
    if awk -F/ '$2 == "docker"' /proc/self/cgroup | read -r 2>/dev/null || [[ -f /.dockerenv ]]; then
        echo -e "${RED}ERROR! Docker container is not supported (at the moment)${NC}"
        exit 1
    fi

    # Pacstrap check
    if [ ! -f /usr/bin/pacstrap ]; then
        echo -e "${RED}This script must be run from an Arch Linux ISO environment.${NC}"
        exit 1
    fi
}

# Enhanced selection function using gum if available
select_option() {
    local options=("$@")

    if command -v gum >/dev/null 2>&1; then
        gum choose "${options[@]}"
    else
        # Fallback to arrow navigation
        local num_options=${#options[@]}
        local selected=0
        local last_selected=-1

        while true; do
            # Move cursor up to the start of the menu
            if [ $last_selected -ne -1 ]; then
                echo -ne "\033[${num_options}A"
            fi

            if [ $last_selected -eq -1 ]; then
                echo "Please select an option using the arrow keys and Enter:"
            fi
            for i in "${!options[@]}"; do
                if [ "$i" -eq $selected ]; then
                    echo "> ${options[$i]}"
                else
                    echo "  ${options[$i]}"
                fi
            done

            last_selected=$selected

            # Read user input
            read -rsn1 key
            case $key in
                $'\x1b') # ESC sequence
                    read -rsn2 -t 0.1 key
                    case $key in
                        '[A') # Up arrow
                            ((selected--))
                            if [ $selected -lt 0 ]; then
                                selected=$((num_options - 1))
                            fi
                            ;;
                        '[B') # Down arrow
                            ((selected++))
                            if [ $selected -ge $num_options ]; then
                                selected=0
                            fi
                            ;;
                    esac
                    ;;
                '') # Enter key
                    break
                    ;;
            esac
        done

        echo "${options[$selected]}"
    fi
}

# Filesystem selection
filesystem_selection() {
    echo -e "${CYAN}Please Select your file system for both boot and root${NC}"
    options=("btrfs" "ext4" "luks" "exit")
    selection=$(select_option "${options[@]}")

    case "$selection" in
        "btrfs") export FS=btrfs;;
        "ext4") export FS=ext4;;
        "luks")
            set_luks_password
            export FS=luks
            ;;
        "exit") exit 0;;
        *) echo -e "${RED}Invalid selection${NC}"; filesystem_selection;;
    esac
}

# Set LUKS password
set_luks_password() {
    while true; do
        read -rs -p "Please enter password for LUKS encryption: " password1
        echo ""
        read -rs -p "Please re-enter password: " password2
        echo ""
        if [[ "$password1" == "$password2" ]]; then
            export LUKS_PASSWORD="$password1"
            break
        else
            echo -e "${RED}ERROR! Passwords do not match.${NC}"
        fi
    done
}

# Timezone selection
timezone_selection() {
    time_zone="$(curl --fail https://ipapi.co/timezone 2>/dev/null || echo 'UTC')"
    echo -e "${CYAN}System detected your timezone to be '${time_zone}'${NC}"

    confirm=$(get_user_confirmation "Is this correct?")
    case "${confirm,,}" in
        y|yes)
            echo -e "${GREEN}${time_zone} set as timezone${NC}"
            export TIMEZONE=$time_zone
            ;;
        *)
            echo -n "Please enter your desired timezone (e.g. Europe/London): "
            read -r new_timezone
            echo -e "${GREEN}${new_timezone} set as timezone${NC}"
            export TIMEZONE=$new_timezone
            ;;
    esac
}

# Keymap selection
keymap_selection() {
    echo -e "${CYAN}Please select keyboard layout${NC}"
    options=(us by ca cf cz de dk es et fa fi fr gr hu il it lt lv mk nl no pl ro ru se sg ua uk)
    keymap=$(select_option "${options[@]}")
    echo -e "${GREEN}Your keyboard layout: ${keymap}${NC}"
    export KEYMAP=$keymap
}

# SSD check
ssd_check() {
    echo -e "${CYAN}Is this an SSD?${NC}"
    options=("Yes" "No")
    selection=$(select_option "${options[@]}")

    case "$selection" in
        "Yes")
            export MOUNT_OPTIONS="noatime,compress=zstd,ssd,commit=120"
            ;;
        "No")
            export MOUNT_OPTIONS="noatime,compress=zstd,commit=120"
            ;;
    esac
}

# Disk selection
disk_selection() {
    echo -e "${RED}------------------------------------------------------------------------${NC}"
    echo -e "${RED}    THIS WILL FORMAT AND DELETE ALL DATA ON THE DISK${NC}"
    echo -e "${RED}    Please make sure you know what you are doing because${NC}"
    echo -e "${RED}    after formatting your disk there is no way to get data back${NC}"
    echo -e "${RED}    *****BACKUP YOUR DATA BEFORE CONTINUING*****${NC}"
    echo -e "${RED}    ***I AM NOT RESPONSIBLE FOR ANY DATA LOSS***${NC}"
    echo -e "${RED}------------------------------------------------------------------------${NC}"
    echo ""

    # Get available disks
    mapfile -t disk_options < <(lsblk -n --output TYPE,KNAME,SIZE | awk '$1=="disk"{print "/dev/"$2" ("$3")"}')

    if [ ${#disk_options[@]} -eq 0 ]; then
        echo -e "${RED}No disks found!${NC}"
        exit 1
    fi

    echo -e "${CYAN}Select the disk to install on:${NC}"
    selected_disk=$(select_option "${disk_options[@]}")

    # Extract disk path from selection
    disk=$(echo "$selected_disk" | cut -d' ' -f1)
    echo -e "${GREEN}${disk} selected${NC}"
    export DISK=$disk

    ssd_check
}

# User information gathering
userinfo_collection() {
    # Username
    while true; do
        read -r -p "Please enter username: " username
        # Validate username: start with letter/underscore, contain only letters, numbers, underscore, dash
        if [[ "${username,,}" =~ ^[a-z_][a-z0-9_-]*$ ]] && [[ ${#username} -le 32 ]] && [[ ${#username} -ge 1 ]]; then
            break
        fi
        echo -e "${RED}Incorrect username. Must start with letter/underscore, contain only lowercase letters, numbers, underscore, and dash (max 32 chars).${NC}"
    done
    export USERNAME=$username

    # Password
    while true; do
        read -rs -p "Please enter password: " PASSWORD1
        echo ""
        read -rs -p "Please re-enter password: " PASSWORD2
        echo ""
        if [[ "$PASSWORD1" == "$PASSWORD2" ]]; then
            break
        else
            echo -e "${RED}ERROR! Passwords do not match.${NC}"
        fi
    done
    export PASSWORD=$PASSWORD1

    # Hostname
    while true; do
        read -r -p "Please name your machine: " name_of_machine
        # Validate hostname: start with letter, contain letters/numbers/dots/dashes, end with alphanumeric
        if [[ "${name_of_machine,,}" =~ ^[a-z][a-z0-9.-]*[a-z0-9]$ ]] && [[ ${#name_of_machine} -le 63 ]] && [[ ${#name_of_machine} -ge 2 ]]; then
            break
        elif [[ ${#name_of_machine} -eq 1 ]] && [[ "${name_of_machine,,}" =~ ^[a-z]$ ]]; then
            # Allow single letter hostnames
            break
        fi

        confirm=$(get_user_confirmation "Hostname doesn't seem correct. Do you still want to save it?")
        case "${confirm,,}" in
            y|yes) break;;
        esac
    done
    export NAME_OF_MACHINE=$name_of_machine
}

# Run the complete Arch Linux installation
run_arch_install() {
    if [[ "$TEST_MODE" == "true" ]]; then
        echo -e "${CYAN}TEST MODE: Simulating Arch Linux installation...${NC}"
        echo -e "${YELLOW}In actual installation, this would guide you through:${NC}"
        echo -e "${YELLOW} • User account creation${NC}"
        echo -e "${YELLOW} • Disk partitioning${NC}"
        echo -e "${YELLOW} • System installation${NC}"
        echo ""

        # Allow testing of user input in test mode
        clear
        show_logo
        echo -e "${CYAN}========== User Information (TEST MODE) ===========${NC}"
        userinfo_collection

        echo -e "${CYAN}TEST MODE: Collected user info - Username: ${USERNAME}, Hostname: ${NAME_OF_MACHINE}${NC}"
        echo -e "${YELLOW}In actual installation, would continue with disk partitioning...${NC}"
        read -p "Press Enter to continue..."
        return 0
    fi

    # Real installation mode - redirect output to log file
    exec > >(tee -i archsetup.txt)
    exec 2>&1

    echo -e "${CYAN}Starting Arch Linux installation...${NC}"
    echo -e "${YELLOW}The installer will guide you through:${NC}"
    echo -e "${YELLOW} • User account creation${NC}"
    echo -e "${YELLOW} • Disk partitioning${NC}"
    echo -e "${YELLOW} • System installation${NC}"
    echo ""

    # Background checks (will be skipped in test mode)
    background_checks

    # Collect user information
    clear
    show_logo
    echo -e "${CYAN}========== User Information ===========${NC}"
    userinfo_collection

    # Disk partitioning
    clear
    show_logo
    echo -e "${CYAN}========== Disk Selection ===========${NC}"
    disk_selection

    # Filesystem selection
    clear
    show_logo
    echo -e "${CYAN}========== Filesystem Selection ===========${NC}"
    filesystem_selection

    # Timezone
    clear
    show_logo
    echo -e "${CYAN}========== Timezone Configuration ===========${NC}"
    timezone_selection

    # Keymap
    clear
    show_logo
    echo -e "${CYAN}========== Keyboard Layout ===========${NC}"
    keymap_selection

    # Start installation process
    clear
    show_logo
    echo -e "${CYAN}========== Starting Installation ===========${NC}"

    # Set up mirrors and basic packages
    echo -e "${CYAN}Setting up mirrors for optimal download${NC}"
    iso=$(curl -4 ifconfig.io/country_code 2>/dev/null || echo "US")
    timedatectl set-ntp true
    pacman -Sy --noconfirm
    pacman -S --noconfirm archlinux-keyring
    pacman -S --noconfirm --needed pacman-contrib terminus-font
    setfont ter-v18b 2>/dev/null || true
    sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
    pacman -S --noconfirm --needed reflector rsync grub
    cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup

    echo -e "${CYAN}Setting up $iso mirrors for faster downloads${NC}"
    reflector -a 48 -c "$iso" --score 5 -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist || {
        echo -e "${YELLOW}Mirror setup failed, using backup${NC}"
        cp /etc/pacman.d/mirrorlist.backup /etc/pacman.d/mirrorlist
    }

    # Install prerequisites
    [ ! -d "/mnt" ] && mkdir /mnt
    echo -e "${CYAN}Installing Prerequisites${NC}"
    pacman -S --noconfirm --needed gptfdisk btrfs-progs glibc

    # Format disk
    echo -e "${CYAN}Formatting Disk${NC}"
    umount -A --recursive /mnt 2>/dev/null || true

    # Partition disk
    sgdisk -Z "${DISK}"
    sgdisk -a 2048 -o "${DISK}"
    sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:'BIOSBOOT' "${DISK}"
    sgdisk -n 2::+1GiB --typecode=2:ef00 --change-name=2:'EFIBOOT' "${DISK}"
    sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' "${DISK}"

    if [[ ! -d "/sys/firmware/efi" ]]; then
        sgdisk -A 1:set:2 "${DISK}"
    fi
    partprobe "${DISK}"

    # Set partition variables
    if [[ "${DISK}" =~ "nvme" ]]; then
        partition2=${DISK}p2
        partition3=${DISK}p3
    else
        partition2=${DISK}2
        partition3=${DISK}3
    fi

    # Create filesystems
    echo -e "${CYAN}Creating Filesystems${NC}"

    if [[ "${FS}" == "btrfs" ]]; then
        mkfs.fat -F32 -n "EFIBOOT" "${partition2}"
        mkfs.btrfs -f "${partition3}"
        mount -t btrfs "${partition3}" /mnt

        # Create subvolumes
        btrfs subvolume create /mnt/@
        btrfs subvolume create /mnt/@home
        umount /mnt
        mount -o "${MOUNT_OPTIONS}",subvol=@ "${partition3}" /mnt
        mkdir -p /mnt/home
        mount -o "${MOUNT_OPTIONS}",subvol=@home "${partition3}" /mnt/home

    elif [[ "${FS}" == "ext4" ]]; then
        mkfs.fat -F32 -n "EFIBOOT" "${partition2}"
        mkfs.ext4 "${partition3}"
        mount -t ext4 "${partition3}" /mnt

    elif [[ "${FS}" == "luks" ]]; then
        mkfs.fat -F32 "${partition2}"
        echo -n "${LUKS_PASSWORD}" | cryptsetup -y -v luksFormat "${partition3}" -
        echo -n "${LUKS_PASSWORD}" | cryptsetup open "${partition3}" ROOT -
        mkfs.btrfs /dev/mapper/ROOT
        mount -t btrfs /dev/mapper/ROOT /mnt

        # Create subvolumes for LUKS
        btrfs subvolume create /mnt/@
        btrfs subvolume create /mnt/@home
        umount /mnt
        mount -o "${MOUNT_OPTIONS}",subvol=@ /dev/mapper/ROOT /mnt
        mkdir -p /mnt/home
        mount -o "${MOUNT_OPTIONS}",subvol=@home /dev/mapper/ROOT /mnt/home

        ENCRYPTED_PARTITION_UUID=$(blkid -s UUID -o value "${partition3}")
    fi

    # Mount boot partition
    BOOT_UUID=$(blkid -s UUID -o value "${partition2}")
    sync

    if ! mountpoint -q /mnt; then
        echo -e "${RED}ERROR! Failed to mount ${partition3} to /mnt${NC}"
        exit 1
    fi

    mkdir -p /mnt/boot
    mount -U "${BOOT_UUID}" /mnt/boot/

    # Install base system
    echo -e "${CYAN}Installing Arch Linux Base System${NC}"
    if [[ ! -d "/sys/firmware/efi" ]]; then
        pacstrap /mnt base base-devel linux-lts linux-firmware --noconfirm --needed
    else
        pacstrap /mnt base base-devel linux-lts linux-firmware efibootmgr --noconfirm --needed
    fi

    echo "keyserver hkp://keyserver.ubuntu.com" >> /mnt/etc/pacman.d/gnupg/gpg.conf
    cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

    # Generate fstab
    genfstab -U /mnt >> /mnt/etc/fstab
    echo -e "${GREEN}Generated /etc/fstab${NC}"

    # Install GRUB for BIOS systems
    if [[ ! -d "/sys/firmware/efi" ]]; then
        echo -e "${CYAN}Installing GRUB BIOS Bootloader${NC}"
        grub-install --boot-directory=/mnt/boot "${DISK}"
    fi

    # Check for low memory and add swap if needed
    TOTAL_MEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
    if [[ $TOTAL_MEM -lt 8000000 ]]; then
        echo -e "${CYAN}Low memory system detected, creating swap file${NC}"
        mkdir -p /mnt/opt/swap
        if findmnt -n -o FSTYPE /mnt | grep -q btrfs; then
            chattr +C /mnt/opt/swap 2>/dev/null || true
        fi
        dd if=/dev/zero of=/mnt/opt/swap/swapfile bs=1M count=2048 status=progress
        chmod 600 /mnt/opt/swap/swapfile
        chown root /mnt/opt/swap/swapfile
        mkswap /mnt/opt/swap/swapfile
        swapon /mnt/opt/swap/swapfile
        echo "/opt/swap/swapfile    none    swap    sw    0    0" >> /mnt/etc/fstab
    fi

    # Get GPU type for driver installation
    gpu_type=$(lspci | grep -E "VGA|3D|Display" 2>/dev/null || echo "")

    # Configure the installed system
    arch-chroot /mnt /bin/bash -c "KEYMAP='${KEYMAP}' /bin/bash" <<EOF

# Network setup
echo -e "${CYAN}Setting up network${NC}"
pacman -S --noconfirm --needed networkmanager dhcpcd
systemctl enable NetworkManager

# Install essential packages
pacman -S --noconfirm --needed pacman-contrib curl reflector rsync grub arch-install-scripts git ntp wget
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak

# Optimize compilation
nc=\$(grep -c ^"cpu cores" /proc/cpuinfo || echo "2")
TOTAL_MEM=\$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
if [[ \$TOTAL_MEM -gt 8000000 ]]; then
    sed -i "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j\$nc\"/g" /etc/makepkg.conf
    sed -i "s/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -T \$nc -z -)/g" /etc/makepkg.conf
fi

# Setup locale
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
timedatectl --no-ask-password set-timezone ${TIMEZONE}
timedatectl --no-ask-password set-ntp 1
localectl --no-ask-password set-locale LANG="en_US.UTF-8" LC_TIME="en_US.UTF-8"
ln -s /usr/share/zoneinfo/${TIMEZONE} /etc/localtime 2>/dev/null || true

# Set keymaps
echo "KEYMAP=${KEYMAP}" > /etc/vconsole.conf
echo "XKBLAYOUT=${KEYMAP}" >> /etc/vconsole.conf

# Configure sudo
sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

# Configure pacman
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
sed -i 's/^#Color/Color\\nILoveCandy/' /etc/pacman.conf
sed -i "/\\[multilib\\]/,/Include/"'s/^#//' /etc/pacman.conf
pacman -Sy --noconfirm --needed

# Install microcode
if grep -q "GenuineIntel" /proc/cpuinfo; then
    echo -e "${CYAN}Installing Intel microcode${NC}"
    pacman -S --noconfirm --needed intel-ucode
elif grep -q "AuthenticAMD" /proc/cpuinfo; then
    echo -e "${CYAN}Installing AMD microcode${NC}"
    pacman -S --noconfirm --needed amd-ucode
fi

# Install graphics drivers
if echo "${gpu_type}" | grep -E "NVIDIA|GeForce"; then
    echo -e "${CYAN}Installing NVIDIA drivers${NC}"
    pacman -S --noconfirm --needed nvidia-lts
elif echo "${gpu_type}" | grep 'VGA' | grep -E "Radeon|AMD"; then
    echo -e "${CYAN}Installing AMD drivers${NC}"
    pacman -S --noconfirm --needed xf86-video-amdgpu
elif echo "${gpu_type}" | grep -E "Integrated Graphics Controller|Intel Corporation UHD"; then
    echo -e "${CYAN}Installing Intel drivers${NC}"
    pacman -S --noconfirm --needed libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-utils lib32-mesa
fi

# Create user
echo -e "${CYAN}Creating user account${NC}"
groupadd libvirt 2>/dev/null || true
useradd -m -G wheel,libvirt -s /bin/bash ${USERNAME}
echo "${USERNAME}:${PASSWORD}" | chpasswd
echo ${NAME_OF_MACHINE} > /etc/hostname

# Handle LUKS encryption
if [[ "${FS}" == "luks" ]]; then
    sed -i 's/filesystems/encrypt filesystems/g' /etc/mkinitcpio.conf
    mkinitcpio -p linux-lts
fi

# Install and configure GRUB
if [[ -d "/sys/firmware/efi" ]]; then
    grub-install --efi-directory=/boot ${DISK}
fi

# Configure GRUB
if [[ "${FS}" == "luks" ]]; then
    sed -i "s%GRUB_CMDLINE_LINUX_DEFAULT=\"%GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=UUID=${ENCRYPTED_PARTITION_UUID}:ROOT root=/dev/mapper/ROOT %g" /etc/default/grub
fi
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& splash /' /etc/default/grub

grub-mkconfig -o /boot/grub/grub.cfg

# Enable essential services
ntpd -qg 2>/dev/null || true
systemctl enable ntpd.service
systemctl disable dhcpcd.service
systemctl enable NetworkManager.service
systemctl enable reflector.timer

# Configure sudo properly
sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
sed -i 's/^%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

EOF

    echo ""
    echo -e "${GREEN}Installation completed successfully!${NC}"
    echo -e "${CYAN}You can now reboot and login as ${USERNAME}${NC}"
    echo ""
    read -p "Press Enter to continue..."
}

# Placeholder for other options
show_placeholder() {
    local option_name="$1"

    if command -v gum >/dev/null 2>&1; then
        gum style --foreground="#ffff00" --bold "$option_name"
        gum style --foreground="#00ffff" "This feature will be available in a future update"
        echo ""
        gum style --foreground="#ffffff" "Press Enter to continue..."
        read -r
    else
        echo -e "${YELLOW}$option_name${NC}"
        echo -e "${CYAN}This feature will be available in a future update${NC}"
        echo ""
        read -p "Press Enter to continue..."
    fi
}

# Main function
main() {
    # Handle test mode
    if [[ "$1" == "--test" ]]; then
        export TEST_MODE="true"
        echo -e "${CYAN}TEST MODE ENABLED${NC}"
        echo -e "${YELLOW}Script will run in test mode - no actual system changes will be made${NC}"
        sleep 2
    fi

    # Check if Arch Linux or Live ISO (skip in test mode)
    if [[ "$TEST_MODE" != "true" ]]; then
        if [[ ! -f /etc/arch-release ]] && ! grep -q "archiso" /proc/cmdline 2>/dev/null; then
            echo -e "${RED}This script is designed for Arch Linux only.${NC}"
            echo -e "${YELLOW}Run from Arch Linux Live ISO for fresh installation, or from installed Arch Linux system.${NC}"
            echo -e "${CYAN}For testing on other systems, use: $0 --test${NC}"
            exit 1
        fi

        # Check internet connection
        if ! ping -c 1 8.8.8.8 &> /dev/null; then
            echo -e "${RED}No internet connection detected.${NC}"
            echo -e "${YELLOW}Please ensure you have an active internet connection.${NC}"
            exit 1
        fi
        echo -e "${GREEN}Internet connection: OK${NC}"

        # Install required packages on any Arch system
        if command -v pacman >/dev/null 2>&1; then
            echo -e "${CYAN}Ensuring required packages are installed...${NC}"
            if ! command -v gum >/dev/null 2>&1 || ! command -v git >/dev/null 2>&1; then
                echo -e "${YELLOW}Installing git and gum for better user experience...${NC}"
                if pacman -Sy --noconfirm git gum >/dev/null 2>&1; then
                    echo -e "${GREEN}Required packages installed successfully${NC}"
                else
                    echo -e "${YELLOW}Warning: Could not install some packages, falling back to basic prompts${NC}"
                    # At least try to install git which is essential
                    pacman -Sy --noconfirm git >/dev/null 2>&1 || true
                fi
            else
                echo -e "${GREEN}Required packages already installed${NC}"
            fi
        fi
    fi

    # Main interactive loop
    while true; do
        # Check if running as root on Live ISO
        if grep -q "archiso" /proc/cmdline 2>/dev/null && [[ "$EUID" -eq 0 ]] && [[ "$TEST_MODE" != "true" ]]; then
            # Live ISO mode - direct installation prompt
            show_livecd_prompt
            echo ""

            # Get user confirmation using gum if available
            confirm=$(get_user_confirmation "Do you want to proceed with Arch Linux installation?")

            case "${confirm,,}" in
                y|yes)
                    run_arch_install
                    # After installation, exit the script
                    echo -e "${GREEN}Installation completed. Please reboot your system.${NC}"
                    exit 0
                    ;;
                n|no|"")
                    echo -e "${CYAN}Installation cancelled. Exiting...${NC}"
                    exit 0
                    ;;
                *)
                    echo -e "${RED}Please answer 'y' for yes or 'n' for no.${NC}"
                    echo ""
                    read -p "Press Enter to try again..." -r
                    ;;
            esac
        else
            # Normal mode - show full menu
            show_menu

            if command -v gum >/dev/null 2>&1; then
                # Use gum for menu selection
                options=(
                    "1) Fresh Arch Linux Installation"
                    "2) Post-Installation Setup (Essential packages, AUR)"
                    "3) GPU Drivers Installation"
                    "4) Desktop Environment Installation"
                    "5) WiFi Setup (if needed)"
                    "6) Complete Base System (1+2+3+4+5)"
                    "7) Gaming Ready System (Base + Gaming optimizations)"
                    "8) Developer Workstation (Base + Dev tools)"
                    "9) Launch Archer Post-Installation Tool"
                    "0) Exit"
                )

                selection=$(gum choose --header="Select an option:" "${options[@]}")
                choice="${selection:0:1}"  # Extract number from selection
            else
                # Fallback to traditional input
                echo -n "Select an option [0-9]: "
                read -r choice
            fi

            echo ""

            # Process choice
            case "$choice" in
                1)
                    if [[ "$TEST_MODE" == "true" ]]; then
                        echo -e "${CYAN}TEST MODE: Executing Fresh Arch Linux Installation${NC}"
                        run_arch_install
                    else
                        echo -e "${YELLOW}Fresh Arch Linux Installation should be run from Live ISO as root${NC}"
                        read -p "Press Enter to continue..."
                    fi
                    ;;
                2)
                    show_placeholder "Post-Installation Setup"
                    ;;
                3)
                    show_placeholder "GPU Drivers Installation"
                    ;;
                4)
                    show_placeholder "Desktop Environment Installation"
                    ;;
                5)
                    show_placeholder "WiFi Setup"
                    ;;
                6|7|8|9)
                    show_placeholder "Installation Profile"
                    ;;
                0)
                    echo -e "${GREEN}Thank you for using Archer!${NC}"
                    exit 0
                    ;;
                *)
                    if command -v gum >/dev/null 2>&1; then
                        gum style --foreground="#ff0000" "Invalid selection. Please try again."
                        sleep 1
                    else
                        echo -e "${RED}Invalid option. Please try again.${NC}"
                        sleep 1
                    fi
                    ;;
            esac
        fi
    done
}

# Run main function with all arguments
main "$@"

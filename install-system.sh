#!/bin/bash

# Archer - Arch Linux System Installer
# Fresh Arch Linux installation from Live ISO
# Based on Chris Titus Tech's Arch Linux installer
# Original: https://github.com/ChrisTitusTech/ArchTitus

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Background checks
background_checks() {
    # Root check
    if [[ "$(id -u)" != "0" ]]; then
        echo -e "${RED}ERROR! This script must be run under the 'root' user!${NC}"
        exit 1
    fi

    # Arch check
    if [[ ! -e /etc/arch-release ]]; then
        echo -e "${RED}ERROR! This script must be run in Arch Linux Live ISO!${NC}"
        exit 1
    fi

    # Pacstrap check
    if [ ! -f /usr/bin/pacstrap ]; then
        echo -e "${RED}This script must be run from an Arch Linux ISO environment.${NC}"
        exit 1
    fi

    # Live ISO check
    if ! grep -q "archiso" /proc/cmdline 2>/dev/null; then
        echo -e "${RED}This script should be run from Arch Linux Live ISO!${NC}"
        echo -e "${YELLOW}For post-installation setup, use install-archer.sh instead.${NC}"
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

            read -rsn1 key
            case $key in
                $'\x1b')
                    read -rsn2 -t 0.1 key
                    case $key in
                        '[A') ((selected--)); [ $selected -lt 0 ] && selected=$((num_options - 1));;
                        '[B') ((selected++)); [ $selected -ge $num_options ] && selected=0;;
                    esac
                    ;;
                '') break;;
            esac
        done

        echo "${options[$selected]}"
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

       Arch Linux System Installer (Live ISO)
LOGOEOF
    echo -e "${NC}"
}

# User information gathering
userinfo_collection() {
    echo -e "${CYAN}========== User Account Setup ===========${NC}"

    # Username
    while true; do
        echo -e "${CYAN}Enter your username:${NC}"
        username=$(gum input --placeholder "e.g., john, alice, user123")

        # Check if username is empty
        if [[ -z "$username" ]]; then
            echo -e "${RED}ERROR! Username cannot be empty.${NC}"
            continue
        fi

        # Check username format and length
        if [[ "$username" =~ ^[a-zA-Z_][a-zA-Z0-9_-]*$ ]] && [[ ${#username} -le 32 ]]; then
            break
        fi
        echo -e "${RED}Invalid username. Must start with letter/underscore, contain only letters, numbers, underscore, dash (max 32 chars).${NC}"
        echo -e "${YELLOW}Examples: john, user123, my_user, test-user${NC}"
    done
    export USERNAME=$username

    # Password
    while true; do
        echo -e "${CYAN}Enter your password:${NC}"
        PASSWORD1=$(gum input --password --placeholder "Password...")
        echo -e "${CYAN}Re-enter your password:${NC}"
        PASSWORD2=$(gum input --password --placeholder "Confirm password...")

        if [[ "$PASSWORD1" == "$PASSWORD2" ]]; then
            break
        else
            echo -e "${RED}ERROR! Passwords do not match.${NC}"
        fi
    done
    export PASSWORD=$PASSWORD1

    # Hostname
    while true; do
        echo -e "${CYAN}Enter machine name (hostname):${NC}"
        name_of_machine=$(gum input --placeholder "e.g., archlinux, mycomputer, workstation")

        if [[ -n "$name_of_machine" ]] && [[ ${#name_of_machine} -le 63 ]]; then
            break
        fi
        echo -e "${YELLOW}Please enter a valid hostname (1-63 characters).${NC}"
    done
    export NAME_OF_MACHINE=$name_of_machine
}

# Filesystem selection
filesystem_selection() {
    echo -e "${CYAN}========== Filesystem Selection ===========${NC}"
    echo -e "${CYAN}Please select your file system for both boot and root${NC}"
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
        echo -e "${CYAN}Enter LUKS encryption password:${NC}"
        password1=$(gum input --password --placeholder "Strong password for disk encryption...")
        echo -e "${CYAN}Re-enter LUKS encryption password:${NC}"
        password2=$(gum input --password --placeholder "Confirm encryption password...")

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
    echo -e "${CYAN}========== Timezone Configuration ===========${NC}"
    time_zone="$(curl --fail https://ipapi.co/timezone 2>/dev/null || echo 'UTC')"
    echo -e "${CYAN}System detected your timezone to be '${time_zone}'${NC}"

    if gum confirm "Is this timezone correct: ${time_zone}?"; then
        export TIMEZONE=$time_zone
    else
        echo -e "${CYAN}Enter your timezone:${NC}"
        new_timezone=$(gum input --placeholder "e.g., Europe/London, America/New_York, Asia/Tokyo")
        export TIMEZONE=$new_timezone
    fi
    echo -e "${GREEN}Timezone set to: ${TIMEZONE}${NC}"
}

# Keymap selection
keymap_selection() {
    echo -e "${CYAN}========== Keyboard Layout ===========${NC}"
    options=(us by ca cf cz de dk es et fa fi fr gr hu il it lt lv mk nl no pl ro ru se sg ua uk)
    keymap=$(select_option "${options[@]}")
    echo -e "${GREEN}Keyboard layout: ${keymap}${NC}"
    export KEYMAP=$keymap
}

# SSD check
ssd_check() {
    echo -e "${CYAN}Is this an SSD?${NC}"
    options=("Yes" "No")
    selection=$(select_option "${options[@]}")

    case "$selection" in
        "Yes") export MOUNT_OPTIONS="noatime,compress=zstd,ssd,commit=120";;
        "No") export MOUNT_OPTIONS="noatime,compress=zstd,commit=120";;
    esac
}

# Disk selection
disk_selection() {
    echo -e "${CYAN}========== Disk Selection ===========${NC}"
    echo -e "${RED}------------------------------------------------------------------------${NC}"
    echo -e "${RED}    THIS WILL FORMAT AND DELETE ALL DATA ON THE DISK${NC}"
    echo -e "${RED}    Please make sure you know what you are doing because${NC}"
    echo -e "${RED}    after formatting your disk there is no way to get data back${NC}"
    echo -e "${RED}    *****BACKUP YOUR DATA BEFORE CONTINUING*****${NC}"
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

# Main installation function
run_installation() {
    # Redirect output to log file
    exec > >(tee -i archsetup.txt)
    exec 2>&1

    show_logo
    echo -e "${CYAN}Starting Arch Linux installation...${NC}"
    echo ""

    # Background checks
    background_checks

    # Collect user information
    userinfo_collection

    # Disk and filesystem selection
    disk_selection
    filesystem_selection
    timezone_selection
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

    # Ask user if they want to use local mirrors
    echo -e "${CYAN}Detected country: $iso${NC}"
    if gum confirm "Use $iso mirrors for faster downloads? (Choose 'No' to keep default mirrors)"; then
        echo -e "${CYAN}Setting up $iso mirrors for faster downloads${NC}"
        if ! reflector -a 48 -c "$iso" --score 5 -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist; then
            echo -e "${YELLOW}$iso mirrors failed, trying worldwide mirrors...${NC}"
            if ! reflector -a 48 --score 5 -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist; then
                echo -e "${YELLOW}All mirror setups failed, using backup mirrors${NC}"
                cp /etc/pacman.d/mirrorlist.backup /etc/pacman.d/mirrorlist
            else
                echo -e "${GREEN}Successfully configured worldwide mirrors${NC}"
            fi
        else
            echo -e "${GREEN}Successfully configured $iso mirrors${NC}"
        fi
    else
        echo -e "${CYAN}Using default mirrors${NC}"
    fi

    # Install prerequisites with retry logic
    [ ! -d "/mnt" ] && mkdir /mnt
    echo -e "${CYAN}Installing Prerequisites${NC}"

    retry_count=0
    max_retries=3

    while [ $retry_count -lt $max_retries ]; do
        echo -e "${CYAN}Installing prerequisites - Attempt $((retry_count + 1)) of $max_retries...${NC}"
        if pacman -S --noconfirm --needed gptfdisk btrfs-progs glibc; then
            echo -e "${GREEN}Prerequisites installed successfully${NC}"
            break
        fi

        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $max_retries ]; then
            echo -e "${YELLOW}Prerequisites installation failed, retrying in 3 seconds...${NC}"
            sleep 3
            pacman -Sy --noconfirm
        else
            echo -e "${RED}ERROR: Prerequisites installation failed after $max_retries attempts!${NC}"
            echo -e "${RED}Please check your network connection.${NC}"
            if gum confirm "Would you like to try installing prerequisites again?"; then
                retry_count=0  # Reset retry counter
                echo -e "${CYAN}Retrying prerequisites installation...${NC}"
                pacman -Sy --noconfirm
            else
                echo -e "${RED}Installation cannot continue without prerequisites.${NC}"
                exit 1
            fi
        fi
    done

    # Format disk
    echo -e "${CYAN}Formatting Disk${NC}"
    umount -A --recursive /mnt 2>/dev/null || true

    # Partition disk
    sgdisk -Z "${DISK}"
    sgdisk -a 2048 -o "${DISK}"
    sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:'BIOSBOOT' "${DISK}"
    sgdisk -n 2::+1GiB --typecode=2:ef00 --change-name=2:'EFIBOOT' "${DISK}"
    sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' "${DISK}"

    # Set bootable flag for BIOS systems and ensure BIOS boot partition is properly configured
    if [[ ! -d "/sys/firmware/efi" ]]; then
        sgdisk -A 1:set:2 "${DISK}"  # Set BIOS boot partition as bootable
        sgdisk -A 2:set:2 "${DISK}"  # Set EFI partition as bootable for compatibility
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

    # Install base system with retry logic
    echo -e "${CYAN}Installing Arch Linux Base System${NC}"

    # Retry pacstrap up to 3 times
    retry_count=0
    max_retries=3

    while [ $retry_count -lt $max_retries ]; do
        echo -e "${CYAN}Attempt $((retry_count + 1)) of $max_retries...${NC}"

        if [[ ! -d "/sys/firmware/efi" ]]; then
            if pacstrap /mnt base base-devel linux-lts linux-firmware --noconfirm --needed; then
                echo -e "${GREEN}Base system installation successful${NC}"
                break
            fi
        else
            if pacstrap /mnt base base-devel linux-lts linux-firmware efibootmgr --noconfirm --needed; then
                echo -e "${GREEN}Base system installation successful${NC}"
                break
            fi
        fi

        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $max_retries ]; then
            echo -e "${YELLOW}Installation failed, retrying in 5 seconds...${NC}"
            sleep 5
            echo -e "${CYAN}Refreshing package databases...${NC}"
            pacman -Sy --noconfirm
        else
            echo -e "${RED}ERROR: Base system installation failed after $max_retries attempts!${NC}"
            echo -e "${RED}Please check your network connection.${NC}"
            if gum confirm "Would you like to try installing the base system again?"; then
                retry_count=0  # Reset retry counter
                echo -e "${CYAN}Retrying base system installation...${NC}"
                pacman -Sy --noconfirm
            else
                echo -e "${RED}Installation cannot continue without base system.${NC}"
                exit 1
            fi
        fi
    done

    echo "keyserver hkp://keyserver.ubuntu.com" >> /mnt/etc/pacman.d/gnupg/gpg.conf
    cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

    # Generate fstab
    genfstab -U /mnt >> /mnt/etc/fstab
    echo -e "${GREEN}Generated /etc/fstab${NC}"

    # Note: GRUB installation will be handled from chroot for both BIOS and UEFI systems

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

# Network setup with retry logic
echo -e "${CYAN}Setting up network${NC}"
retry_count=0
max_retries=3

while [ \$retry_count -lt \$max_retries ]; do
    echo -e "${CYAN}Installing network packages - Attempt \$((retry_count + 1)) of \$max_retries...${NC}"
    if pacman -S --noconfirm --needed networkmanager dhcpcd; then
        echo -e "${GREEN}Network packages installed successfully${NC}"
        break
    fi

    retry_count=\$((retry_count + 1))
    if [ \$retry_count -lt \$max_retries ]; then
        echo -e "${YELLOW}Network setup failed, retrying in 3 seconds...${NC}"
        sleep 3
        pacman -Sy --noconfirm
    else
        echo -e "${RED}ERROR: Network setup failed after \$max_retries attempts${NC}"
        if gum confirm "Would you like to try installing network packages again?"; then
            retry_count=0  # Reset retry counter
            echo -e "${CYAN}Retrying network packages installation...${NC}"
            pacman -Sy --noconfirm
        else
            echo -e "${YELLOW}Continuing without network packages (you may need to install them manually later)${NC}"
            break
        fi
    fi
done

systemctl enable NetworkManager

# Install essential packages with retry logic
echo -e "${CYAN}Installing essential packages${NC}"
retry_count=0

while [ \$retry_count -lt \$max_retries ]; do
    echo -e "${CYAN}Installing essential packages - Attempt \$((retry_count + 1)) of \$max_retries...${NC}"
    if pacman -S --noconfirm --needed pacman-contrib curl reflector rsync grub arch-install-scripts git ntp wget os-prober; then
        echo -e "${GREEN}Essential packages installed successfully${NC}"
        break
    fi

    retry_count=\$((retry_count + 1))
    if [ \$retry_count -lt \$max_retries ]; then
        echo -e "${YELLOW}Essential packages installation failed, retrying in 3 seconds...${NC}"
        sleep 3
        pacman -Sy --noconfirm
    else
        echo -e "${RED}ERROR: Essential packages installation failed after \$max_retries attempts${NC}"
        if gum confirm "Would you like to try installing essential packages again?"; then
            retry_count=0  # Reset retry counter
            echo -e "${CYAN}Retrying essential packages installation...${NC}"
            pacman -Sy --noconfirm
        else
            echo -e "${YELLOW}Continuing without some essential packages (you may need to install them manually later)${NC}"
            break
        fi
    fi
done

# Optimize compilation
nc=\$(grep -c ^"cpu cores" /proc/cpuinfo || echo "2")
TOTAL_MEM=\$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
if [[ \$TOTAL_MEM -gt 8000000 ]]; then
    sed -i "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j\$nc\"/g" /etc/makepkg.conf
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

# Configure sudo - temporarily enable passwordless for installation
sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers

# Configure pacman
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
sed -i 's/^#Color/Color\\nILoveCandy/' /etc/pacman.conf
sed -i "/\\[multilib\\]/,/Include/"'s/^#//' /etc/pacman.conf
pacman -Sy --noconfirm --needed

# Install microcode with retry logic
if grep -q "GenuineIntel" /proc/cpuinfo; then
    echo -e "${CYAN}Installing Intel microcode${NC}"
    retry_count=0
    while [ \$retry_count -lt \$max_retries ]; do
        if pacman -S --noconfirm --needed intel-ucode; then
            echo -e "${GREEN}Intel microcode installed successfully${NC}"
            break
        fi
        retry_count=\$((retry_count + 1))
        if [ \$retry_count -lt \$max_retries ]; then
            echo -e "${YELLOW}Microcode installation failed, retrying...${NC}"
            sleep 2
            pacman -Sy --noconfirm
        elif gum confirm "Intel microcode installation failed. Would you like to try again?"; then
            retry_count=0  # Reset retry counter
            echo -e "${CYAN}Retrying Intel microcode installation...${NC}"
            pacman -Sy --noconfirm
        else
            echo -e "${YELLOW}Continuing without Intel microcode (you may install it manually later)${NC}"
            break
        fi
    done
elif grep -q "AuthenticAMD" /proc/cpuinfo; then
    echo -e "${CYAN}Installing AMD microcode${NC}"
    retry_count=0
    while [ \$retry_count -lt \$max_retries ]; do
        if pacman -S --noconfirm --needed amd-ucode; then
            echo -e "${GREEN}AMD microcode installed successfully${NC}"
            break
        fi
        retry_count=\$((retry_count + 1))
        if [ \$retry_count -lt \$max_retries ]; then
            echo -e "${YELLOW}Microcode installation failed, retrying...${NC}"
            sleep 2
            pacman -Sy --noconfirm
        elif gum confirm "AMD microcode installation failed. Would you like to try again?"; then
            retry_count=0  # Reset retry counter
            echo -e "${CYAN}Retrying AMD microcode installation...${NC}"
            pacman -Sy --noconfirm
        else
            echo -e "${YELLOW}Continuing without AMD microcode (you may install it manually later)${NC}"
            break
        fi
    done
fi

# Install graphics drivers with retry logic
if echo "${gpu_type}" | grep -E "NVIDIA|GeForce"; then
    echo -e "${CYAN}Installing NVIDIA drivers${NC}"
    retry_count=0
    while [ \$retry_count -lt \$max_retries ]; do
        if pacman -S --noconfirm --needed nvidia-lts; then
            echo -e "${GREEN}NVIDIA drivers installed successfully${NC}"
            break
        fi
        retry_count=\$((retry_count + 1))
        if [ \$retry_count -lt \$max_retries ]; then
            echo -e "${YELLOW}GPU driver installation failed, retrying...${NC}"
            sleep 2
            pacman -Sy --noconfirm
        elif gum confirm "NVIDIA driver installation failed. Would you like to try again?"; then
            retry_count=0  # Reset retry counter
            echo -e "${CYAN}Retrying NVIDIA driver installation...${NC}"
            pacman -Sy --noconfirm
        else
            echo -e "${YELLOW}Continuing without NVIDIA drivers (you may install them manually later)${NC}"
            break
        fi
    done
elif echo "${gpu_type}" | grep 'VGA' | grep -E "Radeon|AMD"; then
    echo -e "${CYAN}Installing AMD GPU drivers${NC}"
    retry_count=0
    while [ \$retry_count -lt \$max_retries ]; do
        if pacman -S --noconfirm --needed xf86-video-amdgpu; then
            echo -e "${GREEN}AMD GPU drivers installed successfully${NC}"
            break
        fi
        retry_count=\$((retry_count + 1))
        if [ \$retry_count -lt \$max_retries ]; then
            echo -e "${YELLOW}GPU driver installation failed, retrying...${NC}"
            sleep 2
            pacman -Sy --noconfirm
        elif gum confirm "AMD GPU driver installation failed. Would you like to try again?"; then
            retry_count=0  # Reset retry counter
            echo -e "${CYAN}Retrying AMD GPU driver installation...${NC}"
            pacman -Sy --noconfirm
        else
            echo -e "${YELLOW}Continuing without AMD GPU drivers (you may install them manually later)${NC}"
            break
        fi
    done
elif echo "${gpu_type}" | grep -E "Integrated Graphics Controller|Intel Corporation UHD"; then
    echo -e "${CYAN}Installing Intel GPU drivers${NC}"
    retry_count=0
    while [ \$retry_count -lt \$max_retries ]; do
        if pacman -S --noconfirm --needed libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-utils lib32-mesa; then
            echo -e "${GREEN}Intel GPU drivers installed successfully${NC}"
            break
        fi
        retry_count=\$((retry_count + 1))
        if [ \$retry_count -lt \$max_retries ]; then
            echo -e "${YELLOW}GPU driver installation failed, retrying...${NC}"
            sleep 2
            pacman -Sy --noconfirm
        elif gum confirm "Intel GPU driver installation failed. Would you like to try again?"; then
            retry_count=0  # Reset retry counter
            echo -e "${CYAN}Retrying Intel GPU driver installation...${NC}"
            pacman -Sy --noconfirm
        else
            echo -e "${YELLOW}Continuing without Intel GPU drivers (you may install them manually later)${NC}"
            break
        fi
    done
fi

# Create user
groupadd libvirt 2>/dev/null || true
useradd -m -G wheel,libvirt -s /bin/bash ${USERNAME}
echo "${USERNAME}:${PASSWORD}" | chpasswd
echo ${NAME_OF_MACHINE} > /etc/hostname

# Handle LUKS encryption and regenerate initramfs
if [[ "${FS}" == "luks" ]]; then
    sed -i 's/filesystems/encrypt filesystems/g' /etc/mkinitcpio.conf
fi

# Regenerate initramfs for all systems
mkinitcpio -p linux-lts

# Install and configure GRUB
if [[ -d "/sys/firmware/efi" ]]; then
    echo -e "${CYAN}Installing GRUB for UEFI system${NC}"
    if ! grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB; then
        echo -e "${RED}ERROR: GRUB UEFI installation failed!${NC}"
        exit 1
    fi
    echo -e "${GREEN}GRUB UEFI installation successful${NC}"
else
    echo -e "${CYAN}Installing GRUB for BIOS system${NC}"
    if ! grub-install --target=i386-pc "${DISK}"; then
        echo -e "${RED}ERROR: GRUB BIOS installation failed!${NC}"
        exit 1
    fi
    echo -e "${GREEN}GRUB BIOS installation successful${NC}"
fi

# Configure GRUB
if [[ "${FS}" == "luks" ]]; then
    sed -i "s%GRUB_CMDLINE_LINUX_DEFAULT=\"%GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=UUID=${ENCRYPTED_PARTITION_UUID}:ROOT root=/dev/mapper/ROOT %g" /etc/default/grub
fi

# Add VM-friendly GRUB configuration
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& splash /' /etc/default/grub
sed -i 's/^#GRUB_TERMINAL=console/GRUB_TERMINAL=console/' /etc/default/grub
sed -i 's/^#GRUB_GFXMODE=640x480/GRUB_GFXMODE=1024x768/' /etc/default/grub

# Ensure GRUB timeout is reasonable for VMs
sed -i 's/^GRUB_TIMEOUT=5/GRUB_TIMEOUT=10/' /etc/default/grub

# Enable os-prober for detecting other operating systems
sed -i 's/^#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub

# Generate GRUB configuration
echo -e "${CYAN}Generating GRUB configuration...${NC}"
grub-mkconfig -o /boot/grub/grub.cfg

# Verify GRUB configuration and installation
if [[ ! -f /boot/grub/grub.cfg ]]; then
    echo -e "${RED}ERROR: GRUB configuration not generated!${NC}"
    exit 1
fi

# Additional verification for BIOS systems
if [[ ! -d "/sys/firmware/efi" ]]; then
    if [[ ! -f /boot/grub/i386-pc/core.img ]]; then
        echo -e "${YELLOW}Warning: GRUB BIOS core image not found, attempting recovery...${NC}"
        grub-install --target=i386-pc --recheck "${DISK}"
        grub-mkconfig -o /boot/grub/grub.cfg
    fi
fi

echo -e "${GREEN}GRUB installation and configuration completed${NC}"
echo -e "${CYAN}GRUB configuration summary:${NC}"
grep -E "(menuentry|linux|initrd)" /boot/grub/grub.cfg | head -10

# Enable essential services
systemctl enable ntpd.service
systemctl disable dhcpcd.service
systemctl enable NetworkManager.service
systemctl enable reflector.timer

# Configure sudo properly for post-installation security
# Backup sudoers file
cp /etc/sudoers /etc/sudoers.backup

# Use visudo-safe method to configure wheel group
# Remove any existing wheel entries to avoid conflicts
sed -i '/^%wheel/d' /etc/sudoers
sed -i '/^# %wheel/d' /etc/sudoers

# Add proper wheel group configuration with password requirement
cat >> /etc/sudoers << 'SUDOERS_EOF'

# User privilege specification
%wheel ALL=(ALL) ALL
SUDOERS_EOF

# Verify sudoers file syntax
if ! visudo -c -f /etc/sudoers; then
    echo -e "${RED}ERROR: Invalid sudoers configuration, restoring backup${NC}"
    cp /etc/sudoers.backup /etc/sudoers
else
    echo -e "${GREEN}Sudoers configuration verified and applied${NC}"
fi

EOF

    echo ""
    echo -e "${GREEN}Installation completed successfully!${NC}"
    echo -e "${CYAN}Next steps:${NC}"
    echo -e "${CYAN} 1. Reboot your system${NC}"
    echo -e "${CYAN} 2. Login as ${USERNAME}${NC}"
    echo -e "${CYAN} 3. Run: curl -fsSL https://raw.githubusercontent.com/Edior-DB/archer/master/install-archer.sh | bash${NC}"
    echo ""

    gum confirm "Press Enter to continue..."
}

# Main execution
main() {
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        echo "Archer System Installer - Fresh Arch Linux installation from Live ISO"
        echo ""
        echo "Usage: $0"
        echo ""
        echo "This script must be run as root from an Arch Linux Live ISO."
        echo "It will guide you through a complete Arch Linux installation."
        exit 0
    fi

    run_installation
}

# Run main function
main "$@"

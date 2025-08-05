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
        echo -n "Please enter username: "
        read -r username </dev/tty
        if [[ -n "$username" ]] && [[ "$username" =~ ^[a-zA-Z_][a-zA-Z0-9_-]*$ ]] && [[ ${#username} -le 32 ]]; then
            break
        fi
        echo -e "${RED}Invalid username. Must start with letter/underscore, contain only letters, numbers, underscore, dash (max 32 chars).${NC}"
        echo -e "${YELLOW}Examples: john, user123, my_user, test-user${NC}"
    done
    export USERNAME=$username

    # Password
    while true; do
        echo -n "Please enter password: "
        read -rs PASSWORD1 </dev/tty
        echo ""
        echo -n "Please re-enter password: "
        read -rs PASSWORD2 </dev/tty
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
        echo -n "Please name your machine: "
        read -r name_of_machine </dev/tty
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
        echo -n "Please enter password for LUKS encryption: "
        read -rs password1 </dev/tty
        echo ""
        echo -n "Please re-enter password: "
        read -rs password2 </dev/tty
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
    echo -e "${CYAN}========== Timezone Configuration ===========${NC}"
    time_zone="$(curl --fail https://ipapi.co/timezone 2>/dev/null || echo 'UTC')"
    echo -e "${CYAN}System detected your timezone to be '${time_zone}'${NC}"

    echo -n "Is this correct? (Y/n): "
    read -r confirm </dev/tty
    case "${confirm,,}" in
        n|no)
            echo -n "Please enter your desired timezone (e.g. Europe/London): "
            read -r new_timezone </dev/tty
            export TIMEZONE=$new_timezone
            ;;
        *)
            export TIMEZONE=$time_zone
            ;;
    esac
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

    # Try to install gum for better UX
    echo -e "${CYAN}Installing gum for better user experience...${NC}"
    pacman -Sy --noconfirm gum 2>/dev/null || echo -e "${YELLOW}Gum not available, using fallback interface${NC}"

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

# Configure sudo
sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers

# Configure pacman
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
sed -i 's/^#Color/Color\\nILoveCandy/' /etc/pacman.conf
sed -i "/\\[multilib\\]/,/Include/"'s/^#//' /etc/pacman.conf
pacman -Sy --noconfirm --needed

# Install microcode
if grep -q "GenuineIntel" /proc/cpuinfo; then
    pacman -S --noconfirm --needed intel-ucode
elif grep -q "AuthenticAMD" /proc/cpuinfo; then
    pacman -S --noconfirm --needed amd-ucode
fi

# Install graphics drivers
if echo "${gpu_type}" | grep -E "NVIDIA|GeForce"; then
    pacman -S --noconfirm --needed nvidia-lts
elif echo "${gpu_type}" | grep 'VGA' | grep -E "Radeon|AMD"; then
    pacman -S --noconfirm --needed xf86-video-amdgpu
elif echo "${gpu_type}" | grep -E "Integrated Graphics Controller|Intel Corporation UHD"; then
    pacman -S --noconfirm --needed libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-utils lib32-mesa
fi

# Create user
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
systemctl enable ntpd.service
systemctl disable dhcpcd.service
systemctl enable NetworkManager.service
systemctl enable reflector.timer

# Configure sudo properly
sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

EOF

    echo ""
    echo -e "${GREEN}Installation completed successfully!${NC}"
    echo -e "${CYAN}Next steps:${NC}"
    echo -e "${CYAN} 1. Reboot your system${NC}"
    echo -e "${CYAN} 2. Login as ${USERNAME}${NC}"
    echo -e "${CYAN} 3. Run: curl -fsSL https://raw.githubusercontent.com/Edior-DB/archer/master/install-archer.sh | bash${NC}"
    echo ""
    echo -n "Press Enter to continue..."
    read </dev/tty
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

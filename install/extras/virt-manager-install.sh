#!/bin/bash
# Install virt-manager on Arch Linux
set -e

sudo pacman -S --noconfirm virt-manager qemu vde2 ebtables dnsmasq bridge-utils openbsd-netcat

# Enable and start libvirtd
sudo systemctl enable --now libvirtd

# Add user to libvirt and kvm groups
if ! groups $USER | grep -qw libvirt; then
	sudo usermod -aG libvirt $USER
	echo "Added $USER to libvirt group. You may need to log out and back in."
fi
if ! groups $USER | grep -qw kvm; then
	sudo usermod -aG kvm $USER
	echo "Added $USER to kvm group. You may need to log out and back in."
fi

# Set permissions for /dev/kvm (if needed)
sudo chown root:kvm /dev/kvm 2>/dev/null || true
sudo chmod 660 /dev/kvm 2>/dev/null || true

echo -e "\033[32mvirt-manager and dependencies installed.\033[0m"
echo -e "\033[33mIf you just added yourself to groups, log out and back in for changes to take effect.\033[0m"



#!/bin/bash
# Install virt-manager on Arch Linux
set -e




source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/..}/install/system/common-funcs.sh"



# Check for iptables and backend type
if pacman -Q iptables &>/dev/null; then
	# Check if iptables is using the legacy backend
	if iptables --version 2>&1 | grep -q 'legacy'; then
		echo -e "${YELLOW}Legacy iptables is installed.${NC}"
		echo "This will cause a conflict with ebtables (which requires iptables-nft)."
		options=(
			"Install virt-manager and dependencies WITHOUT ebtables (limited networking features)"
			"Remove iptables manually and rerun this script (NOT recommended, may break base/networking)"
			"Exit and wait for Arch to resolve the conflict in the repositories"
		)
		choice=$(select_option "${options[@]}")
		if [[ "$choice" == *WITHOUT* ]]; then
			echo -e "${YELLOW}Installing without ebtables... Some networking features may not work.${NC}"
			if ! sudo pacman -S --noconfirm virt-manager qemu vde2 dnsmasq bridge-utils openbsd-netcat; then
				echo -e "${RED}Failed to install virt-manager or dependencies.${NC}"
				archer_die "Failed to install virt-manager dependencies"
			fi
		elif [[ "$choice" == *Remove* ]]; then
			echo -e "${RED}Please remove iptables manually with 'sudo pacman -Rs iptables' and rerun this script.${NC}"
			echo -e "${RED}WARNING: Removing iptables might break iproute2, base, netctl, and networkmanager.${NC}"
			archer_die "iptables conflict prevents virt-manager installation"
		else
			echo -e "${YELLOW}Exiting. Wait for Arch Linux to resolve the iptables/ebtables conflict.${NC}"
			archer_die "Deferred due to iptables/ebtables conflict"
		fi
	else
		# iptables is present but using nft backend, proceed as normal
    echo -e "${YELLOW}Installing everything${NC}"
		if ! sudo pacman -S --noconfirm virt-manager qemu vde2 ebtables dnsmasq bridge-utils openbsd-netcat; then
			echo -e "\033[31mFailed to install virt-manager or dependencies. Please resolve any package conflicts manually.\033[0m"
			archer_die "Failed to install virt-manager dependencies"
		fi
	fi
else
	# No iptables at all, proceed as normal
  echo -e "${YELLOW}Installing everything${NC}"
	if ! sudo pacman -S --noconfirm virt-manager qemu vde2 ebtables dnsmasq bridge-utils openbsd-netcat; then
		echo -e "\033[31mFailed to install virt-manager or dependencies. Please resolve any package conflicts manually.\033[0m"
		archer_die "Failed to install virt-manager dependencies"
	fi
fi

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



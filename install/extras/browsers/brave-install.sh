#!/bin/bash
# Install Brave browser on Arch Linux
set -e
if ! pacman -Qi brave-bin &>/dev/null; then
    if ! pacman -Qi yay &>/dev/null; then
        sudo pacman -S --noconfirm yay
    fi
    yay -S --noconfirm brave-bin
else
    echo "Brave is already installed."
fi

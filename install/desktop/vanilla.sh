
    # Set default fonts

# Archer KDE Plasma Vanilla Reset Script
# Restores a true fresh KDE Plasma user config (like a new user)
set -e

show_logo() {
    echo -e "\033[0;34m"
    cat << "EOF"
   _   _      _ _         _   _ _____ _   _  _____
  | \ | |    | | |       | | | |_   _| \ | |/  ___|
  |  \| | ___| | | ___   | |_| | | | |  \| |\ `--.
  | . ` |/ _ \ | |/ _ \  |  _  | | | | . ` | `--. \
  | |\  |  __/ | | (_) | | | | |_| |_| |\  |/\__/ /
  \_| \_/\___|_|_|\___/  \_| |_/\___/\_| \_/\____/
EOF
    echo -e "\033[0m"
}

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/..}/install/system/common-funcs.sh"

main() {
    show_logo
    echo -e "\033[1;33mThis will reset your KDE Plasma desktop to a true fresh state (like a new user).\033[0m"
    echo -e "\033[1;33mAll user KDE/Plasma config files will be moved to a backup folder.\033[0m"
    echo
    read -p "Continue? [y/N]: " resp
    [[ $resp =~ ^[Yy]$ ]] || exit 0

    # Stop plasmashell if running
    if pgrep -x plasmashell &>/dev/null; then
        echo -e "\033[1;33mStopping plasmashell...\033[0m"
        killall plasmashell
        sleep 2
    fi

    BACKUP_DIR="$HOME/.config/kde_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    echo -e "\033[1;34mMoving KDE/Plasma config files to $BACKUP_DIR\033[0m"

    for f in plasma* kdeglobals kwinrc kscreenlockerrc ksmserverrc breezerc dolphinrc systemsettingsrc; do
        if [ -e "$HOME/.config/$f" ]; then
            mv "$HOME/.config/$f" "$BACKUP_DIR/"
        fi
    done

    echo -e "\033[1;34mClearing KDE/Plasma cache...\033[0m"
    rm -rf "$HOME/.cache/*"

    if command -v kbuildsycoca6 &>/dev/null; then
        echo -e "\033[1;34mRebuilding KDE config cache...\033[0m"
        kbuildsycoca6 --noincremental
    fi


    echo -e "\033[1;32mKDE Plasma user config reset complete!\033[0m"
    echo -e "\033[1;33mLog out and log back in (or reboot) to experience a true fresh KDE desktop.\033[0m"
    echo -e "\033[1;34mYour old configs are backed up in: $BACKUP_DIR\033[0m"

    if confirm_action "Would you like to log out now to apply the reset?"; then
        echo -e "\033[1;34mLogging out in 3 seconds...\033[0m"
        sleep 1
        echo -e "\033[1;34mLogging out in 2 seconds...\033[0m"
        sleep 1
        echo -e "\033[1;34mLogging out in 1 second...\033[0m"
        sleep 1
        loginctl terminate-user "$USER"
    else
        wait_for_input "Press Enter to continue..."
    fi
}

main


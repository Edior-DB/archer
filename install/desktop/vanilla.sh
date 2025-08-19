
    # Set default fonts

# Archer KDE Plasma Vanilla Reset Script
# Restores a true fresh KDE Plasma user config (like a new user)
set -e

show_logo() {
    echo -e "\033[0;34m"
    cat << "LOGOEOF"
██    ██  █████  ███    ██ ██ ██      ██      █████      ██████  ██      █████  ███    ███  █████
██    ██ ██   ██ ████   ██ ██ ██      ██     ██   ██     ██   ██ ██     ██   ██ ████  ████ ██   ██
██    ██ ███████ ██ ██  ██ ██ ██      ██     ███████     ██████  ██     ███████ ██ ████ ██ ███████
 ██  ██  ██   ██ ██  ██ ██ ██ ██      ██     ██   ██     ██   ██ ██     ██   ██ ██  ██  ██ ██   ██
  ████   ██   ██ ██   ████ ██ ███████ ██████ ██   ██     ██████  ██████ ██   ██ ██      ██ ██   ██

LOGOEOF
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


    echo -e "\033[1;34mRemoving all user KDE/Plasma config and cache for a true fresh start...\033[0m"

    # Remove ~/.config KDE/Plasma files
    for f in plasma* kdeglobals kwinrc kscreenlockerrc ksmserverrc breezerc dolphinrc systemsettingsrc autostart; do
        rm -rf "$HOME/.config/$f"
    done

    # Remove ~/.local/share KDE/Plasma files
    for d in plasma kactivitymanagerd user-places.xbel kxmlgui5 knewstuff3; do
        rm -rf "$HOME/.local/share/$d"
    done

    # Remove ~/.cache KDE/Plasma files
    for d in kactivitymanagerd plasma*; do
        rm -rf "$HOME/.cache/$d"
    done

    # Remove legacy ~/.kde4
    rm -rf "$HOME/.kde4"

    # Optionally reinstall core Plasma packages
    if confirm_action "Do you want to reinstall core Plasma packages to ensure a clean system?"; then
        echo -e "\033[1;34mReinstalling core Plasma packages...\033[0m"
        sudo pacman -S --noconfirm --needed plasma-desktop plasma-workspace plasma-x11-session kde-cli-tools systemsettings dolphin konsole sddm xorg xorg-server breeze breeze-gtk breeze-icons kde-gtk-config ark kwalletmanager kdeplasma-addons xdg-utils qt5-tools
    fi

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
        # Try Plasma 6 logout via qdbus Shutdown interface
        if command -v qdbus &>/dev/null && qdbus org.kde.Shutdown /Shutdown org.kde.Shutdown.logout; then
            echo -e "\033[1;32mRequested Plasma logout.\033[0m"
        else
            echo -e "\033[1;33mPlasma logout failed or not available, forcing logout...\033[0m"
            if [[ -n "$XDG_SESSION_ID" ]]; then
                loginctl terminate-session "$XDG_SESSION_ID"
            else
                loginctl terminate-user "$USER"
            fi
        fi
    else
        wait_for_input "Press Enter to continue..."
    fi
}

main


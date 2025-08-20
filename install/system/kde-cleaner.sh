#!/bin/bash
# Archer KDE/Plasma Cleaner Script
# Removes all user KDE/Plasma config, cache, and local data for a true fresh start
set -e

show_logo() {
    echo -e "\033[0;34m"
    cat << "LOGOEOF"
██   ██  ██████  ██████  ███████     ██████  ███████  █████  ███████ ███████
██   ██ ██    ██ ██   ██ ██          ██   ██ ██      ██   ██ ██      ██
███████ ██    ██ ██   ██ █████       ██████  █████   ███████ █████   ███████
██   ██ ██    ██ ██   ██ ██          ██      ██      ██   ██ ██           ██
██   ██  ██████  ██████  ███████     ██      ███████ ██   ██ ███████ ███████
LOGOEOF
    echo -e "\033[0m"
}



clean() {
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

    echo -e "\033[1;32mKDE/Plasma user config and cache removed!\033[0m"
}

restore_kde() {
    echo -e "\033[1;34mRestoring golden KDE Plasma config...\033[0m"
    GOLDEN_CONFIG_DIR="${ARCHER_DIR:-$HOME/.local/share/archer}/defaults/.config"
    if [ -d "$GOLDEN_CONFIG_DIR" ]; then
        mkdir -p "$HOME/.config"
        cp -a "$GOLDEN_CONFIG_DIR/"* "$HOME/.config/"
        echo -e "\033[1;32mKDE Plasma user config restored from golden config!\033[0m"
    else
        echo -e "\033[1;33mWarning: No golden KDE Plasma config found in $GOLDEN_CONFIG_DIR. Plasma will regenerate new defaults.\033[0m"
    fi
}

main() {
    show_logo
    echo -e "\033[1;33mThis will remove all user KDE/Plasma config, cache, and local data for a true fresh start, then restore from the golden config.\033[0m"
    echo -e "\033[1;33mYour configs will be lost unless you have a backup!\033[0m"
    echo
    read -p "Continue? [y/N]: " resp
    [[ $resp =~ ^[Yy]$ ]] || exit 0

    # Stop plasmashell if running
    if pgrep -x plasmashell &>/dev/null; then
        echo -e "\033[1;33mStopping plasmashell...\033[0m"
        killall plasmashell
        sleep 2
    fi

    clean
    restore_kde

    if command -v qdbus &>/dev/null; then
        read -p "Would you like to log out now to apply the reset? [y/N]: " logout_resp
        if [[ $logout_resp =~ ^[Yy]$ ]]; then

            if qdbus org.kde.Shutdown /Shutdown org.kde.Shutdown.logout; then
                echo -e "\033[1;32mRequested Plasma logout.\033[0m"
            else
                echo -e "\033[1;33mPlasma logout failed or not available, forcing logout...\033[0m"
                if [[ -n "$XDG_SESSION_ID" ]]; then
                    loginctl terminate-session "$XDG_SESSION_ID"
                else
                    loginctl terminate-user "$USER"
                fi
            fi
        fi
    fi
}

main

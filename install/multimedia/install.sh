#!/bin/bash
# Multimedia Applications installation script
# Provides gaming, media players, content creation, and streaming tools

# ==============================================================================
# CONFIGURATION
# ==============================================================================
COMPONENT_NAME="Multimedia Applications"
COMPONENT_DIR="$(dirname "$(realpath "$0")")"
ARCHER_DIR="${ARCHER_DIR:-$(dirname "$(dirname "$COMPONENT_DIR")")}"

# Source common functions
source "$ARCHER_DIR/install/system/common-funcs.sh"

# ==============================================================================
# INSTALLATION FUNCTIONS
# ==============================================================================

install_all_multimedia() {
    log_info "Installing all $COMPONENT_NAME modules..."

    # Array of all multimedia module directories in order
    local modules=(
        "gaming"
        "media-players"
        "content-creation"
        "streaming"
    )

    local total=${#modules[@]}
    local current=0

    for module in "${modules[@]}"; do
        current=$((current + 1))
        local module_path="$COMPONENT_DIR/$module"

        if [[ -d "$module_path" && -f "$module_path/install.sh" ]]; then
            log_info "[$current/$total] Installing $module modules..."
            execute_with_progress "bash '$module_path/install.sh' --all" "Installing $module..."
        else
            log_warning "Module not found: $module"
        fi
    done

    log_success "All $COMPONENT_NAME modules installed!"
}

install_essential_multimedia() {
    log_info "Installing essential $COMPONENT_NAME modules..."

    # Array of essential multimedia components
    local essential_modules=(
        "gaming"          # Basic gaming platforms
        "media-players"   # Essential media players
    )

    local total=${#essential_modules[@]}
    local current=0

    for module in "${essential_modules[@]}"; do
        current=$((current + 1))
        local module_path="$COMPONENT_DIR/$module"

        if [[ -d "$module_path" && -f "$module_path/install.sh" ]]; then
            log_info "[$current/$total] Installing essential $module..."
            execute_with_progress "bash '$module_path/install.sh' --essential" "Installing essential $module..."
        else
            log_warning "Module not found: $module"
        fi
    done

    log_success "Essential $COMPONENT_NAME modules installed!"
}

install_gaming_only() {
    log_info "Installing gaming modules..."

    local gaming_path="$COMPONENT_DIR/gaming"
    if [[ -d "$gaming_path" && -f "$gaming_path/install.sh" ]]; then
        execute_with_progress "bash '$gaming_path/install.sh' --all" "Installing gaming modules..."
    else
        log_warning "Gaming module not found"
    fi

    log_success "Gaming modules installed!"
}

install_media_only() {
    log_info "Installing media player modules..."

    local media_path="$COMPONENT_DIR/media-players"
    if [[ -d "$media_path" && -f "$media_path/install.sh" ]]; then
        execute_with_progress "bash '$media_path/install.sh' --all" "Installing media player modules..."
    else
        log_warning "Media players module not found"
    fi

    log_success "Media player modules installed!"
}

install_content_creation_only() {
    log_info "Installing content creation modules..."

    local content_path="$COMPONENT_DIR/content-creation"
    if [[ -d "$content_path" && -f "$content_path/install.sh" ]]; then
        execute_with_progress "bash '$content_path/install.sh' --all" "Installing content creation modules..."
    else
        log_warning "Content creation module not found"
    fi

    log_success "Content creation modules installed!"
}

install_streaming_only() {
    log_info "Installing streaming modules..."

    local streaming_path="$COMPONENT_DIR/streaming"
    if [[ -d "$streaming_path" && -f "$streaming_path/install.sh" ]]; then
        execute_with_progress "bash '$streaming_path/install.sh' --all" "Installing streaming modules..."
    else
        log_warning "Streaming module not found"
    fi

    log_success "Streaming modules installed!"
}

install_all_scripts() {
    log_info "Installing all scripts in the multimedia directory..."
    for script in $(find "$COMPONENT_DIR" -name "install.sh" -type f); do
        bash "$script" --all
    done
}

install_custom_selection() {
    log_info "Installing selected scripts in the multimedia directory..."
    for script in "$@"; do
        if [[ -f "$script" ]]; then
            bash "$script"
        else
            log_warning "Script not found: $script"
        fi
    done
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

main() {
    log_info "Starting $COMPONENT_NAME installation..."

    # Parse command line arguments
    local install_mode="all"
    local custom_scripts=()

    while [[ $# -gt 0 ]]; do
        case $1 in
            --essential)
                install_mode="essential"
                shift
                ;;
            --gaming)
                install_mode="gaming"
                shift
                ;;
            --media)
                install_mode="media"
                shift
                ;;
            --content-creation)
                install_mode="content"
                shift
                ;;
            --streaming)
                install_mode="streaming"
                shift
                ;;
            --all)
                install_mode="all"
                shift
                ;;
            --scripts)
                install_mode="custom"
                shift
                # Collect script names until next option or end
                while [[ $# -gt 0 && ! "$1" =~ ^-- ]]; do
                    custom_scripts+=("$1")
                    shift
                done
                ;;
            --help)
                echo "Usage: $0 [--all|--essential|--gaming|--media|--content-creation|--streaming|--scripts script1 script2 ...] [--help]"
                echo ""
                echo "Multimedia applications installation options:"
                echo "  --all               Install all multimedia modules (default)"
                echo "  --essential         Install essential modules (gaming, media players)"
                echo "  --gaming            Install gaming platforms and tools"
                echo "  --media             Install media players and codecs"
                echo "  --content-creation  Install video/image/audio editing tools"
                echo "  --streaming         Install OBS Studio and streaming tools"
                echo "  --scripts           Install specific module scripts"
                echo "  --help              Show this help message"
                echo ""
                echo "Available modules:"
                echo "  Gaming:           Steam, Lutris, emulators, gaming tools"
                echo "  Media Players:    VLC, MPV, audio tools, codecs"
                echo "  Content Creation: Video editing, image editing, audio production"
                echo "  Streaming:        OBS Studio, streaming and recording tools"
                echo ""
                echo "Examples:"
                echo "  $0                                    # Install all modules"
                echo "  $0 --essential                       # Install essential modules"
                echo "  $0 --gaming                          # Install gaming only"
                echo "  $0 --scripts gaming/gaming-platforms.sh streaming/obs-studio.sh"
                exit 0
                ;;
            *)
                log_warning "Unknown option: $1"
                shift
                ;;
        esac
    done

    # Execute installation based on mode
    case "$install_mode" in
        "essential")
            install_essential_multimedia
            ;;
        "gaming")
            install_gaming_only
            ;;
        "media")
            install_media_only
            ;;
        "content")
            install_content_creation_only
            ;;
        "streaming")
            install_streaming_only
            ;;
        "custom")
            install_custom_selection "${custom_scripts[@]}"
            ;;
        "all"|*)
            install_all_multimedia
            ;;
    esac

    log_info "$COMPONENT_NAME installation completed!"
}

# Execute main function with all arguments
main "$@"

#!/bin/bash
# Database Tools installation script
# Provides unopinionated bulk installation of database systems and clients

# ==============================================================================
# CONFIGURATION
# ==============================================================================
COMPONENT_NAME="Database Tools"
COMPONENT_DIR="$(dirname "$(realpath "$0")")"
ARCHER_DIR="${ARCHER_DIR:-$(dirname "$(dirname "$(dirname "$COMPONENT_DIR")")")}"

# Source common functions
source "$ARCHER_DIR/install/system/common-funcs.sh"

# ==============================================================================
# INSTALLATION FUNCTIONS
# ==============================================================================

install_all_scripts() {
    log_info "Installing all $COMPONENT_NAME..."

    # Array of all database installation scripts in order
    local scripts=(
        "postgresql.sh"
        "mariadb.sh"
        "redis.sh"
        "sqlite.sh"
        "mongodb.sh"
        "dbeaver.sh"
        "dbmate.sh"
    )

    local total=${#scripts[@]}
    local current=0

    for script in "${scripts[@]}"; do
        current=$((current + 1))
        local script_path="$COMPONENT_DIR/$script"

        if [[ -f "$script_path" ]]; then
            log_info "[$current/$total] Installing $(basename "$script" .sh | sed 's/-/ /g')..."
            execute_with_progress "bash '$script_path'" "Installing $(basename "$script" .sh)..."
        else
            log_warning "Script not found: $script"
        fi
    done

    log_success "All $COMPONENT_NAME installed!"
}

install_essential_scripts() {
    log_info "Installing essential $COMPONENT_NAME..."

    # Array of essential database tools
    local essential_scripts=(
        "postgresql.sh"
        "sqlite.sh"
        "dbeaver.sh"
    )

    local total=${#essential_scripts[@]}
    local current=0

    for script in "${essential_scripts[@]}"; do
        current=$((current + 1))
        local script_path="$COMPONENT_DIR/$script"

        if [[ -f "$script_path" ]]; then
            log_info "[$current/$total] Installing $(basename "$script" .sh | sed 's/-/ /g')..."
            execute_with_progress "bash '$script_path'" "Installing $(basename "$script" .sh)..."
        else
            log_warning "Script not found: $script"
        fi
    done

    log_success "Essential $COMPONENT_NAME installed!"
}

install_servers() {
    log_info "Installing database servers..."

    local server_scripts=(
        "postgresql.sh"
        "mariadb.sh"
        "redis.sh"
        "mongodb.sh"
    )

    local total=${#server_scripts[@]}
    local current=0

    for script in "${server_scripts[@]}"; do
        current=$((current + 1))
        local script_path="$COMPONENT_DIR/$script"

        if [[ -f "$script_path" ]]; then
            log_info "[$current/$total] Installing $(basename "$script" .sh | sed 's/-/ /g')..."
            execute_with_progress "bash '$script_path'" "Installing $(basename "$script" .sh)..."
        else
            log_warning "Script not found: $script"
        fi
    done

    log_success "Database servers installed!"
}

install_clients() {
    log_info "Installing database clients..."

    local client_scripts=(
        "sqlite.sh"
        "dbeaver.sh"
        "dbmate.sh"
    )

    local total=${#client_scripts[@]}
    local current=0

    for script in "${client_scripts[@]}"; do
        current=$((current + 1))
        local script_path="$COMPONENT_DIR/$script"

        if [[ -f "$script_path" ]]; then
            log_info "[$current/$total] Installing $(basename "$script" .sh | sed 's/-/ /g')..."
            execute_with_progress "bash '$script_path'" "Installing $(basename "$script" .sh)..."
        else
            log_warning "Script not found: $script"
        fi
    done

    log_success "Database clients installed!"
}

install_custom_selection() {
    local scripts=("$@")

    if [[ ${#scripts[@]} -eq 0 ]]; then
        log_error "No database scripts specified for custom installation"
        return 1
    fi

    log_info "Installing selected $COMPONENT_NAME..."

    local total=${#scripts[@]}
    local current=0

    for script in "${scripts[@]}"; do
        current=$((current + 1))
        local script_path="$COMPONENT_DIR/$script"

        if [[ -f "$script_path" ]]; then
            log_info "[$current/$total] Installing $(basename "$script" .sh | sed 's/-/ /g')..."
            execute_with_progress "bash '$script_path'" "Installing $(basename "$script" .sh)..."
        else
            log_warning "Script not found: $script"
        fi
    done

    log_success "Selected $COMPONENT_NAME installed!"
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
            --servers)
                install_mode="servers"
                shift
                ;;
            --clients)
                install_mode="clients"
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
                echo "Usage: $0 [--all|--essential|--servers|--clients|--scripts script1 script2 ...] [--help]"
                echo ""
                echo "Database installation options:"
                echo "  --all            Install all tools (default)"
                echo "  --essential      Install essential tools (PostgreSQL, SQLite, DBeaver)"
                echo "  --servers        Install database servers (PostgreSQL, MariaDB, Redis, MongoDB)"
                echo "  --clients        Install database clients (SQLite, DBeaver, dbmate)"
                echo "  --scripts        Install specific tool packages"
                echo "  --help           Show this help message"
                echo ""
                echo "Available tool packages:"
                echo "  postgresql.sh    PostgreSQL database server"
                echo "  mariadb.sh       MariaDB database server"
                echo "  redis.sh         Redis in-memory database"
                echo "  sqlite.sh        SQLite database and client"
                echo "  mongodb.sh       MongoDB document database"
                echo "  dbeaver.sh       DBeaver universal database client"
                echo "  dbmate.sh        dbmate database migration tool"
                echo ""
                echo "Examples:"
                echo "  $0                                    # Install all tools"
                echo "  $0 --essential                       # Install essential tools"
                echo "  $0 --servers                         # Install database servers"
                echo "  $0 --clients                         # Install database clients"
                echo "  $0 --scripts postgresql.sh dbeaver.sh # Install specific tools"
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
            install_essential_scripts
            ;;
        "servers")
            install_servers
            ;;
        "clients")
            install_clients
            ;;
        "custom")
            install_custom_selection "${custom_scripts[@]}"
            ;;
        "all"|*)
            install_all_scripts
            ;;
    esac

    log_info "$COMPONENT_NAME installation completed!"
}

# Execute main function with all arguments
main "$@"

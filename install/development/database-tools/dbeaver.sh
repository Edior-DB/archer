#!/bin/bash
# DBeaver Universal Database Tool Installation
# Cross-platform database administration tool

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/../..}/install/system/common-funcs.sh"

show_banner "DBeaver Database Tool"

echo -e "${BLUE}DBeaver - Universal Database Administration Tool${NC}"
echo -e "${YELLOW}Installing DBeaver GUI database client${NC}"
echo ""

if ! archer_confirm_or_default "Install DBeaver database administration tool?"; then
    echo -e "${YELLOW}DBeaver installation cancelled.${NC}"
    exit 0
fi

echo -e "${BLUE}Installing DBeaver...${NC}"

# Try to install from official repos first, then AUR
if install_with_retries dbeaver; then
    echo -e "${GREEN}✓ DBeaver installed successfully from official repository!${NC}"
else
    echo -e "${YELLOW}DBeaver not found in official repos, trying AUR...${NC}"

    # Check for AUR helper
    if command -v yay &> /dev/null; then
        aur_helper="yay"
    elif command -v paru &> /dev/null; then
        aur_helper="paru"
    else
        echo -e "${YELLOW}AUR helper (yay or paru) not found. Installing yay first...${NC}"
    if ! install_with_retries base-devel git; then
      echo -e "${RED}✗ Failed to install build dependencies${NC}"
      archer_die "Failed to install build dependencies for DBeaver"
    fi

        cd /tmp
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
        aur_helper="yay"
    fi

    echo -e "${BLUE}Installing DBeaver from AUR using $aur_helper...${NC}"
    if $aur_helper -S --noconfirm dbeaver; then
        echo -e "${GREEN}✓ DBeaver installed successfully from AUR!${NC}"
  else
    echo -e "${RED}✗ Failed to install DBeaver from AUR${NC}"
    archer_die "Failed to install DBeaver from AUR"
  fi
fi

# Check if DBeaver was installed successfully
if command -v dbeaver &> /dev/null; then
    echo -e "${GREEN}✓ DBeaver installation verified${NC}"

    # Get version if possible
    dbeaver_version=$(dbeaver --version 2>/dev/null | head -1 || echo "DBeaver installed")

    echo -e "${GREEN}
=========================================================================
                    DBeaver Installation Complete!
=========================================================================

Installed version:
  $dbeaver_version

Launch DBeaver:
  dbeaver                          # Start DBeaver GUI
  Applications → Development → DBeaver

Supported databases:
  Relational Databases:
  - PostgreSQL, MySQL, MariaDB
  - SQLite, Oracle, SQL Server
  - IBM DB2, Firebird, H2
  - HSQLDB, Derby, Sybase

  NoSQL Databases:
  - MongoDB, Cassandra
  - Redis, InfluxDB
  - Elasticsearch, DynamoDB

  Cloud Databases:
  - Amazon RDS, Aurora
  - Google Cloud SQL
  - Microsoft Azure SQL

Key features:
  - SQL editor with syntax highlighting
  - Visual query builder
  - Database schema browser
  - Data export/import tools
  - ER diagrams and visualizations
  - Connection management
  - Multi-platform support

Getting started:
  1. Launch DBeaver
  2. Click 'New Database Connection'
  3. Select your database type
  4. Enter connection details
  5. Test connection
  6. Start browsing your database

Connection examples:
  PostgreSQL:
    Host: localhost, Port: 5432
    Database: your_db_name
    Username: your_username

  MySQL/MariaDB:
    Host: localhost, Port: 3306
    Database: your_db_name
    Username: your_username

  SQLite:
    Path: /path/to/database.db

  MongoDB:
    Host: localhost, Port: 27017
    Database: your_db_name

Tips:
  - Use connection templates for common setups
  - Save frequently used queries as bookmarks
  - Export data in various formats (CSV, JSON, XML)
  - Use SSH tunneling for secure remote connections
  - Install database drivers when prompted

Configuration:
  ~/.local/share/DBeaverData/        # User data directory
  ~/.dbeaver/                        # Configuration files

Documentation: https://dbeaver.io/docs/
Community: https://github.com/dbeaver/dbeaver
${NC}"

    # Offer to create desktop entry if not exists
    desktop_file="$HOME/.local/share/applications/dbeaver.desktop"
    if [[ ! -f "$desktop_file" ]] && [[ ! -f "/usr/share/applications/dbeaver.desktop" ]]; then
        echo ""
  if archer_confirm_or_default "Create desktop entry for easy access?"; then
            echo -e "${BLUE}Creating desktop entry...${NC}"
            mkdir -p "$HOME/.local/share/applications"
            cat > "$desktop_file" <<EOF
[Desktop Entry]
Name=DBeaver
Comment=Universal Database Tool
Exec=dbeaver
Icon=dbeaver
Type=Application
Categories=Development;Database;
StartupNotify=true
EOF
            echo -e "${GREEN}✓ Desktop entry created${NC}"
            echo -e "${CYAN}DBeaver will appear in Applications → Development${NC}"
        fi
    fi

    # Show next steps
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo -e "1. Launch DBeaver: ${CYAN}dbeaver${NC}"
    echo -e "2. Set up database connections"
    echo -e "3. Install any required database drivers when prompted"
    echo -e "4. Explore your databases with the intuitive GUI"

else
    echo -e "${RED}✗ DBeaver installation verification failed${NC}"
    echo -e "${YELLOW}Try launching manually: dbeaver${NC}"
fi

wait_for_input

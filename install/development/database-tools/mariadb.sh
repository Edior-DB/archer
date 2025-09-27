#!/bin/bash
# MariaDB Database Server Installation
# Popular open-source relational database, MySQL-compatible

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/../..}/install/system/common-funcs.sh"

show_banner "MariaDB Database Server"

echo -e "${BLUE}MariaDB - Reliable, High Performance MySQL-compatible Database${NC}"
echo -e "${YELLOW}Installing MariaDB server and client tools${NC}"
echo ""

if ! archer_confirm_or_default "Install MariaDB database server?"; then
  echo -e "${YELLOW}MariaDB installation cancelled.${NC}"
  exit 0
fi

echo -e "${BLUE}Installing MariaDB...${NC}"

# Install MariaDB server and client
if install_with_retries mariadb mariadb-clients; then
    echo -e "${GREEN}✓ MariaDB installed successfully!${NC}"

    # Enable and start MariaDB service
    echo -e "${BLUE}Enabling MariaDB service...${NC}"
    sudo systemctl enable mariadb
    sudo systemctl start mariadb

    # Check if service is running
    if systemctl is-active --quiet mariadb; then
        echo -e "${GREEN}✓ MariaDB service is running${NC}"

        # Get version
        mariadb_version=$(mysql --version 2>/dev/null | head -1 || echo "MariaDB installed")

        echo -e "${GREEN}
=========================================================================
                    MariaDB Installation Complete!
=========================================================================

Installed version:
  $mariadb_version

Service status:
  ✓ MariaDB service enabled and running

Key commands:
  mysql -u root -p                   # Connect as root user
  sudo systemctl status mariadb      # Check service status
  sudo systemctl stop mariadb        # Stop service
  sudo systemctl start mariadb       # Start service
  mysqladmin create database_name    # Create database
  mysqladmin drop database_name      # Drop database

Database files location:
  /var/lib/mysql/

Configuration files:
  /etc/my.cnf.d/server.cnf          # Main server config
  /etc/my.cnf                       # Global config

Default setup:
  - Root user: root (no password initially)
  - Port: 3306
  - Socket: /run/mysqld/mysqld.sock

Security configuration:
  Run 'sudo mysql_secure_installation' to:
  - Set root password
  - Remove anonymous users
  - Disable remote root login
  - Remove test database

Common MariaDB commands:
  SHOW DATABASES;                    # List databases
  USE database_name;                 # Switch to database
  SHOW TABLES;                       # List tables
  CREATE DATABASE name;              # Create database
  DROP DATABASE name;                # Delete database

Documentation: https://mariadb.org/documentation/
${NC}"

        # Offer to run security setup
        echo ""
  if archer_confirm_or_default "Run MariaDB security configuration now?"; then
            echo -e "${BLUE}Running MariaDB security configuration...${NC}"
            echo -e "${YELLOW}You'll be prompted to set root password and security options${NC}"
            sudo mysql_secure_installation
            echo -e "${GREEN}✓ MariaDB security configuration completed${NC}"
        else
            echo -e "${YELLOW}⚠ Remember to run 'sudo mysql_secure_installation' later for security${NC}"
        fi

        # Offer to create a sample database
        echo ""
  if archer_confirm_or_default "Create a sample database for testing?"; then
            echo -e "${BLUE}Creating sample database 'testdb'...${NC}"
            mysql -u root -e "CREATE DATABASE IF NOT EXISTS testdb;"
            echo -e "${GREEN}✓ Sample database 'testdb' created${NC}"
            echo -e "${CYAN}Connect with: mysql -u root -p testdb${NC}"
        fi

    else
        echo -e "${RED}✗ MariaDB service failed to start${NC}"
        echo -e "${YELLOW}You can try starting it manually with: sudo systemctl start mariadb${NC}"
    fi

else
  echo -e "${RED}✗ Failed to install MariaDB${NC}"
  archer_die "Failed to install MariaDB"
fi

wait_for_input

#!/bin/bash
# PostgreSQL Database Server Installation
# High-performance, feature-rich relational database

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/../..}/install/system/common-funcs.sh"

show_banner "PostgreSQL Database Server"

echo -e "${BLUE}PostgreSQL - The World's Most Advanced Open Source Database${NC}"
echo -e "${YELLOW}Installing PostgreSQL server and client tools${NC}"
echo ""

if ! confirm_action "Install PostgreSQL database server?"; then
    echo -e "${YELLOW}PostgreSQL installation cancelled.${NC}"
    exit 0
fi

echo -e "${BLUE}Installing PostgreSQL...${NC}"

# Install PostgreSQL server and client
if install_with_retries postgresql postgresql-contrib; then
    echo -e "${GREEN}✓ PostgreSQL installed successfully!${NC}"

    # Initialize the database if not already done
    if [[ ! -d /var/lib/postgres/data ]]; then
        echo -e "${BLUE}Initializing PostgreSQL database...${NC}"
        sudo -u postgres initdb -D /var/lib/postgres/data
        echo -e "${GREEN}✓ Database initialized${NC}"
    fi

    # Enable and start PostgreSQL service
    echo -e "${BLUE}Enabling PostgreSQL service...${NC}"
    sudo systemctl enable postgresql
    sudo systemctl start postgresql

    # Check if service is running
    if systemctl is-active --quiet postgresql; then
        echo -e "${GREEN}✓ PostgreSQL service is running${NC}"

        # Get version
        pg_version=$(sudo -u postgres psql -c "SELECT version();" | grep PostgreSQL | head -1 || echo "PostgreSQL installed")

        echo -e "${GREEN}
=========================================================================
                    PostgreSQL Installation Complete!
=========================================================================

Installed version:
  $pg_version

Service status:
  ✓ PostgreSQL service enabled and running

Key commands:
  sudo -u postgres psql              # Connect as postgres user
  sudo systemctl status postgresql   # Check service status
  sudo systemctl stop postgresql     # Stop service
  sudo systemctl start postgresql    # Start service
  createdb database_name              # Create database
  dropdb database_name                # Drop database

Database files location:
  /var/lib/postgres/data/

Configuration files:
  /var/lib/postgres/data/postgresql.conf    # Main config
  /var/lib/postgres/data/pg_hba.conf        # Authentication config

Default setup:
  - Superuser: postgres (no password by default)
  - Port: 5432
  - Encoding: UTF8

First steps:
  1. Set password for postgres user:
     sudo -u postgres psql -c \"ALTER USER postgres PASSWORD 'your_password';\"

  2. Create your first database:
     sudo -u postgres createdb mydatabase

  3. Connect to database:
     sudo -u postgres psql mydatabase

Security notes:
  - Configure pg_hba.conf for your security needs
  - Set strong passwords for database users
  - Consider firewall rules for port 5432

Documentation: https://www.postgresql.org/docs/
${NC}"

        # Offer to set up postgres password
        echo ""
        if confirm_action "Set up password for postgres user?"; then
            echo -e "${BLUE}Setting up postgres user password...${NC}"
            sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'postgres';"
            echo -e "${GREEN}✓ Default password 'postgres' set for postgres user${NC}"
            echo -e "${YELLOW}⚠ Remember to change this to a secure password in production!${NC}"
        fi

        # Offer to create a sample database
        echo ""
        if confirm_action "Create a sample database for testing?"; then
            echo -e "${BLUE}Creating sample database 'testdb'...${NC}"
            sudo -u postgres createdb testdb
            echo -e "${GREEN}✓ Sample database 'testdb' created${NC}"
            echo -e "${CYAN}Connect with: sudo -u postgres psql testdb${NC}"
        fi

    else
        echo -e "${RED}✗ PostgreSQL service failed to start${NC}"
        echo -e "${YELLOW}You can try starting it manually with: sudo systemctl start postgresql${NC}"
    fi

else
    echo -e "${RED}✗ Failed to install PostgreSQL${NC}"
    exit 1
fi

wait_for_input

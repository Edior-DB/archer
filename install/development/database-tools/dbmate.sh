#!/bin/bash
# DBmate Database Migration Tool Installation
# Lightweight database migration tool

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/../..}/install/system/common-funcs.sh"

show_banner "DBmate Migration Tool"

echo -e "${BLUE}DBmate - Database Migration Tool${NC}"
echo -e "${YELLOW}Installing DBmate for database schema migrations${NC}"
echo ""

if ! confirm_action "Install DBmate database migration tool?"; then
    echo -e "${YELLOW}DBmate installation cancelled.${NC}"
    exit 0
fi

echo -e "${BLUE}Installing DBmate...${NC}"

# Setup mise if not available
setup_mise

# Install DBmate using mise
if install_mise_tool "dbmate" "latest"; then
    echo -e "${GREEN}✓ DBmate installed successfully!${NC}"

    # Verify installation
    if verify_mise_tool "dbmate"; then
        echo -e "${GREEN}✓ DBmate is available and working${NC}"

        # Get version
        dbmate_version=$(dbmate --version 2>/dev/null || echo "DBmate installed")

        echo -e "${GREEN}
=========================================================================
                    DBmate Installation Complete!
=========================================================================

Installed version:
  $dbmate_version

Key commands:
  dbmate --help                    # Show help and commands
  dbmate new migration_name        # Create new migration
  dbmate up                        # Apply pending migrations
  dbmate down                      # Rollback last migration
  dbmate status                    # Show migration status
  dbmate create                    # Create database
  dbmate drop                      # Drop database
  dbmate dump                      # Dump database schema

Supported databases:
  - PostgreSQL
  - MySQL/MariaDB
  - SQLite
  - ClickHouse

Configuration:
  Set DATABASE_URL environment variable:

  PostgreSQL:
    export DATABASE_URL=\"postgres://user:pass@host/dbname?sslmode=disable\"

  MySQL/MariaDB:
    export DATABASE_URL=\"mysql://user:pass@host/dbname\"

  SQLite:
    export DATABASE_URL=\"sqlite:database.db\"

Project setup:
  1. Set DATABASE_URL in your environment
  2. Initialize migrations: mkdir -p db/migrations
  3. Create first migration: dbmate new create_users_table
  4. Edit migration file in db/migrations/
  5. Apply migrations: dbmate up

Migration file structure:
  db/migrations/
    20230101000000_create_users_table.sql
    20230101000001_add_email_to_users.sql

Example migration (create_users_table.sql):
  -- migrate:up
  CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );

  -- migrate:down
  DROP TABLE users;

Environment variables:
  DATABASE_URL                     # Database connection string
  DBMATE_MIGRATIONS_DIR           # Migrations directory (default: db/migrations)
  DBMATE_SCHEMA_FILE              # Schema file (default: db/schema.sql)
  DBMATE_NO_DUMP_SCHEMA           # Skip schema dump after migration

Workflow:
  1. dbmate new add_posts_table    # Create migration
  2. Edit the migration file
  3. dbmate up                     # Apply migration
  4. dbmate status                 # Check status
  5. dbmate down                   # Rollback if needed

Common patterns:
  # Apply all pending migrations
  dbmate up

  # Create and apply migration in one step
  dbmate new add_column && dbmate up

  # Check what migrations are pending
  dbmate status

  # Dump current schema to file
  dbmate dump

Integration:
  - Works well with Docker containers
  - Can be used in CI/CD pipelines
  - Integrates with most web frameworks
  - Supports transaction-wrapped migrations

Documentation: https://github.com/amacneil/dbmate
${NC}"

        # Offer to set up a sample project
        echo ""
        if confirm_action "Set up a sample migration project for testing?"; then
            echo -e "${BLUE}Setting up sample project...${NC}"

            # Create sample project structure
            mkdir -p dbmate-example/db/migrations
            cd dbmate-example

            # Set up SQLite database for demo
            echo "DATABASE_URL=sqlite:example.db" > .env
            export DATABASE_URL="sqlite:example.db"

            # Create sample migration
            dbmate new create_users_table

            # Find the migration file and add content
            migration_file=$(ls db/migrations/*_create_users_table.sql)
            cat > "$migration_file" <<EOF
-- migrate:up
CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO users (name, email) VALUES
  ('John Doe', 'john@example.com'),
  ('Jane Smith', 'jane@example.com');

-- migrate:down
DROP TABLE users;
EOF

            # Apply the migration
            dbmate up

            echo -e "${GREEN}✓ Sample project created in 'dbmate-example/'${NC}"
            echo -e "${CYAN}Explore with:${NC}"
            echo -e "  cd dbmate-example"
            echo -e "  source .env"
            echo -e "  dbmate status"
            echo -e "  sqlite3 example.db 'SELECT * FROM users;'"
            echo -e "  dbmate down  # to rollback"
            echo -e "  dbmate up    # to reapply"

            cd ..
        fi

        echo ""
        echo -e "${BLUE}Quick start:${NC}"
        echo -e "1. Set DATABASE_URL: ${CYAN}export DATABASE_URL=\"sqlite:myapp.db\"${NC}"
        echo -e "2. Create migration: ${CYAN}dbmate new create_initial_schema${NC}"
        echo -e "3. Edit migration file in db/migrations/"
        echo -e "4. Apply migration: ${CYAN}dbmate up${NC}"

    else
        echo -e "${RED}✗ DBmate installation verification failed${NC}"
        echo -e "${YELLOW}Try running: mise exec dbmate -- --version${NC}"
    fi

else
    echo -e "${RED}✗ Failed to install DBmate${NC}"
    exit 1
fi

wait_for_input

#!/bin/bash
# SQLite Database Installation
# Lightweight embedded SQL database engine

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/../..}/install/system/common-funcs.sh"

show_banner "SQLite Database"

echo -e "${BLUE}SQLite - Self-contained SQL Database Engine${NC}"
echo -e "${YELLOW}Installing SQLite database engine and tools${NC}"
echo ""

if ! confirm_action "Install SQLite database tools?"; then
    echo -e "${YELLOW}SQLite installation cancelled.${NC}"
    exit 0
fi

echo -e "${BLUE}Installing SQLite...${NC}"

# Install SQLite
if install_with_retries sqlite; then
    echo -e "${GREEN}✓ SQLite installed successfully!${NC}"

    # Get version
    sqlite_version=$(sqlite3 --version 2>/dev/null | awk '{print $1}' || echo "SQLite installed")

    echo -e "${GREEN}
=========================================================================
                    SQLite Installation Complete!
=========================================================================

Installed version:
  SQLite $sqlite_version

Key commands:
  sqlite3 database.db               # Open/create database file
  sqlite3 database.db \"SQL;\"       # Execute SQL command
  sqlite3 database.db < script.sql  # Execute SQL script
  sqlite3 database.db .dump         # Export database

SQLite CLI commands (within sqlite3):
  .help                            # Show all commands
  .tables                          # List all tables
  .schema table_name               # Show table structure
  .dump                            # Export all data as SQL
  .backup backup.db                # Create backup
  .restore backup.db               # Restore from backup
  .quit                            # Exit SQLite CLI

Basic SQL commands:
  CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT);
  INSERT INTO users (name) VALUES ('John Doe');
  SELECT * FROM users;
  UPDATE users SET name = 'Jane' WHERE id = 1;
  DELETE FROM users WHERE id = 1;
  DROP TABLE users;

SQLite features:
  - No server setup required
  - Database stored in single file
  - ACID compliant transactions
  - Cross-platform compatibility
  - Zero configuration
  - Supports most SQL features

File operations:
  - Database files usually have .db or .sqlite extension
  - Portable between different systems
  - Can be copied like regular files
  - No special permissions needed

Use cases:
  - Application databases
  - Development and testing
  - Data analysis and reporting
  - Configuration storage
  - Cache databases

Programming language support:
  - Python: Built-in sqlite3 module
  - Node.js: sqlite3 npm package
  - Go: database/sql with sqlite3 driver
  - PHP: PDO SQLite extension
  - Java: SQLite JDBC driver

Performance tips:
  - Use transactions for bulk inserts
  - Create indexes for frequently queried columns
  - Use PRAGMA statements for optimization
  - Consider WAL mode for concurrent access

Documentation: https://sqlite.org/docs.html
${NC}"

    # Offer to create a sample database
    echo ""
    if confirm_action "Create a sample database for testing?"; then
        echo -e "${BLUE}Creating sample database 'test.db'...${NC}"

        # Create sample database with table and data
        sqlite3 test.db <<EOF
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO users (name, email) VALUES
    ('John Doe', 'john@example.com'),
    ('Jane Smith', 'jane@example.com'),
    ('Bob Johnson', 'bob@example.com');

CREATE TABLE posts (
    id INTEGER PRIMARY KEY,
    user_id INTEGER,
    title TEXT NOT NULL,
    content TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users (id)
);

INSERT INTO posts (user_id, title, content) VALUES
    (1, 'Hello World', 'This is my first post!'),
    (2, 'SQLite Rocks', 'I love how simple SQLite is to use.'),
    (1, 'Another Post', 'Just testing the database.');
EOF

        echo -e "${GREEN}✓ Sample database 'test.db' created${NC}"
        echo -e "${CYAN}Explore with:${NC}"
        echo -e "  sqlite3 test.db"
        echo -e "  .tables"
        echo -e "  SELECT * FROM users;"
        echo -e "  SELECT u.name, p.title FROM users u JOIN posts p ON u.id = p.user_id;"

        # Show database info
        echo ""
        echo -e "${BLUE}Sample database contents:${NC}"
        echo -e "${CYAN}Tables created:${NC}"
        sqlite3 test.db ".tables"
        echo ""
        echo -e "${CYAN}Sample data:${NC}"
        sqlite3 test.db "SELECT COUNT(*) as users FROM users; SELECT COUNT(*) as posts FROM posts;"
    fi

    # Show common SQLite tools that could be installed
    echo ""
    echo -e "${BLUE}Additional SQLite tools you might want:${NC}"
    echo -e "  sqlitebrowser                    # GUI SQLite database browser"
    echo -e "  sqlite3-tools                    # Additional SQLite utilities"
    echo -e "  sqliteodbc                       # ODBC driver for SQLite"
    echo ""
    echo -e "${CYAN}Install with: pacman -S sqlitebrowser sqlite3-tools${NC}"

else
    echo -e "${RED}✗ Failed to install SQLite${NC}"
    exit 1
fi

wait_for_input

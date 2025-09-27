#!/bin/bash
# MongoDB NoSQL Database Installation
# Document-oriented database system

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/../..}/install/system/common-funcs.sh"

show_banner "MongoDB NoSQL Database"

echo -e "${BLUE}MongoDB - Document-oriented NoSQL Database${NC}"
echo -e "${YELLOW}Installing MongoDB database server and tools${NC}"
echo ""

if ! archer_confirm_or_default "Install MongoDB database server?"; then
  echo -e "${YELLOW}MongoDB installation cancelled.${NC}"
  exit 0
fi

echo -e "${BLUE}Installing MongoDB...${NC}"

# Install MongoDB from AUR (since it's not in official Arch repos anymore)
if command -v yay &> /dev/null; then
    aur_helper="yay"
elif command -v paru &> /dev/null; then
    aur_helper="paru"
else
    echo -e "${YELLOW}AUR helper (yay or paru) not found. Installing yay first...${NC}"
  if ! install_with_retries base-devel git; then
    echo -e "${RED}✗ Failed to install build dependencies${NC}"
    archer_die "Failed to install build dependencies for AUR helper"
  fi

    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    aur_helper="yay"
fi

echo -e "${BLUE}Installing MongoDB from AUR using $aur_helper...${NC}"
if $aur_helper -S --noconfirm mongodb-bin mongodb-tools-bin; then
    echo -e "${GREEN}✓ MongoDB installed successfully!${NC}"

    # Create MongoDB user and directories
    echo -e "${BLUE}Setting up MongoDB...${NC}"
    sudo useradd -r -s /bin/false mongodb 2>/dev/null || true
    sudo mkdir -p /var/lib/mongodb
    sudo mkdir -p /var/log/mongodb
    sudo chown mongodb:mongodb /var/lib/mongodb
    sudo chown mongodb:mongodb /var/log/mongodb

    # Enable and start MongoDB service
    echo -e "${BLUE}Enabling MongoDB service...${NC}"
    sudo systemctl enable mongodb
    sudo systemctl start mongodb

    # Check if service is running
    if systemctl is-active --quiet mongodb; then
        echo -e "${GREEN}✓ MongoDB service is running${NC}"

        # Get version
        mongo_version=$(mongod --version 2>/dev/null | grep "db version" | head -1 || echo "MongoDB installed")

        echo -e "${GREEN}
=========================================================================
                    MongoDB Installation Complete!
=========================================================================

Installed version:
  $mongo_version

Service status:
  ✓ MongoDB service enabled and running

Key commands:
  mongosh                          # MongoDB Shell (new)
  mongo                            # MongoDB Shell (legacy)
  mongodump                        # Create database backup
  mongorestore                     # Restore database backup
  mongostat                        # Monitor MongoDB statistics
  mongotop                         # Monitor collection activity

Database location:
  /var/lib/mongodb/

Log files:
  /var/log/mongodb/mongod.log

Configuration:
  /etc/mongod.conf

Default setup:
  - Port: 27017
  - Bind: 127.0.0.1 (localhost only)
  - No authentication by default
  - Database path: /var/lib/mongodb

Basic MongoDB commands (in mongosh):
  show dbs                         # List databases
  use database_name                # Switch to database
  show collections                 # List collections
  db.collection.find()             # Query documents
  db.collection.insertOne({})      # Insert document
  db.collection.updateOne({}, {})  # Update document
  db.collection.deleteOne({})      # Delete document

Document operations:
  db.users.insertOne({name: \"John\", age: 30})
  db.users.find({name: \"John\"})
  db.users.updateOne({name: \"John\"}, {\$set: {age: 31}})
  db.users.deleteOne({name: \"John\"})

Administration:
  db.stats()                       # Database statistics
  db.serverStatus()                # Server status
  db.adminCommand('listCollections') # List collections
  use admin; db.shutdownServer()   # Shutdown server

Security notes:
  - MongoDB runs without authentication by default
  - Consider enabling authentication for production
  - Configure proper firewall rules if exposing externally

Performance monitoring:
  mongostat                        # Real-time statistics
  mongotop                         # Collection-level statistics
  db.currentOp()                   # Current operations

Documentation: https://docs.mongodb.com/
${NC}"

        # Test MongoDB connection
        echo ""
        echo -e "${BLUE}Testing MongoDB connection...${NC}"
        if mongosh --eval "print('MongoDB connection successful')" --quiet > /dev/null 2>&1; then
            echo -e "${GREEN}✓ MongoDB is accepting connections${NC}"

            # Offer to create sample data
            if archer_confirm_or_default "Create sample database and collection for testing?"; then
                echo -e "${BLUE}Creating sample data...${NC}"
                mongosh --eval "
                    use testdb;
                    db.users.insertMany([
                        {name: 'John Doe', email: 'john@example.com', age: 30},
                        {name: 'Jane Smith', email: 'jane@example.com', age: 25},
                        {name: 'Bob Johnson', email: 'bob@example.com', age: 35}
                    ]);
                    db.posts.insertMany([
                        {title: 'Hello MongoDB', content: 'This is my first post', author: 'John Doe'},
                        {title: 'NoSQL is Great', content: 'Document databases are flexible', author: 'Jane Smith'}
                    ]);
                    print('Sample data created successfully');
                " --quiet
                echo -e "${GREEN}✓ Sample data created in 'testdb' database${NC}"
                echo -e "${CYAN}Explore with:${NC}"
                echo -e "  mongosh"
                echo -e "  use testdb"
                echo -e "  db.users.find()"
                echo -e "  db.posts.find()"
            fi
        else
            echo -e "${RED}✗ MongoDB connection test failed${NC}"
            echo -e "${YELLOW}You can try connecting manually with: mongosh${NC}"
        fi

    else
        echo -e "${RED}✗ MongoDB service failed to start${NC}"
        echo -e "${YELLOW}Check logs: sudo journalctl -u mongodb${NC}"
        echo -e "${YELLOW}Try starting manually: sudo systemctl start mongodb${NC}"
    fi

  else
  echo -e "${RED}✗ Failed to install MongoDB${NC}"
  echo -e "${YELLOW}You may need to install it manually from the AUR${NC}"
  archer_die "Failed to install MongoDB via AUR helper"
fi

wait_for_input

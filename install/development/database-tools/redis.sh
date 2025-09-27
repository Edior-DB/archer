#!/bin/bash
# Redis In-Memory Database Installation
# High-performance key-value store and caching system

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/../..}/install/system/common-funcs.sh"

show_banner "Redis In-Memory Database"

echo -e "${BLUE}Redis - Advanced Key-Value Store and Cache${NC}"
echo -e "${YELLOW}Installing Redis server and client tools${NC}"
echo ""

if ! archer_confirm_or_default "Install Redis database server?"; then
  echo -e "${YELLOW}Redis installation cancelled.${NC}"
  exit 0
fi

echo -e "${BLUE}Installing Redis...${NC}"

# Install Redis server
if install_with_retries redis; then
    echo -e "${GREEN}✓ Redis installed successfully!${NC}"

    # Enable and start Redis service
    echo -e "${BLUE}Enabling Redis service...${NC}"
    sudo systemctl enable redis
    sudo systemctl start redis

    # Check if service is running
    if systemctl is-active --quiet redis; then
        echo -e "${GREEN}✓ Redis service is running${NC}"

        # Get version
        redis_version=$(redis-server --version 2>/dev/null | head -1 || echo "Redis installed")

        echo -e "${GREEN}
=========================================================================
                    Redis Installation Complete!
=========================================================================

Installed version:
  $redis_version

Service status:
  ✓ Redis service enabled and running

Key commands:
  redis-cli                         # Connect to Redis CLI
  redis-cli ping                    # Test connection (should return PONG)
  redis-cli info                    # Show server information
  sudo systemctl status redis       # Check service status
  sudo systemctl stop redis         # Stop service
  sudo systemctl start redis        # Start service

Database files location:
  /var/lib/redis/

Configuration files:
  /etc/redis/redis.conf             # Main Redis configuration

Default setup:
  - Port: 6379
  - Bind: 127.0.0.1 (localhost only)
  - No authentication by default
  - Maximum memory: Not limited

Basic Redis commands:
  SET key value                     # Store key-value pair
  GET key                          # Retrieve value by key
  DEL key                          # Delete key
  EXISTS key                       # Check if key exists
  KEYS *                           # List all keys (use carefully!)
  FLUSHALL                         # Clear all data (careful!)
  INFO                             # Server information
  CLIENT LIST                      # Show connected clients

Data types:
  - Strings: Simple key-value pairs
  - Lists: Ordered collections
  - Sets: Unordered unique collections
  - Hashes: Field-value pairs
  - Sorted Sets: Ordered sets with scores

Security notes:
  - Redis runs on localhost by default (secure)
  - Consider setting up authentication for production
  - Configure proper firewall rules if exposing externally

Performance monitoring:
  redis-cli monitor                # Watch all commands in real-time
  redis-cli --latency             # Monitor latency
  redis-cli --stat                # Show statistics

Documentation: https://redis.io/documentation
${NC}"

        # Test Redis connection
        echo ""
        echo -e "${BLUE}Testing Redis connection...${NC}"
        if redis-cli ping > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Redis is responding to connections${NC}"

            # Offer to set some sample data
            if archer_confirm_or_default "Set some sample data for testing?"; then
                echo -e "${BLUE}Setting sample data...${NC}"
                redis-cli set "test:message" "Hello Redis!"
                redis-cli set "test:counter" "1"
                redis-cli lpush "test:list" "item1" "item2" "item3"
                echo -e "${GREEN}✓ Sample data created${NC}"
                echo -e "${CYAN}Test with:${NC}"
                echo -e "  redis-cli get test:message"
                echo -e "  redis-cli get test:counter"
                echo -e "  redis-cli lrange test:list 0 -1"
            fi
        else
            echo -e "${RED}✗ Redis connection test failed${NC}"
            echo -e "${YELLOW}You can try connecting manually with: redis-cli${NC}"
        fi

    else
        echo -e "${RED}✗ Redis service failed to start${NC}"
        echo -e "${YELLOW}You can try starting it manually with: sudo systemctl start redis${NC}"
    fi

else
  echo -e "${RED}✗ Failed to install Redis${NC}"
  archer_die "Failed to install Redis"
fi

wait_for_input

#!/bin/bash
# PHP Programming Language Installation
# Server-side scripting language for web development

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/../..}/install/system/common-funcs.sh"

show_banner "PHP Programming Language"

echo -e "${BLUE}PHP - Popular web development language${NC}"
echo -e "${YELLOW}Installing via Mise for better version management${NC}"
echo ""

if ! confirm_action "Install PHP via Mise?"; then
    echo -e "${YELLOW}PHP installation cancelled.${NC}"
    exit 0
fi

# Check if Mise is installed
if ! command -v mise &> /dev/null; then
    echo -e "${YELLOW}Mise not found. Installing Mise first...${NC}"
    if ! install_with_retries mise; then
        echo -e "${YELLOW}Installing Mise via curl...${NC}"
        curl https://mise.run | sh
        echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc
        eval "$(~/.local/bin/mise activate bash)"
    fi
fi

# Initialize mise for current session
eval "$(mise activate bash)" 2>/dev/null || true

echo -e "${BLUE}Installing PHP dependencies first...${NC}"
# Install PHP dependencies that might be needed
if ! install_with_retries gd; then
    echo -e "${YELLOW}Warning: Could not install some PHP dependencies${NC}"
fi

if ! install_with_retries gd; then
    echo -e "${YELLOW}Warning: Could not install some PHP dependencies${NC}"
fi

echo -e "${BLUE}Installing PHP via Mise...${NC}"

if mise install php@latest; then
    echo -e "${GREEN}✓ PHP installed successfully!${NC}"

    # Set as global default
    mise use -g php@latest

    # Show version and information
    php_version=$(php --version 2>/dev/null | head -1 || echo "Not available")
    composer_status="Not installed"

    # Check if Composer is available
    if command -v composer &>/dev/null; then
        composer_status=$(composer --version 2>/dev/null | head -1 || echo "Available")
    fi

    echo -e "${GREEN}
=========================================================================
                        PHP Installation Complete!
=========================================================================

Installed version:
  $php_version
  Composer: $composer_status

Key commands:
  php -v                  # Check PHP version
  php -m                  # List installed modules
  php -S localhost:8000   # Start built-in development server
  php script.php          # Run PHP script
  php -i                  # Show PHP info (like phpinfo())

Common PHP files:
  index.php               # Main entry point
  composer.json           # Dependency management
  .php                    # PHP script files

Hello World example:
  echo '<?php echo \"Hello, PHP World!\\n\"; ?>' > hello.php
  php hello.php

Web server example:
  mkdir my-php-app && cd my-php-app
  echo '<?php echo \"<h1>Hello from PHP!</h1>\"; ?>' > index.php
  php -S localhost:8000
  # Visit http://localhost:8000

Composer (PHP package manager):
  curl -sS https://getcomposer.org/installer | php
  sudo mv composer.phar /usr/local/bin/composer
  composer init                    # Initialize new project
  composer require package/name    # Install package
  composer install                 # Install dependencies
  composer update                  # Update dependencies

Popular frameworks:
  - Laravel: Modern, elegant PHP framework
  - Symfony: Component-based framework
  - CodeIgniter: Lightweight framework
  - CakePHP: Convention over configuration

Useful extensions (install via system package manager):
  - php-mysql / php-pgsql (database)
  - php-curl (HTTP requests)
  - php-json (JSON handling)
  - php-xml (XML processing)
  - php-gd (image manipulation)

PHP configuration:
  - Use 'mise use php@8.3.0' for specific versions
  - Configuration files managed by system package manager
  - Use .tool-versions file for project-specific versions

Documentation: https://php.net/
Package repository: https://packagist.org/
${NC}"

    # Suggest Composer installation
    if ! command -v composer &>/dev/null; then
        echo ""
        if confirm_action "Install Composer (PHP package manager)?"; then
            echo -e "${BLUE}Installing Composer...${NC}"
            cd /tmp
            curl -sS https://getcomposer.org/installer | php
            sudo mv composer.phar /usr/local/bin/composer
            composer --version
            echo -e "${GREEN}✓ Composer installed successfully!${NC}"
        fi
    fi

else
    echo -e "${RED}✗ Failed to install PHP via Mise${NC}"
    echo -e "${YELLOW}You can try installing PHP manually:${NC}"
    echo -e "${CYAN}  sudo pacman -S php php-apache${NC}"
    exit 1
fi

wait_for_input

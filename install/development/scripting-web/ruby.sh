#!/bin/bash
# Ruby Programming Language Installation
# Dynamic, open source programming language with focus on simplicity

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/../..}/install/system/common-funcs.sh"

show_banner "Ruby Programming Language"

echo -e "${BLUE}Ruby - A programmer's best friend${NC}"
echo -e "${YELLOW}Installing via Mise for better version management${NC}"
echo ""

if ! archer_confirm_or_default "Install Ruby via Mise?"; then
  echo -e "${YELLOW}Ruby installation cancelled.${NC}"
  return 0
fi

# Setup Mise and install Ruby
setup_mise || {
    echo -e "${RED}Failed to setup Mise. Trying system package manager...${NC}"
  if install_with_retries ruby; then
    echo -e "${GREEN}✓ Ruby installed via system package manager!${NC}"
    exit 0
  else
    echo -e "${RED}✗ Failed to install Ruby${NC}"
    archer_die "Failed to install Ruby via system package manager"
  fi
}

echo -e "${BLUE}Installing Ruby via Mise...${NC}"

if install_mise_tool ruby latest; then
    # Verify installation
    if verify_mise_tool ruby ruby; then
        echo -e "${GREEN}✓ Ruby is ready to use!${NC}"
    else
        echo -e "${YELLOW}⚠ Ruby installed but requires shell restart${NC}"
    fi

    # Show versions
    ruby_version=$(ruby --version 2>/dev/null || echo "Run 'source ~/.bashrc' to activate")
    gem_version=$(gem --version 2>/dev/null || echo "Run 'source ~/.bashrc' to activate")

    echo -e "${GREEN}
=========================================================================
                        Ruby Installation Complete!
=========================================================================

Installed versions:
  Ruby: $ruby_version
  RubyGems: $gem_version

Key commands:
  ruby --version           # Check Ruby version
  gem --version           # Check RubyGems version
  ruby script.rb          # Run Ruby script
  gem install <gem>       # Install Ruby gem
  gem list                # List installed gems
  bundle init             # Initialize new Ruby project
  bundle install          # Install project dependencies

Popular gems to try:
  gem install rails       # Ruby on Rails web framework
  gem install sinatra     # Lightweight web framework
  gem install rspec       # Testing framework
  gem install jekyll      # Static site generator

Project setup:
  bundle init             # Create Gemfile
  echo 'gem \"sinatra\"' >> Gemfile
  bundle install          # Install dependencies

Next steps:
- Restart your terminal or run 'source ~/.bashrc'
- Try 'ruby -e \"puts 'Hello, Ruby!'\"'
- Use 'mise use ruby@3.2' in project directories for specific versions
- Explore gems at rubygems.org

Version management with Mise:
  mise install ruby@3.2    # Install specific version
  mise use ruby@3.2        # Use version in current project
  mise ls ruby             # List available versions

Documentation: https://www.ruby-lang.org/
${NC}"

else
    echo -e "${RED}✗ Failed to install Ruby via Mise${NC}"
    echo -e "${YELLOW}Trying fallback installation via pacman...${NC}"
    if install_with_retries ruby; then
        echo -e "${GREEN}✓ Ruby installed via pacman${NC}"
    else
    echo -e "${RED}✗ Failed to install Ruby${NC}"
    archer_die "Failed to install Ruby via all methods"
  fi
fi

wait_for_input

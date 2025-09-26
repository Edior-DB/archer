#!/bin/bash
# Docker & Docker Compose Installation
# Containerization platform for development and deployment

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/../..}/install/system/common-funcs.sh"

show_banner "Docker & Docker Compose"

echo -e "${BLUE}Docker - Build, ship, and run applications in containers${NC}"
echo -e "${YELLOW}Installing Docker Engine and Docker Compose${NC}"
echo ""

if ! archer_confirm_or_default "Install Docker and Docker Compose?"; then
    echo -e "${YELLOW}Docker installation cancelled.${NC}"
    exit 0
fi

echo -e "${BLUE}Installing Docker and Docker Compose...${NC}"

# Install Docker and Docker Compose
container_packages=("docker" "docker-compose")

if install_with_retries "${container_packages[@]}"; then
    echo -e "${GREEN}✓ Docker packages installed successfully!${NC}"

    # Enable and start Docker service
    echo -e "${CYAN}Configuring Docker service...${NC}"
    sudo systemctl enable docker
    sudo systemctl start docker

    # Add user to docker group
    echo -e "${CYAN}Adding user to docker group...${NC}"
    sudo usermod -aG docker $USER

    # Show versions
    docker_version=$(docker --version 2>/dev/null || echo "Not available")
    compose_version=$(docker-compose --version 2>/dev/null || echo "Not available")

    echo -e "${GREEN}
=========================================================================
                        Docker Installation Complete!
=========================================================================

Installed versions:
  $docker_version
  $compose_version

Key commands:
  docker --version         # Check Docker version
  docker run hello-world   # Test Docker installation
  docker ps               # List running containers
  docker images           # List Docker images
  docker pull <image>     # Download Docker image
  docker build -t name .  # Build image from Dockerfile

Docker Compose commands:
  docker-compose up       # Start services defined in docker-compose.yml
  docker-compose down     # Stop and remove containers
  docker-compose build    # Build services
  docker-compose logs     # View service logs

Quick start:
  1. Create a Dockerfile:
     echo 'FROM nginx' > Dockerfile

  2. Build and run:
     docker build -t my-nginx .
     docker run -p 8080:80 my-nginx

  3. Visit http://localhost:8080

Important notes:
- Docker service is now enabled and started
- You've been added to the 'docker' group
- ${YELLOW}You may need to log out and back in for group permissions to take effect${NC}
- ${YELLOW}Or run 'newgrp docker' to apply group changes immediately${NC}

Next steps:
- Test: 'docker run hello-world'
- Try Docker tutorial: 'docker run -it ubuntu bash'
- Explore Docker Hub: https://hub.docker.com/

Documentation: https://docs.docker.com/
${NC}"

else
    echo -e "${RED}✗ Failed to install Docker${NC}"
    exit 1
fi

wait_for_input

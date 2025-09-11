#!/bin/bash
# Podman Container Engine Installation Script
# Installs Podman as a Docker alternative

# ==============================================================================
# CONFIGURATION
# ==============================================================================
TOOL_NAME="Podman Container Engine"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
ARCHER_DIR="${ARCHER_DIR:-$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")}"

# Source common functions
source "$ARCHER_DIR/install/system/common-funcs.sh"

# ==============================================================================
# INSTALLATION FUNCTIONS
# ==============================================================================

install_podman() {
    log_info "Installing Podman container engine..."

    # Install Podman and related tools
    local packages=(
        "podman"           # Main Podman package
        "buildah"          # Container image builder
        "skopeo"           # Container image inspector
        "podman-compose"   # Docker Compose compatibility
        "crun"             # OCI runtime
        "slirp4netns"      # User-mode networking
        "fuse-overlayfs"   # Overlay filesystem
    )

    for package in "${packages[@]}"; do
        if ! pacman -Qi "$package" &>/dev/null; then
            execute_with_progress "sudo pacman -S --noconfirm $package" "Installing $package..."
        fi
    done

    # Verify installation
    if command -v podman &>/dev/null; then
        local version=$(podman --version)
        log_success "Podman installed: $version"
    else
        log_error "Failed to install Podman"
        return 1
    fi
}

configure_podman() {
    log_info "Configuring Podman for rootless operation..."

    # Enable user namespaces if not already enabled
    if [[ ! -f /proc/sys/user/max_user_namespaces ]] || [[ "$(cat /proc/sys/user/max_user_namespaces)" -eq 0 ]]; then
        echo 'user.max_user_namespaces=65536' | sudo tee -a /etc/sysctl.conf
        sudo sysctl -p
        log_info "Enabled user namespaces"
    fi

    # Configure subuid and subgid for current user
    local username=$(whoami)
    if ! grep -q "^$username:" /etc/subuid; then
        echo "$username:100000:65536" | sudo tee -a /etc/subuid
        log_info "Added subuid entry for user $username"
    fi

    if ! grep -q "^$username:" /etc/subgid; then
        echo "$username:100000:65536" | sudo tee -a /etc/subgid
        log_info "Added subgid entry for user $username"
    fi

    # Create Podman configuration directory
    mkdir -p "$HOME/.config/containers"

    # Create registries configuration
    if [[ ! -f "$HOME/.config/containers/registries.conf" ]]; then
        cat > "$HOME/.config/containers/registries.conf" << 'EOF'
[registries.search]
registries = ['docker.io', 'quay.io']

[registries.insecure]
registries = []

[registries.block]
registries = []
EOF
        log_info "Created registries configuration"
    fi

    # Create storage configuration
    if [[ ! -f "$HOME/.config/containers/storage.conf" ]]; then
        cat > "$HOME/.config/containers/storage.conf" << 'EOF'
[storage]
driver = "overlay"
runroot = "/run/user/1000/containers"
graphroot = "$HOME/.local/share/containers/storage"

[storage.options]
additionalimagestores = []

[storage.options.overlay]
mountopt = "nodev,metacopy=on"
EOF
        log_info "Created storage configuration"
    fi
}

setup_podman_compose() {
    log_info "Setting up Podman Compose compatibility..."

    # Create docker alias for podman
    local bashrc="$HOME/.bashrc"
    if [[ -f "$bashrc" ]] && ! grep -q "# Podman aliases" "$bashrc"; then
        cat >> "$bashrc" << 'EOF'

# Podman aliases
alias docker='podman'
alias docker-compose='podman-compose'

# Podman shortcuts
alias pc='podman'
alias pcp='podman-compose'
alias pps='podman ps'
alias pimg='podman images'
alias prm='podman rm'
alias prmi='podman rmi'
EOF
        log_info "Added Podman aliases to ~/.bashrc"
    fi

    # Create example docker-compose.yml
    local examples_dir="$HOME/podman-examples"
    mkdir -p "$examples_dir/webapp"

    cat > "$examples_dir/webapp/docker-compose.yml" << 'EOF'
version: '3.8'

services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ./html:/usr/share/nginx/html:ro
    restart: unless-stopped

  redis:
    image: redis:alpine
    ports:
      - "6379:6379"
    restart: unless-stopped

volumes:
  html_data:
EOF

    # Create example HTML file
    mkdir -p "$examples_dir/webapp/html"
    cat > "$examples_dir/webapp/html/index.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Podman Web App</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 600px; margin: 0 auto; }
        .success { color: green; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Welcome to Podman!</h1>
        <p class="success">Your Podman setup is working correctly!</p>
        <p>This web application is running in containers managed by Podman.</p>
        <ul>
            <li>Web server: Nginx</li>
            <li>Database: Redis</li>
        </ul>
    </div>
</body>
</html>
EOF

    log_info "Created example webapp: $examples_dir/webapp"
}

create_podman_examples() {
    log_info "Creating Podman usage examples..."

    local examples_dir="$HOME/podman-examples"
    mkdir -p "$examples_dir"

    # Create basic commands script
    cat > "$examples_dir/basic-commands.sh" << 'EOF'
#!/bin/bash
# Basic Podman Commands Examples

echo "=== Podman Basic Commands ==="

echo "1. Pull an image:"
echo "   podman pull nginx:alpine"

echo "2. Run a container:"
echo "   podman run -d --name webserver -p 8080:80 nginx:alpine"

echo "3. List running containers:"
echo "   podman ps"

echo "4. List all containers:"
echo "   podman ps -a"

echo "5. Stop a container:"
echo "   podman stop webserver"

echo "6. Remove a container:"
echo "   podman rm webserver"

echo "7. List images:"
echo "   podman images"

echo "8. Remove an image:"
echo "   podman rmi nginx:alpine"

echo "9. Build an image from Dockerfile:"
echo "   podman build -t myapp ."

echo "10. Create and start with compose:"
echo "    podman-compose up -d"

echo "=== Advanced Usage ==="

echo "• Run interactive shell:"
echo "  podman run -it --rm alpine sh"

echo "• Mount volume:"
echo "  podman run -v /host/path:/container/path image"

echo "• Set environment variables:"
echo "  podman run -e VAR=value image"

echo "• View container logs:"
echo "  podman logs container_name"

echo "• Execute command in running container:"
echo "  podman exec -it container_name bash"
EOF

    chmod +x "$examples_dir/basic-commands.sh"

    # Create Dockerfile example
    cat > "$examples_dir/Dockerfile.example" << 'EOF'
# Example Dockerfile for a simple Python web app
FROM python:3.11-alpine

# Set working directory
WORKDIR /app

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Expose port
EXPOSE 5000

# Run the application
CMD ["python", "app.py"]
EOF

    # Create example Python app
    cat > "$examples_dir/app.py" << 'EOF'
#!/usr/bin/env python3
from flask import Flask

app = Flask(__name__)

@app.route('/')
def hello():
    return '''
    <h1>Hello from Podman!</h1>
    <p>This Python Flask app is running in a container.</p>
    '''

@app.route('/health')
def health():
    return {'status': 'healthy'}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
EOF

    cat > "$examples_dir/requirements.txt" << 'EOF'
Flask==2.3.3
EOF

    log_info "Created Podman examples in $examples_dir"
}

print_podman_info() {
    echo ""
    echo "=============================================="
    echo "Podman Container Engine Ready!"
    echo "=============================================="
    echo ""
    echo "Installed components:"
    if command -v podman &>/dev/null; then
        echo "  • Podman: $(podman --version | cut -d' ' -f3)"
    fi
    if command -v buildah &>/dev/null; then
        echo "  • Buildah: $(buildah --version | cut -d' ' -f3)"
    fi
    if command -v skopeo &>/dev/null; then
        echo "  • Skopeo: $(skopeo --version | cut -d' ' -f3)"
    fi
    echo ""
    echo "Key advantages over Docker:"
    echo "  • Rootless containers (more secure)"
    echo "  • No daemon required"
    echo "  • OCI-compliant"
    echo "  • Docker CLI compatibility"
    echo ""
    echo "Quick start:"
    echo "  podman run hello-world      # Test installation"
    echo "  podman pull nginx:alpine    # Pull an image"
    echo "  podman run -d -p 8080:80 nginx:alpine  # Run web server"
    echo "  podman ps                   # List containers"
    echo ""
    echo "Docker compatibility:"
    echo "  alias docker='podman'       # Use podman as docker"
    echo "  podman-compose up           # Use compose files"
    echo ""
    echo "Examples:"
    echo "  ~/podman-examples/basic-commands.sh"
    echo "  ~/podman-examples/webapp/ (compose example)"
    echo ""
    echo "Configuration: ~/.config/containers/"
    echo ""
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

main() {
    log_info "Starting $TOOL_NAME installation..."

    # Check system requirements
    check_system_requirements

    # Install Podman
    install_podman || return 1

    # Configure Podman
    configure_podman

    # Setup compose compatibility
    setup_podman_compose

    # Create examples
    create_podman_examples

    # Show information
    print_podman_info

    log_success "$TOOL_NAME installation completed!"
}

# Execute main function
main "$@"

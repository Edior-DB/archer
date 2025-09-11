#!/bin/bash
# Kubernetes CLI Tools Installation Script
# Installs kubectl, k9s, helm, and other Kubernetes tools

# ==============================================================================
# CONFIGURATION
# ==============================================================================
TOOL_NAME="Kubernetes CLI Tools"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
ARCHER_DIR="${ARCHER_DIR:-$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")}"

# Source common functions
source "$ARCHER_DIR/install/system/common-funcs.sh"

# ==============================================================================
# INSTALLATION FUNCTIONS
# ==============================================================================

install_kubectl() {
    log_info "Installing kubectl (Kubernetes CLI)..."

    # Install kubectl from official repository
    if ! pacman -Qi kubectl &>/dev/null; then
        execute_with_progress "sudo pacman -S --noconfirm kubectl" "Installing kubectl..."
    else
        log_info "kubectl already installed"
    fi

    # Verify installation
    if command -v kubectl &>/dev/null; then
        local version=$(kubectl version --client --short 2>/dev/null | cut -d' ' -f3 || echo "installed")
        log_success "kubectl installed: $version"
    else
        log_error "Failed to install kubectl"
        return 1
    fi
}

install_k9s() {
    log_info "Installing k9s (Kubernetes TUI)..."

    if command -v yay &>/dev/null; then
        execute_with_progress "yay -S --noconfirm k9s" "Installing k9s from AUR..."
    else
        log_warning "k9s requires AUR helper. Installing manually..."

        # Install k9s manually from GitHub releases
        local temp_dir="/tmp/k9s_install"
        mkdir -p "$temp_dir"
        cd "$temp_dir"

        local k9s_version="v0.28.2"
        local k9s_url="https://github.com/derailed/k9s/releases/download/${k9s_version}/k9s_Linux_amd64.tar.gz"

        execute_with_progress "curl -L -o k9s.tar.gz '$k9s_url'" "Downloading k9s..."
        tar -xzf k9s.tar.gz
        sudo mv k9s /usr/local/bin/

        cd "$HOME"
        rm -rf "$temp_dir"
    fi

    # Verify installation
    if command -v k9s &>/dev/null; then
        local version=$(k9s version --short 2>/dev/null | head -n 1 || echo "installed")
        log_success "k9s installed: $version"
    else
        log_warning "k9s installation may have failed"
    fi
}

install_helm() {
    log_info "Installing Helm (Kubernetes package manager)..."

    if command -v yay &>/dev/null; then
        execute_with_progress "yay -S --noconfirm helm" "Installing Helm from AUR..."
    else
        log_info "Installing Helm manually..."

        # Install Helm from official script
        local temp_dir="/tmp/helm_install"
        mkdir -p "$temp_dir"
        cd "$temp_dir"

        execute_with_progress "curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3" "Downloading Helm installer..."
        chmod +x get_helm.sh
        ./get_helm.sh

        cd "$HOME"
        rm -rf "$temp_dir"
    fi

    # Verify installation
    if command -v helm &>/dev/null; then
        local version=$(helm version --short 2>/dev/null || echo "installed")
        log_success "Helm installed: $version"
    else
        log_warning "Helm installation may have failed"
    fi
}

install_additional_tools() {
    log_info "Installing additional Kubernetes tools..."

    # Install kubectx and kubens if available
    if command -v yay &>/dev/null; then
        execute_with_progress "yay -S --noconfirm kubectx" "Installing kubectx/kubens..."
    fi

    # Install kustomize
    if ! command -v kustomize &>/dev/null; then
        log_info "Installing kustomize..."
        local temp_dir="/tmp/kustomize_install"
        mkdir -p "$temp_dir"
        cd "$temp_dir"

        execute_with_progress "curl -s 'https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh' | bash" "Installing kustomize..."
        sudo mv kustomize /usr/local/bin/

        cd "$HOME"
        rm -rf "$temp_dir"
    fi
}

setup_kubectl_config() {
    log_info "Setting up kubectl configuration..."

    # Create .kube directory
    mkdir -p "$HOME/.kube"

    # Create kubectl completion and aliases
    local bashrc="$HOME/.bashrc"
    if [[ -f "$bashrc" ]] && ! grep -q "# Kubernetes aliases" "$bashrc"; then
        cat >> "$bashrc" << 'EOF'

# Kubernetes aliases
alias k='kubectl'
alias kg='kubectl get'
alias kd='kubectl describe'
alias kl='kubectl logs'
alias ka='kubectl apply'
alias kdel='kubectl delete'

# Kubectl completion
if command -v kubectl &>/dev/null; then
    source <(kubectl completion bash)
    complete -F __start_kubectl k
fi

# Helm completion
if command -v helm &>/dev/null; then
    source <(helm completion bash)
fi
EOF
        log_info "Added Kubernetes aliases and completion to ~/.bashrc"
    fi

    # Create k9s configuration directory
    mkdir -p "$HOME/.config/k9s"

    # Create example kubeconfig
    if [[ ! -f "$HOME/.kube/config" ]]; then
        cat > "$HOME/.kube/example-config" << 'EOF'
# Example kubeconfig file
# Copy this to ~/.kube/config and modify for your cluster

apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: <base64-encoded-ca-cert>
    server: https://kubernetes.example.com:6443
  name: example-cluster

contexts:
- context:
    cluster: example-cluster
    user: example-user
  name: example-context

current-context: example-context

users:
- name: example-user
  user:
    token: <your-token>
    # OR use certificate-based auth:
    # client-certificate-data: <base64-encoded-client-cert>
    # client-key-data: <base64-encoded-client-key>
EOF
        log_info "Created example kubeconfig: ~/.kube/example-config"
    fi
}

create_kubernetes_examples() {
    log_info "Creating Kubernetes examples..."

    local examples_dir="$HOME/kubernetes-examples"
    mkdir -p "$examples_dir"

    # Create basic commands reference
    cat > "$examples_dir/basic-commands.sh" << 'EOF'
#!/bin/bash
# Basic Kubernetes Commands Reference

echo "=== Cluster Information ==="
echo "kubectl cluster-info               # Show cluster info"
echo "kubectl get nodes                  # List cluster nodes"
echo "kubectl get namespaces             # List namespaces"

echo ""
echo "=== Pod Management ==="
echo "kubectl get pods                   # List pods"
echo "kubectl get pods -A                # List pods in all namespaces"
echo "kubectl describe pod <pod-name>    # Describe a pod"
echo "kubectl logs <pod-name>            # View pod logs"
echo "kubectl exec -it <pod-name> -- bash # Execute shell in pod"

echo ""
echo "=== Deployments ==="
echo "kubectl get deployments            # List deployments"
echo "kubectl create deployment nginx --image=nginx  # Create deployment"
echo "kubectl scale deployment nginx --replicas=3    # Scale deployment"
echo "kubectl rollout status deployment/nginx        # Check rollout status"

echo ""
echo "=== Services ==="
echo "kubectl get services               # List services"
echo "kubectl expose deployment nginx --port=80 --type=ClusterIP  # Expose deployment"

echo ""
echo "=== ConfigMaps and Secrets ==="
echo "kubectl get configmaps             # List config maps"
echo "kubectl get secrets                # List secrets"
echo "kubectl create configmap myconfig --from-file=config.txt"

echo ""
echo "=== Apply/Delete Resources ==="
echo "kubectl apply -f deployment.yaml   # Apply resource from file"
echo "kubectl delete -f deployment.yaml  # Delete resource from file"
echo "kubectl delete pod <pod-name>      # Delete a pod"

echo ""
echo "=== Helm Commands ==="
echo "helm list                          # List installed charts"
echo "helm search repo <chart-name>      # Search for charts"
echo "helm install <release-name> <chart> # Install chart"
echo "helm upgrade <release-name> <chart> # Upgrade release"
echo "helm uninstall <release-name>      # Uninstall release"

echo ""
echo "=== K9s Usage ==="
echo "k9s                                # Start k9s TUI"
echo "# Inside k9s:"
echo "# :pods                            # View pods"
echo "# :deployments                     # View deployments"
echo "# :services                        # View services"
echo "# q                                # Quit"
EOF

    chmod +x "$examples_dir/basic-commands.sh"

    # Create example deployment
    cat > "$examples_dir/nginx-deployment.yaml" << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        ports:
        - containerPort: 80
        resources:
          limits:
            cpu: 500m
            memory: 512Mi
          requests:
            cpu: 250m
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
EOF

    # Create example ConfigMap
    cat > "$examples_dir/configmap.yaml" << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  database_url: "postgresql://localhost:5432/mydb"
  debug: "true"
  max_connections: "100"
---
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  # echo -n 'mypassword' | base64
  database_password: bXlwYXNzd29yZA==
  # echo -n 'secret-key-123' | base64
  api_key: c2VjcmV0LWtleS0xMjM=
EOF

    # Create deployment script
    cat > "$examples_dir/deploy.sh" << 'EOF'
#!/bin/bash
# Deployment script for examples

echo "Deploying Kubernetes examples..."

# Apply all YAML files
kubectl apply -f nginx-deployment.yaml
kubectl apply -f configmap.yaml

echo "Deployment completed!"
echo ""
echo "Check status:"
echo "  kubectl get pods"
echo "  kubectl get services"
echo "  kubectl get configmaps"
echo "  kubectl get secrets"
echo ""
echo "Clean up:"
echo "  kubectl delete -f nginx-deployment.yaml"
echo "  kubectl delete -f configmap.yaml"
EOF

    chmod +x "$examples_dir/deploy.sh"

    log_info "Created Kubernetes examples in $examples_dir"
}

print_kubernetes_info() {
    echo ""
    echo "=============================================="
    echo "Kubernetes CLI Tools Ready!"
    echo "=============================================="
    echo ""
    echo "Installed tools:"
    if command -v kubectl &>/dev/null; then
        echo "  • kubectl: $(kubectl version --client --short 2>/dev/null | cut -d' ' -f3 || echo 'installed')"
    fi
    if command -v k9s &>/dev/null; then
        echo "  • k9s: $(k9s version --short 2>/dev/null | head -n 1 || echo 'installed')"
    fi
    if command -v helm &>/dev/null; then
        echo "  • helm: $(helm version --short 2>/dev/null || echo 'installed')"
    fi
    if command -v kustomize &>/dev/null; then
        echo "  • kustomize: $(kustomize version --short 2>/dev/null || echo 'installed')"
    fi
    echo ""
    echo "Quick start:"
    echo "  kubectl cluster-info           # Test connection"
    echo "  kubectl get nodes              # List cluster nodes"
    echo "  k9s                            # Start visual interface"
    echo "  helm search repo nginx         # Search for charts"
    echo ""
    echo "Configuration:"
    echo "  • kubeconfig: ~/.kube/config"
    echo "  • Example config: ~/.kube/example-config"
    echo "  • k9s config: ~/.config/k9s/"
    echo ""
    echo "Examples:"
    echo "  ~/kubernetes-examples/basic-commands.sh"
    echo "  ~/kubernetes-examples/nginx-deployment.yaml"
    echo "  ~/kubernetes-examples/deploy.sh"
    echo ""
    echo "Useful aliases (restart terminal):"
    echo "  k = kubectl"
    echo "  kg = kubectl get"
    echo "  kd = kubectl describe"
    echo ""
    echo "Next steps:"
    echo "  1. Configure ~/.kube/config for your cluster"
    echo "  2. Add Helm repositories: helm repo add stable https://charts.helm.sh/stable"
    echo "  3. Try k9s for visual cluster management"
    echo ""
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

main() {
    log_info "Starting $TOOL_NAME installation..."

    # Check system requirements
    check_system_requirements

    # Install core tools
    install_kubectl || return 1
    install_k9s
    install_helm
    install_additional_tools

    # Setup configuration
    setup_kubectl_config

    # Create examples
    create_kubernetes_examples

    # Show information
    print_kubernetes_info

    log_success "$TOOL_NAME installation completed!"
}

# Execute main function
main "$@"

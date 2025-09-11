#!/bin/bash
# Anaconda Python Distribution Installation Script
# Installs Anaconda for scientific Python computing

# ==============================================================================
# CONFIGURATION
# ==============================================================================
TOOL_NAME="Anaconda Python Distribution"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
ARCHER_DIR="${ARCHER_DIR:-$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")}"

# Source common functions
source "$ARCHER_DIR/install/system/common-funcs.sh"

# ==============================================================================
# INSTALLATION FUNCTIONS
# ==============================================================================

install_anaconda() {
    log_info "Installing Anaconda Python distribution..."

    # Check if Anaconda is already installed
    if command -v conda &>/dev/null; then
        log_info "Anaconda is already installed"
        conda --version
        return 0
    fi

    # Create temporary directory for download
    local temp_dir="/tmp/anaconda_install"
    mkdir -p "$temp_dir"
    cd "$temp_dir"

    # Download Anaconda installer
    local anaconda_url="https://repo.anaconda.com/archive/Anaconda3-2023.09-0-Linux-x86_64.sh"
    local installer="Anaconda3-2023.09-0-Linux-x86_64.sh"

    log_info "Downloading Anaconda installer..."
    execute_with_progress "curl -L -o '$installer' '$anaconda_url'" "Downloading Anaconda..."

    # Verify download
    if [[ ! -f "$installer" ]]; then
        log_error "Failed to download Anaconda installer"
        return 1
    fi

    # Make installer executable
    chmod +x "$installer"

    # Install Anaconda
    log_info "Installing Anaconda (this may take a few minutes)..."
    log_info "Please follow the installer prompts:"
    log_info "  1. Press ENTER to continue"
    log_info "  2. Type 'yes' to accept the license"
    log_info "  3. Press ENTER to use default location (~/.anaconda3)"
    log_info "  4. Type 'yes' to initialize conda"

    ./"$installer"

    # Clean up
    cd "$HOME"
    rm -rf "$temp_dir"

    # Source conda to make it available immediately
    if [[ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]]; then
        source "$HOME/anaconda3/etc/profile.d/conda.sh"
        log_success "Anaconda installed successfully"
    else
        log_error "Anaconda installation may have failed"
        return 1
    fi
}

setup_conda_environments() {
    log_info "Setting up Conda environments..."

    # Ensure conda is available
    if ! command -v conda &>/dev/null; then
        if [[ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]]; then
            source "$HOME/anaconda3/etc/profile.d/conda.sh"
        else
            log_error "Conda not found"
            return 1
        fi
    fi

    # Update conda
    execute_with_progress "conda update -n base -c defaults conda -y" "Updating conda..."

    # Create data science environment
    log_info "Creating data science environment..."
    execute_with_progress "conda create -n datascience python=3.11 jupyter numpy pandas matplotlib seaborn scikit-learn scipy -y" "Creating datascience environment..."

    # Create machine learning environment
    log_info "Creating machine learning environment..."
    execute_with_progress "conda create -n ml python=3.11 tensorflow pytorch torchvision torchaudio jupyter -c pytorch -c conda-forge -y" "Creating ML environment..."

    # Create web development environment
    log_info "Creating web development environment..."
    execute_with_progress "conda create -n web python=3.11 flask django fastapi requests beautifulsoup4 -y" "Creating web environment..."
}

create_jupyter_config() {
    log_info "Setting up Jupyter configuration..."

    # Source conda if needed
    if ! command -v conda &>/dev/null && [[ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]]; then
        source "$HOME/anaconda3/etc/profile.d/conda.sh"
    fi

    # Generate Jupyter config
    if command -v jupyter &>/dev/null; then
        jupyter notebook --generate-config --allow-root 2>/dev/null || true

        # Create custom Jupyter config
        local jupyter_config="$HOME/.jupyter/jupyter_notebook_config.py"
        if [[ -f "$jupyter_config" ]]; then
            # Add useful configurations
            cat >> "$jupyter_config" << 'EOF'

# Custom Jupyter configuration
c.NotebookApp.open_browser = False
c.NotebookApp.ip = 'localhost'
c.NotebookApp.port = 8888
c.NotebookApp.notebook_dir = '~/jupyter-notebooks'
c.NotebookApp.quit_button = True
EOF
            log_info "Updated Jupyter configuration"
        fi
    fi

    # Create notebooks directory
    mkdir -p "$HOME/jupyter-notebooks"

    # Create example notebook
    if [[ ! -f "$HOME/jupyter-notebooks/Welcome.ipynb" ]]; then
        cat > "$HOME/jupyter-notebooks/Welcome.ipynb" << 'EOF'
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# Welcome to Anaconda!\n",
    "\n",
    "This is an example Jupyter notebook demonstrating key scientific Python libraries."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "import numpy as np\n",
    "import pandas as pd\n",
    "import matplotlib.pyplot as plt\n",
    "import seaborn as sns\n",
    "\n",
    "print(\"Scientific Python libraries loaded successfully!\")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Create sample data\n",
    "np.random.seed(42)\n",
    "data = pd.DataFrame({\n",
    "    'x': np.random.randn(100),\n",
    "    'y': np.random.randn(100),\n",
    "    'category': np.random.choice(['A', 'B', 'C'], 100)\n",
    "})\n",
    "\n",
    "# Display basic statistics\n",
    "print(\"Data shape:\", data.shape)\n",
    "print(\"\\nFirst 5 rows:\")\n",
    "data.head()"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Create visualization\n",
    "plt.figure(figsize=(10, 6))\n",
    "sns.scatterplot(data=data, x='x', y='y', hue='category')\n",
    "plt.title('Sample Data Visualization')\n",
    "plt.show()"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  },
  "language_info": {
   "codemirror_mode": {
    "name": "ipython",
    "version": 3
   },
   "file_extension": ".py",
   "mimetype": "text/x-python",
   "name": "python",
   "version": "3.11.0"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 4
}
EOF
        log_info "Created welcome notebook: ~/jupyter-notebooks/Welcome.ipynb"
    fi
}

setup_conda_environment() {
    log_info "Setting up Conda shell integration..."

    # Add conda initialization to bashrc if not present
    local bashrc="$HOME/.bashrc"
    if [[ -f "$bashrc" ]] && ! grep -q "# >>> conda initialize >>>" "$bashrc"; then
        if [[ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]]; then
            cat >> "$bashrc" << 'EOF'

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('~/anaconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "~/anaconda3/etc/profile.d/conda.sh" ]; then
        . "~/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="~/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# Conda aliases
alias jn='jupyter notebook'
alias jl='jupyter lab'
alias ca='conda activate'
alias cda='conda deactivate'
alias cel='conda env list'
EOF
            log_info "Added Conda initialization to ~/.bashrc"
        fi
    fi
}

print_anaconda_info() {
    echo ""
    echo "=============================================="
    echo "Anaconda Python Distribution Ready!"
    echo "=============================================="
    echo ""
    if command -v conda &>/dev/null; then
        echo "Installed components:"
        echo "  • Conda: $(conda --version | cut -d' ' -f2)"
        echo "  • Python: $(python --version 2>&1 | cut -d' ' -f2)"
        echo "  • Jupyter: $(jupyter --version 2>/dev/null | head -n 1 | cut -d' ' -f2 || echo 'Available')"
    fi
    echo ""
    echo "Created environments:"
    echo "  • base (default environment)"
    echo "  • datascience (NumPy, Pandas, Matplotlib, Scikit-learn)"
    echo "  • ml (TensorFlow, PyTorch, Jupyter)"
    echo "  • web (Flask, Django, FastAPI)"
    echo ""
    echo "Quick start:"
    echo "  conda activate datascience  # Activate environment"
    echo "  jupyter notebook            # Start Jupyter"
    echo "  conda list                  # List installed packages"
    echo "  conda env list              # List environments"
    echo ""
    echo "Jupyter notebooks: ~/jupyter-notebooks/"
    echo ""
    echo "Note: Restart your terminal or run 'source ~/.bashrc' to use conda commands"
    echo ""
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

main() {
    log_info "Starting $TOOL_NAME installation..."

    # Check system requirements
    check_system_requirements

    # Install Anaconda
    install_anaconda || return 1

    # Setup conda environments
    setup_conda_environments

    # Setup Jupyter
    create_jupyter_config

    # Setup shell integration
    setup_conda_environment

    # Show information
    print_anaconda_info

    log_success "$TOOL_NAME installation completed!"
}

# Execute main function
main "$@"

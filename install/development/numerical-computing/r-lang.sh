#!/bin/bash
# R Statistical Computing Installation Script
# Installs R programming language and essential packages

# ==============================================================================
# CONFIGURATION
# ==============================================================================
TOOL_NAME="R Statistical Computing"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
ARCHER_DIR="${ARCHER_DIR:-$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")}"

# Source common functions
source "$ARCHER_DIR/install/system/common-funcs.sh"

# ==============================================================================
# INSTALLATION FUNCTIONS
# ==============================================================================

install_r_base() {
    log_info "Installing R programming language..."

    # Install R base
    if ! pacman -Qi r &>/dev/null; then
        execute_with_progress "sudo pacman -S --noconfirm r" "Installing R base..."
    else
        log_info "R already installed"
    fi

    # Install development tools for R packages
    local dev_packages=(
        "gcc-fortran"      # For Fortran code in R packages
        "tk"               # For tcltk R package
        "libxml2"          # For XML processing
        "curl"             # For downloading packages
        "openssl"          # For secure connections
    )

    for package in "${dev_packages[@]}"; do
        if ! pacman -Qi "$package" &>/dev/null; then
            execute_with_progress "sudo pacman -S --noconfirm $package" "Installing $package..."
        fi
    done

    # Verify installation
    if command -v R &>/dev/null; then
        local version=$(R --version | head -n 1)
        log_success "R installed: $version"
    else
        log_error "Failed to install R"
        return 1
    fi
}

install_rstudio() {
    log_info "Installing RStudio IDE..."

    # Check if RStudio is available
    if command -v yay &>/dev/null; then
        execute_with_progress "yay -S --noconfirm rstudio-desktop" "Installing RStudio from AUR..."

        if command -v rstudio &>/dev/null; then
            log_success "RStudio installed successfully"
        else
            log_warning "RStudio installation may have failed"
        fi
    else
        log_warning "RStudio requires AUR helper. Install yay first."
    fi
}

install_essential_packages() {
    log_info "Installing essential R packages..."

    # Create R script for package installation
    local r_script="/tmp/install_r_packages.R"
    cat > "$r_script" << 'EOF'
# Install essential R packages
packages <- c(
    "tidyverse",    # Data manipulation and visualization
    "ggplot2",      # Advanced plotting
    "dplyr",        # Data manipulation
    "readr",        # Data reading
    "stringr",      # String manipulation
    "devtools",     # Development tools
    "rmarkdown",    # Dynamic documents
    "knitr",        # Document generation
    "shiny",        # Web applications
    "DT",           # Interactive tables
    "plotly",       # Interactive plots
    "roxygen2",     # Documentation
    "testthat"      # Testing framework
)

install.packages(packages, repos = "https://cran.rstudio.com/", dependencies = TRUE)

# Check which packages were successfully installed
installed <- sapply(packages, requireNamespace, quietly = TRUE)
cat("Successfully installed packages:\n")
cat(paste(names(installed)[installed], collapse = ", "), "\n")

if (any(!installed)) {
    cat("Failed to install:\n")
    cat(paste(names(installed)[!installed], collapse = ", "), "\n")
}
EOF

    # Run R script to install packages
    execute_with_progress "Rscript '$r_script'" "Installing essential R packages..."

    # Clean up
    rm -f "$r_script"
}

setup_r_environment() {
    log_info "Setting up R development environment..."

    # Create R project directory
    local r_projects="$HOME/r-projects"
    if [[ ! -d "$r_projects" ]]; then
        mkdir -p "$r_projects/example"

        # Create example R script
        cat > "$r_projects/example/analysis.R" << 'EOF'
# Example R Analysis Script
library(tidyverse)

# Create sample data
data <- data.frame(
    x = rnorm(100),
    y = rnorm(100),
    group = sample(c("A", "B", "C"), 100, replace = TRUE)
)

# Basic statistics
summary(data)

# Create plot
ggplot(data, aes(x = x, y = y, color = group)) +
    geom_point() +
    theme_minimal() +
    labs(title = "Sample Data Visualization")

# Save plot
ggsave("sample_plot.png", width = 8, height = 6)

cat("Analysis completed! Check sample_plot.png\n")
EOF

        log_info "Created example R project in $r_projects/example"
    fi

    # Create R profile for better defaults
    local rprofile="$HOME/.Rprofile"
    if [[ ! -f "$rprofile" ]]; then
        cat > "$rprofile" << 'EOF'
# R Profile Configuration
options(
    repos = c(CRAN = "https://cran.rstudio.com/"),
    download.file.method = "libcurl",
    Ncpus = parallel::detectCores()
)

# Load commonly used packages
.First <- function() {
    if (interactive()) {
        cat("\nWelcome to R!\n")
        cat("Useful commands:\n")
        cat("  library(tidyverse)  # Load tidyverse\n")
        cat("  help.start()        # Open help system\n")
        cat("  q()                 # Quit R\n\n")
    }
}
EOF
        log_info "Created R profile: ~/.Rprofile"
    fi
}

print_r_info() {
    echo ""
    echo "=============================================="
    echo "R Statistical Computing Environment Ready!"
    echo "=============================================="
    echo ""
    echo "Installed components:"
    if command -v R &>/dev/null; then
        echo "  • R: $(R --version | head -n 1 | cut -d' ' -f1-3)"
    fi
    if command -v rstudio &>/dev/null; then
        echo "  • RStudio IDE: Available"
    fi
    echo ""
    echo "Quick start:"
    echo "  R                          # Start R console"
    echo "  rstudio                    # Start RStudio (if installed)"
    echo "  Rscript script.R           # Run R script"
    echo ""
    echo "Essential packages installed:"
    echo "  • tidyverse (data manipulation)"
    echo "  • ggplot2 (visualization)"
    echo "  • shiny (web apps)"
    echo "  • rmarkdown (documents)"
    echo ""
    echo "Example project: ~/r-projects/example"
    echo "  cd ~/r-projects/example && Rscript analysis.R"
    echo ""
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

main() {
    log_info "Starting $TOOL_NAME installation..."

    # Check system requirements
    check_system_requirements

    # Install R base system
    install_r_base || return 1

    # Install RStudio (optional)
    install_rstudio

    # Install essential packages
    install_essential_packages

    # Setup development environment
    setup_r_environment

    # Show information
    print_r_info

    log_success "$TOOL_NAME installation completed!"
}

# Execute main function
main "$@"

#!/bin/bash
# GNU Octave Installation Script
# Installs GNU Octave (MATLAB alternative) with essential packages

# ==============================================================================
# CONFIGURATION
# ==============================================================================
TOOL_NAME="GNU Octave"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
ARCHER_DIR="${ARCHER_DIR:-$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")}"

# Source common functions
source "$ARCHER_DIR/install/system/common-funcs.sh"

# ==============================================================================
# INSTALLATION FUNCTIONS
# ==============================================================================

install_octave() {
    log_info "Installing GNU Octave..."

    # Install Octave and essential packages
    local packages=(
        "octave"           # Main Octave package
        "gnuplot"          # Plotting backend
        "ghostscript"      # PostScript/PDF support
        "epstool"          # EPS manipulation
        "transfig"         # Figure conversion
        "pstoedit"         # PostScript to vector formats
    )

    for package in "${packages[@]}"; do
        if ! pacman -Qi "$package" &>/dev/null; then
            execute_with_progress "sudo pacman -S --noconfirm $package" "Installing $package..."
        fi
    done

    # Verify installation
    if command -v octave &>/dev/null; then
        local version=$(octave --version | head -n 1)
        log_success "Octave installed: $version"
    else
        log_error "Failed to install Octave"
        return 1
    fi
}

install_octave_packages() {
    log_info "Installing essential Octave packages..."

    # Create Octave script for package installation
    local octave_script="/tmp/install_octave_packages.m"
    cat > "$octave_script" << 'EOF'
% Install essential Octave packages
pkg_list = {
    'signal',     % Signal processing
    'control',    % Control systems
    'image',      % Image processing
    'statistics', % Statistics functions
    'symbolic',   % Symbolic math
    'io',         % Input/output functions
    'general',    % General functions
    'miscellaneous' % Miscellaneous utilities
};

% Install packages
for i = 1:length(pkg_list)
    pkg_name = pkg_list{i};
    try
        fprintf('Installing package: %s\n', pkg_name);
        pkg('install', '-forge', pkg_name);
        fprintf('Successfully installed: %s\n', pkg_name);
    catch
        fprintf('Failed to install: %s\n', pkg_name);
    end
end

% Load essential packages
try
    pkg('load', 'signal');
    pkg('load', 'control');
    pkg('load', 'statistics');
    fprintf('Essential packages loaded successfully\n');
catch
    fprintf('Some packages failed to load\n');
end

fprintf('Octave package installation completed\n');
quit
EOF

    # Run Octave script (this might take a while)
    execute_with_progress "octave --no-gui '$octave_script'" "Installing Octave packages (this may take several minutes)..."

    # Clean up
    rm -f "$octave_script"
}

setup_octave_environment() {
    log_info "Setting up Octave development environment..."

    # Create Octave projects directory
    local octave_projects="$HOME/octave-projects"
    if [[ ! -d "$octave_projects" ]]; then
        mkdir -p "$octave_projects/examples"

        # Create example script
        cat > "$octave_projects/examples/demo.m" << 'EOF'
% Octave Demo Script
% Basic mathematical operations and plotting

% Clear workspace
clear all; close all; clc;

% Display welcome message
fprintf('Welcome to GNU Octave!\n');
fprintf('MATLAB-compatible scientific computing environment\n\n');

% Create sample data
x = linspace(0, 2*pi, 100);
y1 = sin(x);
y2 = cos(x);

% Create plots
figure(1);
subplot(2,1,1);
plot(x, y1, 'b-', 'LineWidth', 2);
title('Sine Wave');
xlabel('x'); ylabel('sin(x)');
grid on;

subplot(2,1,2);
plot(x, y2, 'r-', 'LineWidth', 2);
title('Cosine Wave');
xlabel('x'); ylabel('cos(x)');
grid on;

% Save figure
print('octave_demo.png', '-dpng');

% Matrix operations
A = [1 2; 3 4];
B = [5 6; 7 8];
C = A * B;

fprintf('Matrix multiplication result:\n');
disp(C);

% Statistical analysis
data = randn(1000, 1);
fprintf('Statistics for random data (n=1000):\n');
fprintf('Mean: %.4f\n', mean(data));
fprintf('Std:  %.4f\n', std(data));

fprintf('\nDemo completed! Check octave_demo.png\n');
EOF

        # Create function example
        cat > "$octave_projects/examples/myfunction.m" << 'EOF'
function result = myfunction(x, y)
% MYFUNCTION Example function in Octave
% Usage: result = myfunction(x, y)
% Computes x^2 + y^2

if nargin < 2
    error('Two arguments required');
end

result = x.^2 + y.^2;

end
EOF

        log_info "Created example Octave project in $octave_projects/examples"
    fi

    # Create Octave startup script
    local octaverc="$HOME/.octaverc"
    if [[ ! -f "$octaverc" ]]; then
        cat > "$octaverc" << 'EOF'
% Octave startup script
% Automatic configuration for better user experience

% Set graphics backend
graphics_toolkit('gnuplot');

% Add current directory to path
addpath(pwd);

% Display startup message
if (exist('OCTAVE_VERSION', 'builtin'))
    fprintf('\nGNU Octave %s\n', OCTAVE_VERSION);
    fprintf('Type "help" for help, "demo" for demonstrations\n');
    fprintf('Current directory: %s\n\n', pwd);
end

% Set better defaults
format long;
more off;

% Load essential packages if available
pkg_to_load = {'signal', 'control', 'statistics'};
for i = 1:length(pkg_to_load)
    try
        pkg('load', pkg_to_load{i});
    catch
        % Package not available, continue silently
    end
end
EOF
        log_info "Created Octave startup script: ~/.octaverc"
    fi
}

print_octave_info() {
    echo ""
    echo "=============================================="
    echo "GNU Octave Environment Ready!"
    echo "=============================================="
    echo ""
    echo "Installed components:"
    if command -v octave &>/dev/null; then
        echo "  • Octave: $(octave --version | head -n 1 | cut -d' ' -f4)"
    fi
    if command -v gnuplot &>/dev/null; then
        echo "  • Gnuplot: $(gnuplot --version | cut -d' ' -f2)"
    fi
    echo ""
    echo "Quick start:"
    echo "  octave                     # Start Octave CLI"
    echo "  octave --gui               # Start Octave GUI"
    echo "  octave script.m            # Run Octave script"
    echo ""
    echo "Essential packages:"
    echo "  • signal (signal processing)"
    echo "  • control (control systems)"
    echo "  • statistics (statistical functions)"
    echo "  • image (image processing)"
    echo ""
    echo "Example project: ~/octave-projects/examples"
    echo "  cd ~/octave-projects/examples && octave demo.m"
    echo ""
    echo "Key differences from MATLAB:"
    echo "  • Use 'end' instead of 'endif', 'endwhile', etc."
    echo "  • Comments with % or #"
    echo "  • String comparisons with strcmp()"
    echo ""
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

main() {
    log_info "Starting $TOOL_NAME installation..."

    # Check system requirements
    check_system_requirements

    # Install Octave
    install_octave || return 1

    # Install Octave packages (this may take a while)
    install_octave_packages

    # Setup development environment
    setup_octave_environment

    # Show information
    print_octave_info

    log_success "$TOOL_NAME installation completed!"
}

# Execute main function
main "$@"

#!/bin/bash

# Script to fix remaining read -p calls in Archer scripts

set -e

# List of scripts that still need fixing
scripts=(
    "./test_installer.sh"
    "./install/multimedia/gaming.sh"
    "./install/desktop/office-tools/office-suite.sh"
    "./install/desktop/de-installer.sh"
    "./install/network/wifi-install.sh"
    "./install/network/wifi-setup.sh"
    "./install/system/gpu-drivers.sh"
)

echo "Fixing read -p calls in remaining scripts..."

for script in "${scripts[@]}"; do
    if [[ -f "$script" ]]; then
        echo "Processing $script..."

        # Add gum functions if not present
        if ! grep -q "confirm_action()" "$script"; then
            # Find insertion point after color definitions
            if grep -q "NC=.*No Color" "$script"; then
                sed -i '/NC=.*No Color/a\\n# Confirm function using gum\nconfirm_action() {\n    local message="$1"\n    gum confirm "$message"\n}\n\n# Wait function using gum\nwait_for_input() {\n    local message="${1:-Press Enter to continue...}"\n    gum input --placeholder "$message" --value "" > /dev/null\n}\n\n# Input function using gum\nget_input() {\n    local prompt="$1"\n    local placeholder="${2:-}"\n    gum input --prompt "$prompt " --placeholder "$placeholder"\n}' "$script"
            fi
        fi

        # Replace simple "Press Enter to continue..." patterns
        sed -i 's/read -p "Press Enter to continue\.\.\."/wait_for_input/g' "$script"

        # Replace y/N confirmation patterns
        sed -i 's/read -p "\([^"]*\) (y\/N): " \([a-zA-Z_][a-zA-Z0-9_]*\)/if confirm_action "\1"; then/g' "$script"
        sed -i 's/read -p "\([^"]*\) (Y\/n): " \([a-zA-Z_][a-zA-Z0-9_]*\)/if ! confirm_action "\1"; then\n        echo -e "${YELLOW}Skipping...${NC}"\n    else/g' "$script"

        # Clean up conditional logic that follows the old pattern
        sed -i 's/if \[\[ "\$[a-zA-Z_][a-zA-Z0-9_]*" =~ \^\[Yy\]\$ \]\]; then//g' "$script"
        sed -i 's/if \[\[ "\$[a-zA-Z_][a-zA-Z0-9_]*" =~ \^\[Nn\]\$ \]\]; then/else/g' "$script"

        echo "Fixed $script"
    else
        echo "Warning: $script not found"
    fi
done

echo "Done! Please review and test the changes."

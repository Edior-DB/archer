#!/bin/bash

# Comprehensive menu validation script
# Tests all menu.toml files for parsing errors and navigation issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Comprehensive Menu Validation ===${NC}"
echo ""

# Find all unique menu.toml files
menu_files=$(find install -name "menu.toml" | sort | uniq)
total_files=0
passed_files=0
failed_files=0

# Source common functions
source install/system/common-funcs.sh

echo -e "${BLUE}Testing individual menu files...${NC}"
echo ""

for menu_file in $menu_files; do
    total_files=$((total_files + 1))
    menu_dir=$(dirname "$menu_file")
    menu_name=$(basename "$menu_dir")

    echo -n "Testing $menu_file ... "

    # Test Python parsing
    if python3 install/system/parse_toml.py "$menu_file" >/dev/null 2>&1; then
        # Test bash function parsing
        if parse_menu_toml "$menu_file" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ PASS${NC}"
            passed_files=$((passed_files + 1))
        else
            echo -e "${RED}❌ FAIL (bash parsing)${NC}"
            failed_files=$((failed_files + 1))
        fi
    else
        echo -e "${RED}❌ FAIL (python parsing)${NC}"
        failed_files=$((failed_files + 1))
    fi
done

echo ""
echo -e "${BLUE}=== Menu Navigation Check ===${NC}"
echo ""

# Check navigation ordering for a sample of menus
test_menus=(
    "install/menu.toml"
    "install/development/menu.toml"
    "install/multimedia/gaming/menu.toml"
    "install/desktop/fonts/menu.toml"
    "install/extras/browsers/menu.toml"
)

for menu_file in "${test_menus[@]}"; do
    if [[ -f "$menu_file" ]]; then
        echo "Checking navigation order: $menu_file"

        # Get last few options to check navigation
        last_options=$(python3 install/system/parse_toml.py "$menu_file" | grep "OPTION_" | tail -3)

        # Check if navigation is at the end
        if echo "$last_options" | grep -q "back\|exit"; then
            echo -e "  ${GREEN}✅ Navigation items at end${NC}"
        else
            echo -e "  ${YELLOW}⚠ Navigation ordering may need attention${NC}"
        fi
        echo ""
    fi
done

echo -e "${BLUE}=== Summary ===${NC}"
echo -e "Total menu files tested: $total_files"
echo -e "${GREEN}Passed: $passed_files${NC}"
echo -e "${RED}Failed: $failed_files${NC}"

if [[ $failed_files -eq 0 ]]; then
    echo -e "${GREEN}🎉 All menu files are valid!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some menu files need attention${NC}"
    exit 1
fi

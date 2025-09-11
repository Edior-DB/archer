#!/bin/bash
# Quick test script for TOML parsing functionality

set -e

# Load common functions
source "$(dirname "$0")/install/system/common-funcs.sh"

echo "=== Testing TOML Menu Parsing ==="
echo ""

# Test main menu
echo "1. Testing main menu..."
if parse_menu_toml "install/menu.toml"; then
    echo "✅ Main menu parsed successfully"
    echo "   Menu: $MENU_NAME"
    echo "   Options: $OPTION_COUNT"
    echo ""
else
    echo "❌ Failed to parse main menu"
    exit 1
fi

# Test development menu
echo "2. Testing development submenu..."
if parse_menu_toml "install/development/menu.toml"; then
    echo "✅ Development menu parsed successfully"
    echo "   Menu: $MENU_NAME"
    echo "   Options: $OPTION_COUNT"
    echo "   Quick Actions: $QUICK_ACTIONS_COUNT"
    echo ""
else
    echo "❌ Failed to parse development menu"
    exit 1
fi

# Test discover functionality
echo "3. Testing menu discovery..."
menus=$(discover_toml_menus "install")
if [[ -n "$menus" ]]; then
    echo "✅ Menu discovery working"
    echo "   Found menus: $menus"
    echo ""
else
    echo "❌ No menus found"
    exit 1
fi

echo "🎉 All TOML parsing tests passed!"

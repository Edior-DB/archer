#!/bin/bash

# Fix sudo access script
# Run this in your VM to diagnose and fix sudo issues

echo "=== Checking current sudo configuration ==="
echo "Current user: $(whoami)"
echo "User groups: $(groups)"
echo ""

echo "=== Current sudoers file wheel entries ==="
sudo cat /etc/sudoers | grep -E '^\s*#?\s*%wheel'
echo ""

echo "=== Testing sudo access ==="
if sudo -n true 2>/dev/null; then
    echo "✓ Passwordless sudo works"
elif sudo -v; then
    echo "✓ Password-based sudo works"
else
    echo "✗ Sudo access failed"
fi
echo ""

echo "=== Fixing sudoers configuration ==="
# Backup original
sudo cp /etc/sudoers /etc/sudoers.backup

# Remove any existing wheel configurations
sudo sed -i '/^%wheel/d' /etc/sudoers
sudo sed -i '/^# %wheel/d' /etc/sudoers

# Add clean wheel configuration (with password)
echo '%wheel ALL=(ALL) ALL' | sudo tee -a /etc/sudoers

echo "=== New sudoers wheel configuration ==="
sudo cat /etc/sudoers | grep -E 'wheel'
echo ""

echo "=== Testing sudo access again ==="
if sudo -v; then
    echo "✓ Sudo access fixed!"
else
    echo "✗ Still having issues - may need manual intervention"
fi

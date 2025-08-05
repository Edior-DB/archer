#!/bin/bash

# Quick fix for sudoers issue
# Run this script as root in your VM

echo "=== Sudoers Quick Fix ==="

# Backup current sudoers
cp /etc/sudoers /etc/sudoers.backup.$(date +%Y%m%d_%H%M%S)

# Check current wheel entries
echo "Current wheel entries in sudoers:"
grep -n wheel /etc/sudoers || echo "No wheel entries found"

# Remove any malformed wheel entries
sed -i '/^%wheel/d' /etc/sudoers
sed -i '/^# %wheel/d' /etc/sudoers

# Add proper wheel group configuration using visudo-safe method
echo "" >> /etc/sudoers
echo "# User privilege specification" >> /etc/sudoers
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# Verify sudoers file syntax
if visudo -c; then
    echo "✓ Sudoers file syntax is valid"
    echo ""
    echo "New wheel configuration:"
    grep wheel /etc/sudoers
    echo ""
    echo "Now logout and login again, then test with: sudo whoami"
else
    echo "✗ Sudoers file has syntax errors, restoring backup"
    cp /etc/sudoers.backup.* /etc/sudoers
fi

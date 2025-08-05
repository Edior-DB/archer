# Troubleshooting Tools

This directory contains diagnostic and repair scripts for common issues that may arise after installation.

## Scripts

### `fix-sudo.sh`
**Purpose**: Diagnose and fix sudo access issues
**Usage**: Run as any user to diagnose sudo problems, includes interactive fixes
**When to use**: When you can't use sudo commands after installation

```bash
curl -fsSL https://raw.githubusercontent.com/Edior-DB/archer/master/troubleshooting/fix-sudo.sh | bash
```

### `fix-sudoers.sh`
**Purpose**: Emergency sudoers file repair
**Usage**: Must be run as root to fix broken sudoers configuration
**When to use**: When sudoers file is completely broken and needs emergency repair

```bash
# Run as root only
curl -fsSL https://raw.githubusercontent.com/Edior-DB/archer/master/troubleshooting/fix-sudoers.sh | bash
```

## When You Might Need These

These tools are provided for edge cases and troubleshooting. The main installation scripts (`install-system.sh` and `install-archer.sh`) should configure everything correctly.

You might need these if:
- You have an existing Arch installation with broken sudo access
- Something went wrong during the installation process
- You modified system files manually and broke sudo

## Prevention

The best way to avoid needing these tools is to use the official installation scripts without manual modifications to system files like `/etc/sudoers`.

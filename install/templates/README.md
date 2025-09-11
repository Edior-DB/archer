# TOML Menu and Installation Templates

## Overview

This directory contains templates for creating TOML-based menu configurations and installation scripts that follow the new modular UI architecture.

## Template Files

### Menu Templates

- **`menu-main-template.toml`** - Template for top-level category menus
- **`menu-sub-template.toml`** - Template for component-specific menus

### Installation Script Templates

- **`install-main-template.sh`** - Template for main category installation scripts
- **`install-component-template.sh`** - Template for component-level installation scripts

## Usage Guide

### Creating a New Category Menu

1. Copy `menu-main-template.toml` to your category directory as `menu.toml`
2. Edit the `[menu]` section with your category details
3. Update the `[options]` section with your subcategories
4. Modify the `[quick_actions]` section for custom installation combinations
5. Update the `[metadata]` section with requirements and estimates

Example:
```bash
cp /home/giorgil/archer/install/templates/menu-main-template.toml /home/giorgil/archer/install/development/menu.toml
# Edit the file with your category specifics
```

### Creating a Component Menu

1. Copy `menu-sub-template.toml` to your component directory as `menu.toml`
2. Edit the `[menu]` section with component details
3. Update the `[options]` section with available scripts
4. Configure the `[multiselect]` section for gum choose integration
5. Update the `[metadata]` section appropriately

Example:
```bash
cp /home/giorgil/archer/install/templates/menu-sub-template.toml /home/giorgil/archer/install/development/editors/menu.toml
```

### Creating Installation Scripts

1. For main categories, copy `install-main-template.sh` as `install.sh`
2. For components, copy `install-component-template.sh` as `install.sh`
3. Update the configuration variables at the top
4. Modify the script arrays to match your actual scripts
5. Make the script executable

Example:
```bash
cp /home/giorgil/archer/install/templates/install-main-template.sh /home/giorgil/archer/install/development/install.sh
chmod +x /home/giorgil/archer/install/development/install.sh
```

## TOML Structure Reference

### Menu Configuration

```toml
[menu]
name = "Display Name"           # Human-readable name
description = "Description"     # Brief explanation
icon = "📁"                    # Unicode icon
level = "main|sub"             # Menu level type

[options]
# Format: key = { display = "Text", action = "type", target = "path" }
# Actions: submenu, script, install, multiselect, custom, back, exit

[multiselect]
# For gum choose --no-limit integration
available_scripts = [
    { file = "script.sh", display = "Name", description = "Desc" }
]

[quick_actions]
# Custom installation combinations
action_name = ["script1.sh", "script2.sh"]

[metadata]
requires_network = true|false
requires_aur = true|false
estimated_time = "duration"
dependencies = ["dep1", "dep2"]
categories = ["tag1", "tag2"]
```

### Installation Script Structure

```bash
#!/bin/bash
# Configuration
COMPONENT_NAME="Name"
COMPONENT_DIR="$(dirname "$(realpath "$0")")"
ARCHER_DIR="${ARCHER_DIR:-path}"

# Source common functions
source "$ARCHER_DIR/install/system/common-funcs.sh"

# Installation functions
install_all_scripts() {
    # Implementation
}

# Main execution with argument parsing
main() {
    # Parse args and execute
}

main "$@"
```

## Integration with Gum

The templates are designed to work with the enhanced gum functions:

- **`gum spin`** - Used by `execute_with_progress()` for progress indication
- **`gum choose --no-limit`** - Used by multiselect actions for multiple selection
- **`gum select`** - Used by standard menu options
- **`gum confirm`** - Used by confirmation dialogs

## Testing Your Templates

After creating new menus and scripts:

1. Test the TOML parsing:
   ```bash
   /home/giorgil/archer/bin/archer-toml.sh --menu your-category/
   ```

2. Test the installation script:
   ```bash
   your-category/install.sh --help
   your-category/install.sh --all
   ```

3. Test with the main archer interface:
   ```bash
   /home/giorgil/archer/bin/archer-toml.sh
   ```

## Migration Process

1. **Backup**: Create rollback point (already done at d4e9c6c)
2. **Template**: Use these templates to create TOML menus
3. **Scripts**: Create install.sh scripts for bulk installation
4. **Test**: Verify functionality with existing scripts
5. **Convert**: Gradually migrate existing modules
6. **Validate**: Test full integration

## Security Benefits

- **TOML over Shell**: Configuration files can't execute arbitrary code
- **Validation**: TOML structure can be validated before parsing
- **Separation**: Menu logic separated from installation logic
- **Auditing**: Easier to audit configuration changes

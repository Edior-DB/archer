#!/usr/bin/env python3
"""
Enhanced TOML parser for Archer menus with pythonic auto-discovery
Supports the new simplified TOML format with directory-based auto-discovery
"""
import os
import sys
import re
from pathlib import Path

def resolve_path(path, base_dir=None):
    """Resolve relative paths to absolute paths using $ARCHER_DIR or base_dir"""
    if os.path.isabs(path):
        return path

    if base_dir is None:
        archer_dir = os.environ.get('ARCHER_DIR', '/home/giorgil/archer')
        base_dir = archer_dir

    return os.path.join(base_dir, path)

def parse_toml_simplified(file_path):
    """Parse simplified TOML format with auto-discovery"""
    result = {}
    current_section = None

    try:
        with open(file_path, 'r') as f:
            content = f.read()
    except Exception as e:
        print(f"Error reading {file_path}: {e}", file=sys.stderr)
        return {}

    lines = content.split('\n')
    base_dir = os.path.dirname(file_path)

    for line in lines:
        line = line.strip()

        # Skip comments and empty lines
        if not line or line.startswith('#'):
            continue

        # Section headers
        if line.startswith('[') and line.endswith(']'):
            current_section = line[1:-1]
            if current_section not in result:
                result[current_section] = {}
            continue

        # Key-value pairs
        if '=' in line and current_section:
            key, value = line.split('=', 1)
            key = key.strip().strip('"')
            value = value.strip().strip('"')

            # Handle arrays (basic support)
            if value.startswith('[') and value.endswith(']'):
                value = [v.strip().strip('"') for v in value[1:-1].split(',') if v.strip()]

            result[current_section][key] = value

    return result

def auto_discover_directory(dir_path):
    """Auto-discover scripts and subdirectories in a directory"""
    items = {}

    try:
        for item in sorted(os.listdir(dir_path)):
            if item.startswith('.') or item == 'menu.toml':
                continue

            item_path = os.path.join(dir_path, item)

            if os.path.isfile(item_path) and item.endswith('.sh'):
                # Create display name from script filename
                display_name = item.replace('.sh', '').replace('-', ' ').replace('_', ' ')
                display_name = ' '.join(word.capitalize() for word in display_name.split())
                items[item] = {
                    'display': display_name,
                    'action': 'script',
                    'target': item,
                    'type': 'file'
                }
            elif os.path.isdir(item_path):
                # Check if subdirectory has a menu.toml
                submenu_path = os.path.join(item_path, 'menu.toml')
                if os.path.exists(submenu_path):
                    display_name = item.replace('-', ' ').replace('_', ' ')
                    display_name = ' '.join(word.capitalize() for word in display_name.split())
                    items[item + '/'] = {
                        'display': display_name,
                        'action': 'submenu',
                        'target': submenu_path,
                        'type': 'directory'
                    }
    except Exception as e:
        print(f"Error discovering directory {dir_path}: {e}", file=sys.stderr)

    return items

def process_menu_data(data, file_path):
    """Process parsed TOML data and generate menu items"""
    menu_items = {}
    base_dir = os.path.dirname(file_path)

    # Get menu metadata
    menu_info = data.get('menu', {})
    metadata = data.get('metadata', {})
    excludes = data.get('excludes', {'files': [], 'directories': []})
    display_overrides = data.get('display', {})

    # If we have display overrides, use them as the primary source
    if display_overrides:
        for key, display_name in display_overrides.items():
            if key.endswith('/'):
                # Directory - target should be the subdirectory's menu.toml
                subdir = key.rstrip('/')
                submenu_path = f"{subdir}/menu.toml"
                menu_items[key] = {
                    'display': display_name,
                    'action': 'submenu',
                    'target': submenu_path,
                    'type': 'directory'
                }
            else:
                # File
                menu_items[key] = {
                    'display': display_name,
                    'action': 'script',
                    'target': key,
                    'type': 'file'
                }
    else:
        # Fallback to auto-discovery if no display section
        auto_items = auto_discover_directory(base_dir)

        # Apply excludes
        excluded_files = excludes.get('files', [])
        excluded_dirs = excludes.get('directories', [])

        for key, item in auto_items.items():
            should_exclude = False

            if item['type'] == 'file' and item['target'] in excluded_files:
                should_exclude = True
            elif item['type'] == 'directory' and key.rstrip('/') in excluded_dirs:
                should_exclude = True

            if not should_exclude:
                menu_items[key] = item

    return menu_items, menu_info, metadata

def escape_bash_string(s):
    """Escape single quotes for bash variable assignment"""
    return s.replace("'", "'\"'\"'")

def generate_bash_output(menu_items, menu_info, metadata):
    """Generate bash-compatible output in old format for compatibility"""
    output = []

    # Menu metadata
    menu_name = menu_info.get('name', 'Menu')
    menu_desc = menu_info.get('description', '')
    menu_icon = menu_info.get('icon', '📁')
    menu_level = metadata.get('level', 'submenu')

    output.append(f"MENU_NAME='{escape_bash_string(menu_name)}'")
    output.append(f"MENU_DESCRIPTION='{escape_bash_string(menu_desc)}'")
    output.append(f"MENU_HEADING_COLOR='blue'")
    output.append(f"MENU_ICON='{menu_icon}'")
    output.append(f"MENU_LEVEL='{menu_level}'")

    # Sort items: files first, then directories, alphabetically within each group
    sorted_items = sorted(menu_items.items(), key=lambda x: (
        0 if x[1]['type'] == 'file' else 1,  # Files before directories
        x[1]['display'].lower()  # Alphabetical within each group
    ))

    # Add navigation items
    nav_items = [
        ('back', {'display': '← Back', 'action': 'back', 'target': '..', 'type': 'nav'}),
        ('exit', {'display': 'Exit Archer', 'action': 'exit', 'target': '', 'type': 'nav'})
    ]

    # Combine all items
    all_items = sorted_items + nav_items

    # Generate option variables in old format for compatibility
    for i, (key, item) in enumerate(all_items):
        display = escape_bash_string(item['display'])
        action = item['action']
        target = item['target']

        # Resolve target paths
        if action == 'script':
            target = os.path.join(os.path.dirname(sys.argv[1]), target)
        elif action == 'submenu':
            target = os.path.join(os.path.dirname(sys.argv[1]), target)

        target = escape_bash_string(target)
        description = escape_bash_string(item.get('description', ''))

        output.append(f"OPTION_{i}='{display}|{action}|{target}|{description}'")

    output.append(f"OPTION_COUNT='{len(all_items)}'")

    # No quick actions in new format
    output.append("QUICK_ACTIONS_AVAILABLE='false'")
    output.append("QUICK_ACTIONS_COUNT='0'")

    return '\n'.join(output)

def main():
    if len(sys.argv) != 2:
        print("Usage: python3 parse_toml.py <menu.toml>", file=sys.stderr)
        sys.exit(1)

    toml_file = sys.argv[1]

    if not os.path.exists(toml_file):
        print(f"Error: File {toml_file} not found", file=sys.stderr)
        sys.exit(1)

    # Parse TOML file
    data = parse_toml_simplified(toml_file)

    if not data:
        print("Error: Failed to parse TOML file", file=sys.stderr)
        sys.exit(1)

    # Process menu data
    menu_items, menu_info, metadata = process_menu_data(data, toml_file)

    # Generate output
    bash_output = generate_bash_output(menu_items, menu_info, metadata)
    print(bash_output)

if __name__ == "__main__":
    main()

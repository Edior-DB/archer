#!/usr/bin/env python3
"""
Archer TOML Menu Parser
Parses TOML menu configuration files and outputs bash-compatible variable assignments
"""

import sys
import tomllib
import os
from pathlib import Path


def escape_bash_string(s):
    """Escape single quotes for bash variable assignment"""
    return s.replace("'", "'\"'\"'")


def resolve_path(path, toml_file_path):
    """
    Resolve relative paths to absolute paths using ARCHER_DIR
    """
    if not path or path == 'multiselect':
        return path

    # If it's already an absolute path, return as-is
    if os.path.isabs(path):
        return path

    # Get ARCHER_DIR from environment (set by archer-toml.sh)
    archer_dir = os.environ.get('ARCHER_DIR')
    if not archer_dir:
        # Fallback: calculate ARCHER_DIR from toml_file_path
        toml_path = Path(toml_file_path).resolve()
        # Navigate up to find the archer root (where install/ directory is)
        current = toml_path.parent
        while current != current.parent:
            if (current / 'install').exists():
                archer_dir = str(current)
                break
            current = current.parent

        if not archer_dir:
            # Last resort: assume we're already in the right location
            return path

    # Handle different path patterns
    if path.startswith('./'):
        # Path relative to current menu location
        menu_dir = str(Path(toml_file_path).parent)
        resolved = os.path.join(menu_dir, path[2:])
    elif path.startswith('../'):
        # Path relative to parent directory
        menu_dir = str(Path(toml_file_path).parent)
        resolved = os.path.normpath(os.path.join(menu_dir, path))
    else:
        # Path relative to current menu directory
        menu_dir = str(Path(toml_file_path).parent)
        resolved = os.path.join(menu_dir, path)

    # Convert to absolute path and normalize
    return os.path.normpath(os.path.abspath(resolved))


def main():
    if len(sys.argv) != 2:
        print("Usage: parse_toml.py <toml_file>", file=sys.stderr)
        sys.exit(1)

    toml_file = sys.argv[1]

    if not Path(toml_file).exists():
        print(f"Error: TOML file not found: {toml_file}", file=sys.stderr)
        sys.exit(1)

    try:
        with open(toml_file, 'rb') as f:
            config = tomllib.load(f)

        # Get header information
        menu_info = config.get('menu', {})

        # Fallback to root-level properties if no [menu] section exists
        if not menu_info:
            description = escape_bash_string(config.get('description', 'Unknown Menu'))
            heading_color = config.get('heading_color', 'blue')
            icon = config.get('icon', '📁')
            level = config.get('level', 'main')
        else:
            description = escape_bash_string(menu_info.get('description', menu_info.get('name', 'Unknown Menu')))
            heading_color = menu_info.get('heading_color', 'blue')
            icon = menu_info.get('icon', '📁')
            level = menu_info.get('level', 'main')

        print(f"MENU_NAME='{description}'")
        print(f"MENU_DESCRIPTION='{description}'")
        print(f"MENU_HEADING_COLOR='{heading_color}'")
        print(f"MENU_ICON='{icon}'")
        print(f"MENU_LEVEL='{level}'")

        # Parse menu_items array (new format) or options section (legacy format)
        menu_items = config.get('menu_items', [])
        options = config.get('options', {})

        # Handle new format (menu_items array)
        if menu_items:
            # Create a list to store all menu items with proper ordering
            all_menu_items = []

            for i, item in enumerate(menu_items):
                name = item.get('name', f'Item {i}')
                description = item.get('description', '')
                action_type = item.get('action_type', 'unknown')

                # Handle different action types
                if action_type == 'submenu':
                    target = resolve_path(item.get('submenu_path', ''), toml_file)
                elif action_type == 'script':
                    target = resolve_path(item.get('script_path', ''), toml_file)
                elif action_type == 'multiselect':
                    target = 'multiselect'
                    # Store multiselect items for later processing
                    items = item.get('items', [])
                    for j, multi_item in enumerate(items):
                        item_name = escape_bash_string(multi_item.get('name', f'Item {j}'))
                        item_script = resolve_path(multi_item.get('script', ''), toml_file)
                        item_script_escaped = escape_bash_string(item_script)
                        print(f"MULTISELECT_{i}_{j}='{item_name}|{item_script_escaped}'")
                else:
                    target = resolve_path(item.get('target', ''), toml_file)

                # Create menu item data structure
                menu_item_data = {
                    'name': name,
                    'action_type': action_type,
                    'target': target,
                    'description': description
                }
                all_menu_items.append(menu_item_data)

            # Create a dictionary with numbered IDs using range and zip
            menu_dict = dict(zip(range(len(all_menu_items)), all_menu_items))

            # Output menu items using the dictionary with proper numbering
            for item_id, item_data in menu_dict.items():
                name = escape_bash_string(item_data['name'])
                action_type = item_data['action_type']
                target = escape_bash_string(item_data['target'])
                description = escape_bash_string(item_data['description'])

                # Create option variable with sequential numbering
                print(f"OPTION_{item_id}='{name}|{action_type}|{target}|{description}'")

            # Store total number of options
            print(f"OPTION_COUNT='{len(menu_dict)}'")

        # Handle legacy format (options section)
        elif options:
            # Create ordered lists for different option types
            main_options = []
            quick_options = []
            navigation_options = []

            # Process all options and categorize them
            for key, value in options.items():
                if isinstance(value, dict):
                    action_type = value.get('action', 'unknown')
                    display_name = value.get('display', f'Option {key}')
                    target = resolve_path(value.get('target', ''), toml_file)
                    description = value.get('description', '')

                    option_data = {
                        'key': key,
                        'display': display_name,
                        'action': action_type,
                        'target': target,
                        'description': description
                    }

                    # Categorize options by type
                    if action_type in ['back', 'exit']:
                        # Navigation items go at the end
                        if action_type == 'back':
                            nav_order = 1000
                        elif action_type == 'exit':
                            nav_order = 2000
                        else:
                            nav_order = 1500
                        navigation_options.append((nav_order, option_data))

                    elif action_type in ['install', 'custom'] or key in ['all', 'essential', 'editors', 'terminals', 'languages_core', 'scientific', 'platforms', 'containers', 'multimedia', 'audio', 'video', 'graphics', 'recording', 'productivity']:
                        # Quick install options go in middle
                        try:
                            quick_order = int(key) if key.isdigit() else 100 + len(quick_options)
                        except ValueError:
                            quick_order = 100 + len(quick_options)
                        quick_options.append((quick_order, option_data))

                    else:
                        # Main menu items go first
                        try:
                            main_order = int(key)
                        except ValueError:
                            main_order = 50 + len(main_options)
                        main_options.append((main_order, option_data))

            # Sort each category by their order value
            main_options.sort(key=lambda x: x[0])
            quick_options.sort(key=lambda x: x[0])
            navigation_options.sort(key=lambda x: x[0])

            # Create final ordered list by combining categories
            all_options = []
            all_options.extend([option_data for _, option_data in main_options])
            all_options.extend([option_data for _, option_data in quick_options])
            all_options.extend([option_data for _, option_data in navigation_options])

            # Create a dictionary with numbered IDs using range and zip
            option_dict = dict(zip(range(len(all_options)), all_options))

            # Output options using the dictionary with proper numbering
            for option_id, option_data in option_dict.items():
                name = escape_bash_string(option_data['display'])
                action_type = option_data['action']
                target = escape_bash_string(option_data['target'])
                description = escape_bash_string(option_data['description'])

                # Create option variable with sequential numbering
                print(f"OPTION_{option_id}='{name}|{action_type}|{target}|{description}'")

            # Store total number of options
            print(f"OPTION_COUNT='{len(option_dict)}'")
        else:
            print(f"OPTION_COUNT='0'")

        # Parse quick_actions (handle both array and dictionary formats)
        quick_actions = config.get('quick_actions', [])
        if quick_actions:
            print(f"QUICK_ACTIONS_AVAILABLE='true'")
            action_list = []

            # Handle array format [[quick_actions]]
            if isinstance(quick_actions, list):
                for action in quick_actions:
                    if isinstance(action, dict):
                        name = action.get('name', 'Unknown Action')
                        description = action.get('description', f'Execute {name}')
                        command = action.get('command', '')
                        # Resolve command if it looks like a script path
                        if command and not command.startswith(('cd ', 'export ', 'source ')):
                            command = resolve_path(command, toml_file)
                        action_list.append((name, description, command))

            # Handle dictionary format [quick_actions]
            elif isinstance(quick_actions, dict):
                for action_name, action_items in quick_actions.items():
                    if isinstance(action_items, list):
                        # Convert list of scripts to a single command
                        command_parts = []
                        for item in action_items:
                            if isinstance(item, str):
                                resolved_item = resolve_path(item, toml_file)
                                command_parts.append(f"bash '{resolved_item}'")
                        command = " && ".join(command_parts)
                        action_list.append((action_name, f"Execute {action_name}", command))
                    elif isinstance(action_items, dict):
                        # Handle dictionary format
                        description = action_items.get('description', f'Execute {action_name}')
                        command = action_items.get('command', '')
                        # Resolve command if it looks like a script path
                        if command and not command.startswith(('cd ', 'export ', 'source ')):
                            command = resolve_path(command, toml_file)
                        action_list.append((action_name, description, command))
                    else:
                        # Handle simple string
                        resolved_action = resolve_path(str(action_items), toml_file)
                        action_list.append((action_name, f'Execute {action_name}', resolved_action))

            print(f"QUICK_ACTIONS_COUNT='{len(action_list)}'")
            for i, (name, description, command) in enumerate(action_list):
                name = escape_bash_string(name)
                description = escape_bash_string(description)
                command = escape_bash_string(command)
                print(f"QUICK_ACTION_{i}='{name}|{description}|{command}'")
        else:
            print(f"QUICK_ACTIONS_AVAILABLE='false'")
            print(f"QUICK_ACTIONS_COUNT='0'")

    except Exception as e:
        print(f"Error parsing TOML file '{toml_file}': {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()

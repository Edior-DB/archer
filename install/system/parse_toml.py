#!/usr/bin/env python3
"""
Archer TOML Menu Parser
Parses TOML menu configuration files and outputs bash-compatible variable assignments
"""

import sys
import tomllib
from pathlib import Path


def escape_bash_string(s):
    """Escape single quotes for bash variable assignment"""
    return s.replace("'", "'\"'\"'")


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
            for i, item in enumerate(menu_items):
                name = escape_bash_string(item.get('name', f'Item {i}'))
                description = escape_bash_string(item.get('description', ''))
                action_type = item.get('action_type', 'unknown')

                # Handle different action types
                if action_type == 'submenu':
                    target = item.get('submenu_path', '')
                elif action_type == 'script':
                    target = item.get('script_path', '')
                elif action_type == 'multiselect':
                    target = 'multiselect'
                    # Store multiselect items for later processing
                    items = item.get('items', [])
                    for j, multi_item in enumerate(items):
                        item_name = escape_bash_string(multi_item.get('name', f'Item {j}'))
                        item_script = escape_bash_string(multi_item.get('script', ''))
                        print(f"MULTISELECT_{i}_{j}='{item_name}|{item_script}'")
                else:
                    target = item.get('target', '')

                target = escape_bash_string(target)

                # Create option variable
                print(f"OPTION_{i}='{name}|{action_type}|{target}|{description}'")

            # Store total number of options
            print(f"OPTION_COUNT='{len(menu_items)}'")

        # Handle legacy format (options section)
        elif options:
            option_list = []
            for key, value in options.items():
                # Skip non-numeric keys for option ordering
                try:
                    option_num = int(key)
                    option_list.append((option_num, key, value))
                except ValueError:
                    # Handle named options like "all", "essential", etc.
                    option_list.append((999 + len(option_list), key, value))

            # Sort by option number
            option_list.sort(key=lambda x: x[0])

            for i, (_, key, value) in enumerate(option_list):
                if isinstance(value, dict):
                    name = escape_bash_string(value.get('display', f'Option {key}'))
                    action_type = value.get('action', 'unknown')
                    target = escape_bash_string(value.get('target', ''))
                    description = escape_bash_string(value.get('description', ''))
                else:
                    # Handle simple string values
                    name = escape_bash_string(str(value))
                    action_type = 'unknown'
                    target = ''
                    description = ''

                # Create option variable
                print(f"OPTION_{i}='{name}|{action_type}|{target}|{description}'")

            # Store total number of options
            print(f"OPTION_COUNT='{len(option_list)}'")
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
                        action_list.append((name, description, command))

            # Handle dictionary format [quick_actions]
            elif isinstance(quick_actions, dict):
                for action_name, action_items in quick_actions.items():
                    if isinstance(action_items, list):
                        # Convert list of scripts to a single command
                        command_parts = []
                        for item in action_items:
                            if isinstance(item, str):
                                command_parts.append(f"bash '{item}'")
                        command = " && ".join(command_parts)
                        action_list.append((action_name, f"Execute {action_name}", command))
                    elif isinstance(action_items, dict):
                        # Handle dictionary format
                        description = action_items.get('description', f'Execute {action_name}')
                        command = action_items.get('command', '')
                        action_list.append((action_name, description, command))
                    else:
                        # Handle simple string
                        action_list.append((action_name, f'Execute {action_name}', str(action_items)))

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

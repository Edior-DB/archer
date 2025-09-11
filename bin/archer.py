#!/usr/bin/env python3
"""
Archer Linux Enhancement Suite - Python Implementation
A comprehensive system enhancement and software installation tool
"""

import os
import sys
import subprocess
import time
from pathlib import Path
from typing import Dict, List, Optional, Tuple

from rich.console import Console
from rich.panel import Panel
from rich.table import Table
from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn, TimeElapsedColumn
from rich.prompt import Prompt, Confirm
from rich.text import Text
from rich.align import Align
from rich.layout import Layout
from rich.live import Live
from rich.tree import Tree

class ArcherUI:
    """Enhanced UI using Rich library"""

    def __init__(self):
        self.console = Console()
        self.archer_dir = os.environ.get('ARCHER_DIR', str(Path(__file__).parent.parent))

    def print_banner(self):
        """Display the Archer banner"""
        banner_text = """
    🏹 ARCHER LINUX ENHANCEMENT SUITE 🏹

    Comprehensive System Enhancement & Software Installation

    Built for Arch Linux • Enhanced with Python & Rich
        """

        panel = Panel(
            Align.center(banner_text),
            border_style="bold blue",
            padding=(1, 2),
            title="[bold cyan]Welcome to Archer[/bold cyan]",
            title_align="center"
        )

        self.console.print(panel)
        self.console.print()

    def display_menu(self, menu_name: str, menu_description: str, options: List[Dict]) -> int:
        """Display an interactive menu and get user selection"""

        # Rich-enhanced menu
        self.console.print(Panel(
            f"[bold cyan]{menu_name}[/bold cyan]\n{menu_description}",
            border_style="blue",
            padding=(0, 1)
        ))

        table = Table(show_header=True, header_style="bold magenta", box=None)
        table.add_column("Choice", style="cyan", width=8)
        table.add_column("Option", style="white")
        table.add_column("Description", style="dim")

        for i, option in enumerate(options, 1):
            # Add icons based on action type
            icon = self._get_action_icon(option.get('action', 'script'))
            display_text = f"{icon} {option['display']}"
            description = option.get('description', '')

            table.add_row(
                f"[bold cyan]{i}[/bold cyan]",
                display_text,
                description[:50] + "..." if len(description) > 50 else description
            )

        self.console.print(table)
        self.console.print()

        while True:
            try:
                choice_str = Prompt.ask(
                    "[bold green]Enter your choice[/bold green]",
                    default="",
                    show_default=False
                )

                if choice_str.lower() in ['q', 'quit', 'exit']:
                    return len(options) - 1  # Assume last option is exit

                choice = int(choice_str)
                if 1 <= choice <= len(options):
                    return choice - 1

                self.console.print(f"[red]Please enter a number between 1 and {len(options)}[/red]")

            except ValueError:
                self.console.print("[red]Please enter a valid number[/red]")
            except KeyboardInterrupt:
                self.console.print("\n[yellow]Operation cancelled[/yellow]")
                return len(options) - 1  # Exit

    def _get_action_icon(self, action: str) -> str:
        """Get appropriate icon for action type"""
        icons = {
            'script': '🔧',
            'submenu': '📁',
            'back': '⬅️',
            'exit': '🚪',
            'install': '📦'
        }
        return icons.get(action, '⚙️')

    def show_progress(self, description: str, command: str) -> bool:
        """Show progress while executing a command"""
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            BarColumn(),
            TimeElapsedColumn(),
            console=self.console,
            transient=True
        ) as progress:

            task = progress.add_task(description, total=100)

            # Start the subprocess
            process = subprocess.Popen(
                command,
                shell=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )

            # Simulate progress (in real implementation, you'd parse actual progress)
            while process.poll() is None:
                progress.advance(task, 2)
                time.sleep(0.1)
                if progress.tasks[0].completed >= 100:
                    progress.reset(task)

            # Complete the progress
            progress.update(task, completed=100)

            # Get the result
            stdout, stderr = process.communicate()

            if process.returncode == 0:
                self.console.print(f"[green]✓ {description} completed successfully[/green]")
                return True
            else:
                self.console.print(f"[red]✗ {description} failed[/red]")
                if stderr:
                    self.console.print(f"[red]Error: {stderr.strip()}[/red]")
                return False

    def confirm_action(self, message: str) -> bool:
        """Ask for user confirmation"""
        return Confirm.ask(f"[yellow]{message}[/yellow]", default=False)

    def display_info(self, title: str, content: str):
        """Display informational content"""
        panel = Panel(
            content,
            title=f"[bold blue]{title}[/bold blue]",
            border_style="blue",
            padding=(1, 2)
        )
        self.console.print(panel)

    def display_error(self, message: str):
        """Display error message"""
        self.console.print(f"[bold red]ERROR:[/bold red] {message}")

    def display_success(self, message: str):
        """Display success message"""
        self.console.print(f"[bold green]SUCCESS:[/bold green] {message}")


class ArcherMenu:
    """Menu system for Archer with directory-based auto-discovery"""

    def __init__(self, ui: ArcherUI):
        self.ui = ui
        self.archer_dir = ui.archer_dir
        self.install_dir = os.path.join(self.archer_dir, "install")
        self.menu_structure = {}
        self.discovered_menus = {}

        # Discover all menus at initialization
        self._discover_all_menus()

    def _discover_all_menus(self):
        """Discover all menu.toml files and build the complete menu structure"""
        self.ui.console.print("[dim]Discovering menu structure...[/dim]")

        # Start from install directory and recursively discover
        self._discover_directory(self.install_dir, "")

        self.ui.console.print(f"[dim]Discovered {len(self.discovered_menus)} menus[/dim]")

    def _discover_directory(self, directory_path: str, relative_path: str):
        """Recursively discover menus in a directory"""
        menu_toml_path = os.path.join(directory_path, "menu.toml")

        if os.path.exists(menu_toml_path):
            # Parse this menu
            menu_data = self._parse_toml_file(menu_toml_path)
            menu_key = relative_path if relative_path else "main"
            self.discovered_menus[menu_key] = {
                'path': menu_toml_path,
                'relative_path': relative_path,
                'data': menu_data,
                'submenus': [],
                'scripts': []
            }

            # Get excludes from menu data
            excludes = menu_data.get('excludes', {'files': [], 'directories': []})
            excluded_dirs = excludes.get('directories', [])
            excluded_files = excludes.get('files', [])

            # Discover subdirectories and scripts
            try:
                for item in sorted(os.listdir(directory_path)):
                    if item.startswith('.') or item == 'menu.toml':
                        continue

                    item_path = os.path.join(directory_path, item)
                    item_relative = os.path.join(relative_path, item) if relative_path else item

                    if os.path.isdir(item_path):
                        # Check if directory should be excluded
                        if item not in excluded_dirs:
                            # Recursively discover subdirectory
                            self._discover_directory(item_path, item_relative)

                            # Check if subdirectory has a menu
                            sub_menu_path = os.path.join(item_path, "menu.toml")
                            if os.path.exists(sub_menu_path):
                                self.discovered_menus[menu_key]['submenus'].append({
                                    'name': item,
                                    'path': item_relative,
                                    'display_name': self._create_display_name(item)
                                })

                    elif item.endswith('.sh') and os.path.isfile(item_path):
                        # Check if script should be excluded
                        if item not in excluded_files:
                            self.discovered_menus[menu_key]['scripts'].append({
                                'name': item,
                                'path': item_path,
                                'display_name': self._create_display_name(item.replace('.sh', ''))
                            })

            except PermissionError:
                self.ui.display_error(f"Permission denied accessing {directory_path}")

    def _parse_toml_file(self, toml_path: str) -> Dict:
        """Parse a TOML file using our simplified parser"""
        try:
            data = {}
            current_section = None

            with open(toml_path, 'r') as f:
                for line in f:
                    line = line.strip()

                    # Skip comments and empty lines
                    if not line or line.startswith('#'):
                        continue

                    # Section headers
                    if line.startswith('[') and line.endswith(']'):
                        current_section = line[1:-1]
                        if current_section not in data:
                            data[current_section] = {}
                        continue

                    # Key-value pairs
                    if '=' in line and current_section:
                        key, value = line.split('=', 1)
                        key = key.strip().strip('"')
                        value = value.strip().strip('"')

                        # Handle arrays (basic support)
                        if value.startswith('[') and value.endswith(']'):
                            value = [v.strip().strip('"') for v in value[1:-1].split(',') if v.strip()]

                        data[current_section][key] = value

            return data

        except Exception as e:
            self.ui.display_error(f"Error parsing {toml_path}: {e}")
            return {}

    def _create_display_name(self, name: str) -> str:
        """Create a human-readable display name from a filename/directory name"""
        # Replace hyphens and underscores with spaces, then title case
        display_name = name.replace('-', ' ').replace('_', ' ')
        return ' '.join(word.capitalize() for word in display_name.split())

    def get_menu_options(self, menu_key: str = "main") -> Tuple[str, str, List[Dict]]:
        """Get menu options for a specific menu"""
        if menu_key not in self.discovered_menus:
            raise KeyError(f"Menu not found: {menu_key}")

        menu = self.discovered_menus[menu_key]
        menu_data = menu['data']

        # Get menu info
        menu_info = menu_data.get('menu', {})
        menu_name = menu_info.get('name', self._create_display_name(menu_key))
        menu_description = menu_info.get('description', '')

        # Get display overrides
        display_overrides = menu_data.get('display', {})

        options = []

        # Add scripts first
        for script in menu['scripts']:
            display_name = display_overrides.get(script['name'], script['display_name'])
            options.append({
                'display': display_name,
                'action': 'script',
                'target': script['path'],
                'description': f"Execute {display_name}"
            })

        # Add submenus
        for submenu in menu['submenus']:
            display_name = display_overrides.get(submenu['name'] + '/', submenu['display_name'])
            options.append({
                'display': display_name,
                'action': 'submenu',
                'target': submenu['path'],
                'description': f"Navigate to {display_name}"
            })

        # Add navigation options
        if menu_key != "main":
            options.append({
                'display': '← Back',
                'action': 'back',
                'target': self._get_parent_menu_key(menu_key),
                'description': 'Return to previous menu'
            })

        options.append({
            'display': 'Exit Archer',
            'action': 'exit',
            'target': '',
            'description': 'Exit the application'
        })

        return menu_name, menu_description, options

    def _get_parent_menu_key(self, menu_key: str) -> str:
        """Get the parent menu key for navigation"""
        if '/' not in menu_key:
            return "main"

        parent_parts = menu_key.split('/')[:-1]
        return '/'.join(parent_parts) if parent_parts else "main"

    def run_menu(self, menu_key: str = "main") -> None:
        """Run the interactive menu system starting from specified menu"""
        try:
            while True:
                menu_name, menu_description, options = self.get_menu_options(menu_key)

                choice = self.ui.display_menu(menu_name, menu_description, options)

                if choice >= len(options):
                    break

                selected_option = options[choice]
                action = selected_option['action']
                target = selected_option['target']

                if action == 'exit':
                    # Exit the entire application
                    return 'exit'
                elif action == 'back':
                    menu_key = target
                elif action == 'submenu':
                    # Navigate to submenu
                    result = self.run_menu(target)
                    if result == 'exit':
                        return 'exit'
                elif action == 'script':
                    # Execute script
                    self._execute_script(selected_option, target)
                else:
                    self.ui.display_error(f"Unknown action: {action}")

        except Exception as e:
            self.ui.display_error(f"Menu error: {e}")

    def _execute_script(self, option: Dict, script_path: str) -> None:
        """Execute a script with progress indication"""
        script_name = option['display']

        if not self.ui.confirm_action(f"Execute {script_name}?"):
            self.ui.console.print("[yellow]Operation cancelled[/yellow]")
            return

        # Check if script exists
        if not os.path.exists(script_path):
            self.ui.display_error(f"Script not found: {script_path}")
            return

        # Make the script executable
        os.chmod(script_path, 0o755)

        # Execute with progress
        success = self.ui.show_progress(
            f"Installing {script_name}",
            f"cd '{self.archer_dir}' && bash '{script_path}'"
        )

        if success:
            self.ui.display_success(f"{script_name} installed successfully!")
        else:
            self.ui.display_error(f"Failed to install {script_name}")

        # Wait for user to continue
        Prompt.ask("\n[dim]Press Enter to continue[/dim]", default="")

    def print_discovered_structure(self):
        """Debug method to print the discovered menu structure"""
        self.ui.console.print("\n[bold blue]Discovered Menu Structure:[/bold blue]")

        from rich.tree import Tree
        tree = Tree("📁 Install Directory")

        def add_menu_to_tree(parent_node, menu_key, menu_data):
            menu_info = menu_data['data'].get('menu', {})
            menu_name = menu_info.get('name', menu_key)

            menu_node = parent_node.add(f"📋 {menu_name}")

            # Add scripts
            for script in menu_data['scripts']:
                menu_node.add(f"🔧 {script['display_name']}")

            # Add submenus
            for submenu in menu_data['submenus']:
                submenu_key = submenu['path']
                if submenu_key in self.discovered_menus:
                    add_menu_to_tree(menu_node, submenu_key, self.discovered_menus[submenu_key])

        # Start with main menu
        if "main" in self.discovered_menus:
            add_menu_to_tree(tree, "main", self.discovered_menus["main"])

        self.ui.console.print(tree)


def main():
    """Main entry point"""
    # Set up environment
    archer_dir = str(Path(__file__).parent.parent)
    os.environ['ARCHER_DIR'] = archer_dir
    os.chdir(archer_dir)

    # Initialize UI and menu system
    ui = ArcherUI()
    menu = ArcherMenu(ui)

    try:
        # Display banner
        ui.print_banner()

        # Debug option: show discovered structure if requested
        if len(sys.argv) > 1 and sys.argv[1] == '--debug':
            menu.print_discovered_structure()
            return

        # Check if we're running as root (optional warning)
        if os.geteuid() == 0:
            ui.console.print("[yellow]Warning: Running as root. Some operations may not work as expected.[/yellow]\n")

        # Show system info
        try:
            with open('/etc/os-release', 'r') as f:
                os_info = f.read()
                if 'Arch Linux' in os_info:
                    ui.display_info("System Detected", "✓ Arch Linux detected - ready to proceed!")
                else:
                    ui.display_info("System Detected", "⚠️ Non-Arch system detected - some features may not work")
        except:
            pass

        # Start the main menu
        result = menu.run_menu()

        # Goodbye message
        ui.console.print("\n[bold blue]Thank you for using Archer Linux Enhancement Suite![/bold blue]")

    except KeyboardInterrupt:
        ui.console.print("\n[yellow]Operation cancelled by user[/yellow]")
        sys.exit(0)
    except Exception as e:
        ui.display_error(f"Unexpected error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()

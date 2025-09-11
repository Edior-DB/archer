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
from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn, TimeElapsedColumn, MofNCompleteColumn, TaskProgressColumn
from rich.live import Live
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

    def show_multi_package_progress(self, description: str, packages: List[str], command_template: str) -> bool:
        """Show nala-style multi-package installation progress"""
        self.console.print(f"\n[bold blue]📦 {description}[/bold blue]")
        self.console.print(f"[dim]Installing {len(packages)} packages[/dim]\n")

        # Create nala-style multi-progress display
        with Progress(
            TextColumn("[bold blue]{task.description}"),
            BarColumn(bar_width=30),
            TaskProgressColumn(),
            TextColumn("•"),
            TimeElapsedColumn(),
            TextColumn("•"),
            TextColumn("[cyan]{task.fields[status]}"),
            console=self.console,
            transient=False,
            expand=False
        ) as progress:

            # Overall progress
            overall_task = progress.add_task(
                f"[bold]{description}",
                total=len(packages),
                status="Starting..."
            )

            success_count = 0
            failed_packages = []

            for i, package in enumerate(packages, 1):
                # Create task for this package
                package_task = progress.add_task(
                    f"  [{i}/{len(packages)}] {package}",
                    total=100,
                    status="Queued"
                )

                # Execute package installation
                command = command_template.format(package=package)
                process = subprocess.Popen(
                    command,
                    shell=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True,
                    bufsize=1,
                    universal_newlines=True
                )

                progress.update(package_task, completed=10, status="Downloading")

                output_lines = []
                package_progress = 10

                while True:
                    output = process.stdout.readline()
                    if output == '' and process.poll() is not None:
                        break

                    if output:
                        line = output.strip()
                        output_lines.append(line)
                        line_lower = line.lower()

                        # Update progress based on output
                        if 'downloading' in line_lower:
                            package_progress = min(package_progress + 5, 40)
                            progress.update(package_task, completed=package_progress, status="Downloading")
                        elif 'installing' in line_lower:
                            package_progress = min(package_progress + 10, 80)
                            progress.update(package_task, completed=package_progress, status="Installing")
                        elif 'configuring' in line_lower:
                            package_progress = min(package_progress + 5, 90)
                            progress.update(package_task, completed=package_progress, status="Configuring")

                return_code = process.poll()

                if return_code == 0:
                    progress.update(
                        package_task,
                        completed=100,
                        status="✓ Installed"
                    )
                    success_count += 1
                else:
                    progress.update(
                        package_task,
                        completed=package_progress,
                        status="✗ Failed"
                    )
                    failed_packages.append(package)

                # Update overall progress
                progress.update(
                    overall_task,
                    completed=i,
                    status=f"Processing ({success_count}/{i} successful)"
                )

                time.sleep(0.1)  # Brief pause between packages

            # Final status
            if success_count == len(packages):
                progress.update(
                    overall_task,
                    status=f"✓ All {len(packages)} packages installed"
                )
                self.console.print(f"\n[bold green]✓ All packages installed successfully![/bold green]")
                return True
            else:
                progress.update(
                    overall_task,
                    status=f"⚠ {success_count}/{len(packages)} successful"
                )
                self.console.print(f"\n[bold yellow]⚠ {success_count}/{len(packages)} packages installed[/bold yellow]")
                if failed_packages:
                    self.console.print(f"[red]Failed packages: {', '.join(failed_packages)}[/red]")
                return success_count > 0

    def show_progress(self, description: str, command: str) -> bool:
        """Show progress while executing a command with nala-style interface"""
        self.console.print(f"\n[bold blue]� {description}[/bold blue]")
        self.console.print(f"[dim]Command: {command}[/dim]\n")

        # Create nala-style progress display
        with Progress(
            TextColumn("[bold blue]{task.description}"),
            BarColumn(bar_width=40),
            TaskProgressColumn(),
            TextColumn("•"),
            TimeElapsedColumn(),
            TextColumn("•"),
            TextColumn("[cyan]{task.fields[status]}"),
            console=self.console,
            transient=False,
            expand=False
        ) as progress:

            # Main task for overall progress
            main_task = progress.add_task(
                f"[bold]{description}",
                total=100,
                status="Initializing..."
            )

            # Subtask for current operation
            sub_task = progress.add_task(
                "  └─ Preparing...",
                total=100,
                status="Starting"
            )

            # Start the subprocess with real-time output
            process = subprocess.Popen(
                command,
                shell=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
                universal_newlines=True
            )

            # Progress tracking variables
            output_lines = []
            main_progress = 0
            sub_progress = 0
            current_operation = "Starting"
            operations_seen = set()

            while True:
                output = process.stdout.readline()
                if output == '' and process.poll() is not None:
                    break

                if output:
                    line = output.strip()
                    output_lines.append(line)

                    # Keep only last 50 lines
                    if len(output_lines) > 50:
                        output_lines = output_lines[-25:]

                    # Parse different types of operations for progress estimation
                    line_lower = line.lower()

                    # Detect different phases
                    if any(keyword in line_lower for keyword in ['downloading', 'download']):
                        if 'downloading' not in operations_seen:
                            operations_seen.add('downloading')
                            main_progress = min(main_progress + 20, 90)
                        current_operation = "Downloading"
                        sub_progress = min(sub_progress + 15, 100)

                    elif any(keyword in line_lower for keyword in ['installing', 'install']):
                        if 'installing' not in operations_seen:
                            operations_seen.add('installing')
                            main_progress = min(main_progress + 25, 90)
                        current_operation = "Installing"
                        sub_progress = min(sub_progress + 20, 100)

                    elif any(keyword in line_lower for keyword in ['building', 'compiling', 'compile']):
                        if 'building' not in operations_seen:
                            operations_seen.add('building')
                            main_progress = min(main_progress + 30, 90)
                        current_operation = "Building"
                        sub_progress = min(sub_progress + 10, 100)

                    elif any(keyword in line_lower for keyword in ['configuring', 'configure']):
                        if 'configuring' not in operations_seen:
                            operations_seen.add('configuring')
                            main_progress = min(main_progress + 15, 90)
                        current_operation = "Configuring"
                        sub_progress = min(sub_progress + 25, 100)

                    elif any(keyword in line_lower for keyword in ['extracting', 'extract']):
                        if 'extracting' not in operations_seen:
                            operations_seen.add('extracting')
                            main_progress = min(main_progress + 10, 90)
                        current_operation = "Extracting"
                        sub_progress = min(sub_progress + 30, 100)

                    elif any(keyword in line_lower for keyword in ['processing', 'process']):
                        current_operation = "Processing"
                        sub_progress = min(sub_progress + 5, 100)

                    elif any(keyword in line_lower for keyword in ['complete', 'finished', 'done', 'success']):
                        current_operation = "Completing"
                        main_progress = min(main_progress + 10, 100)
                        sub_progress = 100

                    # Update progress bars
                    progress.update(
                        main_task,
                        completed=main_progress,
                        status=f"{current_operation}..."
                    )

                    # Show current package/file being processed
                    if len(line) > 0:
                        # Extract package name or file name if visible
                        display_line = line[:50] + "..." if len(line) > 50 else line
                        progress.update(
                            sub_task,
                            description=f"  └─ {current_operation}: {display_line}",
                            completed=sub_progress,
                            status="Active"
                        )

                    # Small delay to make progress visible
                    time.sleep(0.05)

            # Complete the progress
            return_code = process.poll()

            if return_code == 0:
                progress.update(
                    main_task,
                    completed=100,
                    status="✓ Completed"
                )
                progress.update(
                    sub_task,
                    description="  └─ Installation successful",
                    completed=100,
                    status="✓ Done"
                )
                time.sleep(0.5)  # Brief pause to show completion

                self.console.print(f"\n[bold green]✓ {description} completed successfully![/bold green]")
                return True
            else:
                progress.update(
                    main_task,
                    completed=main_progress,
                    status="✗ Failed"
                )
                progress.update(
                    sub_task,
                    description="  └─ Installation failed",
                    completed=sub_progress,
                    status="✗ Error"
                )
                time.sleep(0.5)

                self.console.print(f"\n[bold red]✗ {description} failed (exit code: {return_code})[/bold red]")

                # Show last few lines of output for debugging
                if output_lines:
                    self.console.print("\n[yellow]Last output:[/yellow]")
                    for line in output_lines[-5:]:  # Show last 5 lines
                        self.console.print(f"  [dim]{line}[/dim]")

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

        # Show script info
        self.ui.display_info(
            f"About to execute: {script_name}",
            f"Script location: {script_path}\n"
            f"This will install/configure: {script_name}\n\n"
            f"⚠️  Some installations may require sudo privileges"
        )

        if not self.ui.confirm_action(f"Execute {script_name}?"):
            self.ui.console.print("[yellow]Operation cancelled[/yellow]")
            return

        # Check if script exists
        if not os.path.exists(script_path):
            self.ui.display_error(f"Script not found: {script_path}")
            return

        # Make the script executable
        try:
            os.chmod(script_path, 0o755)
        except PermissionError:
            self.ui.display_error(f"Cannot make script executable: {script_path}")
            return

        # Execute with progress and real-time feedback
        success = self.ui.show_progress(
            f"Installing {script_name}",
            f"cd '{self.archer_dir}' && bash '{script_path}'"
        )

        if success:
            self.ui.display_success(f"{script_name} installed successfully!")

            # Offer to view installation log if available
            log_files = [
                os.path.join(self.archer_dir, 'logs', f"{script_name.lower().replace(' ', '_')}.log"),
                f"/tmp/archer_{script_name.lower().replace(' ', '_')}.log"
            ]

            for log_file in log_files:
                if os.path.exists(log_file):
                    if self.ui.confirm_action(f"View installation log?"):
                        with open(log_file, 'r') as f:
                            log_content = f.read()
                            self.ui.display_info("Installation Log", log_content[-2000:])  # Last 2000 chars
                    break
        else:
            self.ui.display_error(f"Failed to install {script_name}")

            # Offer troubleshooting suggestions
            self.ui.display_info(
                "Troubleshooting",
                "Common solutions:\n"
                "• Check internet connection\n"
                "• Ensure you have sufficient disk space\n"
                "• Try running with sudo if permission errors occurred\n"
                "• Check if the package repository is available\n"
                f"• Manually run: bash '{script_path}' for detailed output"
            )

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

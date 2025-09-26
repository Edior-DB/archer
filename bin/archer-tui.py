#!/usr/bin/env python3
"""
Archer Linux Enhancement Suite - Textual TUI Implementation
Reusing the existing ArcherMenu discovery system with enhanced TUI interface
"""

from textual.app import App, ComposeResult
from textual.containers import Container, Horizontal, Vertical, ScrollableContainer
from textual.widgets import (
    Header, Footer, Tree, DataTable, RadioSet, RadioButton,
    Checkbox, ProgressBar, Static, RichLog, Button, Select
)
from textual.widget import Widget
from textual.reactive import reactive
from textual.message import Message
from textual import events
import asyncio
import os
import sys
import subprocess
import time
import shutil
from pathlib import Path
from typing import Dict, List, Optional, Tuple

# Add the bin directory to Python path to import archer
sys.path.insert(0, str(Path(__file__).parent))

# Import our existing ArcherMenu and ArcherUI classes
from archer import ArcherMenu, ArcherUI

# Minimum terminal dimensions
MIN_COLUMNS = 100
MIN_ROWS = 25



class DynamicPackageTable(Widget):
    """A widget that displays packages in a data table with checkboxes"""

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self._packages = []
        self._selected_package_indices = set()  # Track by index instead of dict

    @property
    def packages(self):
        return self._packages

    @packages.setter
    def packages(self, value):
        self._packages = value or []
        self._selected_package_indices.clear()  # Clear selections when packages change
        self._refresh_table()

    def compose(self) -> ComposeResult:
        """Create the data table"""
        # Just two columns: Select and Package
        yield DataTable(id="package_table", show_header=True, zebra_stripes=True)

    def _refresh_table(self):
        """Refresh the table with current packages"""
        table = self.query_one("#package_table", DataTable)
        table.clear(columns=True)

        if not self._packages:
            # Create empty table with headers
            table.add_columns("Select", "Package")
            return

        # Add columns
        table.add_columns("☐", "Package")  # Use checkbox symbols for Select column

        # Add rows
        for i, package in enumerate(self._packages):
            display_name = package.get('display', 'Unknown Package')
            # If package is disabled, gray it out
            if package.get('disabled', False):
                display_name = f"[dim]{display_name}[/dim]"
            checkbox = "☑" if i in self._selected_package_indices else "☐"
            table.add_row(checkbox, display_name)

    def on_data_table_cell_selected(self, event: DataTable.CellSelected):
        """Handle cell selection (toggle checkbox when Select column is clicked)"""
        if event.coordinate.column == 0:  # Select column
            # Get the package index at this row
            package_index = event.coordinate.row

            # Toggle selection
            if package_index in self._selected_package_indices:
                self._selected_package_indices.remove(package_index)
            else:
                self._selected_package_indices.add(package_index)

            # Refresh the table to update checkbox display
            self._refresh_table()

    def get_selected_packages(self):
        """Get list of currently selected packages"""
        return [self._packages[i] for i in self._selected_package_indices if i < len(self._packages)]

    def clear_selection(self):
        """Clear all package selections"""
        self._selected_package_indices.clear()
        self._refresh_table()
class InstallationOutputPanel(Container):
    """Fixed-size output panel for installation logs"""

    def compose(self) -> ComposeResult:
        yield Static("Installation Output:", classes="panel-title")
        yield RichLog(
            id="install_log",
            max_lines=8,  # Fixed number of lines
            wrap=True,
            highlight=True,
            markup=True
        )

    def add_output(self, text: str):
        """Add text to the installation output"""
        log = self.query_one("#install_log", RichLog)
        timestamp = time.strftime("%H:%M:%S")
        log.write(f"[dim]{timestamp}[/dim] {text}")


class ArcherMenuTree(Tree):
    """Enhanced tree that uses the existing ArcherMenu discovery system"""

    class MenuSelected(Message):
        """Message sent when a menu item is selected"""
        def __init__(self, menu_key: str, options: List[Dict]) -> None:
            self.menu_key = menu_key
            self.options = options
            super().__init__()

    def __init__(self, archer_menu: ArcherMenu):
        super().__init__("🏹 Archer Categories")
        self.archer_menu = archer_menu
        self.root.expand()
        self._build_tree_from_menu()

    def _build_tree_from_menu(self):
        """Build the tree using the existing ArcherMenu discovery system"""
        # Get the discovered menu structure
        menus = self.archer_menu.discovered_menus

        # Build tree hierarchy based on menu keys
        menu_nodes = {}

        for menu_key, menu_data in menus.items():
            if menu_key == "main":
                continue  # Skip main menu as it's the root

            # Create hierarchical structure based on menu key path
            path_parts = menu_key.split('/')
            current_parent = self.root

            # Build the path incrementally
            for i, part in enumerate(path_parts):
                current_path = '/'.join(path_parts[:i+1])

                if current_path not in menu_nodes:
                    # Create display name from the part
                    display_name = self._create_display_name(part)
                    icon = self._get_menu_icon(current_path, menu_data)

                    node = current_parent.add(f"{icon} {display_name}", expand=False)
                    # Store the EXACT menu key that ArcherMenu expects
                    node.data = {
                        "menu_key": current_path,  # This should match the discovered_menus keys
                        "menu_data": menu_data
                    }
                    menu_nodes[current_path] = node

                current_parent = menu_nodes[current_path]

    def _create_display_name(self, name: str) -> str:
        """Create a display name from a menu key part"""
        return name.replace('-', ' ').replace('_', ' ').title()

    def _get_menu_icon(self, menu_key: str, menu_data: Dict) -> str:
        """Get an appropriate icon for the menu"""
        key_lower = menu_key.lower()

        if 'development' in key_lower:
            return '💻'
        elif 'system' in key_lower:
            return '⚙️'
        elif 'desktop' in key_lower:
            return '🖥️'
        elif 'gaming' in key_lower or 'game' in key_lower:
            return '🎮'
        elif 'multimedia' in key_lower or 'media' in key_lower:
            return '🎬'
        elif 'network' in key_lower:
            return '🌐'
        elif 'security' in key_lower:
            return '🔒'
        elif 'terminal' in key_lower:
            return '💻'
        elif 'database' in key_lower:
            return '🗃️'
        elif 'font' in key_lower:
            return '🔤'
        else:
            return '📁'

    def on_tree_node_selected(self, event: Tree.NodeSelected) -> None:
        """Handle menu selection"""
        node = event.node

        # Debug: Always log when a node is selected
        print(f"DEBUG: Tree node selected: {node.label}")

        if hasattr(node, 'data') and node.data:
            menu_key = node.data["menu_key"]
            print(f"DEBUG: Menu key: {menu_key}")

            # Get menu options using the existing ArcherMenu system with filtering
            try:
                _, _, options = self.archer_menu.get_menu_options_filtered(menu_key)
                print(f"DEBUG: Found {len(options)} options for {menu_key}")
                self.post_message(self.MenuSelected(menu_key, options))
            except Exception as e:
                print(f"DEBUG: Error getting options for {menu_key}: {e}")
                # If menu doesn't exist or has no options, try to get any child menus
                options = []
                self.post_message(self.MenuSelected(menu_key, options))
        else:
            print(f"DEBUG: Node has no data: {node}")


class ProgressPanel(Container):
    """Progress panel for installation progress only (no buttons)"""

    visible = reactive(False)

    def compose(self) -> ComposeResult:
        yield Static("Installation Progress:", classes="panel-title")
        yield ProgressBar(total=100, show_eta=True, id="main_progress")

    def watch_visible(self, visible):
        """Show/hide the container based on visibility"""
        self.display = visible

    def show_panel(self):
        """Show this panel"""
        self.visible = True

    def hide_panel(self):
        """Hide this panel"""
        self.visible = False


class ActionButtonsPanel(Container):
    """Bottom panel containing all action buttons with neutral colors"""

    def compose(self) -> ComposeResult:
        yield Static("Actions:", classes="panel-title")
        with Horizontal(classes="button-container"):
            yield Button(label="INSTALL NOW", id="install_btn")
            yield Button(label="QUEUE IT", id="queue_btn")
            yield Button(label="CLEAR ALL", id="clear_btn")
            yield Button(label="INSTALL ALL", id="install_all_btn")


class ArcherTUIApp(App):
    """Main Archer TUI Application"""

    TITLE = "🏹 Archer Linux Enhancement Suite - TUI"

    current_menu_key = reactive("")
    current_options = reactive([])
    installation_mode = reactive("install_all")

    def __init__(self):
        super().__init__()
        self.archer_dir = os.environ.get('ARCHER_DIR', str(Path(__file__).parent.parent))

        # Initialize the existing ArcherMenu system
        self.archer_ui = ArcherUI(verbose=False)
        self.archer_menu = ArcherMenu(self.archer_ui)

    def compose(self) -> ComposeResult:
        """Create the application layout"""
        yield Header()
        with Horizontal():
            with Vertical(id="left_panel"):
                tree = ArcherMenuTree(self.archer_menu)
                tree.id = "menu_tree"
                yield tree
                yield InstallationOutputPanel(id="output_panel")
            with Vertical(id="right_panel"):
                with Vertical(id="selection_panel"):
                    yield Static("Sub-Topics:", classes="panel-title")
                    yield DataTable(id="subtopics_panel", show_header=False, zebra_stripes=True)
                yield Static("Select Tools and Packages:", classes="panel-title")
                yield DynamicPackageTable(id="package_panel")
                yield ActionButtonsPanel(id="actions_panel")
                yield ProgressPanel(id="progress_panel")

    CSS = """
    Screen {
        layout: vertical;
        padding: 1;
    }
    Horizontal {
        width: 100%;
        height: 100%;
    }
    #left_panel {
        width: 33%;
        min-width: 30%;
        max-width: 33%;
        height: 100%;
        border: solid $primary;
        layout: vertical;
    }
    #right_panel {
        width: 67%;
        min-width: 67%;
        max-width: 70%;
        height: 100%;
        border: solid $secondary;
        layout: vertical;
    }
    #selection_panel {
        height: 10%;
        min-height: 6;
        max-height: 20%;
        border-bottom: solid $primary-lighten-2;
    }
    #subtopics_panel {
        height: 6;
        min-height: 6;
        max-height: 12;
    }
    #package_panel {
        height: 40%;
        min-height: 12;
        max-height: 50%;
    }
    #actions_panel {
        height: 8%;
        min-height: 3;
        max-height: 12%;
        border-top: solid $primary-lighten-2;
    }
    #progress_panel {
        height: 8%;
        min-height: 3;
        max-height: 12%;
        border-top: solid $success-lighten-2;
    }
    #menu_tree {
        height: 60%;
        min-height: 12;
    }
    #output_panel {
        height: 40%;
        min-height: 8;
    }
    """

    def on_archer_menu_tree_menu_selected(self, message: ArcherMenuTree.MenuSelected):
        """Handle menu selection from tree"""
        self.current_menu_key = message.menu_key
        self.current_options = message.options
        output = self.query_one("#output_panel", InstallationOutputPanel)
        package_panel = self.query_one("#package_panel", DynamicPackageTable)
        subtopics_table = self.query_one("#subtopics_panel", DataTable)

        # Determine if this is a top-level menu (main topic)
        is_top_level = '/' not in message.menu_key
        if is_top_level:
            # Show sub-topics in subtopics_table (single-select)
            submenus = [
                k.split('/')[-1].replace('-', ' ').title()
                for k in self.archer_menu.discovered_menus.keys()
                if k.startswith(message.menu_key + '/') and k.count('/') == 1
            ]
            subtopics_table.clear(columns=True)
            subtopics_table.add_columns("Sub-Topic")
            for submenu in submenus:
                subtopics_table.add_row(submenu)
            subtopics_table.visible = True
            package_panel.visible = False
            output.add_output(f"[blue]Selected main topic:[/blue] {message.menu_key}")
            output.add_output(f"[green]Sub-topics presented: {', '.join(submenus)}[/green]")
        else:
            # Show toolsets in package_panel (multi-select)
            package_panel.packages = message.options
            package_panel.visible = True
            subtopics_table.visible = False
            output.add_output(f"[blue]Selected sub-topic:[/blue] {message.menu_key}")
            output.add_output(f"[green]Toolsets presented: {len(message.options)} options[/green]")
            for opt in message.options:
                output.add_output(f"[dim]- {opt.get('display', 'Unknown')}[/dim]")
    def _handle_subtopic_selection(self, subtopic):
        """Shared logic for subtopic selection events"""
        output = self.query_one("#output_panel", InstallationOutputPanel)
        package_panel = self.query_one("#package_panel", DynamicPackageTable)
        subtopics_table = self.query_one("#subtopics_panel", DataTable)

        # Find the menu_key for the selected subtopic (robust mapping)
        matched_key = None
        for k in self.archer_menu.discovered_menus.keys():
            if k.split('/')[-1].replace('-', ' ').title() == subtopic:
                matched_key = k
                break

        if matched_key:
            _, _, options = self.archer_menu.get_menu_options_filtered(matched_key)
            self.current_menu_key = matched_key
            self.current_options = options
            package_panel.packages = options
            package_panel.visible = True
            subtopics_table.visible = False
            output.add_output(f"[blue]Selected sub-topic:[/blue] {subtopic}")
            output.add_output(f"[green]Toolsets presented: {len(options)} options[/green]")
            for opt in options:
                output.add_output(f"[dim]- {opt.get('display', 'Unknown')}[/dim]")
        else:
            package_panel.packages = []
            package_panel.visible = False
            output.add_output(f"[red]No toolsets found for sub-topic: {subtopic}[/red]")

    def on_data_table_row_selected(self, event: DataTable.RowSelected):
        """Handle single selection in Sub-Topics panel and show corresponding toolsets"""
        subtopic = event.row[0]
        self._handle_subtopic_selection(subtopic)

    def on_data_table_row_highlighted(self, event: DataTable.RowHighlighted):
        """Handle row highlight in Sub-Topics panel and show corresponding toolsets"""
        subtopic = event.row[0]
        self._handle_subtopic_selection(subtopic)

    def _update_package_panel_visibility(self):
        """Show/hide package panel based on selection mode"""
        package_panel = self.query_one("#package_panel", DynamicPackageTable)
        output = self.query_one("#output_panel", InstallationOutputPanel)

        if self.installation_mode == "choose_individual" and self.current_options:
            package_panel.visible = True
            output.add_output(f"[green]Package selection table shown with {len(self.current_options)} packages[/green]")
        else:
            package_panel.visible = False
            output.add_output(f"[dim]Package selection table hidden (mode: {self.installation_mode})[/dim]")

    async def on_button_pressed(self, event: Button.Pressed) -> None:
        """Handle button presses"""
        output = self.query_one("#output_panel", InstallationOutputPanel)
        progress_panel = self.query_one("#progress_panel", ProgressPanel)
        progress = self.query_one("#main_progress", ProgressBar)

        # Debug: Always show when any button is pressed
        output.add_output(f"[dim]DEBUG: Button pressed: {event.button.id}[/dim]")

        if event.button.id == "install_btn":
            package_panel = self.query_one("#package_panel", DynamicPackageTable)
            selected_pkgs = package_panel.get_selected_packages()
            output.add_output(f"[dim]DEBUG: Selected packages: {len(selected_pkgs)}[/dim]")
            if not selected_pkgs:
                output.add_output("[red]No packages selected! Check packages in the table first.[/red]")
                return

            progress_panel.show_panel()
            selected_scripts = [pkg.get('script_path') for pkg in selected_pkgs if pkg.get('script_path')]
            output.add_output(f"[green]Installing selected packages:[/green] {', '.join(selected_scripts)}")

            # Invoke install_custom_selection with the selected scripts
            install_dir = selected_pkgs[0].get('install_dir', '') if selected_pkgs else ''
            if install_dir:
                install_sh = os.path.join(install_dir, 'install.sh')
                cmd = f"bash '{install_sh}' --custom {' '.join(selected_scripts)}"
                output.add_output(f"[dim]Executing:[/dim] {cmd}")
                await self._run_command(cmd, install_dir)

        elif event.button.id == "install_all_btn":
            output.add_output(f"[dim]DEBUG: Current options count: {len(self.current_options) if self.current_options else 0}[/dim]")
            if not self.current_options:
                output.add_output("[red]No installation options available! Select a menu first.[/red]")
                return

            progress_panel.show_panel()
            output.add_output(f"[green]Installing all packages from:[/green] {self.current_menu_key}")

            # Invoke install_all_scripts
            install_dir = self.current_options[0].get('install_dir', '') if self.current_options else ''
            if install_dir:
                install_sh = os.path.join(install_dir, 'install.sh')
                cmd = f"bash '{install_sh}' --all"
                output.add_output(f"[dim]Executing:[/dim] {cmd}")
                await self._run_command(cmd, install_dir)

    async def _run_command(self, cmd: str, cwd: str):
        """Run a shell command asynchronously and display output in the log panel"""
        output = self.query_one("#output_panel", InstallationOutputPanel)
        try:
            process = await asyncio.create_subprocess_shell(
                cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.STDOUT,
                cwd=cwd
            )
            while True:
                line = await process.stdout.readline()
                if not line:
                    break
                line_text = line.decode().strip()
                if line_text:
                    output.add_output(f"[dim]{line_text}[/dim]")
            await process.wait()
            if process.returncode != 0:
                output.add_output(f"[red]Command failed with code {process.returncode}[/red]")
            else:
                output.add_output(f"[green]Command completed successfully[/green]")
        except Exception as e:
            output.add_output(f"[red]Error running command: {str(e)}[/red]")
        except Exception as e:
            try:
                output = self.query_one("#output_panel", InstallationOutputPanel)
                output.add_output(f"[red]🚨 EXCEPTION in _install_packages: {str(e)}[/red]")
                output.add_output(f"[red]Exception type: {type(e).__name__}[/red]")
                import traceback
                output.add_output(f"[red]Traceback: {traceback.format_exc()}[/red]")
            except:
                print(f"CRITICAL ERROR: Exception in _install_packages: {e}")
            output.add_output("[bold green]🎉 All installations completed![/bold green]")

    async def _execute_script_async(self, option: Dict, script_path: str, index: int, total: int):
        """Execute installation script asynchronously with progress updates"""
        output = self.query_one("#output_panel", InstallationOutputPanel)

        # Determine the command to run
        command = option.get('command', '')
        if not command and script_path:
            command = f"bash {script_path}"

        if not command:
            raise Exception("No command or script path specified")

        output.add_output(f"[dim]Executing:[/dim] {command}")

        # Run the command asynchronously
        process = await asyncio.create_subprocess_shell(
            command,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.STDOUT,
            cwd=self.archer_dir
        )

        # Read output line by line
        while True:
            line = await process.stdout.readline()
            if not line:
                break

            line_text = line.decode().strip()
            if line_text:
                # Show installation progress in output
                display_line = line_text[:60] + "..." if len(line_text) > 60 else line_text
                output.add_output(f"[dim]{display_line}[/dim]")

        await process.wait()

        if process.returncode != 0:
            raise Exception(f"Script exited with code {process.returncode}")

    async def _simulate_installation(self, package_name: str, index: int, total: int):
        """Simulate installation for testing purposes"""
        output = self.query_one("#output_panel", InstallationOutputPanel)

        phases = ["Downloading", "Installing", "Configuring"]

        for phase in phases:
            output.add_output(f"[dim]{phase} {package_name}...[/dim]")
            await asyncio.sleep(0.5)  # Simulate work


def check_terminal_dimensions():
    """Check if terminal meets minimum dimension requirements"""
    try:
        terminal_size = shutil.get_terminal_size()
        columns, rows = terminal_size.columns, terminal_size.lines

        if columns < MIN_COLUMNS or rows < MIN_ROWS:
            print(f"❌ Terminal too small!")
            print(f"   Current size: {columns}x{rows}")
            print(f"   Required size: {MIN_COLUMNS}x{MIN_ROWS}")
            print(f"   Please resize your terminal and try again.")
            return False

        print(f"✅ Terminal size OK: {columns}x{rows}")
        return True
    except Exception as e:
        print(f"⚠️  Could not determine terminal size: {e}")
        print("   Proceeding anyway...")
        return True


def main():
    """Run the Archer TUI application"""
    import argparse

    parser = argparse.ArgumentParser(description='Archer Linux Enhancement Suite - TUI')
    parser.add_argument('--debug', action='store_true', help='Enable debug mode')
    parser.add_argument('--skip-size-check', action='store_true', help='Skip terminal size check')
    args = parser.parse_args()

    # Check terminal dimensions unless skipped
    if not args.skip_size_check:
        if not check_terminal_dimensions():
            sys.exit(1)

    # Set up environment
    archer_dir = str(Path(__file__).parent.parent)
    os.environ['ARCHER_DIR'] = archer_dir
    os.chdir(archer_dir)

    app = ArcherTUIApp()
    app.run()


if __name__ == "__main__":
    main()

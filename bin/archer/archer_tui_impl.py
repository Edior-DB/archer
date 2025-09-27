#!/usr/bin/env python3
"""Internal TUI implementation module for archer.tui to import.

This module contains the actual Textual application class used by the package
entrypoint `archer.tui`.
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

# Import the package-local lib
from .lib import ArcherMenu, ArcherUI

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
        # Main (global) progress bar
        yield ProgressBar(total=100, show_eta=True, id="main_progress")
        # Per-package progress bar and status
        yield Static("Current task:", id="pkg_status_label")
        yield ProgressBar(total=100, show_eta=False, id="pkg_progress")
        yield Static("", id="pkg_status")

    def watch_visible(self, visible):
        """Show/hide the container based on visibility"""
        self.display = visible

    def show_panel(self):
        """Show this panel"""
        self.visible = True

    def hide_panel(self):
        """Hide this panel"""
        self.visible = False

    def set_pkg_status(self, text: str):
        try:
            lbl = self.query_one("#pkg_status", Static)
            lbl.update(text)
        except Exception:
            pass

    def set_pkg_progress(self, pct: int):
        try:
            bar = self.query_one("#pkg_progress", ProgressBar)
            # clamp
            if pct < 0:
                pct = 0
            if pct > 100:
                pct = 100
            bar.update(pct)
        except Exception:
            pass


class ActionButtonsPanel(Container):
    """Bottom panel containing all action buttons with neutral colors"""

    def compose(self) -> ComposeResult:
        yield Static("Actions:", classes="panel-title")
        with Horizontal(classes="button-container"):
            yield Button(label="INSTALL NOW", id="install_btn")
            yield Button(label="QUEUE IT", id="queue_btn")
            yield Button(label="CLEAR ALL", id="clear_btn")
            yield Button(label="INSTALL ALL", id="install_all_btn")


class SudoModal(Container):
    """A very small modal-like widget asking the user to allow sudo pre-flight."""

    def __init__(self, message: str = "This action requires elevated privileges. Request sudo now?"):
        super().__init__()
        self.message = message

    def compose(self) -> ComposeResult:
        yield Static(self.message, id="sudo_msg")
        with Horizontal():
            yield Button(label="Continue", id="sudo_confirm")
            yield Button(label="Cancel", id="sudo_cancel")

    def on_button_pressed(self, event: Button.Pressed):
        """Set a simple attribute on the modal to indicate the user's choice."""
        btn = event.control
        if btn.id == 'sudo_confirm':
            self.choice = 'confirm'
        elif btn.id == 'sudo_cancel':
            self.choice = 'cancel'


class ArcherTUIApp(App):
    """Main Archer TUI Application"""

    TITLE = "🏹 Archer Linux Enhancement Suite - TUI"

    current_menu_key = reactive("")
    current_options = reactive([])
    installation_mode = reactive("install_all")

    def __init__(self):
        super().__init__()
        # Default to project root (two levels up from bin/archer)
        default_archer_dir = str(Path(__file__).resolve().parents[2])
        self.archer_dir = os.environ.get('ARCHER_DIR', default_archer_dir)

        # Initialize the existing ArcherMenu system
        self.archer_ui = ArcherUI(verbose=False)
        self.archer_menu = ArcherMenu(self.archer_ui)
        # modal state
        self._sudo_modal_active = False

    def compose(self) -> ComposeResult:
        """Create the application layout"""
        yield Header()
        # Top-level split: top_panel (67% height) and bottom_panel (33% height)
        with Vertical(id="root_vertical"):
            with Horizontal(id="top_panel"):
                # Left: main menu (33% width) - simplified to a single-select list
                with Vertical(id="left_panel"):
                    yield Static("Main Menu:", classes="panel-title")
                    yield DataTable(id="menu_list", show_header=False, zebra_stripes=True, show_cursor=True)
                # Right: selection area (67% width) - vertically divided into sub-panels
                with Vertical(id="right_panel"):
                    with Vertical(id="subtopics_container"):
                        yield Static("Sub-Topics:", classes="panel-title")
                        yield DataTable(id="subtopics_panel", show_header=False, zebra_stripes=True, show_cursor=True)
                    with Vertical(id="package_container"):
                        yield Static("Select Tools and Packages:", classes="panel-title")
                        yield DynamicPackageTable(id="package_panel")
                    with Vertical(id="actions_container"):
                        yield ActionButtonsPanel(id="actions_panel")
            # Bottom panel (33% height) split horizontally into output (75%) and progress (25%)
            with Horizontal(id="bottom_panel"):
                yield InstallationOutputPanel(id="output_panel")
                yield ProgressPanel(id="progress_panel")

    async def on_mount(self) -> None:
        """Populate the main menu list on mount using discovered menus (top-level items)."""
        # Build ordered list of top-level menu keys (preserve discovery order)
        menu_list = self.query_one("#menu_list", DataTable)
        menu_list.clear(columns=True)
        menu_list.add_columns("Main Menu")

        self._menu_row_map = {}
        self._menu_row_keys = []
        seen = set()
        order = []
        for menu_key in self.archer_menu.discovered_menus.keys():
            if menu_key == "main":
                continue
            top = menu_key.split('/')[0]
            if top not in seen:
                seen.add(top)
                order.append(top)

        for top_key in order:
            display_name = top_key.replace('-', ' ').replace('_', ' ').title()
            row_key = menu_list.add_row(display_name)
            self._menu_row_map[row_key] = top_key
            self._menu_row_keys.append(row_key)

        # Ensure menu list is focused so keyboard/selection works immediately
        try:
            menu_list.focus()
        except Exception:
            pass

        # Ensure subtopics table exists and is empty initially
        subtopics_table = self.query_one("#subtopics_panel", DataTable)
        subtopics_table.clear(columns=True)
        subtopics_table.add_columns("Sub-Topic")

    def on_data_table_cell_selected(self, event: DataTable.CellSelected):
        """Handle cell selection for both menu_list and subtopics_panel."""
        control_id = event.control.id
        # MENU LIST: select to show sub-topics
        if control_id == "menu_list":
            row_identifier = getattr(event.coordinate, "row_key", None) or event.coordinate.row
            # Delegate to the row-selected logic
            self._handle_menu_selection_by_row(row_identifier)
            return

        # SUBTOPICS: activate subtopic row when selected cell in column 0
        if control_id == "subtopics_panel":
            if event.coordinate.column != 0:
                return
            row_identifier = getattr(event.coordinate, "row_key", None) or event.coordinate.row
            output = self.query_one("#output_panel", InstallationOutputPanel)
            output.add_output(f"[dim]DEBUG: CellSelected row={row_identifier}[/dim]")
            self._activate_subtopic_row(row_identifier)

    def on_data_table_row_selected(self, event: DataTable.RowSelected):
        """Handle row selection for both menu_list and subtopics_panel."""
        control_id = event.control.id
        # MENU LIST selection -> populate subtopics
        if control_id == "menu_list":
            row_identifier = getattr(event, "row_key", None)
            if row_identifier is None:
                row_identifier = getattr(event, "cursor_row", None)
            if row_identifier is None:
                row_identifier = getattr(event, "row_index", None)
            self._handle_menu_selection_by_row(row_identifier)
            return

        # SUBTOPS selection -> activate
        if control_id == "subtopics_panel":
            row_identifier = getattr(event, "row_key", None)
            if row_identifier is None:
                row_identifier = getattr(event, "cursor_row", None)
            if row_identifier is None:
                row_identifier = getattr(event, "row_index", None)
            output = self.query_one("#output_panel", InstallationOutputPanel)
            output.add_output(f"[dim]DEBUG: RowSelected row={row_identifier}[/dim]")
            if row_identifier is not None:
                self._activate_subtopic_row(row_identifier)

    def _handle_menu_selection_by_row(self, row_identifier):
        """Given a menu_list row identifier, populate the subtopics panel with its sub-menus."""
        output = self.query_one("#output_panel", InstallationOutputPanel)
        menu_list = self.query_one("#menu_list", DataTable)
        subtopics_table = self.query_one("#subtopics_panel", DataTable)
        package_panel = self.query_one("#package_panel", DynamicPackageTable)

        if not hasattr(self, '_menu_row_map'):
            output.add_output("[red]DEBUG: No menu row map present[/red]")
            return

        # Resolve row_key
        row_key = None
        if row_identifier in self._menu_row_map:
            row_key = row_identifier
        elif isinstance(row_identifier, int) and hasattr(self, '_menu_row_keys'):
            # Use the ordered keys list we stored on mount
            if 0 <= row_identifier < len(self._menu_row_keys):
                row_key = self._menu_row_keys[row_identifier]
        else:
            identifier_str = str(row_identifier)
            # Try to match by stringified row_key
            for candidate in self._menu_row_map.keys():
                if str(candidate) == identifier_str:
                    row_key = candidate
                    break
            # As a last resort, match against display names stored in the DataTable rows
            if row_key is None:
                # iterate rows to find a display match
                for candidate_key, top_key in self._menu_row_map.items():
                    # attempt to retrieve content at row candidate_key
                    try:
                        cell = menu_list.get_row(candidate_key)
                        if cell and len(cell) > 0 and str(cell[0]) == identifier_str:
                            row_key = candidate_key
                            break
                    except Exception:
                        continue

        if row_key is None:
            output.add_output(f"[red]DEBUG: Menu row {row_identifier} not found[/red]")
            return

        menu_key = self._menu_row_map[row_key]
        try:
            submenus = self.archer_menu.get_sub_menus(menu_key)
        except Exception as e:
            output.add_output(f"[red]Error getting sub-menus for '{menu_key}': {e}[/red]")
            submenus = {}

        # Store for later reverse lookup
        self._current_submenus = submenus
        self._subtopic_row_map = {}
        self._subtopic_row_keys = []
        self._last_highlighted_subtopic_row = None

        subtopics_table.clear(columns=True)
        subtopics_table.add_columns("Sub-Topic")
        for display_name, submenu_key in submenus.items():
            row_key = subtopics_table.add_row(display_name)
            self._subtopic_row_map[row_key] = (submenu_key, display_name)
            self._subtopic_row_keys.append(row_key)

        subtopics_table.visible = True
        package_panel.visible = False
        output.add_output(f"[blue]Selected main topic:[/blue] {menu_key}")
        if submenus:
            output.add_output(f"[green]Sub-topics presented: {', '.join(submenus.keys())}[/green]")
        else:
            output.add_output(f"[dim]No sub-topics available for {menu_key}[/dim]")

    # Subtopic selection: unified logic using row mapping
    def _activate_subtopic_row(self, row_identifier):
        output = self.query_one("#output_panel", InstallationOutputPanel)
        if not hasattr(self, '_subtopic_row_map'):
            output.add_output("[red]DEBUG: No subtopic row map present[/red]")
            return
        row_key = None

        if row_identifier in self._subtopic_row_map:
            row_key = row_identifier
        elif isinstance(row_identifier, int) and hasattr(self, '_subtopic_row_keys'):
            if 0 <= row_identifier < len(self._subtopic_row_keys):
                row_key = self._subtopic_row_keys[row_identifier]
        else:
            identifier_str = str(row_identifier)
            for candidate in self._subtopic_row_map.keys():
                if str(candidate) == identifier_str:
                    row_key = candidate
                    break

        if row_key is None:
            output.add_output(f"[red]DEBUG: Row {row_identifier} not in subtopic map[/red]")
            return

        menu_key, display_name = self._subtopic_row_map[row_key]
        output.add_output(f"[dim]DEBUG: Activating row {row_identifier} -> {menu_key}")
        package_panel = self.query_one("#package_panel", DynamicPackageTable)
        subtopics_table = self.query_one("#subtopics_panel", DataTable)
        try:
            _, _, options = self.archer_menu.get_menu_options_filtered(menu_key)
            self.current_menu_key = menu_key
            self.current_options = options
            package_panel.packages = options
            # Show package panel but keep subtopics visible so user can navigate back
            package_panel.visible = True
            subtopics_table.visible = True
            output.add_output(f"[blue]Selected sub-topic:[/blue] {display_name}")
            output.add_output(f"[green]Toolsets presented: {len(options)} options[/green]")
        except Exception as e:
            package_panel.packages = []
            package_panel.visible = False
            output.add_output(f"[red]Error loading toolsets for '{menu_key}': {e}[/red]")


    def on_data_table_row_highlighted(self, event: DataTable.RowHighlighted):
        # Support both menu_list and subtopics_panel
        if event.control.id == "menu_list":
            # store last highlighted menu row so Enter can activate it
            self._last_highlighted_menu_row = getattr(event, 'row_key', None) or getattr(event, 'row_index', None)
            return
        if event.control.id != "subtopics_panel":
            return
        row_identifier = getattr(event, "row_key", None)
        if row_identifier is None:
            row_identifier = getattr(event, "row_index", None)
        self._last_highlighted_subtopic_row = row_identifier

    def on_key(self, event: events.Key):
        # Enter on highlighted menu -> populate subtopics
        if event.key == "enter":
            # If a menu row is highlighted, activate it
            if hasattr(self, '_last_highlighted_menu_row') and self._last_highlighted_menu_row is not None:
                self._handle_menu_selection_by_row(self._last_highlighted_menu_row)
                return
            # Otherwise, fallback to subtopic activation (existing behavior)
            if hasattr(self, '_last_highlighted_subtopic_row') and self._last_highlighted_subtopic_row is not None:
                self._activate_subtopic_row(self._last_highlighted_subtopic_row)
                return

    CSS = """
    Screen {
        layout: vertical; /* Stack top and bottom panels vertically */
        padding: 1;
    }

    /* Top and bottom parent panels */
    #top_panel {
        height: 67%;
        min-height: 60%;
        max-height: 67%;
        width: 100%;
        border: none;
        layout: horizontal; /* left and right columns */
    }

    #bottom_panel {
        height: 33%;
        min-height: 30%;
        max-height: 33%;
        width: 100%;
        border: none;
        layout: horizontal; /* output and progress side-by-side */
    }


    /* Top-left main menu column */
    #left_panel {
        width: 33%;
        min-width: 33%;
        max-width: 33%;
        height: 100%;
        border: solid $primary;
        layout: vertical;
    }

    /* Top-right column that holds three stacked areas */
    #right_panel {
        width: 67%;
        min-width: 67%;
        max-width: 67%;
        height: 100%;
        border: solid $secondary;
        layout: vertical; /* stack subtopics, package, actions vertically */
    }

    /* The three containers inside the right panel - use percentage heights of right_panel */
    #subtopics_container {
        height: 40%;
        min-height: 40%;
        max-height: 40%;
        width: 100%;
        layout: vertical;
        border-bottom: solid $primary-lighten-2;
    }

    #package_container {
        height: 40%;
        min-height: 40%;
        max-height: 40%;
        width: 100%;
        layout: vertical;
        border-bottom: solid $primary-lighten-2;
    }

    #actions_container {
        height: 20%;
        min-height: 20%;
        max-height: 20%;
        width: 100%;
        layout: vertical;
    }

    /* Ensure inner widgets occupy full width of their containers */
    #subtopics_panel, #package_panel, #actions_panel, #menu_list, #menu_tree {
        width: 100%;
        min-width: 100%;
        max-width: 100%;
    }

    /* Bottom panel children proportions */
    #output_panel {
        width: 75%;
        min-width: 75%;
        max-width: 75%;
        height: 100%;
        border: solid $primary-lighten-2;
        layout: vertical;
    }

    #progress_panel {
        width: 25%;
        min-width: 25%;
        max-width: 25%;
        height: 100%;
        border: solid $secondary-lighten-2;
        layout: vertical;
    }

    /* Visual styling */
    .panel-title {
        dock: top;
        padding: 0 1;
        height: 1;
        content-align: left middle;
        background: $surface;
        color: $text;
        text-style: bold;
    }

    DataTable {
        background: $background;
        border: none;
    }

    DataTable > .header {
        color: $primary-lighten-2;
        text-style: bold;
    }

    RichLog {
        background: $background-darken-1;
        border: solid $primary-lighten-2;
        padding: 1;
    }

    Button {
        margin: 0 1;
    }
    """

    async def _run_install_command(self, description: str, command: str, script_path: str = ""):
        """Run a shell command asynchronously and stream output to the installation panel."""
        output = self.query_one("#output_panel", InstallationOutputPanel)
        progress_panel = self.query_one("#progress_panel", ProgressPanel)

        output.add_output(f"[blue]Starting: {description}[/blue]")
        progress_panel.show_panel()
        # Reset per-package progress/status
        try:
            progress_panel.set_pkg_progress(0)
            progress_panel.set_pkg_status("")
        except Exception:
            pass

        try:
            # Create subprocess
            # Before launching, if this command likely needs sudo/package installs
            # attempt to collect sudo credentials via the shell helper. This
            # runs the helper in a subshell that sources the common functions.
            needs_sudo = any(x in command for x in ("sudo", "pacman", "pacstrap", "yay", "paru", "makepkg"))
            if needs_sudo:
                try:
                    # Build a safe check command that sources common-funcs and
                    # calls archer_request_sudo
                    cli_path = os.path.join(self.archer_dir, 'install', 'system', 'common-funcs.sh')
                    # Run synchronously to get result before starting the installer.
                    # Use an argument list to avoid shell-quoting issues.
                    import subprocess as _sub
                    rc = _sub.run([
                        'bash', '-c', f"source '{cli_path}' >/dev/null 2>&1; archer_request_sudo"
                    ]).returncode
                    if rc != 0:
                        out = self.query_one("#output_panel", InstallationOutputPanel)
                        out.add_output(f"[yellow]Skipping install because sudo credentials could not be obtained (exit {rc}).[/yellow]")
                        progress_panel.hide_panel()
                        return
                except Exception:
                    pass

            # Run child scripts with stdin redirected to DEVNULL so they cannot
            # block waiting for input from the TUI's stdin. Also ensure we
            # propagate environment variables that indicate a TUI context and
            # non-interactive defaults so installers will avoid prompting.
            env = os.environ.copy()
            env.setdefault('ARCHER_TUI', '1')
            # Force AUTO_CONFIRM to 1 for child processes so they don't attempt
            # interactive confirmations in the TUI session.
            env.setdefault('AUTO_CONFIRM', '1')

            proc = await asyncio.create_subprocess_shell(
                command,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.STDOUT,
                stdin=asyncio.subprocess.DEVNULL,
                env=env,
            )

            # Stream stdout lines to the output panel
            assert proc.stdout is not None
            while True:
                line = await proc.stdout.readline()
                if not line:
                    break
                try:
                    text = line.decode('utf-8', errors='replace').rstrip()
                except Exception:
                    text = str(line)

                # Token parsing: ARCHER_PROGRESS: <pct>, ARCHER_STEP: i/n, ARCHER_STATUS: <text>
                stripped = text.strip()
                handled = False
                if stripped.startswith('ARCHER_PROGRESS:'):
                    try:
                        pct = int(stripped.split(':',1)[1].strip())
                        progress_panel.set_pkg_progress(pct)
                        handled = True
                    except Exception:
                        pass
                elif stripped.startswith('ARCHER_STEP:'):
                    # Format i/n -> convert to percent
                    try:
                        parts = stripped.split(':',1)[1].strip().split('/')
                        i = int(parts[0]); n = int(parts[1])
                        pct = int((i / max(1, n)) * 100)
                        progress_panel.set_pkg_progress(pct)
                        handled = True
                    except Exception:
                        pass
                elif stripped.startswith('ARCHER_STATUS:'):
                    try:
                        status = stripped.split(':',1)[1].strip()
                        progress_panel.set_pkg_status(status)
                        handled = True
                    except Exception:
                        pass

                # Heuristic percent parsing if no token
                if not handled:
                    import re
                    m = re.search(r"(\d{1,3})\s?%", stripped)
                    if m:
                        try:
                            pct = int(m.group(1))
                            if 0 <= pct <= 100:
                                progress_panel.set_pkg_progress(pct)
                                handled = True
                        except Exception:
                            pass

                # Always write the output to the log panel
                output.add_output(text)

            rc = await proc.wait()
            if rc == 0:
                output.add_output(f"[green]Completed: {description}[/green]")
            else:
                # Print a concise failure summary to the installation output
                # panel and continue running the TUI without exiting.
                if script_path:
                    output.add_output(f"[red]Script failed: {script_path} (exit {rc})[/red]")
                else:
                    output.add_output(f"[red]Command failed (exit {rc}): {description}[/red]")

        except Exception as e:
            output.add_output(f"[red]Exception running {description}: {e}[/red]")
        finally:
            progress_panel.hide_panel()

    def _command_looks_like_needs_sudo(self, command: str) -> bool:
        """Heuristic: return True if the command or referenced scripts likely need sudo.

        This is intentionally conservative: look for sudo keywords or common package manager
        binaries or file paths that typically require root (e.g., /usr, /etc, pacman).
        """
        check_tokens = ("sudo", "pacman", "pacstrap", "yay", "paru", "makepkg", "dnf", "apt", "/usr/", "/etc/")
        return any(tok in command for tok in check_tokens)

    async def _show_sudo_modal_and_request(self) -> bool:
        """Show the SudoModal and perform `archer_request_sudo` when user confirms.

        Returns True when sudo credentials were obtained (or not needed). Returns False if
        user cancelled or credentials couldn't be obtained.
        """
        output = self.query_one("#output_panel", InstallationOutputPanel)

        # Present a simple modal-like interaction in the output panel by asking user
        # to confirm. We cannot open a true blocking modal easily; instead write a prompt
        # and wait for a button press from the small modal widget we can add to the UI.
        if self._sudo_modal_active:
            return False

        self._sudo_modal_active = True
        try:
            # Add the modal to the app layout (at root) and focus it
            modal = SudoModal()
            await self.mount(modal, after=self.query_one("#root_vertical"))
            # Wait for a button press event by polling the modal's children
            # We'll listen for button presses via events; set up a future.
            fut = asyncio.get_event_loop().create_future()

            async def _wait_for_choice():
                # Busy-wait for modal button to set attribute
                while True:
                    try:
                        btn = modal.query_one("#sudo_confirm")
                    except Exception:
                        btn = None
                    try:
                        cancel = modal.query_one("#sudo_cancel")
                    except Exception:
                        cancel = None
                    # Check whether either was pressed by reading a custom attr
                    if getattr(modal, 'choice', None) is not None:
                        return modal.choice
                    await asyncio.sleep(0.05)

            choice = await _wait_for_choice()
            # Remove modal
            await modal.remove()
            self._sudo_modal_active = False

            if choice == 'confirm':
                # Attempt to source common-funcs.sh and call archer_request_sudo synchronously
                try:
                    cli_path = os.path.join(self.archer_dir, 'install', 'system', 'common-funcs.sh')
                    import subprocess as _sub
                    rc = _sub.run([
                        'bash', '-c', f"source '{cli_path}' >/dev/null 2>&1; archer_request_sudo"
                    ]).returncode
                    if rc == 0:
                        output.add_output("[green]Sudo credentials obtained.[/green]")
                        return True
                    else:
                        output.add_output(f"[yellow]Could not obtain sudo credentials (exit {rc}).[/yellow]")
                        return False
                except Exception as e:
                    output.add_output(f"[red]Error requesting sudo: {e}[/red]")
                    return False
            else:
                output.add_output("[dim]User cancelled sudo request.[/dim]")
                return False
        finally:
            self._sudo_modal_active = False

    async def _install_selected(self):
        """Install packages selected in the DynamicPackageTable sequentially."""
        package_panel = self.query_one("#package_panel", DynamicPackageTable)
        output = self.query_one("#output_panel", InstallationOutputPanel)

        selected = package_panel.get_selected_packages()
        if not selected:
            output.add_output("[yellow]No packages selected to install.[/yellow]")
            return

        # Each selected item is expected to be an option dict from ArcherMenu
        for opt in selected:
            display = opt.get('display', 'Unnamed')
            target = opt.get('target')
            if not target:
                output.add_output(f"[red]No target for {display}, skipping.[/red]")
                continue

            # Build command to run the script in the archer directory
            cmd = f"cd '{self.archer_dir}' && bash '{target}'"
            await self._run_install_command(display, cmd, target)

    async def _install_all_for_current_menu(self):
        """Run the install.sh for the current menu (install_all semantics)."""
        output = self.query_one("#output_panel", InstallationOutputPanel)
        menu_key = getattr(self, 'current_menu_key', None)
        if not menu_key:
            output.add_output("[yellow]No menu selected for Install All.[/yellow]")
            return

        menus = getattr(self.archer_menu, 'discovered_menus', {})
        menu = menus.get(menu_key)
        if not menu:
            output.add_output(f"[red]Menu not found: {menu_key}[/red]")
            return

        menu_dir = os.path.dirname(menu.get('path', ''))
        install_sh = os.path.join(menu_dir, 'install.sh')
        if not os.path.exists(install_sh):
            output.add_output(f"[red]install.sh not found for {menu_key}: {install_sh}[/red]")
            return

        cmd = f"cd '{self.archer_dir}' && bash '{install_sh}' --all"
        await self._run_install_command(f"Install All: {menu_key}", cmd, install_sh)

    def on_button_pressed(self, event: Button.Pressed):
        """Handle action buttons: install, queue, clear, install all."""
        btn_id = event.control.id
        output = self.query_one("#output_panel", InstallationOutputPanel)

        if btn_id == 'clear_btn':
            package_panel = self.query_one("#package_panel", DynamicPackageTable)
            package_panel.clear_selection()
            output.add_output("[dim]Selections cleared[/dim]")
            return

        if btn_id == 'queue_btn':
            # Queueing not implemented yet — just show a message
            output.add_output("[dim]Queueing feature not implemented yet — will install immediately instead.[/dim]")
            # fall through to install selected

        if btn_id == 'install_btn' or btn_id == 'queue_btn':
            # Before starting, check whether selected packages appear to need sudo and
            # request credentials via a modal if so.
            package_panel = self.query_one("#package_panel", DynamicPackageTable)
            selected = package_panel.get_selected_packages()
            # Determine if any selected item likely needs sudo
            needs = False
            for opt in selected:
                target = opt.get('target', '')
                if self._command_looks_like_needs_sudo(target):
                    needs = True
                    break

            async def _maybe_request_and_install():
                if needs:
                    ok = await self._show_sudo_modal_and_request()
                    if not ok:
                        return
                await self._install_selected()

            asyncio.create_task(_maybe_request_and_install())
            return

        if btn_id == 'install_all_btn':
            # For Install All, check the menu's install.sh path for likely sudo needs
            menu_key = getattr(self, 'current_menu_key', None)
            menus = getattr(self.archer_menu, 'discovered_menus', {})
            menu = menus.get(menu_key) if menu_key else None
            install_sh = None
            if menu:
                menu_dir = os.path.dirname(menu.get('path', ''))
                install_sh = os.path.join(menu_dir, 'install.sh')

            async def _maybe_request_and_install_all():
                if install_sh and os.path.exists(install_sh):
                    if self._command_looks_like_needs_sudo(install_sh) or self._command_looks_like_needs_sudo(menu.get('path','')):
                        ok = await self._show_sudo_modal_and_request()
                        if not ok:
                            return
                await self._install_all_for_current_menu()

            asyncio.create_task(_maybe_request_and_install_all())
            return


def check_terminal_dimensions():
    """Check if terminal meets minimum dimension requirements"""
    try:
        terminal_size = shutil.get_terminal_size()
        columns, rows = terminal_size.columns, terminal_size.lines

        if columns < MIN_COLUMNS or rows < MIN_ROWS:
            print(f"❌ Terminal too small: {columns}x{rows} (required {MIN_COLUMNS}x{MIN_ROWS})")
            return False

        print(f"✅ Terminal size OK: {columns}x{rows}")
        return True
    except Exception as e:
        print(f"⚠️  Could not determine terminal size: {e}")
        return True


def main():
    """Run the Archer TUI application with verbose startup logging"""
    import argparse
    import traceback

    parser = argparse.ArgumentParser(description='Archer Linux Enhancement Suite - TUI')
    parser.add_argument('--debug', action='store_true', help='Enable debug mode')
    parser.add_argument('--skip-size-check', action='store_true', help='Skip terminal size check')
    args = parser.parse_args()

    print("[archer-tui] Starting up...")
    print(f"[archer-tui] Python: {sys.executable} {sys.version.splitlines()[0]}")
    print(f"[archer-tui] CWD: {os.getcwd()}")
    print(f"[archer-tui] ARGS: {sys.argv}")

    # Check terminal dimensions unless skipped
    if not args.skip_size_check:
        ok = check_terminal_dimensions()
        if not ok:
            print("[archer-tui] Exiting due to terminal size")
            sys.exit(1)

    # Set up environment: default to project root (two levels up from bin/archer)
    archer_dir = str(Path(__file__).resolve().parents[2])
    os.environ['ARCHER_DIR'] = archer_dir
    try:
        os.chdir(archer_dir)
    except Exception as e:
        print(f"[archer-tui] Could not change directory to {archer_dir}: {e}")

    try:
        app = ArcherTUIApp()
        print("[archer-tui] Running App...")
        app.run()
        print("[archer-tui] App exited normally")
    except SystemExit as se:
        print(f"[archer-tui] SystemExit: {se}")
        raise
    except Exception as e:
        print("[archer-tui] Unhandled exception while running app:")
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()

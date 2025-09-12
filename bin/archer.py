#!/usr/bin/env python3
"""
Archer Linux Enhancement Suite - Python Implementation
A comprehensive system enhancement and software installation tool
"""

import os
import sys
import subprocess
import time
import argparse
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

    def __init__(self, verbose=False):
        self.console = Console()
        self.archer_dir = os.environ.get('ARCHER_DIR', str(Path(__file__).parent.parent))
        self.verbose = verbose

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

    def _detect_installation_type(self, command: str, script_path: str = "") -> str:
        """Detect the type of installation to determine progress display strategy"""
        command_lower = command.lower()

        # Check script content for better detection
        script_content = ""
        if script_path and os.path.exists(script_path):
            try:
                with open(script_path, 'r') as f:
                    script_content = f.read().lower()
            except:
                pass

        combined_text = f"{command_lower} {script_content}"

        # Check for mise first - it has its own excellent progress bars
        mise_patterns = [
            'mise install',
            'mise plugin',
            'curl https://mise.run',
            'eval.*mise.*activate',
            'source.*mise',
            'mise use',
            'mise exec',
        ]
        if any(pattern in combined_text for pattern in mise_patterns):
            return 'mise'

        # Quick installers that don't benefit from detailed progress bars
        quick_patterns = [
            'npm install -g',
            'pip install',
            'cargo install',
            'go install',
            'go get',
            'gem install',
            'luarocks install',
            'curl.*|.*sh',  # Curl pipe to shell installers
            'wget.*|.*sh',  # Wget pipe to shell installers
            'curl.*install',
            'wget.*install',
            'eval.*mise.*activate',
            'source.*mise',
            'sh.rustup.rs',  # Rust installer
            'curl.*sh$',     # Curl ending with sh
        ]

        if any(pattern in combined_text for pattern in quick_patterns):
            return 'quick'

        # Package managers that show detailed progress
        package_manager_patterns = [
            'pacman -s',
            'yay -s',
            'paru -s',
            'apt install',
            'apt-get install',
            'dnf install',
            'zypper install',
            'emerge ',
            'portage',
            'install_with_retries',  # Our custom function
        ]

        if any(pattern in combined_text for pattern in package_manager_patterns):
            return 'package_manager'

        # Compilation/building processes that benefit from detailed progress
        build_patterns = [
            'make ',
            'cmake',
            './configure',
            'meson',
            'ninja',
            'autogen',
            'autoconf',
            'configure && make',
            'build.sh',
            'compile',
            'gcc ',
            'clang ',
        ]

        if any(pattern in combined_text for pattern in build_patterns):
            return 'build'

        # Check for shell script execution
        if 'bash ' in command_lower and '.sh' in command_lower:
            return 'script'

        # Check for specific script types that typically use quick installers
        if script_path:
            script_name = os.path.basename(script_path).lower()
            if any(name in script_name for name in ['go.sh', 'rust.sh', 'node.sh', 'ruby.sh']):
                # These often use mise or similar quick installers
                return 'quick'

        # Default for complex installations
        return 'standard'

    def show_script_progress(self, description: str, command: str) -> bool:
        """Show progress for shell script execution with panel interface"""
        from rich.live import Live
        from rich.panel import Panel
        from rich.text import Text
        from rich.console import Group

        # Initialize progress components
        progress = Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            TimeElapsedColumn(),
            expand=False
        )

        task = progress.add_task(f"Running {description}...", total=None)

        # Start the script process
        process = subprocess.Popen(
            command,
            shell=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
            universal_newlines=True
        )

        output_lines = []
        current_operation = "Starting installation..."

        with Live(console=self.console, refresh_per_second=4, transient=False) as live:

            def update_display():
                # Create status text
                status_text = Text(current_operation, style="cyan")

                # Group progress and status together
                content_group = Group(progress, "", status_text)

                # Create panel with both progress and status inside
                panel = Panel(
                    content_group,
                    title=f"[bold blue]🔧 {description}[/bold blue]",
                    border_style="blue",
                    padding=(0, 1)
                )
                live.update(panel)
                status_text = Text(current_operation, style="cyan")
                layout["status"].update(status_text)

            # Initial display
            update_display()

            while True:
                output = process.stdout.readline()
                if output == '' and process.poll() is not None:
                    break

                if output:
                    line = output.strip()
                    output_lines.append(line)
                    current_operation = line

                    # Update status based on common script patterns
                    line_lower = line.lower()
                    if any(pattern in line_lower for pattern in ['installing', 'install ']):
                        if 'gfortran' in line_lower:
                            current_operation += "Installing GFortran compiler..."
                        elif 'lfortran' in line_lower:
                            current_operation = "Building LFortran (this may take 20-45 minutes)..."
                        elif any(pkg in line_lower for pkg in ['dlang', 'dmd', 'ldc']):
                            current_operation += "Installing D compiler..."
                        elif 'nim' in line_lower:
                            current_operation += "Installing Nim language..."
                        elif 'zig' in line_lower:
                            current_operation += "Installing Zig language..."
                        elif 'rust' in line_lower:
                            current_operation += "Installing Rust toolchain..."
                        elif 'go' in line_lower:
                            current_operation += "Installing Go language..."
                        elif 'postgresql' in line_lower:
                            current_operation += "Installing PostgreSQL database..."
                        elif 'mariadb' in line_lower or 'mysql' in line_lower:
                            current_operation += "Installing MariaDB database..."
                        elif 'redis' in line_lower:
                            current_operation += "Installing Redis cache..."
                        elif 'sqlite' in line_lower:
                            current_operation += "Installing SQLite database..."
                        elif 'mongodb' in line_lower:
                            current_operation += "Installing MongoDB database..."
                        elif 'dbeaver' in line_lower:
                            current_operation += "Installing DBeaver GUI client..."
                        elif 'dbmate' in line_lower:
                            current_operation += "Installing DBmate migration tool..."
                        else:
                            current_operation += "Installing packages..."
                    elif 'downloading' in line_lower:
                        current_operation += "Downloading packages..."
                    elif 'building' in line_lower or 'compiling' in line_lower:
                        # Special handling for LFortran build process
                        if 'lfortran' in line_lower or any(word in line_lower for word in ['bison', 'parser', 'grammar']):
                            current_operation += "Building LFortran (bison parser generation - please be patient)..."
                        else:
                            current_operation += "Building from source..."
                    elif 'configuring' in line_lower:
                        current_operation += "Configuring installation..."
                    elif 'complete' in line_lower or 'success' in line_lower:
                        current_operation += "Installation completing..."
                    elif 'mise install' in line_lower:
                        current_operation += "Installing via Mise..."
                    elif 'yay -s' in line_lower or 'pacman -s' in line_lower:
                        current_operation += "Installing from repositories..."
                    elif 'systemctl enable' in line_lower:
                        current_operation += "Enabling system services..."
                    elif 'service' in line_lower and 'start' in line_lower:
                        current_operation += "Starting services..."

                    # Update progress task and display
                    progress.update(task, description=f"Running {description}...")
                    update_display()

            return_code = process.poll()

            if return_code == 0:
                current_operation = f"✓ {description} completed successfully!"
                progress.update(task, description=f"✓ {description} completed")
                update_display()
                time.sleep(1)  # Show completion
                return True
            else:
                current_operation = f"✗ {description} failed (exit code: {return_code})"
                progress.update(task, description=f"✗ {description} failed")
                update_display()
                time.sleep(1)  # Show error

                # Show debugging info after live display ends
                if output_lines:
                    self.console.print(f"\n[yellow]Last output (for debugging):[/yellow]")
                    for line in output_lines[-5:]:
                        if line.strip():  # Only show non-empty lines
                            self.console.print(f"  [dim]{line}[/dim]")

                return False

    def show_verbose_passthrough(self, description: str, command: str) -> bool:
        """Show raw command output without any progress wrapper (verbose mode)"""
        self.console.print(f"\n[bold blue]🔧 {description}[/bold blue]")
        self.console.print(f"[dim]Command: {command}[/dim]")
        self.console.print(f"[dim]Running in verbose mode - showing raw output[/dim]\n")

        # Execute command and show raw output directly
        try:
            result = subprocess.run(
                command,
                shell=True,
                check=False,
                text=True
            )

            if result.returncode == 0:
                self.console.print(f"\n[bold green]✓ {description} completed successfully! (exit code: 0)[/bold green]")
                return True
            else:
                self.console.print(f"\n[bold red]✗ {description} failed (exit code: {result.returncode})[/bold red]")
                return False

        except Exception as e:
            self.console.print(f"\n[bold red]✗ {description} failed: {str(e)}[/bold red]")
            return False

    def show_mise_passthrough(self, description: str, command: str) -> bool:
        """Show mise output directly without any progress wrapper"""
        self.console.print(f"\n[bold blue]⚡ {description}[/bold blue]")
        self.console.print(f"[dim]Using mise package manager with native progress display[/dim]\n")

        # Execute command and let mise show its own progress
        try:
            result = subprocess.run(
                command,
                shell=True,
                check=False,
                text=True
            )

            if result.returncode == 0:
                self.console.print(f"\n[bold green]✓ {description} completed successfully![/bold green]")
                return True
            else:
                self.console.print(f"\n[bold red]✗ {description} failed (exit code: {result.returncode})[/bold red]")
                return False

        except Exception as e:
            self.console.print(f"\n[bold red]✗ {description} failed: {str(e)}[/bold red]")
            return False

    def show_simple_progress(self, description: str, command: str) -> bool:
        """Show simple spinner-based progress with panel interface for quick installations"""
        from rich.live import Live
        from rich.panel import Panel
        from rich.text import Text
        from rich.console import Group

        # Initialize progress components
        progress = Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            TimeElapsedColumn(),
            expand=False
        )

        task = progress.add_task(f"Running {description}...", total=None)

        # Start the subprocess
        process = subprocess.Popen(
            command,
            shell=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
            universal_newlines=True
        )

        # Simple output capture without heavy processing
        output_lines = []
        current_operation = "Starting installation..."

        with Live(layout, console=self.console, refresh_per_second=4, transient=False) as live:

            def update_display():
                # Update progress panel
                progress_panel = Panel(
                    progress,
                    title=f"[bold blue]⚡ {description}[/bold blue]",
                    border_style="blue",
                    padding=(0, 1)
                )
                layout["progress_panel"].update(progress_panel)

                # Update status line
                status_text = Text(current_operation, style="cyan")
                layout["status"].update(status_text)

            # Initial display
            update_display()

            while True:
                output = process.stdout.readline()
                if output == '' and process.poll() is not None:
                    break

                if output:
                    line = output.strip()
                    output_lines.append(line)

                    # Update status for key operations
                    line_lower = line.lower()
                    if 'downloading' in line_lower:
                        current_operation = "Downloading components..."
                    elif 'installing' in line_lower:
                        current_operation = "Installing packages..."
                    elif 'complete' in line_lower or 'success' in line_lower:
                        current_operation = "Completing installation..."
                    elif 'cargo install' in line_lower:
                        current_operation = "Installing Rust package..."
                    elif 'npm install' in line_lower:
                        current_operation = "Installing Node.js package..."
                    elif 'pip install' in line_lower:
                        current_operation = "Installing Python package..."
                    elif 'go install' in line_lower:
                        current_operation = "Installing Go package..."

                    # Update display
                    update_display()

            return_code = process.poll()

            if return_code == 0:
                current_operation = f"✓ {description} completed successfully!"
                progress.update(task, description=f"✓ {description} completed")
                update_display()
                time.sleep(1)  # Show completion
                return True
            else:
                current_operation = f"✗ {description} failed (exit code: {return_code})"
                progress.update(task, description=f"✗ {description} failed")
                update_display()
                time.sleep(1)  # Show error

                # Show debugging info after live display ends
                if output_lines:
                    self.console.print(f"\n[yellow]Last output:[/yellow]")
                    for line in output_lines[-3:]:
                        if line.strip():
                            self.console.print(f"  [dim]{line}[/dim]")

                return False

    def show_multi_package_progress(self, description: str, packages: List[str], command_template: str) -> bool:
        """Show nala-style progress with panel for multiple packages"""
        from rich.live import Live
        from rich.panel import Panel
        from rich.text import Text
        from rich.console import Group

        # Initialize progress components
        progress = Progress(
            TextColumn("[bold blue]{task.description}"),
            BarColumn(bar_width=40),
            TaskProgressColumn(),
            TextColumn("•"),
            TimeElapsedColumn(),
            expand=False
        )

        main_task = progress.add_task(f"[bold]{description}", total=len(packages))

        # Status tracking
        success_count = 0
        failed_packages = []
        current_status = "Starting installation..."

        with Live(console=self.console, refresh_per_second=4, transient=False) as live:

            def update_display():
                # Create status text
                status_text = Text(current_status, style="cyan")

                # Group progress and status together
                content_group = Group(progress, "", status_text)

                # Create panel with both progress and status inside
                panel = Panel(
                    content_group,
                    title=f"[bold blue]📦 {description}[/bold blue]",
                    border_style="blue",
                    padding=(0, 1)
                )
                live.update(panel)

        with Live(layout, console=self.console, refresh_per_second=4, transient=False) as live:

            def update_display():
                # Update progress panel
                progress_panel = Panel(
                    progress,
                    title=f"[bold blue]📦 {description}[/bold blue]",
                    border_style="blue",
                    padding=(0, 1)
                )
                layout["progress_panel"].update(progress_panel)

                # Update status line
                status_text = Text(current_status, style="cyan")
                layout["status"].update(status_text)

            # Initial display
            update_display()

            for i, package in enumerate(packages, 1):
                # Update main progress
                progress.update(main_task, completed=i-1)

                # Update status
                current_status = f"[{i}/{len(packages)}] Installing {package}..."
                update_display()

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

                output_lines = []

                # Monitor installation progress
                while True:
                    output = process.stdout.readline()
                    if output == '' and process.poll() is not None:
                        break

                    if output:
                        line = output.strip()
                        output_lines.append(line)
                        line_lower = line.lower()

                        # Update sub-status based on output
                        if 'downloading' in line_lower:
                            current_status = f"[{i}/{len(packages)}] Downloading {package}..."
                        elif 'installing' in line_lower:
                            current_status = f"[{i}/{len(packages)}] Installing {package}..."
                        elif 'configuring' in line_lower:
                            current_status = f"[{i}/{len(packages)}] Configuring {package}..."
                        elif 'building' in line_lower:
                            current_status = f"[{i}/{len(packages)}] Building {package}..."

                        update_display()

                # Check result
                return_code = process.poll()

                if return_code == 0:
                    current_status = f"[{i}/{len(packages)}] ✓ {package} installed successfully"
                    success_count += 1
                else:
                    current_status = f"[{i}/{len(packages)}] ✗ {package} failed"
                    failed_packages.append(package)

                update_display()
                time.sleep(0.5)  # Brief pause to show individual result

            # Complete the main progress
            progress.update(main_task, completed=len(packages))

            # Final status
            if success_count == len(packages):
                current_status = f"✓ All {len(packages)} packages installed successfully!"
                update_display()
                time.sleep(1)
                return True
            else:
                current_status = f"⚠ {success_count}/{len(packages)} packages installed (some failed)"
                update_display()
                time.sleep(1)

                # Show failed packages after live display ends
                if failed_packages:
                    self.console.print(f"\n[red]Failed packages: {', '.join(failed_packages)}[/red]")

                return success_count > 0

    def show_progress(self, description: str, command: str, script_path: str = "") -> bool:
        """Show progress with intelligent detection of installation type"""

        # Verbose mode: bypass all progress wrappers and show raw output
        if self.verbose:
            return self.show_verbose_passthrough(description, command)

        # Detect installation type and choose appropriate progress display
        install_type = self._detect_installation_type(command, script_path)

        if install_type == 'script':
            # Use script-specific progress for shell script execution
            return self.show_script_progress(description, command)
        elif install_type == 'mise':
            # Let mise show its own native progress bars
            return self.show_mise_passthrough(description, command)
        elif install_type == 'quick':
            # Use simple spinner for quick installers (npm, pip, cargo, etc.)
            return self.show_simple_progress(description, command)
        else:
            # Use full nala-style progress bar for package managers and builds
            return self.show_nala_progress(description, command)

    def show_nala_progress(self, description: str, command: str) -> bool:
        """Show progress while executing a command with nala-style interface using panel"""
        from rich.live import Live
        from rich.panel import Panel
        from rich.text import Text
        from rich.console import Group

        # Start the subprocess
        process = subprocess.Popen(
            command,
            shell=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
            universal_newlines=True
        )

        # Initialize progress components
        progress = Progress(
            TextColumn("[bold blue]{task.description}"),
            BarColumn(bar_width=40),
            TaskProgressColumn(),
            TextColumn("•"),
            TimeElapsedColumn(),
            expand=False
        )

        main_task = progress.add_task(f"[bold]{description}", total=100)

        # Progress tracking variables
        output_lines = []
        main_progress = 0
        current_operation = "Starting installation..."
        operations_seen = set()

        with Live(console=self.console, refresh_per_second=8, transient=False) as live:

            def update_display():
                # Create status text
                status_text = Text(current_operation, style="cyan")

                # Group progress and status together
                content_group = Group(progress, "", status_text)

                # Create panel with both progress and status inside
                panel = Panel(
                    content_group,
                    title=f"[bold blue]📦 {description}[/bold blue]",
                    border_style="blue",
                    padding=(0, 1)
                )
                live.update(panel)

            # Initial display
            update_display()

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

                    # Always update with most recent meaningful output for better feedback
                    previous_operation = current_operation

                    # Detect different phases and update progress
                    if any(keyword in line_lower for keyword in ['downloading', 'download']):
                        if 'downloading' not in operations_seen:
                            operations_seen.add('downloading')
                            main_progress = min(main_progress + 20, 90)

                        # Extract specific package/file being downloaded
                        if any(pkg in line_lower for pkg in ['http', 'ftp', '.tar', '.zip', '.gz', '.xz']):
                            # Extract filename from URL or path
                            words = line.split()
                            for word in words:
                                if any(ext in word.lower() for ext in ['.tar', '.zip', '.gz', '.xz', '.deb', '.rpm']):
                                    filename = word.split('/')[-1][:40]
                                    current_operation = f"Downloading {filename}..."
                                    break
                            else:
                                current_operation = "Downloading packages..."
                        else:
                            current_operation = "Downloading packages..."

                    elif any(keyword in line_lower for keyword in ['installing', 'install']):
                        if 'installing' not in operations_seen:
                            operations_seen.add('installing')
                            main_progress = min(main_progress + 25, 90)

                        # Extract specific package name being installed
                        import re
                        package_patterns = [
                            r'installing\s+(\w+[-\w]*)',
                            r'install:\s+(\w+[-\w]*)',
                            r'package\s+(\w+[-\w]*)',
                            r'setting up\s+(\w+[-\w]*)',
                            r'unpacking\s+(\w+[-\w]*)'
                        ]
                        for pattern in package_patterns:
                            match = re.search(pattern, line_lower)
                            if match:
                                package_name = match.group(1)[:20]
                                current_operation = f"Installing {package_name}..."
                                break
                        else:
                            current_operation = "Installing packages..."

                    elif any(keyword in line_lower for keyword in ['building', 'compiling', 'compile', 'make', 'gcc', 'clang']):
                        if 'building' not in operations_seen:
                            operations_seen.add('building')
                            main_progress = min(main_progress + 30, 90)

                        # Show specific file being compiled
                        if any(ext in line_lower for ext in ['.c', '.cpp', '.cc', '.cxx', '.h', '.hpp']):
                            words = line.split()
                            for word in words:
                                if any(ext in word.lower() for ext in ['.c', '.cpp', '.cc', '.cxx']):
                                    filename = word.split('/')[-1][:30]
                                    current_operation = f"Compiling {filename}..."
                                    break
                            else:
                                current_operation = "Building from source..."
                        elif 'makepkg' in line_lower:
                            current_operation = "Building package with makepkg..."
                        elif 'cargo' in line_lower and 'build' in line_lower:
                            current_operation = "Building Rust project..."
                        elif 'npm' in line_lower and any(cmd in line_lower for cmd in ['build', 'compile']):
                            current_operation = "Building Node.js project..."
                        else:
                            current_operation = "Building from source..."

                    elif any(keyword in line_lower for keyword in ['configuring', 'configure']):
                        if 'configuring' not in operations_seen:
                            operations_seen.add('configuring')
                            main_progress = min(main_progress + 15, 90)
                        current_operation = "Configuring installation..."

                    elif any(keyword in line_lower for keyword in ['extracting', 'extract']):
                        if 'extracting' not in operations_seen:
                            operations_seen.add('extracting')
                            main_progress = min(main_progress + 10, 90)
                        current_operation = "Extracting packages..."

                    elif any(keyword in line_lower for keyword in ['processing', 'process']):
                        current_operation = "Processing installation..."

                    elif any(keyword in line_lower for keyword in ['complete', 'finished', 'done', 'success']):
                        current_operation = "Completing installation..."
                        main_progress = min(main_progress + 10, 100)

                    # More granular detection for specific operations
                    elif 'resolving dependencies' in line_lower:
                        current_operation = "Resolving dependencies..."
                    elif 'checking for conflicts' in line_lower:
                        current_operation = "Checking for conflicts..."
                    elif 'checking keys' in line_lower or 'validating' in line_lower:
                        current_operation = "Validating packages..."
                    elif 'loading packages' in line_lower:
                        current_operation = "Loading package files..."
                    elif 'checking integrity' in line_lower:
                        current_operation = "Checking package integrity..."
                    elif 'preparing' in line_lower:
                        current_operation = "Preparing installation..."
                    elif 'updating' in line_lower and 'database' in line_lower:
                        current_operation = "Updating package database..."
                    elif 'synchronizing' in line_lower:
                        current_operation = "Synchronizing package databases..."
                    elif 'retrieving' in line_lower:
                        current_operation = "Retrieving packages..."

                    # Show recent output for any line that contains useful info
                    elif len(line) > 10 and not any(skip in line_lower for skip in [
                        'warning:', 'note:', 'info:', 'debug:', 'trace:',
                        '==>', '-->', ':::', '   ', '    '  # Skip indented/formatted lines
                    ]):
                        # Show last meaningful output line (truncated)
                        display_line = line[:60] + "..." if len(line) > 60 else line
                        if not display_line.isspace() and len(display_line.strip()) > 5:
                            current_operation = f"Processing: {display_line}"

                    # Always update display if operation changed or periodically for activity indication
                    if current_operation != previous_operation or len(output_lines) % 2 == 0:
                        # Update progress bar
                        progress.update(main_task, completed=main_progress)

                        # Update display
                        update_display()

                    # Reduced delay for more responsive updates
                    time.sleep(0.01)

            # Final completion
            return_code = process.poll()

            if return_code == 0:
                progress.update(main_task, completed=100)
                current_operation = f"✓ {description} completed successfully!"
                update_display()
                time.sleep(1)  # Show completion for a moment
                return True
            else:
                current_operation = f"✗ {description} failed (exit code: {return_code})"
                update_display()
                time.sleep(1)  # Show error for a moment

                # Show error details after the live display ends
                if output_lines:
                    self.console.print(f"\n[yellow]Last output (for debugging):[/yellow]")
                    for line in output_lines[-5:]:
                        if line.strip():
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

    def get_menu_options_filtered(self, menu_key: str = "main") -> Tuple[str, str, List[Dict]]:
        """Get filtered menu options for TUI (removes navigation and bulk actions)"""
        menu_name, menu_description, all_options = self.get_menu_options(menu_key)

        # Filter out unwanted options for TUI
        unwanted_patterns = [
            'install all',
            'back',
            'exit',
            'main menu',
            'return to',
            '←'
        ]

        filtered_options = []
        for option in all_options:
            display_lower = option['display'].lower()
            action = option['action']

            # Skip navigation actions
            if action in ['back', 'exit']:
                continue

            # Skip options with unwanted patterns in display name
            if any(pattern in display_lower for pattern in unwanted_patterns):
                continue

            filtered_options.append(option)

        return menu_name, menu_description, filtered_options

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
            f"cd '{self.archer_dir}' && bash '{script_path}'",
            script_path
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
    # Parse command line arguments
    parser = argparse.ArgumentParser(description='Archer Linux Enhancement Suite')
    parser.add_argument('--debug', action='store_true', help='Show discovered menu structure and exit')
    parser.add_argument('--verbose', '-v', action='store_true', help='Show raw command output without progress bars')
    args = parser.parse_args()

    # Set up environment
    archer_dir = str(Path(__file__).parent.parent)
    os.environ['ARCHER_DIR'] = archer_dir
    os.chdir(archer_dir)

    # Initialize UI and menu system with verbose flag
    ui = ArcherUI(verbose=args.verbose)
    menu = ArcherMenu(ui)

    try:
        # Display banner
        ui.print_banner()

        # Show verbose mode notice
        if args.verbose:
            ui.console.print("[yellow]🔧 Verbose mode enabled - showing raw command output[/yellow]\n")

        # Debug option: show discovered structure if requested
        if args.debug:
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

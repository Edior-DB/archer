#!/usr/bin/env python3
"""
Lightweight Archer library for the TUI.
Provides ArcherMenu and ArcherUI classes used by the TUI when importing from `archer`.
This file is intentionally simple: it discovers menu directories under ./install
and exposes a small API the TUI expects:

- ArcherMenu.discovered_menus: Dict[str, Dict]
- ArcherMenu.get_sub_menus(menu_key) -> Dict[display_name -> menu_key]
- ArcherMenu.get_menu_options_filtered(menu_key) -> (menu_key, menu_meta, options_list)

- ArcherUI(verbose=False) with show_progress(description, command, script_path) stub

This is a pragmatic shim so the TUI can run and exercise install scripts. It is
not a full reimplementation of the project's original `archer` module.
"""
from pathlib import Path
import os
import shlex
import asyncio
import subprocess
from typing import Dict, List, Tuple, Optional
import time


class ArcherUI:
    """Minimal UI helper used by the TUI and ArcherMenu.

    This class intentionally provides a small show_progress method. The TUI has its
    own streaming runner, so this implementation simply logs and returns.
    """

    def __init__(self, verbose: bool = False):
        self.verbose = verbose

    def show_progress(self, description: str, command: str, script_path: str = ""):
        """Run a command synchronously and print minimal info.

        The TUI prefers to use its own async runner. This method is provided so
        other code that expects ArcherUI.show_progress will still work in a basic way.
        """
        if self.verbose:
            print(f"[ArcherUI] Running: {description} -> {command}")
        try:
            # Run the command synchronously; capture output and print timestamps.
            proc = subprocess.run(command, shell=True, check=False, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            out = proc.stdout.decode('utf-8', errors='replace') if proc.stdout else ''
            if self.verbose:
                print(out)
            return proc.returncode, out
        except Exception as e:
            if self.verbose:
                print(f"[ArcherUI] Exception: {e}")
            return 1, str(e)


class ArcherMenu:
    """Lightweight menu discovery and option provider.

    Behavior:
    - Scans `<project_root>/install` for directories containing install scripts.
    - Builds `discovered_menus` mapping where keys are relative paths like "desktop/themes"
      or top-level names like "development".
    - get_sub_menus(top_key) returns immediate subdirectories under that top key.
    - get_menu_options_filtered(menu_key) returns (menu_key, menu_meta, options_list)
      where each option in options_list is a dict with at least 'display' and 'target'.
    """

    def __init__(self, ui: Optional[ArcherUI] = None):
        self.ui = ui or ArcherUI(verbose=False)
        self.project_root = Path(__file__).parent.parent
        self.install_root = self.project_root / 'install'
        self.discovered_menus: Dict[str, Dict] = {}
        self._discover_menus()

    def _discover_menus(self):
        """Discover install directories and record menu keys.

        A discovered menu key is the path relative to `install/`, with path components
        joined by '/'. For each directory we store a small metadata dict with the
        directory path and install script path (if present).
        """
        self.discovered_menus.clear()
        if not self.install_root.exists():
            return

        for root, dirs, files in os.walk(self.install_root):
            root_path = Path(root)
            # compute relative path from install_root
            try:
                rel = root_path.relative_to(self.install_root)
            except Exception:
                continue
            if rel == Path('.'):
                # top-level install root; skip creating a menu for '.'
                continue
            key = '/'.join(rel.parts)
            install_sh = None
            if (root_path / 'install.sh').exists():
                install_sh = str((root_path / 'install.sh').resolve())
            # record discovered menu
            self.discovered_menus[key] = {
                'path': str(root_path.resolve()),
                'install': install_sh,
            }

    def get_sub_menus(self, top_key: str) -> Dict[str, str]:
        """Return mapping {display_name: submenu_key} for immediate children of top_key.

        Example: if discovered_menus contains 'desktop/themes' and 'desktop/icons', then
        get_sub_menus('desktop') -> {'Themes': 'desktop/themes', 'Icons': 'desktop/icons'}
        """
        children = {}
        prefix = top_key + '/'
        for key in sorted(self.discovered_menus.keys()):
            if not key.startswith(prefix):
                continue
            rest = key[len(prefix):]
            # only immediate children (no additional '/'), take first part
            parts = rest.split('/')
            child = parts[0]
            display = child.replace('-', ' ').replace('_', ' ').title()
            child_key = prefix + child
            # avoid duplicates
            if display not in children:
                # find full key that corresponds exactly to child (prefer exact match)
                match_key = None
                candidate = child_key
                # prefer exact directory key match if present
                if candidate in self.discovered_menus:
                    match_key = candidate
                else:
                    # otherwise find the first key that starts with candidate
                    for k in self.discovered_menus.keys():
                        if k.startswith(candidate + '/') or k == candidate:
                            match_key = k
                            break
                if match_key:
                    children[display] = match_key
        return children

    def get_menu_options_filtered(self, menu_key: str) -> Tuple[str, Dict, List[Dict]]:
        """Return tuple (menu_key, menu_meta, options_list).

        Each option is a dict containing:
        - 'display': user-friendly name
        - 'target': path to a script that can be executed (absolute path)
        - optional 'disabled': bool
        """
        menu_meta = self.discovered_menus.get(menu_key, {})
        options: List[Dict] = []
        if not menu_meta:
            return menu_key, {}, options

        menu_dir = Path(menu_meta.get('path', ''))
        # prefer listing scripts in the menu directory
        if menu_dir.exists() and menu_dir.is_dir():
            # first, if install.sh exists, offer it as the primary option
            install_sh = menu_dir / 'install.sh'
            if install_sh.exists():
                options.append({
                    'display': 'Run install.sh',
                    'target': str(install_sh.resolve()),
                })
            # also enumerate other .sh scripts (non-install.sh)
            for p in sorted(menu_dir.glob('*.sh')):
                if p.name == 'install.sh':
                    continue
                options.append({
                    'display': p.stem.replace('-', ' ').replace('_', ' ').title(),
                    'target': str(p.resolve()),
                })
        return menu_key, menu_meta, options


# Provide a module-level convenience: when users `from archer import ArcherMenu, ArcherUI`
# they can import from this file if the project's import path points here.
__all__ = ['ArcherMenu', 'ArcherUI']

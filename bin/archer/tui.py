#!/usr/bin/env python3
"""Modular TUI entrypoint for Archer.

This module exposes `main()` which starts the Textual application. It is
designed to be executed as `python3 -m archer.tui` or imported by other code.
"""
import os
import sys
from pathlib import Path

# Ensure the package bin directory is on sys.path for relative imports
PACKAGE_DIR = Path(__file__).parent
ROOT_DIR = PACKAGE_DIR.parent
if str(ROOT_DIR) not in sys.path:
    sys.path.insert(0, str(ROOT_DIR))

from .archer_tui_impl import ArcherTUIApp  # type: ignore


def main(argv=None):
    argv = argv or sys.argv[1:]
    if ArcherTUIApp is None:
        print("No TUI implementation found. Ensure 'bin/archer/archer_tui_impl.py' exists.")
        return 2

    # Pass through CLI args to the module's main if present, otherwise instantiate
    # and run the application directly.
    try:
        # If the module defined a main(), call it
        ns = globals()
        # If the extracted ns has a main, call it
        # Otherwise, create and run the App
        app = ArcherTUIApp()
        app.run()
        return 0
    except SystemExit as e:
        return e.code if isinstance(e.code, int) else 0
    except Exception as e:
        print(f"Error running Archer TUI: {e}")
        raise


if __name__ == '__main__':
    sys.exit(main())

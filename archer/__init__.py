"""Package shim to make `archer` importable from the repository root.

This package adjusts its __path__ to include `./bin/archer` so that
`import archer.tui` will load `bin/archer/tui.py`.

This keeps the physical implementation under `bin/archer` while allowing
users to run the TUI as `python -m archer.tui` from the project root.
"""
from pathlib import Path
import os

# Compute the path to bin/archer relative to the repository root.
HERE = Path(__file__).resolve().parent
REPO_ROOT = HERE.parent
BIN_ARCHER = (REPO_ROOT / 'bin' / 'archer').resolve()

if BIN_ARCHER.exists():
    # Prepend to __path__ so submodules in bin/archer are discoverable as
    # archer.<module>
    __path__.insert(0, str(BIN_ARCHER))

__all__ = []

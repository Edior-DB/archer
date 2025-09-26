#!/usr/bin/env python3
"""Small Textual-based CLI to show single-purpose modals (confirm / secret).

This script is intended to be called by shell installers when a Textual TUI
is running and a modal/popup is preferred over a plain-text prompt.

Usage:
  archer_tui_cli.py confirm --message "Proceed?"
    -> exit code 0 for Yes, 1 for No

  archer_tui_cli.py secret --prompt "Enter password:"
    -> prints secret on stdout and exits 0 (or non-zero on failure)
"""
from textual.app import App
from textual.widgets import Static, Button, Input
from textual.containers import Vertical, Horizontal
from textual import events
import argparse
import sys


class ConfirmApp(App):
    CSS = """
    Screen {
        align: center middle;
    }
    """

    def __init__(self, message: str):
        super().__init__()
        self.message = message

    def compose(self):
        with Vertical():
            yield Static(self.message)
            with Horizontal():
                yield Button("Yes", id="yes")
                yield Button("No", id="no")

    def on_button_pressed(self, event: Button.Pressed) -> None:
        btn = event.button.id
        if btn == "yes":
            sys.exit(0)
        else:
            sys.exit(1)


class SecretApp(App):
    CSS = """
    Screen { align: center middle; }
    Input { width: 60; }
    """

    def __init__(self, prompt: str):
        super().__init__()
        self.prompt = prompt

    def compose(self):
        with Vertical():
            yield Static(self.prompt)
            # Textual Input supports password=True in newer versions
            self.input_widget = Input(password=True, placeholder="Password")
            yield self.input_widget
            with Horizontal():
                yield Button("OK", id="ok")
                yield Button("Cancel", id="cancel")

    def on_button_pressed(self, event: Button.Pressed) -> None:
        btn = event.button.id
        if btn == "ok":
            # Print the password to stdout and exit
            pwd = self.input_widget.value or ""
            print(pwd, end="", flush=True)
            sys.exit(0)
        else:
            sys.exit(1)


def main():
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_confirm = sub.add_parser("confirm")
    p_confirm.add_argument("--message", required=True)

    p_secret = sub.add_parser("secret")
    p_secret.add_argument("--prompt", default="Password:")

    args = parser.parse_args()

    if args.cmd == "confirm":
        app = ConfirmApp(args.message)
        app.run()
    elif args.cmd == "secret":
        app = SecretApp(args.prompt)
        app.run()


if __name__ == '__main__':
    main()

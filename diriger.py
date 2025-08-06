#!/usr/bin/env python3

import argparse
import os
import subprocess
import sys
import time
import uuid
from pathlib import Path
from typing import List, Optional

SESSION_PREFIX = "diriger"
INIT_SLEEP = 5


class Diriger:
    def __init__(self):
        self.dry_run = False
        self.feature = ""
        self.prompt = ""
        self.root = Path.cwd()
        self.commands = []
        self.config_file = Path(os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config"))) / "diriger"
        self.worktree_root = Path(os.environ.get("XDG_DATA_HOME", os.path.expanduser("~/.local/share"))) / "diriger"
        self.worktree_root.mkdir(parents=True, exist_ok=True)

    def run(self, cmd: str) -> Optional[subprocess.CompletedProcess]:
        """Execute command, with dry-run support"""
        if self.dry_run:
            print(f"$ {cmd}")
            return None
        return subprocess.run(cmd, shell=True, capture_output=False)

    def run_capture(self, cmd: str) -> str:
        """Execute command and capture output"""
        if self.dry_run:
            print(f"$ {cmd}")
            return ""
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        return result.stdout.strip()

    def load_config(self):
        """Load commands from config file if not provided via CLI"""
        if not self.commands:
            if not self.config_file.exists():
                print(f"Config file {self.config_file} not found")
                sys.exit(1)
            self.commands = [line.strip() for line in self.config_file.read_text().splitlines() if line.strip()]

    def get_input(self, prompt: str) -> str:
        """Get input from user (simplified version without gum dependency)"""
        return input(f"{prompt} ").strip()

    def launch(self):
        """Launch multi-agent session"""
        if not self.feature:
            self.feature = self.get_input("Feature:")
        if not self.prompt:
            print("Prompt (multi-line, Ctrl+D to finish):")
            lines = []
            try:
                while True:
                    lines.append(input())
            except EOFError:
                pass
            self.prompt = "\n".join(lines)

        projname = self.root.name
        session_name = f"{SESSION_PREFIX}-{projname}-{self.feature}-{str(uuid.uuid4())[:8]}"
        print(f"Session: {session_name}")

        self.run(f'tmux new -s "{session_name}" -c "{self.root}" -d')

        for i, cmd in enumerate(self.commands, 1):
            agent = cmd.split()[0]
            print(f"Launching {cmd}")

            treename = f"{projname}-{self.feature}-{agent}-{i}"
            treepath = self.worktree_root / treename
            self.run(f'git worktree add -b "{self.feature}-{agent}-{i}" "{treepath}"')

            # Append prompt based on agent type
            unknown_agent = False
            ready_msg = ""
            if self.prompt:
                if agent == "gmn":
                    cmd += f" -i '{self.prompt}'"
                elif agent == "ocd":
                    cmd += f" -p '{self.prompt}'"
                elif agent == "cld":
                    cmd += f" '{self.prompt}'"
                elif agent == "crs":
                    ready_msg = "Ready?"
                else:
                    unknown_agent = True

            pane = f"{agent}-{i}"
            self.run(f'tmux neww -t "{session_name}" -n "{pane}" -c "{treepath}" "{cmd}"')

            if ready_msg or unknown_agent:
                if ready_msg:
                    ready = False
                    for _ in range(25):
                        if not self.dry_run:
                            capture = self.run_capture(f'tmux capture-pane -t "{pane}" -p')
                            if ready_msg in capture:
                                ready = True
                                break
                        time.sleep(0.2)
                    if not ready and not self.dry_run:
                        print(f"Agent '{agent}' failed to initialize")
                        continue
                else:
                    print(f"Unknown agent '{agent}', using hardcoded sleep interval: {INIT_SLEEP}")
                    if not self.dry_run:
                        time.sleep(INIT_SLEEP)

                self.run(f'tmux send-keys -t "{session_name}:{pane}" "{self.prompt}"')
                if not self.dry_run:
                    time.sleep(0.1)
                self.run(f'tmux send-keys -t "{session_name}:{pane}" Enter')

        print(f"{len(self.commands)} agents started")
        self.run(f'tmux killp -t "{session_name}:0"')
        self.run(f'tmux a -t "{session_name}"')

    def send(self):
        """Send prompt to existing session"""
        sessions_output = self.run_capture(f"tmux ls -F '#S' | grep -F '{SESSION_PREFIX}'")
        if not sessions_output:
            print("No diriger sessions found")
            sys.exit(1)

        sessions = sessions_output.split("\n")
        if len(sessions) == 1:
            session_name = sessions[0]
        else:
            print("Available sessions:")
            for i, session in enumerate(sessions, 1):
                print(f"{i}. {session}")
            choice = int(self.get_input("Choose session:")) - 1
            session_name = sessions[choice]

        if not self.prompt:
            print(f"Prompt for {session_name} (multi-line, Ctrl+D to finish):")
            lines = []
            try:
                while True:
                    lines.append(input())
            except EOFError:
                pass
            self.prompt = "\n".join(lines)

        panes_output = self.run_capture(f'tmux list-p -st "{session_name}" -F "#D"')
        panes = panes_output.split("\n") if panes_output else []

        print("Sending: ", end="")
        for pane in panes:
            self.run(f'tmux send-keys -t "{pane}" "{self.prompt}"')
            if not self.dry_run:
                time.sleep(0.1)
            self.run(f'tmux send-keys -t "{pane}" Enter')
            print(".", end="", flush=True)
        print()
        print(f"Prompt sent to {len(panes)} agents")

    def config(self):
        """Open config file for editing"""
        editor = os.environ.get("EDITOR", "vim")
        subprocess.run([editor, str(self.config_file)])


def main():
    parser = argparse.ArgumentParser(description="Multi-agent orchestration tool")
    subparsers = parser.add_subparsers(dest="command", help="Commands")

    # Launch subcommand
    launch_parser = subparsers.add_parser("launch", help="Launch new multi-agent session")
    launch_parser.add_argument("-n", "--dry-run", action="store_true", help="Show commands without executing")
    launch_parser.add_argument("-f", "--feature", help="Feature name")
    launch_parser.add_argument("-p", "--prompt", help="Initial prompt")
    launch_parser.add_argument("-r", "--root", type=Path, help="Project root directory")
    launch_parser.add_argument(
        "-a", "--agent", action="append", dest="agents", help="Agent command (can be used multiple times)"
    )

    # Send subcommand
    send_parser = subparsers.add_parser("send", help="Send prompt to existing session")
    send_parser.add_argument("-n", "--dry-run", action="store_true", help="Show commands without executing")
    send_parser.add_argument("-p", "--prompt", help="Prompt to send")

    # Config subcommand
    subparsers.add_parser("config", help="Edit configuration file")

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        sys.exit(1)

    diriger = Diriger()
    diriger.dry_run = getattr(args, "dry_run", False)

    if hasattr(args, "feature") and args.feature:
        diriger.feature = args.feature
    if hasattr(args, "prompt") and args.prompt:
        diriger.prompt = args.prompt
    if hasattr(args, "root") and args.root:
        diriger.root = args.root
    if hasattr(args, "agents") and args.agents:
        diriger.commands = args.agents

    if args.command == "launch":
        diriger.load_config()
        diriger.launch()
    elif args.command == "send":
        diriger.send()
    elif args.command == "config":
        diriger.config()


if __name__ == "__main__":
    main()

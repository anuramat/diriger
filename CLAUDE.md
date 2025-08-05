# Diriger Demo

A multi-agent orchestration tool that launches AI agents in parallel tmux sessions to work on development features collaboratively.

## Purpose

Diriger automates the setup of a multi-agent development environment where different AI agents can work simultaneously on the same codebase using git worktrees for isolation.

## Architecture

- **Main Script**: `diriger.sh` - Bash orchestration script
- **Configuration**: Commands read from `$XDG_CONFIG_HOME/diriger` (one per line)
- **Isolation**: Each agent works in separate git worktrees
- **Session Management**: tmux for parallel execution and monitoring

## Workflow

1. Creates unique tmux session with format `diriger-<projname>-<feature>-<uuid>`
2. Accepts optional `-f` (feature), `-p` (prompt), `-n` (dry-run), `-r` (root), `-a` (agents) args
3. Reads commands from config file (`$XDG_CONFIG_HOME/diriger`), or from `-a` flags
4. Launches tmux session in $root dir
5. For each command:
   - Creates dedicated git worktree `$worktree_root/<projname>-<feature>-<agent>-<num>`
   - Spawns tmux window in that worktree with the agent command and injected prompt, varying per agent type
   - Special handling for agent init depending on agent name (prompt injection, ready message, sleep)
6. (If needed) Waits for agent initialization (ready message or sleep) before sending prompt
7. Attaches to tmux session for monitoring

## Formatting

Code style, linting, and formatting are managed by treefmt.toml in the project root. Adjust tools/settings there as needed.

## Configuration

Create `$XDG_CONFIG_HOME/diriger` (or `~/.config/diriger`) with one command per line:

```
gmn
ocd
cld
```

The script reads commands from this file and initializes each with the given prompt to work on the specified feature.

## Instructions

Only ever run it in dry-run mode, *we* don't want to lose $20 in credits on a
debugging session

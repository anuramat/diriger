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

1. Creates unique session ID with `diriger-$(uuidgen)`
2. Accepts feature name and prompt as required arguments
3. Reads commands from config file `$XDG_CONFIG_HOME/diriger`
4. Launches tmux session in project root
5. For each command:
   - Creates dedicated git worktree (`../projname-feature-agent-N`)
   - Spawns tmux window running the command
   - Sends the provided prompt to start work
6. Attaches to tmux session for monitoring

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

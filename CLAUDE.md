# Diriger Demo

A multi-agent orchestration tool that launches three AI agents (`gmn`, `ocd`, `cld`) in parallel tmux sessions to work on development features collaboratively.

## Purpose

Diriger automates the setup of a multi-agent development environment where different AI agents can work simultaneously on the same codebase using git worktrees for isolation.

## Architecture

- **Main Script**: `diriger.sh` - Bash orchestration script
- **Agent Types**: 
  - `gmn` (Gemini)
  - `ocd` (OpenAI Codex/GPT)  
  - `cld` (Claude)
- **Isolation**: Each agent works in separate git worktrees
- **Session Management**: tmux for parallel execution and monitoring

## Workflow

1. Creates unique session ID with `diriger-$(uuidgen)`
2. Accepts feature name and optional prompt as arguments
3. Launches tmux session in project root
4. For each agent:
   - Creates dedicated git worktree (`../projname-feature-agent`)
   - Spawns tmux window running the agent
   - Waits for agent initialization (max 6 seconds)
   - Sends the provided prompt to start work
5. Attaches to tmux session for monitoring

## Usage

```bash
./diriger.sh <feature-name> [prompt]
```

The script expects agents `gmn`, `ocd`, and `cld` to be available in PATH and initializes them with the given prompt to work on the specified feature.
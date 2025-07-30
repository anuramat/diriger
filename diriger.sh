#!/usr/bin/env bash

set -e

session_prefix='diriger-'

# execute command, showing it in dry run mode
run() {
	if $dry_run; then
		printf '$ '
		# XXX eats the quotes, might be confusing...
		eval "printf '%s ' $*"
		echo
	else
		eval "$*"
	fi
}

launch() {
	# defaults
	dry_run=false
	feature=""
	prompt=""
	root=$PWD
	commands=()
	config_file="${XDG_CONFIG_HOME:-$HOME/.config}/diriger"

	# parse arguments
	while [[ $# -gt 0 ]]; do
		case $1 in
			-n)
				dry_run=true
				shift
				;;
			-f)
				feature="$2"
				shift 2
				;;
			-p)
				prompt="$2"
				shift 2
				;;
			-r)
				root="$2"
				shift 2
				;;
			-a)
				commands+=("$2")
				shift 2
				;;
			*)
				echo "Unknown option: $1"
				exit 1
				;;
		esac
	done

	# fallback to interactive input or config file
	[[ -z $feature ]] && feature="$(gum input --header='Feature:')"
	[[ -z $prompt ]] && prompt="$(gum write --header='Prompt:')"
	if [[ ${#commands[@]} -eq 0 ]]; then
		[[ ! -f $config_file ]] && {
			echo "Config file $config_file not found"
			exit 1
		}
		mapfile -t commands < "$config_file"
	fi

	# launch the tmux session
	session_name="$session_prefix$(uuidgen)" # unique id; used to control the session afterwards
	# TODO add project and feature to the session name
	echo "Session: $session_name"
	run 'tmux new -s "$session_name" -c "$root" -d'

	i=0
	projname=$(basename "$root")
	for cmd in "${commands[@]}"; do
		((++i))
		agent=$(cut -d ' ' -f 1 <<< "$cmd")

		echo "Launching $cmd"

		treename="$projname-$feature-$agent-$i"
		run 'git worktree add "../$treename"'
		# shellcheck disable=SC2034
		# used in `eval` inside `run`
		treepath="$(realpath "../$treename")"

		# append the prompt
		case "$agent" in
			gmn) cmd+=" -i '$prompt'" ;;
			ocd) cmd+=" -p '$prompt'" ;;
			cld) cmd+=" ' $prompt'" ;;
			*)
				echo "Invalid agent"
				exit 1
				;;
		esac

		# start the agent
		run 'tmux neww -t "$session_name" -n "$agent-$i" -c "$treepath" "$cmd"'
	done
	echo "${#commands[@]} agents started"
	run 'tmux killp -t "$session_name:0"'
	run 'tmux a -t "$session_name"'
}

send() {
	# TODO use the same flags as the `launch` subcommand
	sessions=$(tmux ls -F '#S' | grep -F "$session_prefix")
	(($(wc -l <<< "$sessions") > 0))
	session_name=$(gum choose --header='Session:' <<< "$sessions")
	# TODO strip away session_prefix, append when needed
	prompt="$(gum write --header='Prompt:')"

	panes=$(tmux list-p -t "$session_name" -F '#D')
	for pane in $panes; do
		tmux send-keys -t "$pane" "$prompt" Enter
	done
}

case "${1:-}" in
	launch)
		shift
		launch "$@"
		;;
	send)
		shift
		send "$@"
		;;
	*) launch "$@" ;;
esac

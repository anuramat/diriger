#!/usr/bin/env bash

set -e

diriger_id="diriger-$(uuidgen)"

echo "Session: $diriger_id"

feature="${1:?enter the feature name}"
prompt="$2"
root=$PWD
projname=$(basename "$root")

tmux new -s "$diriger_id" -c "$root" -d

commands=("gmn" "ocd" "cld")
for cmd in "${commands[@]}"; do
	echo "Launching $cmd"

	treename="$projname-$feature-$cmd"
	git worktree add "../$treename" &> /dev/null
	treepath="$(realpath -e "../$treename")"
	pane="$diriger_id:$cmd"

	tmux neww -t "$diriger_id" -n "$cmd" -c "$treepath" "$cmd; exit"
	case "$cmd" in
		gmn) ready="Type your message" ;;
		ocd) ready="enter send" ;;
		cld) ready="for shortcuts" ;;
		*) exit 1 ;;
	esac
	for i in {1..30}; do
		capture=$(tmux capture-pane -t "$pane" -p)
		if grep -qF "$ready" <<< "$capture"; then
			break
		fi
		sleep 0.2
	done
	if ! grep -qF "$ready" <<< "$capture"; then
		echo "$cmd failed to initialize"
		exit 1
	fi
	tmux send -t "$pane" "${prompt:?enter the prompt}"
	sleep 0.5 # HACK gemini doesn't receive enter otherwise
	tmux send -t "$pane" Enter
done
echo "$# agents started"
tmux killp -t "$diriger_id:0"
tmux a -t "$diriger_id"

#!/usr/bin/env bash

set -e

diriger_id="diriger-$(uuidgen)"

feature="${1:?enter the feature name}"
prompt="$2"
root=$PWD
projname=$(basename "$root")

tmux new -s "$diriger_id" -c "$root" -d

commands=("gmn" "ocd")
for cmd in "${commands[@]}"; do
	treename="$projname-$feature-$cmd"
	git worktree add "../$treename"
	treepath="$(realpath -e "../$treename")"
	pane="$diriger_id:$cmd"

	tmux neww -t "$diriger_id" -n "$cmd" -c "$treepath" "$cmd"
	case "$cmd" in
		gmn) ready="Type your message" ;;
		ocd) ready="enter send" ;;
		*) exit 1 ;;
	esac
	for i in {1..30}; do
		capture=$(tmux capture-pane -t "$pane" -p)
		if grep -qF "$ready" <<< "$capture"; then
			break
		fi
	done
	if ! grep -qF "$ready" <<< "$capture"; then
		echo "$cmd failed to initialize"
		exit 1
	fi
	tmux send -t "$pane" "${prompt:?enter the prompt}" Enter
done

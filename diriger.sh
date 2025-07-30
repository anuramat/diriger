#!/usr/bin/env bash

set -e

_diriger_id="diriger-$(uuidgen)"

feature="${1:?enter the feature name}"
root=$PWD
projname=$(basename "$root")

tmux new -s "$_diriger_id" -c "$root" -d

commands=("gmn" "ocd")
for cmd in "${commands[@]}"; do
	treename="$projname-$feature-$cmd"
	git worktree add "../$treename"
	treepath="$(realpath -e "../$treename")"

	tmux neww -t "$_diriger_id" -n "$cmd" -c "$treepath" "$cmd"
	sleep 2 # HACK: we need to sleep so that the interface loads and is ready to receive keystrokes
	# TODO instead we should use `tmux capture-pane -t ... -p` to capture and continuously check whether the output has a matching string; every command will have it's own
	tmux send -t "$_diriger_id:$cmd" "$2" Enter
done

#!/usr/bin/env bash

set -e

diriger_id="diriger-$(uuidgen)"

echo "Session: $diriger_id"

feature="${1:?enter the feature name}"
prompt="${2:?enter the prompt}"
root=$PWD
projname=$(basename "$root")

tmux new -s "$diriger_id" -c "$root" -d

commands=("${@:3}")
[[ ${#commands[@]} -eq 0 ]] && commands=("gmn" "ocd" "cld")
for cmd in "${commands[@]}"; do
	echo "Launching $cmd"

	treename="$projname-$feature-$cmd"
	if ! git worktree add "../$treename" &> /dev/null; then
		echo "Couldn't create a worktree $treename"
		exit 1
	fi
	treepath="$(realpath -e "../$treename")"

	agent=$(cut -d ' ' -f 1 <<< "$cmd")

	case "$agent" in
		gmn) cmd+=" -i '$prompt'" ;;
		ocd) cmd+=" -p '$prompt'" ;;
		cld) cmd+=" ' $prompt'" ;;
		*)
			echo "Invalid agent"
			exit 1
			;;
	esac

	tmux neww -t "$diriger_id" -n "$cmd" -c "$treepath" "$cmd"
done
echo "${#commands[@]} agents started"
tmux killp -t "$diriger_id:0"
tmux a -t "$diriger_id"

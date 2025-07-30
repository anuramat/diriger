#!/usr/bin/env bash

set -e

# unique id; used to control the session afterwards
diriger_id="diriger-$(uuidgen)"
echo "Session: $diriger_id"

# TODO These should be specified with one char flags:
feature="${1:-$(gum input --header='Feature:')}" # -f featurename
prompt="${2:-$(gum write --header='Prompt:')}"   # -p 'Prompt'
root=$PWD                                        # -r ./long/path
# commands should be specified like this: ./diriger.sh -a cmd1 -a 'cmd2 args2'
config_file="${XDG_CONFIG_HOME:-$HOME/.config}/diriger"
[[ ! -f $config_file ]] && {
	echo "Config file $config_file not found"
	exit 1
}
mapfile -t commands < "$config_file"

# launch a new session
tmux new -s "$diriger_id" -c "$root" -d

i=0
projname=$(basename "$root")
for cmd in "${commands[@]}"; do
	((++i))
	agent=$(cut -d ' ' -f 1 <<< "$cmd")

	echo "Launching $cmd"

	treename="$projname-$feature-$agent-$i"
	if ! git worktree add "../$treename" &> /dev/null; then
		echo "Couldn't create a worktree $treename"
		exit 1
	fi
	treepath="$(realpath -e "../$treename")"

	case "$agent" in
		gmn) cmd+=" -i '$prompt'" ;;
		ocd) cmd+=" -p '$prompt'" ;;
		cld) cmd+=" ' $prompt'" ;;
		*)
			echo "Invalid agent"
			exit 1
			;;
	esac

	tmux neww -t "$diriger_id" -n "$agent-$i" -c "$treepath" "$cmd"
done
echo "${#commands[@]} agents started"
tmux killp -t "$diriger_id:0"
tmux a -t "$diriger_id"

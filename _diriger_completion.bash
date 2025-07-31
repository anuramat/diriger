#!/usr/bin/env bash

_diriger_completion() {
	local cur prev words cword
	_init_completion || return

	case $cword in
		1)
			COMPREPLY=($(compgen -W "launch send" -- "$cur"))
			return 0
			;;
	esac

	case ${words[1]} in
		launch | send)
			case $prev in
				-f)
					# feature name - no completion
					return 0
					;;
				-p)
					# prompt - no completion
					return 0
					;;
				-r)
					# root directory
					_filedir -d
					return 0
					;;
				-a)
					# agent command - suggest common ones
					COMPREPLY=($(compgen -W "gmn ocd cld" -- "$cur"))
					return 0
					;;
			esac

			case $cur in
				-*)
					local opts="-n -f -p -r -a"
					COMPREPLY=($(compgen -W "$opts" -- "$cur"))
					return 0
					;;
			esac
			;;
	esac

	return 0
}

complete -F _diriger_completion diriger

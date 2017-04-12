#!/bin/bash

# Reset for getopts
OPTIND=1

# Variable initialization
output_file=""
target_dir=""

while getopts "h?t:o:" opt; do
	case "$opt" in
	h|\?)
		show_help
		exit 0
		;;
	t) target_dir=$OPTARG
		;;
	o) output_file=$OPTARG
		;;
	esac
done

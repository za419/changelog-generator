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

function show_help {
	echo "changelog-generator: Generates a changelog based on the log for a given
git repository"
	echo "usage: changelog-generator [options]"
	echo "  -o output-file\tSets the output to be sent to output-file"
	echo "     If ommitted, will output to stdout"
	echo "  -t target-dir\tSets the path to the target repository"
	echo "     If ommitted, will expect input formatted like a git log on stdin"
}

if [ -z $output_file ]; then
	exec &3>&1
else
	exec &3>$output_file
fi

infile=`mktemp` || exit 1
if [ -z $target_dir]; then
	$infile<&0

	while read line; do
		echo $line>>$infile
	done
fi

rm $infile
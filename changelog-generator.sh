#!/bin/bash

# Reset for getopts
OPTIND=1

# Variable initialization
output_file=""
target_dir=""
ignore_file=""
titles_only=false
include_merges=false

while getopts "h?t:o:i:sm" opt; do
	case "$opt" in
	h|\?)
		show_help
		exit 0
		;;
	t) target_dir=$OPTARG
		;;
	o) output_file=$OPTARG
		;;
    i) ignore_file=$OPTARG
        ;;
    s) titles_only=true
        ;;
    m) include_merges=true
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
    echo "  -h ignore-file\tA path to a file of hashes to ignore"
    echo "     Expects a file which is a collection of hashes, with one hash per line"
    echo "     Any commit with a hash in this file will not be included in the changelog"
    echo "  -s shorten\tIgnored if target-dir is not set."
    echo "     Only adds the titles of commits to the changelog"
    echo "  -m merges\tInclude merge commits"
    echo "     By default, merge commits are not added to the changelog."
    echo "     Use this flag to include merge commits."
    echo "     Ignored if target-dir is not set."
}

if [ $output_file ]; then
	exec >"$output_file"
fi

infile=`mktemp` || exit 1
if [ -z $target_dir ]; then
	$infile<&0

	while read line; do
		echo $line>>$infile
	done
else
	cd $target_dir
    if $titles_only; then
        if $include_merges; then
            git log --no-max-parents --pretty=format:"commit %H%nDate: %cd%n%s">$infile
        else
            git log --no-merges --pretty=format:"commit %H%nDate: %cd%n%s">$infile
        fi
    else
        if $include_merges; then
            git log --no-max-parents>$infile
        else
            git log --no-merges>$infile
        fi
    fi
	cd ->/dev/null
fi

medfile=`mktemp` || (rm -f infile; exit 1)

ignorecommit=false

while read -r line; do
	if [[ "$line" == "commit "* ]]; then 
        ignorecommit=false
        if [ "$ignore_file" ]; then
            echo $line | sed -ne 's/^commit //p' | grep -f - $ignore_file > /dev/null
            if [ $? -eq 0 ]; then
                ignorecommit=true
            fi
        fi
    elif $ignorecommit; then true
	elif [[ "$line" == "Author: "* ]]; then true
    elif [[ "$line" == "Merge: *"]]; then true
	elif [[ "$line" == "Date: "* ]]; then
        if [ !$ignorecommit ]; then
            echo $line | sed -ne 's/[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\} //
                                  s/ -.*//p'
            echo "commit marker"
        fi
	elif [ -z "$line" ]; then
		echo $line
	else
		echo $line
	fi
done < $infile > $medfile

lastdate="None"
echoline=true
docommit=true

while read -r line; do
    if [[ "$line" == "Date: "* ]]; then
        if [[ "$line" == $lastdate ]]; then
            echoline=false
        else
            if [[ "$lastdate" != "None" ]]; then
                echo '</p>'
                echo '</div>'
            fi
            echo '<div>'
            echo '<h3>'
            echo $line | sed -ne 's/^Date: //p'
            echo '</h3>'
            echo '<p>'
            lastdate=$line
            docommit=false
        fi
    elif [[ "$line" == "commit "* ]]; then
        if $docommit; then
            if [[ "$lastdate" != "None" ]]; then
                echo '</p>'
            fi
            echo '<p>'
        else
            docommit=true
        fi
    elif [[ -z "$line" ]]; then
        if $echoline; then
            if [[ "$lastdate" != "None" ]]; then
                echo '<br>'
            fi
        else
            echoline=`false`
        fi
    else
        echo $line
        echo '<br>'
    fi
done < $medfile

echo '</p>'
echo '</div>'

rm $medfile
rm $infile

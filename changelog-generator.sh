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
	git log>$infile
	cd ->/dev/null
fi

medfile=`mktemp` || (rm -f infile; exit 1)

while read -r line; do
	if [[ "$line" == commit* ]]; then
		echo $line
	elif [[ "$line" == Author:* ]]; then true
	elif [[ "$line" == Date:* ]]; then
		echo $line | sed -ne 's/[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\} //
                              s/ -.*//p'
	elif [ -z "$line" ]; then
		echo $line
	else
		echo $line
	fi
done < $infile > $medfile

lastdate="None"
echoline=`true`

while read -r line; do
    if [[ "$line" == Date:* ]]; then
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
        fi
    elif [[ "$line" == commit* ]]; then
        if [[ "$lastdate" != "None" ]]; then
            echo '</p>'
        fi
        echo '<p>'
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

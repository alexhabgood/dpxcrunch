#!/bin/bash

VERSION="0.3"
SCRIPTNAME="$(basename "${0}")"
SCRIPTDIR="$(dirname "${0}")"
TEMP_DIR="$(mktemp -d $1/dpxcrunch_logs-XXXXX)"
DPX_LIST="$(mktemp -p $TEMP_DIR/ dpx_list.XXXXX)"

#_help(){
#	cat <<EOF
#${SCRIPTNAME} ${VERSION}
#
#This is ${Scriptname} ... a work in progress.
#EOF
#}


#Shell function for cleaning up on exit
_cleanup(){
	find "$1" -name "*_rawcooklog\.?????" -print0 | 
	while IFS= read -rd '' rawcooklog; do 
		failedrawcook="$(echo $rawcooklog | sed 's:_rawcooklog\......:.mkv:')"
		reversabilitydata="$(echo $rawcooklog | sed 's:_rawcooklog\......:.rawcooked_reversibility_data:')"
		if [ -e "$failedrawcook" ]
		then 
			echo "\n Removed Failed Rawcook: $failedrawcook" >&2
			rm -f "$rawcookfail1" "$failedrawcook" "$reversabilitydata"
		fi
	 done
	 rm -fr "$TEMP_DIR"
}

#Shell function for batch rawcooking
_rawcooker(){
	RAWCOOKLOG="$(mktemp "${1}"_rawcooklog.XXXXX)"
	echo y | rawcooked --no-check-padding "$1" 2> "$RAWCOOKLOG"
	if grep -q -i error "$RAWCOOKLOG"; then
		echo "\n ERROR: rawcooked failure: see log file: $RAWCOOKLOG" >&2
	else
		rm "$RAWCOOKLOG"
	fi
}
export -f _rawcooker

#while getopts "h" OPTION ; do
#	case "${OPTION}" in
#		h) 
#		  _help ; exit 0
#		  ;;
#		?) 
#		  echo "script usage: $(basename \$0) [-h]" >&2
#		  exit 1
#		  ;;
#	done
#shift "$((OPTIND-1))"



trap "_cleanup $1" EXIT

#Searches for files with .dpx extension. Edits filepath to go up one level, then removes duplicate entries. Outputs DPX filepaths to temporary file.
find $1 -name "*\.dpx" | sed 's:/[^/]*$::' | uniq > $DPX_LIST

#Rawcooks the discovered DPXs in parallel. Maximum of four processes simultaneously
cat $DPX_LIST | parallel -j 4 _rawcooker



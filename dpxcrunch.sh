#!/bin/bash

VERSION="0.1"
SCRIPTNAME="$(basename "${0}")"
SCRIPTDIR="$(dirname "${0}")"
TEMP_DIR="$(mktemp -d $1/dpxcrunch_logs-XXXXX)"
DPX_LIST="$(mktemp -p $TEMP_DIR/ dpx_list.XXXXX)"

_help(){
	cat <<EOF
${SCRIPTNAME} ${VERSION}

This is ${Scriptname} ... a work in progress.
EOF
}

_cleanup(){

#Deletes temporary file containing DPX filepaths.
	rm "$1/dpx_list.tmp"
}

_rawcooked(){
	rawcooklog="$(mktemp $1_rawcooked.XXXXX)"
	rawcooked --no-check-padding $1 2> "$rawcooklog"
	rm "$rawcooklog"
}

export -f _rawcooked

while getopts "h" OPTION ; do
	case "${OPTION}" in
		h) 
		  _help ; exit 0
		  ;;
		?) 
		  echo "script usage: $(basename \$0) [-h]" >&2
		  exit 1
		  ;;
done
shift "$((OPTIND-1))"

trap _cleanup EXIT

#Searches for files with .dpx extension. Edits filepath to go up one level, then removes duplicate entries. Outputs DPX filepaths to temporary file.

find $1 -name "*\.dpx" | sed 's:/[^/]*$::' | uniq > $DPX_LIST

#Rawcooks the discovered DPXs in parallel. Maximum of four processes simultaneously
cat $DPX_LIST | parallel -j 4 _rawcooked {} 



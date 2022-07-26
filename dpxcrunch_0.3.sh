#!/bin/bash

VERSION="0.3"
SCRIPTNAME="$(basename "${0}")"
SCRIPTDIR="$(dirname "${0}")"
audit=false
checksum=false
log=false
purge=false
verbose=false

_usage() { 
	echo "script usage: $(basename \$0) [-h]" 
}

_help(){
	cat <<EOF
${SCRIPTNAME} ${VERSION}

This is ${Scriptname} ... a work in progress.
EOF
}

while getopts "haclpv" OPTION ; do
	case "${OPTION}" in
		h) 
		  _help ; exit 0
		  ;;
		a)
		  audit=true
		  ;;
		c)
		  checksum=true
		  ;;
		l)
		  log=true
		  ;;
		p)
		  purge=true
		  ;;
		v)
		  verbose=true
		  ;;  
		?) 
		  _usage >&2 ; exit 1
		  ;;
	esac
done
shift "$((OPTIND-1))"


#Shell function for verbose mode logging
_verboser(){
	if [[ $verbose == true ]] ; then
		echo "$@"
	fi
}

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

#Shell function for batch rawcooking (requires rawcooked and hashdeep)
_rawcooker(){
	RAWCOOKLOG="$(mktemp "${1}"_dpxcrunch.XXXXX)"
	echo y | rawcooked --no-check-padding "$1" &> "$RAWCOOKLOG"
	cookstatus=$?
	if [[ "$cookstatus" == 0 && "$2" == true ]] ; then	
		hashdeep -rsb "$1" > "$1_hashset.txt"
	fi
	if [[ "$cookstatus" == 0 && "$3" == true && -f "$1_hashset.txt" ]] ; then
		rawcooked "$1.mkv" &>> "$RAWCOOKLOG"
		hashdeep -varbk "$1_hashset.txt" "$1.mkv.RAWcooked" &>> "$RAWCOOKLOG"
		rm -fr "$1.mkv.RAWcooked"			
	elif [[ "$cookstatus" == 0 && "$3" == true && ! -f "$1_hashset.txt" ]] ; then
		hashdeep -rsb "$1" > "$1_hashset.txt"
		rawcooked "$1.mkv" &>> "$RAWCOOKLOG"
		hashdeep -varbk "$1_hashset.txt" "$1.mkv.RAWcooked" &>> "$RAWCOOKLOG"
		rm "$1_hashset.txt"
		rm -fr "$1.mkv.RAWcooked"
	fi
	if [[ "$cookstatus" == 0 && "$4" == true ]] ; then
		cp "$RAWCOOKLOG" "$1_dpxcrunch.txt"
	fi	
	if [[ "$cookstatus" == 0 && "$5" == true ]] ; then
		rm -fr "$1"
	fi	
	if grep -q -i error "$RAWCOOKLOG" ; then
		echo "\n ERROR: Rawcooked failed: see log file: $RAWCOOKLOG" >&2
	elif grep -q -i 'hashdeep: Audit failed' "$RAWCOOKLOG" ; then
		echo "\n ERROR: Hashdeep Audit failed: see log file: $RAWCOOKLOG" >&2
	else
		rm "$RAWCOOKLOG"		
	fi
}

export -f _logger
export -f _rawcooker

trap "_cleanup $1" EXIT

TEMP_DIR="$(mktemp -d $1/dpxcrunch_logs-XXXXX)"
DPX_LIST="$(mktemp -p $TEMP_DIR/ dpx_list.XXXXX)"

#Searches for files with .dpx extension. Edits filepath to go up one level, then removes duplicate entries. Outputs DPX filepaths to temporary file.
find $1 -name "*\.dpx" | sed 's:/[^/]*$::' | uniq > $DPX_LIST

#Rawcooks the discovered DPXs in parallel. Maximum of four processes simultaneously
cat $DPX_LIST | parallel -j 4 _rawcooker {} $checksum $audit $log $purge



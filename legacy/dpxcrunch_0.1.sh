#!/bin/bash

#Searches for files with .dpx extension. Edits filepath to go up one level, then removes duplicate entries. Outputs DPX filepaths to temporary file.

find $1 -name "*\.dpx" | sed 's:/[^/]*$::' | uniq > $1/dpx_list.tmp

#Rawcooks the discovered DPXs in parallel. Maximum of four processes simultaneously
cat "$1/dpx_list.tmp" | parallel -j 4 rawcooked --no-check-padding {}

#Deletes temporary file containing DPX filepaths.
rm "$1/dpx_list.tmp"

#!/bin/bash

# Wrapper that enables parsing multiple logs via single-parser.
#
# A simple way to use this is "./batch-parser.sh *time.txt",
# which would run single-parser on each of the matched files.
#
# Note that the system type cannot be mixed (i.e., log files
# must all be from Giraph or all be from GPS, etc.).

if [ $# -lt 2 ]; then
    echo "usage: $0 system time-log [time-log ...]"
    echo ""
    echo "system: 1 for Giraph, 2 for GPS, 3 for GraphLab, 4 for Mizan"
    echo "time-log: experiment's time log file"
    echo "          (e.g. pagerank_patents-adj.txt_16_2014-01-01-12-30-50_time.txt)"
    exit -1
fi

# constants
SYS_GIRAPH=1
SYS_GPS=2
SYS_GRAPHLAB=3
SYS_MIZAN=4

# check system arg
system=$1
case $system in
    $SYS_GIRAPH) ;;
    $SYS_GPS) ;;
    $SYS_GRAPHLAB) ;;
    $SYS_MIZAN) ;;
    *) echo "Invalid system"; exit -1;;
esac

# read remaining args into array of files
read -a FILES <<< $(echo "${@:2}")

scriptdir=$(dirname "${BASH_SOURCE[0]}")

for file in "${FILES[@]}"; do
    "$scriptdir"/single-parser.sh $system "$file"
done
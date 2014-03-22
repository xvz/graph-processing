#!/bin/bash -e

# Wrapper that enables parsing multiple logs via single-parser.
#
# A simple way to use this is "./batch-parser.sh *_time.txt",
# which would run single-parser on each of the matched files.
#
# Note that the system type cannot be mixed (i.e., log files
# must all be from Giraph or all be from GPS, etc.).

if [ $# -lt 2 ]; then
    echo "usage: $0 system time-logfile [time-logfile ...]"
    echo ""
    echo "system: 0 for Giraph, 1 for GPS, 2 for GraphLab, 3 for Mizan"
    echo "time-logfile: experiment's time log file"
    echo "    (e.g., pagerank_patents-adj.txt_16_2014-01-01-12-30-50_time.txt)"
    exit -1
fi

cd "$(dirname "${BASH_SOURCE[0]}")"

system=$1

# read remaining args into array of files
read -a FILES <<< $(echo "${@:2}")

for file in "${FILES[@]}"; do
    ./single-parser.sh $system "$file"
done
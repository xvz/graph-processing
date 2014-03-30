#!/bin/bash -e

# Converts a SNAP graph input into an undirected graph
# with unique edge weights. Output is in SNAP format,
# with an additional column for weights.
#
# Processor and memory arguments below are used for sort.
procs=$(nproc)
mem=4G

if [ $# -ne 1 ]; then
    echo "usage: $0 input-graph"
    exit -1
fi

scriptdir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
graph=$(echo "$1" | sed 's/.txt$//g')

if [[ ! -f "${graph}.txt" ]]; then
    echo "${graph}.txt does not exist."
    exit -1
fi

if [[ -f "${graph}-mst.txt" ]]; then
    echo "${graph}-mst.txt already exists. Delete it first."
    exit -1
fi

# sort the input, if it's not already sorted
unsorted=$(sort -nk1 -nk2 --parallel=${procs} -S ${mem} -c "${graph}.txt" |& wc -l)

if [[ ${unsorted} -eq 0 ]]; then
    echo "Input already sorted."
    sortedgraph="$graph"
else
    echo "Sorting input..."
    sort -nk1 -nk2 --parallel=${procs} -S ${mem} "${graph}.txt" > "${graph}-sorted.txt"
    sortedgraph="${graph}-sorted"

    echo "Delete unsorted input?"
    rm -i "${graph}.txt"
fi

echo "Converting to MST format..."

"${scriptdir}"/mst-convert "${sortedgraph}.txt" "${graph}-mst-unsorted.txt"

# sort the output
echo "Sorting output..."
sort -nk1 -nk2 --parallel=${procs} -S ${mem} "${graph}-mst-unsorted.txt" > "${graph}-mst.txt"

rm -f "${graph}-mst-unsorted.txt"

echo "Done!"
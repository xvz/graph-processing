#!/bin/bash -e

# second arg is 1 if graph is for MST (SNAP format w/ edge weights)
# and 0 otherwise (regular SNAP format)
if [ $# -ne 2 ]; then
    echo "usage: $0 input-graph do-mst?"
    echo ""
    echo "do-mst: 0 converts regular SNAP format (src dst)"
    echo "        1 converts SNAP with edge weights (src dst weight)"
    exit -1
fi

scriptdir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
graph=$(echo "$1" | sed 's/.txt$//g')
domst=$2

if [[ ! -f "${graph}.txt" ]]; then
    echo "${graph}.txt does not exist."
    exit -1
fi

if [[ -f "${graph}-adj.txt" ]]; then
    echo "${graph}-adj.txt already exists. Delete it first."
    exit -1
fi

# convert graph to adjacency format
echo "Converting to adjacency format..."
if [[ ${domst} -eq 1 ]]; then
    "${scriptdir}"/snap-convert "${graph}.txt" "${graph}-adj.txt" 2 2
else
    "${scriptdir}"/snap-convert "${graph}.txt" "${graph}-adj.txt" 1 1
fi

echo "Done!"
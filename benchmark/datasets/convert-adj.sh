#!/bin/bash -e

# second arg is 1 if graph is for MST (SNAP format w/ edge weights)
# and 0 otherwise (regular SNAP format)
if [ $# -ne 2 ]; then
    echo "usage: $0 [input graph] [mst?]"
    exit -1
fi

scriptdir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
graph=$(echo "$1" | sed 's/.txt$//g')
domst=$2

if [[ -f "${graph}-adj.txt" ]]; then
    echo "${graph}-adj.txt already exists. Delete it first."
    exit -1
fi

# convert graph to adjacency format
echo "Converting to adjacency format..."
if [[ ${domst} -eq 1 ]]; then
    "${scriptdir}"/mizan-convert "${graph}.txt" "${graph}-adj.txt" 2 3
else
    "${scriptdir}"/mizan-convert "${graph}.txt" "${graph}-adj.txt" 1 2
fi

echo "Done!"
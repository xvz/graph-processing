#!/bin/bash -e

# Split given input-graph into parts, placed in input-graph-split/

if [ $# -ne 2 ]; then
    echo "usage: $0 input-graph num-splits"
    exit -1
fi

graph=$(echo "$1" | sed 's/.txt$//g')
numsplits=$2

if [[ ! -f "${graph}.txt" ]]; then
    echo "${graph}.txt does not exist."
    exit -1
fi

if [[ $2 -le 0 ]]; then
    echo "Invalid number of chunks."
    exit -1
fi

if [[ -d "${graph}-split" ]]; then
    echo "${graph}-split/ already exists. Delete it first."
    exit -1
fi

# split input into specified chunks
mkdir "${graph}-split"

echo "Splitting ${graph}.txt..."
split "${graph}.txt" "${graph}-split/${graph}-" -n l/${numsplits}

echo "Done!"
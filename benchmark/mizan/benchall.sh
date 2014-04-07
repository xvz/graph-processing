#!/bin/bash

if [ $# -ne 2 ]; then
    echo "usage: $0 machines runs"
    echo ""
    echo "machines: 4, 8, 16, 32, 64, or 128"
    exit -1
fi

cd "$(dirname "${BASH_SOURCE[0]}")"

MACHINES=$1
RUNS=$2

case ${MACHINES} in
    4)   GRAPHS=(amazon google patents);
         SRC=(0 0 6009554);;  # for SSSP
    8)   GRAPHS=(amazon google patents);
         SRC=(0 0 6009554);;
    16)  GRAPHS=(livejournal orkut arabic);
         SRC=(0 1 3);;
    32)  GRAPHS=(livejournal orkut arabic);
         SRC=(0 1 3);;
    64)  GRAPHS=(livejournal orkut arabic twitter uk0705);
         SRC=(0 1 3 0 0);;
    128) GRAPHS=(livejournal orkut arabic twitter uk0705);
         SRC=(0 1 3 0 0);;
    *) echo "Invalid machines"; exit -1;;
esac


##################
# Premizan
##################
for graph in "${GRAPHS[@]}"; do
    for ((i = 1; i <= RUNS; i++)); do
        ./premizan.sh "${graph}.txt" ${MACHINES} 1
    done
done

##################
# Static run
##################
# we split the algs up for clarity
for graph in "${GRAPHS[@]}"; do
    for ((i = 1; i <= RUNS; i++)); do
        ./pagerank.sh "${graph}.txt" ${MACHINES} 0
    done
done
 
for j in "${!GRAPHS[@]}"; do
    for ((i = 1; i <= RUNS; i++)); do
        ./sssp.sh "${GRAPHS[$j]}.txt" ${MACHINES} 0 ${SRC[$j]}
    done
done
 
for graph in "${GRAPHS[@]}"; do
    for ((i = 1; i <= RUNS; i++)); do
        ./wcc.sh "${graph}.txt" ${MACHINES} 0
    done
done

# MST does not work (issues w/ aggregators + graph mutation in 0.1bu1)
#for graph in "${GRAPHS[@]}"; do
#    for ((i = 1; i <= RUNS; i++)); do
#        ./mst.sh "${graph}-mst.txt" ${MACHINES} 0
#    done
#done

#for graph in "${GRAPHS[@]}"; do
#    for ((i = 1; i <= RUNS; i++)); do
#        ./dimest.sh "${graph}.txt" ${MACHINES} 0
#    done
#done

## Other Mizan modes aren't working correctly,
## so we cannot test them
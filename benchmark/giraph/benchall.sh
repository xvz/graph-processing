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
         GRAPHS_MST=(amazon google patents);
         GRAPHS_MST_HASH=$GRAPHS_MST;
         SRC=(0 0 6009554);;  # for SSSP
    8)   GRAPHS=(amazon google patents);
         GRAPHS_MST=(amazon google patents);
         GRAPHS_MST_HASH=$GRAPHS_MST;
         SRC=(0 0 6009554);;
    16)  GRAPHS=(livejournal orkut arabic twitter);
         GRAPHS_MST=(livejournal orkut arabic);
         GRAPHS_MST_HASH=(livejournal orkut);
         SRC=(0 1 3 0);;
    32)  GRAPHS=(livejournal orkut arabic twitter);
         GRAPHS_MST=(livejournal orkut arabic);
         GRAPHS_MST_HASH=$GRAPHS_MST;
         SRC=(0 1 3 0);;
    64)  GRAPHS=(livejournal orkut arabic twitter uk0705);
         GRAPHS_MST=(livejournal orkut arabic twitter uk0705);
         GRAPHS_MST_HASH=$GRAPHS_MST;
         SRC=(0 1 3 0 0);;
    128) GRAPHS=(livejournal orkut arabic twitter uk0705);
         GRAPHS_MST=(livejournal orkut arabic twitter uk0705);
         GRAPHS_MST_HASH=$GRAPHS_MST;
         SRC=(0 1 3 0 0);;
    *) echo "Invalid machines"; exit -1;;
esac

##################
# Byte array run
##################
# we split the algs up for clarity
for graph in "${GRAPHS[@]}"; do
    for ((i = 1; i <= RUNS; i++)); do
        ./pagerank.sh "${graph}-adj.txt" ${MACHINES} 0
    done
done
 
for j in "${!GRAPHS[@]}"; do
    for ((i = 1; i <= RUNS; i++)); do
        ./sssp.sh "${GRAPHS[$j]}-adj.txt" ${MACHINES} 0 ${SRC[$j]}
    done
done
 
for graph in "${GRAPHS[@]}"; do
    for ((i = 1; i <= RUNS; i++)); do
        ./wcc.sh "${graph}-adj.txt" ${MACHINES} 0
    done
done

## WARNING: this can be VERY slow for large graphs!!
#for graph in "${GRAPHS_MST[@]}"; do
#    for ((i = 1; i <= RUNS; i++)); do
#        ./mst.sh "${graph}-mst-adj.txt" ${MACHINES} 0
#    done
#done

#for graph in "${GRAPHS[@]}"; do
#    for ((i = 1; i <= RUNS; i++)); do
#        ./dimest.sh "${graph}-adj.txt" ${MACHINES} 0
#    done
#done


#####################
# Hash map run
#####################
for graph in "${GRAPHS[@]}"; do
    for ((i = 1; i <= RUNS; i++)); do
        ./pagerank.sh "${graph}-adj.txt" ${MACHINES} 1
    done
done
 
for j in "${!GRAPHS[@]}"; do
    for ((i = 1; i <= RUNS; i++)); do
        ./sssp.sh "${GRAPHS[$j]}-adj.txt" ${MACHINES} 1 ${SRC[$j]}
    done
done
 
for graph in "${GRAPHS[@]}"; do
    for ((i = 1; i <= RUNS; i++)); do
        ./wcc.sh "${graph}-adj.txt" ${MACHINES} 1
    done
done

for graph in "${GRAPHS_MST_HASH[@]}"; do
    for ((i = 1; i <= RUNS; i++)); do
        ./mst.sh "${graph}-mst-adj.txt" ${MACHINES} 1
    done
done

#for graph in "${GRAPHS[@]}"; do
#    for ((i = 1; i <= RUNS; i++)); do
#        ./dimest.sh "${graph}-adj.txt" ${MACHINES} 1
#    done
#done
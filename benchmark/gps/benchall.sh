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
         SRC=(0 0 6009554);;  # for SSSP
    8)   GRAPHS=(amazon google patents);
         GRAPHS_MST=(amazon google patents);
         SRC=(0 0 6009554);;
    16)  GRAPHS=(livejournal orkut arabic twitter);
         GRAPHS_MST=(livejournal orkut arabic);
         SRC=(0 1 3 0);;
    32)  GRAPHS=(livejournal orkut arabic twitter);
         GRAPHS_MST=(livejournal orkut arabic);
         SRC=(0 1 3 0);;
    64)  GRAPHS=(livejournal orkut arabic twitter uk0705);
         GRAPHS_MST=(livejournal orkut arabic twitter);
         SRC=(0 1 3 0 0);;
    128) GRAPHS=(livejournal orkut arabic twitter uk0705);
         GRAPHS_MST=(livejournal orkut arabic twitter uk0705);
         SRC=(0 1 3 0 0);;
    *) echo "Invalid machines"; exit -1;;
esac

#################
# Normal run
#################
# we split the algs up for simplicity
for graph in "${GRAPHS[@]}"; do
    for ((i = 1; i <= RUNS; i++)); do
        ./pagerank.sh "${graph}-adj.txt" ${MACHINES} 0
        ./stop-nodes.sh
        sleep 80
    done
done
 
for j in "${!GRAPHS[@]}"; do
    for ((i = 1; i <= RUNS; i++)); do
        ./sssp.sh "${GRAPHS[$j]}-adj.txt" ${MACHINES} 0 ${SRC[$j]}
        ./stop-nodes.sh
        sleep 80
    done
done
 
for graph in "${GRAPHS[@]}"; do
    for ((i = 1; i <= RUNS; i++)); do
        ./wcc.sh "${graph}-adj.txt" ${MACHINES} 0
        ./stop-nodes.sh
        sleep 80
    done
done

for graph in "${GRAPHS_MST[@]}"; do
    for ((i = 1; i <= RUNS; i++)); do
        ./mst.sh "${graph}-mst-adj.txt" ${MACHINES}
        ./stop-nodes.sh
        sleep 80
    done
done

#./enable-dimest-fix.sh
#for graph in "${GRAPHS[@]}"; do
#    for ((i = 1; i <= RUNS; i++)); do
#        ./dimest.sh "${graph}-adj.txt" ${MACHINES} 0
#        ./stop-nodes.sh
#        sleep 80
#    done
#done
#./disable-dimest-fix.sh

#################
# LALP Run
#################
for graph in "${GRAPHS[@]}"; do
    for ((i = 1; i <= RUNS; i++)); do
        ./pagerank.sh "${graph}-adj.txt" ${MACHINES} 1
        ./stop-nodes.sh
        sleep 80
    done
done
 
for j in "${!GRAPHS[@]}"; do
    for ((i = 1; i <= RUNS; i++)); do
        ./sssp.sh "${GRAPHS[$j]}-adj.txt" ${MACHINES} 1 ${SRC[$j]}
        ./stop-nodes.sh
        sleep 80
    done
done
 
for graph in "${GRAPHS[@]}"; do
    for ((i = 1; i <= RUNS; i++)); do
        ./wcc.sh "${graph}-adj.txt" ${MACHINES} 1
        ./stop-nodes.sh
        sleep 80
    done
done

# no MST

#./enable-dimest-fix.sh
#for graph in "${GRAPHS[@]}"; do
#    for ((i = 1; i <= RUNS; i++)); do
#        ./dimest.sh "${graph}-adj.txt" ${MACHINES} 0
#        ./stop-nodes.sh
#        sleep 80
#    done
#done
#./disable-dimest-fix.sh

#################
# Dynamic Run
#################
for graph in "${GRAPHS[@]}"; do
    for ((i = 1; i <= RUNS; i++)); do
        ./pagerank.sh "${graph}-adj.txt" ${MACHINES} 2
        ./stop-nodes.sh
        sleep 80
    done
done
 
for j in "${!GRAPHS[@]}"; do
    for ((i = 1; i <= RUNS; i++)); do
        ./sssp.sh "${GRAPHS[$j]}-adj.txt" ${MACHINES} 2 ${SRC[$j]}
        ./stop-nodes.sh
        sleep 80
    done
done
 
for graph in "${GRAPHS[@]}"; do
    for ((i = 1; i <= RUNS; i++)); do
        ./wcc.sh "${graph}-adj.txt" ${MACHINES} 2
        ./stop-nodes.sh
        sleep 80
    done
done

# no MST

#./enable-dimest-fix.sh
#for graph in "${GRAPHS[@]}"; do
#    for ((i = 1; i <= RUNS; i++)); do
#        ./dimest.sh "${graph}-adj.txt" ${MACHINES} 0
#        ./stop-nodes.sh
#        sleep 80
#    done
#done
#./disable-dimest-fix.sh
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
         TOL=(0.408805 2.306985 2.220446E-16);   # for PageRank
         SRC=(0 0 6009554);;  # for SSSP
    8)   GRAPHS=(amazon google patents);
         TOL=(0.408805 2.306985 2.220446E-16);
         SRC=(0 0 6009554);;
    16)  GRAPHS=(livejournal orkut arabic twitter);
         TOL=(0.392500 0.011872 75.448252 0.769316);
         SRC=(0 1 3 0);;
    32)  GRAPHS=(livejournal orkut arabic twitter);
         TOL=(0.392500 0.011872 75.448252 0.769316);
         SRC=(0 1 3 0);;
    64)  GRAPHS=(livejournal orkut arabic twitter uk0705);
         TOL=(0.392500 0.011872 75.448252 0.769316 186.053578);
         SRC=(0 1 3 0 0);;
    128) GRAPHS=(livejournal orkut arabic twitter uk0705);
         TOL=(0.392500 0.011872 75.448252 0.769316 186.053578);
         SRC=(0 1 3 0 0);;
    *) echo "Invalid machines"; exit -1;;
esac

#################
# Sync run
#################
# we split the algs up for simplicity
for j in "${!GRAPHS[@]}"; do
    for ((i = 1; i <= RUNS; i++)); do
        ./pagerank.sh "${GRAPHS[$j]}-adj-split/" ${MACHINES} 0 ${TOL[$j]}
    done
done
 
for j in "${!GRAPHS[@]}"; do
    for ((i = 1; i <= RUNS; i++)); do
        ./sssp.sh "${GRAPHS[$j]}-adj-split/" ${MACHINES} 0 ${SRC[$j]}
    done
done
 
for graph in "${GRAPHS[@]}"; do
    for ((i = 1; i <= RUNS; i++)); do
        ./wcc.sh "${graph}-adj-split/" ${MACHINES}
    done
done

#for graph in "${GRAPHS[@]}"; do
#    for ((i = 1; i <= RUNS; i++)); do
#        ./dimest.sh "${graph}-adj-split/" ${MACHINES}
#    done
#done

#################
# Async Run
#################
for j in "${!GRAPHS[@]}"; do
    for ((i = 1; i <= RUNS; i++)); do
        ./pagerank.sh "${GRAPHS[$j]}-adj-split/" ${MACHINES} 1 ${TOL[$j]}
    done
done

for j in "${!GRAPHS[@]}"; do
    for ((i = 1; i <= RUNS; i++)); do
        ./sssp.sh "${GRAPHS[$j]}-adj-split/" ${MACHINES} 1 ${SRC[$j]}
    done
done

# no WCC
# no dimest
#!/bin/bash -e

commondir=$(dirname "${BASH_SOURCE[0]}")/../common
source "$commondir"/get-hosts.sh
source "$commondir"/get-dirs.sh

# recompile GraphLab
cd "$GRAPHLAB_DIR"/release/toolkits/graph_analytics/
make -j $(nproc)

for ((i = 1; i <= ${NUM_MACHINES}; i++)); do
    # NOTE: only copy binaries that will actually be used.. it takes too long otherwise
    scp ./pagerank ${CLUSTER_NAME}${i}:"$GRAPHLAB_DIR"/release/toolkits/graph_analytics/ &
    scp ./sssp ${CLUSTER_NAME}${i}:"$GRAPHLAB_DIR"/release/toolkits/graph_analytics/ &
    scp ./connected_component ${CLUSTER_NAME}$i:"$GRAPHLAB_DIR"/release/toolkits/graph_analytics/ &
    scp ./approximate_diameter ${CLUSTER_NAME}$i:"$GRAPHLAB_DIR"/release/toolkits/graph_analytics/ &

    rsync -avz --exclude '*.make' --exclude '*.cmake' "$GRAPHLAB_DIR"/deps/local/ ${CLUSTER_NAME}${i}:"$GRAPHLAB_DIR"/deps/local 
done
wait

echo "OK."
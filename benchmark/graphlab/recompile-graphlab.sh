#!/bin/bash -e

commondir=$(dirname "${BASH_SOURCE[0]}")/../common
source "$commondir"/get-hosts.sh
source "$commondir"/get-dirs.sh

# recompile GraphLab
cd "$GRAPHLAB_DIR"/release/toolkits/graph_analytics/
make -j $(nproc)

for ((i = 1; i <= ${nodes}; i++)); do
    # NOTE: only copy binaries that will actually be used.. it takes too long otherwise
    scp ./pagerank ${name}${i}:"$GRAPHLAB_DIR"/release/toolkits/graph_analytics/ &
    scp ./sssp ${name}${i}:"$GRAPHLAB_DIR"/release/toolkits/graph_analytics/ &
    scp ./connected_component ${name}$i:"$GRAPHLAB_DIR"/release/toolkits/graph_analytics/ &
    scp ./approximate_diameter ${name}$i:"$GRAPHLAB_DIR"/release/toolkits/graph_analytics/ &

    rsync -avz --exclude '*.make' --exclude '*.cmake' "$GRAPHLAB_DIR"/deps/local/ ${name}${i}:"$GRAPHLAB_DIR"/deps/local 
done
wait

echo "OK."
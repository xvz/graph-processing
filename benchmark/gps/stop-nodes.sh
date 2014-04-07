#!/bin/bash

# Does the same thing as master-scripts/stop_gps_nodes.sh, but faster.
# Also removes the need for a separate scripts/stop_nodes.sh.
#
# NOTE: we do not use a slave file, as we only need to ssh to each
# machine once to kill all its workers.

source $(dirname "${BASH_SOURCE[0]}")/../common/get-hosts.sh

kill -9 $(ps aux | grep "[g]ps_node_runner" | awk '{print $2}')

for ((i = 1; i <= ${machines}; i++)); do
    ssh ${name}${i} "kill -9 \$(ps aux | grep \"[g]ps_node_runner\" | awk '{print \$2}')" &
done
wait
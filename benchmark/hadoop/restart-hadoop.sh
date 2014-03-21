#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")"/../common/get-hosts.sh

stop-all.sh

# do a kill on the master separately---this is useful when testing on a single machine
kill -9 $(pgrep java)

for ((i = 1; i <= ${nodes}; i++)); do
    ssh ${name}${i} "kill -9 \$(pgrep java)" &
done
wait

start-all.sh
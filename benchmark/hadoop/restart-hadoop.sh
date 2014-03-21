#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")"/../common/get-hosts.sh

stop-all.sh

for ((i = 0; i <= ${nodes}; i++)); do
    ssh ${name}${i} 'kill -9 $(pgrep java)' &
done
wait

start-all.sh
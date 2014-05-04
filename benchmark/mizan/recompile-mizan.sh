#!/bin/bash -e

commondir=$(dirname "${BASH_SOURCE[0]}")/../common
source "$commondir"/get-hosts.sh
source "$commondir"/get-dirs.sh

# recompile Mizan
touch "$MIZAN_DIR"/src/main.cpp
cd "$MIZAN_DIR/Release"
make all

for ((i = 1; i <= ${NUM_MACHINES}; i++)); do
  scp ./Mizan-0.1b ${CLUSTER_NAME}${i}:"$MIZAN_DIR"/Release/ &
done
wait

echo "OK."
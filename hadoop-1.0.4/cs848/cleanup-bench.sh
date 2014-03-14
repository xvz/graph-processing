#!/bin/bash

hostname=$(hostname)

case ${hostname} in
    "cloud0") name=cloud; nodes=4;;
    "cld0") name=cld; nodes=8;;
    "c0") name=c; nodes=16;;
    "cx0") name=cx; nodes=32;;
    "cy0") name=cy; nodes=64;;
    "cz0") name=cz; nodes=128;;
    *) echo "Invalid hostname"; exit -1;;
esac

# cleans up rogue stat programs
for ((i = 0; i <= ${nodes}; i++)); do
    ssh ${name}${i} 'kill $(pgrep sar); kill $(pgrep free)' &
done
wait
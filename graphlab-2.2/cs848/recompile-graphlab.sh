#!/bin/bash -e

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

# recompile GraphLab
cd ../release/toolkits/graph_analytics/
make

for ((i = 1; i <= ${nodes}; i++)); do
    # NOTE: only copy binaries that will actually be used.. it takes too long otherwise
    scp ./pagerank ${name}$i:$PWD/ &
    scp ./sssp ${name}$i:$PWD/ &
    rsync -avz --exclude '*.make' --exclude '*.cmake' ~/graphlab-2.2/deps/local/ ${name}$i:~/graphlab-2.2/deps/local 
done
wait

echo "OK."
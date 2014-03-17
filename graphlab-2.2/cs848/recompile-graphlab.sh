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
# todo...

for((i=1;i<=${nodes};i++)); do
    # rsync is smart, won't copy unchanged files
    rsync -az --exclude '*.make' --exclude '*.cmake' ~/graphlab-2.2/release/toolkits/ ${name}$i:~/graphlab-2.2/release/toolkits &
    rsync -az --exclude '*.make' --exclude '*.cmake' ~/graphlab-2.2/deps/local/ ${name}$i:~/graphlab-2.2/deps/local &
done
wait

echo "OK."
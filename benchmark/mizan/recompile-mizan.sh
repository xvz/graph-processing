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

# recompile Mizan
touch ../src/main.cpp
cd ../Release
make all

for ((i = 1; i <= ${nodes}; i++)); do
  scp ../Release/Mizan-0.1b ${name}$i:~/Mizan-0.1bu1/Release/ &
done
wait

echo "OK."
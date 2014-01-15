#!/bin/bash -e

# recompile Mizan
touch ../src/main.cpp
cd ../Release
make all

for((i=2;i<=4;i++)); do
  scp ../Release/Mizan-0.1b cloud${i}:~/Mizan-0.1bu1/Release/
done

echo "OK."
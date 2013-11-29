#!/bin/bash -e

# recompile Mizan
touch ../src/main.cpp
cd ../Release
make all

echo "OK."
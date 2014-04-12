#!/bin/bash -e

./plot.py 0 --save-paper
./plot.py 1 --save-paper
./plot.py 2 --save-paper

./plot.py 1 --master --save-paper
./plot.py 2 --master --save-paper

./plot.py 1 --premizan --save-paper
./plot.py 2 --premizan --save-paper
./plot.py 1 --premizan --master --save-paper
./plot.py 2 --premizan --master --save-paper
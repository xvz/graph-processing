#!/bin/bash -e

./plot.py 0 --save-paper
./plot.py 1 --save-paper --plot-max
./plot.py 2 --save-paper --plot-sum

./plot-with-cuts.py 0 --save-paper
./plot-with-cuts.py 2 --save-paper
#!/bin/bash -e

./plot.py 0 --save-eps
./plot.py 1 --save-eps
./plot.py 2 --save-eps

./plot.py 1 --do-master --save-eps
./plot.py 2 --do-master --save-eps

./plot.py 1 --do-premizan --save-eps
./plot.py 2 --do-premizan --save-eps
./plot.py 1 --do-premizan --do-master --save-eps
./plot.py 2 --do-premizan --do-master --save-eps
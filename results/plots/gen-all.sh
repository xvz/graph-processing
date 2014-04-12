#!/bin/bash -e

./gen-data.py 0 > data_time.py
./gen-data.py 1 > data_mem.py
./gen-data.py 2 > data_net.py

./gen-data.py 1 --master > data_mem_master.py
./gen-data.py 2 --master > data_net_master.py
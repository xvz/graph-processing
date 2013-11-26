#!/bin/bash -e

read -p "Any key to continue..." none

hadoop dfs -mkdir /user/ubuntu/gps-input/
hadoop dfs -mkdir /user/ubuntu/gps-machine-config/
hadoop dfs -put cs848.cfg /user/ubuntu/gps-machine-config/
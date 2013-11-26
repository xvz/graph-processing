#!/bin/bash -e

read -p "Any key to continue..." none

mkdir ~/var/tmp
hadoop dfs -mkdir /user/ubuntu/gps-machine-config/
hadoop dfs -put cs848.cfg /user/ubuntu/gps-machine-config/
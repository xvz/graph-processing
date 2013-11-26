#!/bin/bash

read -p "Any key to continue..." none

cd ../raw/

# giraph
hadoop dfs -rmr ./giraph-input
hadoop dfs -mkdir ./giraph-input
hadoop dfs -put amazon-giraph.txt ./giraph-input
hadoop dfs -put google-giraph.txt ./giraph-input
hadoop dfs -put patents-giraph.txt ./giraph-input
hadoop dfs -put road-giraph.txt ./giraph-input

# gps
hadoop dfs -rmr ./gps-input
hadoop dfs -mkdir ./gps-input
hadoop dfs -put amazon-gps-noval.txt ./gps-input
hadoop dfs -put google-gps-noval.txt ./gps-input
hadoop dfs -put patents-gps-noval.txt ./gps-input
hadoop dfs -put road-gps-noval.txt ./gps-input

# mizan
hadoop dfs -rmr ./input
hadoop dfs -mkdir ./input
hadoop dfs -put amazon.txt ./input
hadoop dfs -put google.txt ./input
hadoop dfs -put patents.txt ./input
hadoop dfs -put road.txt ./input

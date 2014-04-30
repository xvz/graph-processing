#!/bin/bash

# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#
#
#
# This script is used to start clusters on Amazon EC2, run a benchmark for multiple graph processing systems (GPS, Giraph, Graphlab, and Mizan) and collect their results.
# script written by Khaled Ammar: kammar@uwaterloo.ca
#
# NOTE: In the current version, experiment name ($expName) should not change because some files depends on it
#
#
# You can use one command only to run the benchmark with a cluster size.
# This command is "run-all"
#
# Example: ./run-benchmark.sh -i $PEMFILE -k $PEMNAME -r us-west-2 -z us-west-2c -s $expSIZE --spot-price $spotPrice run-all $expNAME
#
#
#

############################################################################
# CONFIGURATION
############################################################################
export AWS_ACCESS_KEY_ID=<access key>
export AWS_SECRET_ACCESS_KEY=<secret access key>
######################################################################

export PEMFILE=<path to pem file>
export PEMNAME=<key name>
export sportPrice=<price you are welling to pay for a spot instance, e.g., 0.03>

export expNAME=cloud
export expSIZE=4

for expSIZE in {4,8, 16, 32, 64, 128}
do

case $expSIZE in
4)   expNAME=cloud;;
8)   expNAME=cld;;
16)  expNAME=cw;;
32)  expNAME=cx;;
64)  expNAME=cy;;
128) expNAME=cz;;
*) echo "Invalid number of machines"; exit -1;;
esac


./run-benchmark.sh -i $PEMFILE -k $PEMNAME -r us-west-2 -z us-west-2c -s $expSIZE --spot-price $spotPrice launch $expNAME

./run-benchmark.sh -i $PEMFILE -k $PEMNAME -r us-west-2 -z us-west-2c -s $expSIZE --spot-price $spotPrice assign-tags $expNAME

./run-benchmark.sh -i $PEMFILE -k $PEMNAME -r us-west-2 -z us-west-2c -s $expSIZE --spot-price $spotPrice initialize $expNAME

./run-benchmark.sh -i $PEMFILE -k $PEMNAME -r us-west-2 -z us-west-2c -s $expSIZE --spot-price $spotPrice benchmark $expNAME

./run-benchmark.sh -i $PEMFILE -k $PEMNAME -r us-west-2 -z us-west-2c -s $expSIZE --spot-price $spotPrice results $expNAME

./run-benchmark.sh -i $PEMFILE -k $PEMNAME -r us-west-2 -z us-west-2c -s $expSIZE --spot-price $spotPrice close $expNAME

done

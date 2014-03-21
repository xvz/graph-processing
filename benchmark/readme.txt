Scripts specific to each system and/or Hadoop are located in their respective folders. Scripts common across multiple systems (e.g., pre- and post-benchmarking setup/cleanup scripts) are in "common".

All results are stored in ./system/logs/, where system is giraph, gps, graphlab, or mizan.

WARNING: Everything has only been tested in bash! Things may or may not break if you use a different shell.
WARNING: The scripts are NOT robust against spaces in folder/file names! Do not use spaces in system folder names and do not place "benchmark" folder in a place with spaces.

NOTE: Benching scripts MUST be run from their folders (i.e., $PWD = location of script)---otherwise they won't work. Other scripts can be ran from anywhere.

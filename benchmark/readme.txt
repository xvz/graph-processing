=====================================================================
Please see the wiki at http://github.com/xvz/graph-processing/wiki/
=====================================================================

Scripts specific to each system and/or Hadoop are located in their respective folders. Scripts common across multiple systems (e.g., pre- and post-benchmarking setup/cleanup scripts) are in "common".

All results are stored in ./<system>/logs/, where system is giraph, gps, graphlab, or mizan.

WARNING: Everything has only been tested in bash! Things may or may not break if you use a different shell.

NOTE: Benching scripts MUST be run from their folders (i.e., $PWD = location of script)---otherwise they won't work. Other scripts can be ran from anywhere.

#!/bin/bash
WORKERS=4

./sssp.sh google-gps-noval.txt ${WORKERS} 0
sleep 60   # need delay, otherwise will fail
./sssp.sh google-gps-noval.txt ${WORKERS} 0
sleep 60
./sssp.sh google-gps-noval.txt ${WORKERS} 0
sleep 60
 
#./sssp.sh amazon-gps-noval.txt ${WORKERS} 0
#./sssp.sh amazon-gps-noval.txt ${WORKERS} 0
#./sssp.sh amazon-gps-noval.txt ${WORKERS} 0
# 
#./sssp.sh patents-gps-noval.txt ${WORKERS} 6009554
#./sssp.sh patents-gps-noval.txt ${WORKERS} 6009554
#./sssp.sh patents-gps-noval.txt ${WORKERS} 6009554
# 
# 
#./pagerank.sh google-gps-noval.txt ${WORKERS}
#./pagerank.sh google-gps-noval.txt ${WORKERS}
#./pagerank.sh google-gps-noval.txt ${WORKERS}
#
#./pagerank.sh amazon-gps-noval.txt ${WORKERS}
#./pagerank.sh amazon-gps-noval.txt ${WORKERS}
#./pagerank.sh amazon-gps-noval.txt ${WORKERS}
# 
#./pagerank.sh patents-gps-noval.txt ${WORKERS}
#./pagerank.sh patents-gps-noval.txt ${WORKERS}
#./pagerank.sh patents-gps-noval.txt ${WORKERS}
#!/bin/bash
WORKERS=4

./pagerank.sh amazon-gps-noval.txt ${WORKERS} 0
sleep 60    # need delay, otherwise will fail
./pagerank.sh amazon-gps-noval.txt ${WORKERS} 0
sleep 60
./pagerank.sh amazon-gps-noval.txt ${WORKERS} 0
sleep 60
./pagerank.sh amazon-gps-noval.txt ${WORKERS} 0
sleep 60
./pagerank.sh amazon-gps-noval.txt ${WORKERS} 0
sleep 60
./pagerank.sh amazon-gps-noval.txt ${WORKERS} 0
sleep 60

./pagerank.sh amazon-gps-noval.txt ${WORKERS} 1
sleep 60    # need delay, otherwise will fail
./pagerank.sh amazon-gps-noval.txt ${WORKERS} 1
sleep 60
./pagerank.sh amazon-gps-noval.txt ${WORKERS} 1
sleep 60
./pagerank.sh amazon-gps-noval.txt ${WORKERS} 1
sleep 60
./pagerank.sh amazon-gps-noval.txt ${WORKERS} 1
sleep 60
./pagerank.sh amazon-gps-noval.txt ${WORKERS} 1
sleep 60


./pagerank.sh google-gps-noval.txt ${WORKERS} 0
sleep 60
./pagerank.sh google-gps-noval.txt ${WORKERS} 0
sleep 60
./pagerank.sh google-gps-noval.txt ${WORKERS} 0
sleep 60
./pagerank.sh google-gps-noval.txt ${WORKERS} 0
sleep 60
./pagerank.sh google-gps-noval.txt ${WORKERS} 0
sleep 60
./pagerank.sh google-gps-noval.txt ${WORKERS} 0
sleep 60

./pagerank.sh google-gps-noval.txt ${WORKERS} 1
sleep 60
./pagerank.sh google-gps-noval.txt ${WORKERS} 1
sleep 60
./pagerank.sh google-gps-noval.txt ${WORKERS} 1
sleep 60
./pagerank.sh google-gps-noval.txt ${WORKERS} 1
sleep 60
./pagerank.sh google-gps-noval.txt ${WORKERS} 1
sleep 60
./pagerank.sh google-gps-noval.txt ${WORKERS} 1
sleep 60


./pagerank.sh patents-gps-noval.txt ${WORKERS} 0
sleep 60
./pagerank.sh patents-gps-noval.txt ${WORKERS} 0
sleep 60
./pagerank.sh patents-gps-noval.txt ${WORKERS} 0
sleep 60
./pagerank.sh patents-gps-noval.txt ${WORKERS} 0
sleep 60
./pagerank.sh patents-gps-noval.txt ${WORKERS} 0
sleep 60
./pagerank.sh patents-gps-noval.txt ${WORKERS} 0
sleep 60

./pagerank.sh patents-gps-noval.txt ${WORKERS} 1
sleep 60
./pagerank.sh patents-gps-noval.txt ${WORKERS} 1
sleep 60
./pagerank.sh patents-gps-noval.txt ${WORKERS} 1
sleep 60
./pagerank.sh patents-gps-noval.txt ${WORKERS} 1
sleep 60
./pagerank.sh patents-gps-noval.txt ${WORKERS} 1
sleep 60
./pagerank.sh patents-gps-noval.txt ${WORKERS} 1
sleep 60


##===============================================
##===============================================
##===============================================

#./sssp.sh amazon-gps-noval.txt ${WORKERS} 0 0
#sleep 60
#./sssp.sh amazon-gps-noval.txt ${WORKERS} 0 0
#sleep 60
#./sssp.sh amazon-gps-noval.txt ${WORKERS} 0 0
#sleep 60
#./sssp.sh amazon-gps-noval.txt ${WORKERS} 0 0
#sleep 60
#./sssp.sh amazon-gps-noval.txt ${WORKERS} 0 0
#sleep 60
#./sssp.sh amazon-gps-noval.txt ${WORKERS} 0 0
#sleep 60
# 
#./sssp.sh amazon-gps-noval.txt ${WORKERS} 0 1
#sleep 60
#./sssp.sh amazon-gps-noval.txt ${WORKERS} 0 1
#sleep 60
#./sssp.sh amazon-gps-noval.txt ${WORKERS} 0 1
#sleep 60
#./sssp.sh amazon-gps-noval.txt ${WORKERS} 0 1
#sleep 60
#./sssp.sh amazon-gps-noval.txt ${WORKERS} 0 1
#sleep 60
#./sssp.sh amazon-gps-noval.txt ${WORKERS} 0 1
#sleep 60
# 
#
#./sssp.sh google-gps-noval.txt ${WORKERS} 0 0
#sleep 60
#./sssp.sh google-gps-noval.txt ${WORKERS} 0 0
#sleep 60
#./sssp.sh google-gps-noval.txt ${WORKERS} 0 0
#sleep 60
#./sssp.sh google-gps-noval.txt ${WORKERS} 0 0
#sleep 60
#./sssp.sh google-gps-noval.txt ${WORKERS} 0 0
#sleep 60
#./sssp.sh google-gps-noval.txt ${WORKERS} 0 0
#sleep 60
# 
#./sssp.sh google-gps-noval.txt ${WORKERS} 0 1
#sleep 60
#./sssp.sh google-gps-noval.txt ${WORKERS} 0 1
#sleep 60
#./sssp.sh google-gps-noval.txt ${WORKERS} 0 1
#sleep 60
#./sssp.sh google-gps-noval.txt ${WORKERS} 0 1
#sleep 60
#./sssp.sh google-gps-noval.txt ${WORKERS} 0 1
#sleep 60
#./sssp.sh google-gps-noval.txt ${WORKERS} 0 1
#sleep 60
#
#
#./sssp.sh patents-gps-noval.txt ${WORKERS} 6009554 0
#sleep 60
#./sssp.sh patents-gps-noval.txt ${WORKERS} 6009554 0
#sleep 60
#./sssp.sh patents-gps-noval.txt ${WORKERS} 6009554 0
#sleep 60
#./sssp.sh patents-gps-noval.txt ${WORKERS} 6009554 0
#sleep 60
#./sssp.sh patents-gps-noval.txt ${WORKERS} 6009554 0
#sleep 60
#./sssp.sh patents-gps-noval.txt ${WORKERS} 6009554 0
#sleep 60
#
#./sssp.sh patents-gps-noval.txt ${WORKERS} 6009554 1
#sleep 60
#./sssp.sh patents-gps-noval.txt ${WORKERS} 6009554 1
#sleep 60
#./sssp.sh patents-gps-noval.txt ${WORKERS} 6009554 1
#sleep 60
#./sssp.sh patents-gps-noval.txt ${WORKERS} 6009554 1
#sleep 60
#./sssp.sh patents-gps-noval.txt ${WORKERS} 6009554 1
#sleep 60
#./sssp.sh patents-gps-noval.txt ${WORKERS} 6009554 1
#sleep 60
 
#===============================================
#===============================================
#===============================================

#./wcc.sh amazon-gps-noval.txt ${WORKERS} 0
#sleep 60
#./wcc.sh amazon-gps-noval.txt ${WORKERS} 0
#sleep 60
#./wcc.sh amazon-gps-noval.txt ${WORKERS} 0
#sleep 60
#./wcc.sh amazon-gps-noval.txt ${WORKERS} 0
#sleep 60
#./wcc.sh amazon-gps-noval.txt ${WORKERS} 0
#sleep 60
#./wcc.sh amazon-gps-noval.txt ${WORKERS} 0
#sleep 60
# 
#./wcc.sh amazon-gps-noval.txt ${WORKERS} 1
#sleep 60
#./wcc.sh amazon-gps-noval.txt ${WORKERS} 1
#sleep 60
#./wcc.sh amazon-gps-noval.txt ${WORKERS} 1
#sleep 60
#./wcc.sh amazon-gps-noval.txt ${WORKERS} 1
#sleep 60
#./wcc.sh amazon-gps-noval.txt ${WORKERS} 1
#sleep 60
#./wcc.sh amazon-gps-noval.txt ${WORKERS} 1
#sleep 60
#
#
#./wcc.sh google-gps-noval.txt ${WORKERS} 0
#sleep 60
#./wcc.sh google-gps-noval.txt ${WORKERS} 0
#sleep 60
#./wcc.sh google-gps-noval.txt ${WORKERS} 0
#sleep 60
#./wcc.sh google-gps-noval.txt ${WORKERS} 0
#sleep 60
#./wcc.sh google-gps-noval.txt ${WORKERS} 0
#sleep 60
#./wcc.sh google-gps-noval.txt ${WORKERS} 0
#sleep 60
# 
#./wcc.sh google-gps-noval.txt ${WORKERS} 1
#sleep 60
#./wcc.sh google-gps-noval.txt ${WORKERS} 1
#sleep 60
#./wcc.sh google-gps-noval.txt ${WORKERS} 1
#sleep 60
#./wcc.sh google-gps-noval.txt ${WORKERS} 1
#sleep 60
#./wcc.sh google-gps-noval.txt ${WORKERS} 1
#sleep 60
#./wcc.sh google-gps-noval.txt ${WORKERS} 1
#sleep 60
# 
#
#./wcc.sh patents-gps-noval.txt ${WORKERS} 0
#sleep 60
#./wcc.sh patents-gps-noval.txt ${WORKERS} 0
#sleep 60
#./wcc.sh patents-gps-noval.txt ${WORKERS} 0
#sleep 60
#./wcc.sh patents-gps-noval.txt ${WORKERS} 0
#sleep 60
#./wcc.sh patents-gps-noval.txt ${WORKERS} 0
#sleep 60
#./wcc.sh patents-gps-noval.txt ${WORKERS} 0
#sleep 60
#
#./wcc.sh patents-gps-noval.txt ${WORKERS} 1
#sleep 60
#./wcc.sh patents-gps-noval.txt ${WORKERS} 1
#sleep 60
#./wcc.sh patents-gps-noval.txt ${WORKERS} 1
#sleep 60
#./wcc.sh patents-gps-noval.txt ${WORKERS} 1
#sleep 60
#./wcc.sh patents-gps-noval.txt ${WORKERS} 1
#sleep 60
#./wcc.sh patents-gps-noval.txt ${WORKERS} 1
#sleep 60

#===============================================
#===============================================
#===============================================

#./mst.sh amazon-mst-gps.txt ${WORKERS} 0
#sleep 60
#./mst.sh amazon-mst-gps.txt ${WORKERS} 0
#sleep 60
#./mst.sh amazon-mst-gps.txt ${WORKERS} 0
#sleep 60
#./mst.sh amazon-mst-gps.txt ${WORKERS} 0
#sleep 60
#./mst.sh amazon-mst-gps.txt ${WORKERS} 0
#sleep 60
#./mst.sh amazon-mst-gps.txt ${WORKERS} 0
#sleep 60
# 
#./mst.sh amazon-mst-gps.txt ${WORKERS} 1
#sleep 60
#./mst.sh amazon-mst-gps.txt ${WORKERS} 1
#sleep 60
#./mst.sh amazon-mst-gps.txt ${WORKERS} 1
#sleep 60
#./mst.sh amazon-mst-gps.txt ${WORKERS} 1
#sleep 60
#./mst.sh amazon-mst-gps.txt ${WORKERS} 1
#sleep 60
#./mst.sh amazon-mst-gps.txt ${WORKERS} 1
#sleep 60
# 
#
#./mst.sh google-mst-gps.txt ${WORKERS} 0
#sleep 60
#./mst.sh google-mst-gps.txt ${WORKERS} 0
#sleep 60
#./mst.sh google-mst-gps.txt ${WORKERS} 0
#sleep 60
#./mst.sh google-mst-gps.txt ${WORKERS} 0
#sleep 60
#./mst.sh google-mst-gps.txt ${WORKERS} 0
#sleep 60
#./mst.sh google-mst-gps.txt ${WORKERS} 0
#sleep 60
# 
#./mst.sh google-mst-gps.txt ${WORKERS} 1
#sleep 60
#./mst.sh google-mst-gps.txt ${WORKERS} 1
#sleep 60
#./mst.sh google-mst-gps.txt ${WORKERS} 1
#sleep 60
#./mst.sh google-mst-gps.txt ${WORKERS} 1
#sleep 60
#./mst.sh google-mst-gps.txt ${WORKERS} 1
#sleep 60
#./mst.sh google-mst-gps.txt ${WORKERS} 1
#sleep 60
#
#
#./mst.sh patents-mst-gps.txt ${WORKERS} 0
#sleep 60
#./mst.sh patents-mst-gps.txt ${WORKERS} 0
#sleep 60
#./mst.sh patents-mst-gps.txt ${WORKERS} 0
#sleep 60
#./mst.sh patents-mst-gps.txt ${WORKERS} 0
#sleep 60
#./mst.sh patents-mst-gps.txt ${WORKERS} 0
#sleep 60
#./mst.sh patents-mst-gps.txt ${WORKERS} 0
#sleep 60
#
#./mst.sh patents-mst-gps.txt ${WORKERS} 1
#sleep 60
#./mst.sh patents-mst-gps.txt ${WORKERS} 1
#sleep 60
#./mst.sh patents-mst-gps.txt ${WORKERS} 1
#sleep 60
#./mst.sh patents-mst-gps.txt ${WORKERS} 1
#sleep 60
#./mst.sh patents-mst-gps.txt ${WORKERS} 1
#sleep 60
#./mst.sh patents-mst-gps.txt ${WORKERS} 1
#sleep 60
#!/bin/bash
WORKERS=8

./pagerank.sh amazon-gps-noval.txt ${WORKERS} false
sleep 60    # need delay, otherwise will fail
./pagerank.sh amazon-gps-noval.txt ${WORKERS} false
sleep 60
./pagerank.sh amazon-gps-noval.txt ${WORKERS} false
sleep 60
./pagerank.sh amazon-gps-noval.txt ${WORKERS} false
sleep 60
./pagerank.sh amazon-gps-noval.txt ${WORKERS} false
sleep 60
./pagerank.sh amazon-gps-noval.txt ${WORKERS} false
sleep 60

./pagerank.sh amazon-gps-noval.txt ${WORKERS} true
sleep 60    # need delay, otherwise will fail
./pagerank.sh amazon-gps-noval.txt ${WORKERS} true
sleep 60
./pagerank.sh amazon-gps-noval.txt ${WORKERS} true
sleep 60
./pagerank.sh amazon-gps-noval.txt ${WORKERS} true
sleep 60
./pagerank.sh amazon-gps-noval.txt ${WORKERS} true
sleep 60
./pagerank.sh amazon-gps-noval.txt ${WORKERS} true
sleep 60


./pagerank.sh google-gps-noval.txt ${WORKERS} false
sleep 60
./pagerank.sh google-gps-noval.txt ${WORKERS} false
sleep 60
./pagerank.sh google-gps-noval.txt ${WORKERS} false
sleep 60
./pagerank.sh google-gps-noval.txt ${WORKERS} false
sleep 60
./pagerank.sh google-gps-noval.txt ${WORKERS} false
sleep 60
./pagerank.sh google-gps-noval.txt ${WORKERS} false
sleep 60

./pagerank.sh google-gps-noval.txt ${WORKERS} true
sleep 60
./pagerank.sh google-gps-noval.txt ${WORKERS} true
sleep 60
./pagerank.sh google-gps-noval.txt ${WORKERS} true
sleep 60
./pagerank.sh google-gps-noval.txt ${WORKERS} true
sleep 60
./pagerank.sh google-gps-noval.txt ${WORKERS} true
sleep 60
./pagerank.sh google-gps-noval.txt ${WORKERS} true
sleep 60


./pagerank.sh patents-gps-noval.txt ${WORKERS} false
sleep 60
./pagerank.sh patents-gps-noval.txt ${WORKERS} false
sleep 60
./pagerank.sh patents-gps-noval.txt ${WORKERS} false
sleep 60
./pagerank.sh patents-gps-noval.txt ${WORKERS} false
sleep 60
./pagerank.sh patents-gps-noval.txt ${WORKERS} false
sleep 60
./pagerank.sh patents-gps-noval.txt ${WORKERS} false
sleep 60

./pagerank.sh patents-gps-noval.txt ${WORKERS} true
sleep 60
./pagerank.sh patents-gps-noval.txt ${WORKERS} true
sleep 60
./pagerank.sh patents-gps-noval.txt ${WORKERS} true
sleep 60
./pagerank.sh patents-gps-noval.txt ${WORKERS} true
sleep 60
./pagerank.sh patents-gps-noval.txt ${WORKERS} true
sleep 60
./pagerank.sh patents-gps-noval.txt ${WORKERS} true
sleep 60


##===============================================
##===============================================
##===============================================

#./sssp.sh amazon-gps-noval.txt ${WORKERS} 0 false
#sleep 60
#./sssp.sh amazon-gps-noval.txt ${WORKERS} 0 false
#sleep 60
#./sssp.sh amazon-gps-noval.txt ${WORKERS} 0 false
#sleep 60
#./sssp.sh amazon-gps-noval.txt ${WORKERS} 0 false
#sleep 60
#./sssp.sh amazon-gps-noval.txt ${WORKERS} 0 false
#sleep 60
#./sssp.sh amazon-gps-noval.txt ${WORKERS} 0 false
#sleep 60
# 
#./sssp.sh amazon-gps-noval.txt ${WORKERS} 0 true
#sleep 60
#./sssp.sh amazon-gps-noval.txt ${WORKERS} 0 true
#sleep 60
#./sssp.sh amazon-gps-noval.txt ${WORKERS} 0 true
#sleep 60
#./sssp.sh amazon-gps-noval.txt ${WORKERS} 0 true
#sleep 60
#./sssp.sh amazon-gps-noval.txt ${WORKERS} 0 true
#sleep 60
#./sssp.sh amazon-gps-noval.txt ${WORKERS} 0 true
#sleep 60
# 
#
#./sssp.sh google-gps-noval.txt ${WORKERS} 0 false
#sleep 60
#./sssp.sh google-gps-noval.txt ${WORKERS} 0 false
#sleep 60
#./sssp.sh google-gps-noval.txt ${WORKERS} 0 false
#sleep 60
#./sssp.sh google-gps-noval.txt ${WORKERS} 0 false
#sleep 60
#./sssp.sh google-gps-noval.txt ${WORKERS} 0 false
#sleep 60
#./sssp.sh google-gps-noval.txt ${WORKERS} 0 false
#sleep 60
# 
#./sssp.sh google-gps-noval.txt ${WORKERS} 0 true
#sleep 60
#./sssp.sh google-gps-noval.txt ${WORKERS} 0 true
#sleep 60
#./sssp.sh google-gps-noval.txt ${WORKERS} 0 true
#sleep 60
#./sssp.sh google-gps-noval.txt ${WORKERS} 0 true
#sleep 60
#./sssp.sh google-gps-noval.txt ${WORKERS} 0 true
#sleep 60
#./sssp.sh google-gps-noval.txt ${WORKERS} 0 true
#sleep 60
#
#
#./sssp.sh patents-gps-noval.txt ${WORKERS} 6009554 false
#sleep 60
#./sssp.sh patents-gps-noval.txt ${WORKERS} 6009554 false
#sleep 60
#./sssp.sh patents-gps-noval.txt ${WORKERS} 6009554 false
#sleep 60
#./sssp.sh patents-gps-noval.txt ${WORKERS} 6009554 false
#sleep 60
#./sssp.sh patents-gps-noval.txt ${WORKERS} 6009554 false
#sleep 60
#./sssp.sh patents-gps-noval.txt ${WORKERS} 6009554 false
#sleep 60
#
#./sssp.sh patents-gps-noval.txt ${WORKERS} 6009554 true
#sleep 60
#./sssp.sh patents-gps-noval.txt ${WORKERS} 6009554 true
#sleep 60
#./sssp.sh patents-gps-noval.txt ${WORKERS} 6009554 true
#sleep 60
#./sssp.sh patents-gps-noval.txt ${WORKERS} 6009554 true
#sleep 60
#./sssp.sh patents-gps-noval.txt ${WORKERS} 6009554 true
#sleep 60
#./sssp.sh patents-gps-noval.txt ${WORKERS} 6009554 true
#sleep 60
 
#===============================================
#===============================================
#===============================================

#./wcc.sh amazon-gps-noval.txt ${WORKERS} false
#sleep 60
#./wcc.sh amazon-gps-noval.txt ${WORKERS} false
#sleep 60
#./wcc.sh amazon-gps-noval.txt ${WORKERS} false
#sleep 60
#./wcc.sh amazon-gps-noval.txt ${WORKERS} false
#sleep 60
#./wcc.sh amazon-gps-noval.txt ${WORKERS} false
#sleep 60
#./wcc.sh amazon-gps-noval.txt ${WORKERS} false
#sleep 60
# 
#./wcc.sh amazon-gps-noval.txt ${WORKERS} true
#sleep 60
#./wcc.sh amazon-gps-noval.txt ${WORKERS} true
#sleep 60
#./wcc.sh amazon-gps-noval.txt ${WORKERS} true
#sleep 60
#./wcc.sh amazon-gps-noval.txt ${WORKERS} true
#sleep 60
#./wcc.sh amazon-gps-noval.txt ${WORKERS} true
#sleep 60
#./wcc.sh amazon-gps-noval.txt ${WORKERS} true
#sleep 60
#
#
#./wcc.sh google-gps-noval.txt ${WORKERS} false
#sleep 60
#./wcc.sh google-gps-noval.txt ${WORKERS} false
#sleep 60
#./wcc.sh google-gps-noval.txt ${WORKERS} false
#sleep 60
#./wcc.sh google-gps-noval.txt ${WORKERS} false
#sleep 60
#./wcc.sh google-gps-noval.txt ${WORKERS} false
#sleep 60
#./wcc.sh google-gps-noval.txt ${WORKERS} false
#sleep 60
# 
#./wcc.sh google-gps-noval.txt ${WORKERS} true
#sleep 60
#./wcc.sh google-gps-noval.txt ${WORKERS} true
#sleep 60
#./wcc.sh google-gps-noval.txt ${WORKERS} true
#sleep 60
#./wcc.sh google-gps-noval.txt ${WORKERS} true
#sleep 60
#./wcc.sh google-gps-noval.txt ${WORKERS} true
#sleep 60
#./wcc.sh google-gps-noval.txt ${WORKERS} true
#sleep 60
# 
#
#./wcc.sh patents-gps-noval.txt ${WORKERS} false
#sleep 60
#./wcc.sh patents-gps-noval.txt ${WORKERS} false
#sleep 60
#./wcc.sh patents-gps-noval.txt ${WORKERS} false
#sleep 60
#./wcc.sh patents-gps-noval.txt ${WORKERS} false
#sleep 60
#./wcc.sh patents-gps-noval.txt ${WORKERS} false
#sleep 60
#./wcc.sh patents-gps-noval.txt ${WORKERS} false
#sleep 60
#
#./wcc.sh patents-gps-noval.txt ${WORKERS} true
#sleep 60
#./wcc.sh patents-gps-noval.txt ${WORKERS} true
#sleep 60
#./wcc.sh patents-gps-noval.txt ${WORKERS} true
#sleep 60
#./wcc.sh patents-gps-noval.txt ${WORKERS} true
#sleep 60
#./wcc.sh patents-gps-noval.txt ${WORKERS} true
#sleep 60
#./wcc.sh patents-gps-noval.txt ${WORKERS} true
#sleep 60

#===============================================
#===============================================
#===============================================

#./mst.sh amazon-mst-gps.txt ${WORKERS} false
#sleep 60
#./mst.sh amazon-mst-gps.txt ${WORKERS} false
#sleep 60
#./mst.sh amazon-mst-gps.txt ${WORKERS} false
#sleep 60
#./mst.sh amazon-mst-gps.txt ${WORKERS} false
#sleep 60
#./mst.sh amazon-mst-gps.txt ${WORKERS} false
#sleep 60
#./mst.sh amazon-mst-gps.txt ${WORKERS} false
#sleep 60
# 
#./mst.sh amazon-mst-gps.txt ${WORKERS} true
#sleep 60
#./mst.sh amazon-mst-gps.txt ${WORKERS} true
#sleep 60
#./mst.sh amazon-mst-gps.txt ${WORKERS} true
#sleep 60
#./mst.sh amazon-mst-gps.txt ${WORKERS} true
#sleep 60
#./mst.sh amazon-mst-gps.txt ${WORKERS} true
#sleep 60
#./mst.sh amazon-mst-gps.txt ${WORKERS} true
#sleep 60
# 
#
#./mst.sh google-mst-gps.txt ${WORKERS} false
#sleep 60
#./mst.sh google-mst-gps.txt ${WORKERS} false
#sleep 60
#./mst.sh google-mst-gps.txt ${WORKERS} false
#sleep 60
#./mst.sh google-mst-gps.txt ${WORKERS} false
#sleep 60
#./mst.sh google-mst-gps.txt ${WORKERS} false
#sleep 60
#./mst.sh google-mst-gps.txt ${WORKERS} false
#sleep 60
# 
#./mst.sh google-mst-gps.txt ${WORKERS} true
#sleep 60
#./mst.sh google-mst-gps.txt ${WORKERS} true
#sleep 60
#./mst.sh google-mst-gps.txt ${WORKERS} true
#sleep 60
#./mst.sh google-mst-gps.txt ${WORKERS} true
#sleep 60
#./mst.sh google-mst-gps.txt ${WORKERS} true
#sleep 60
#./mst.sh google-mst-gps.txt ${WORKERS} true
#sleep 60
#
#
#./mst.sh patents-mst-gps.txt ${WORKERS} false
#sleep 60
#./mst.sh patents-mst-gps.txt ${WORKERS} false
#sleep 60
#./mst.sh patents-mst-gps.txt ${WORKERS} false
#sleep 60
#./mst.sh patents-mst-gps.txt ${WORKERS} false
#sleep 60
#./mst.sh patents-mst-gps.txt ${WORKERS} false
#sleep 60
#./mst.sh patents-mst-gps.txt ${WORKERS} false
#sleep 60
#
#./mst.sh patents-mst-gps.txt ${WORKERS} true
#sleep 60
#./mst.sh patents-mst-gps.txt ${WORKERS} true
#sleep 60
#./mst.sh patents-mst-gps.txt ${WORKERS} true
#sleep 60
#./mst.sh patents-mst-gps.txt ${WORKERS} true
#sleep 60
#./mst.sh patents-mst-gps.txt ${WORKERS} true
#sleep 60
#./mst.sh patents-mst-gps.txt ${WORKERS} true
#sleep 60
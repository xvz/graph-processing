#!/bin/bash
WORKERS=8

./pagerank.sh amazon-gps-noval.txt ${WORKERS}
sleep 30    # need delay, otherwise will fail
./pagerank.sh amazon-gps-noval.txt ${WORKERS}
sleep 30
./pagerank.sh amazon-gps-noval.txt ${WORKERS}
sleep 30
./pagerank.sh amazon-gps-noval.txt ${WORKERS}
sleep 30
./pagerank.sh amazon-gps-noval.txt ${WORKERS}
sleep 30
./pagerank.sh amazon-gps-noval.txt ${WORKERS}
sleep 30

./pagerank.sh google-gps-noval.txt ${WORKERS}
sleep 30
./pagerank.sh google-gps-noval.txt ${WORKERS}
sleep 30
./pagerank.sh google-gps-noval.txt ${WORKERS}
sleep 30
./pagerank.sh google-gps-noval.txt ${WORKERS}
sleep 30
./pagerank.sh google-gps-noval.txt ${WORKERS}
sleep 30
./pagerank.sh google-gps-noval.txt ${WORKERS}
sleep 30

./pagerank.sh patents-gps-noval.txt ${WORKERS}
sleep 30
./pagerank.sh patents-gps-noval.txt ${WORKERS}
sleep 30
./pagerank.sh patents-gps-noval.txt ${WORKERS}
sleep 30
./pagerank.sh patents-gps-noval.txt ${WORKERS}
sleep 30
./pagerank.sh patents-gps-noval.txt ${WORKERS}
sleep 30
./pagerank.sh patents-gps-noval.txt ${WORKERS}
sleep 30


##===============================================
##===============================================
##===============================================

./sssp.sh amazon-gps-noval.txt ${WORKERS} 0
sleep 30
./sssp.sh amazon-gps-noval.txt ${WORKERS} 0
sleep 30
./sssp.sh amazon-gps-noval.txt ${WORKERS} 0
sleep 30
./sssp.sh amazon-gps-noval.txt ${WORKERS} 0
sleep 30
./sssp.sh amazon-gps-noval.txt ${WORKERS} 0
sleep 30
./sssp.sh amazon-gps-noval.txt ${WORKERS} 0
sleep 30
 
./sssp.sh google-gps-noval.txt ${WORKERS} 0
sleep 30
./sssp.sh google-gps-noval.txt ${WORKERS} 0
sleep 30
./sssp.sh google-gps-noval.txt ${WORKERS} 0
sleep 30
./sssp.sh google-gps-noval.txt ${WORKERS} 0
sleep 30
./sssp.sh google-gps-noval.txt ${WORKERS} 0
sleep 30
./sssp.sh google-gps-noval.txt ${WORKERS} 0
sleep 30

./sssp.sh patents-gps-noval.txt ${WORKERS} 6009554
sleep 30
./sssp.sh patents-gps-noval.txt ${WORKERS} 6009554
sleep 30
./sssp.sh patents-gps-noval.txt ${WORKERS} 6009554
sleep 30
./sssp.sh patents-gps-noval.txt ${WORKERS} 6009554
sleep 30
./sssp.sh patents-gps-noval.txt ${WORKERS} 6009554
sleep 30
./sssp.sh patents-gps-noval.txt ${WORKERS} 6009554
sleep 30
 
#===============================================
#===============================================
#===============================================

./wcc.sh amazon-gps-noval.txt ${WORKERS}
sleep 30
./wcc.sh amazon-gps-noval.txt ${WORKERS}
sleep 30
./wcc.sh amazon-gps-noval.txt ${WORKERS}
sleep 30
./wcc.sh amazon-gps-noval.txt ${WORKERS}
sleep 30
./wcc.sh amazon-gps-noval.txt ${WORKERS}
sleep 30
./wcc.sh amazon-gps-noval.txt ${WORKERS}
sleep 30
 
./wcc.sh google-gps-noval.txt ${WORKERS}
sleep 30
./wcc.sh google-gps-noval.txt ${WORKERS}
sleep 30
./wcc.sh google-gps-noval.txt ${WORKERS}
sleep 30
./wcc.sh google-gps-noval.txt ${WORKERS}
sleep 30
./wcc.sh google-gps-noval.txt ${WORKERS}
sleep 30
./wcc.sh google-gps-noval.txt ${WORKERS}
sleep 30

./wcc.sh patents-gps-noval.txt ${WORKERS}
sleep 30
./wcc.sh patents-gps-noval.txt ${WORKERS}
sleep 30
./wcc.sh patents-gps-noval.txt ${WORKERS}
sleep 30
./wcc.sh patents-gps-noval.txt ${WORKERS}
sleep 30
./wcc.sh patents-gps-noval.txt ${WORKERS}
sleep 30
./wcc.sh patents-gps-noval.txt ${WORKERS}
sleep 30

#===============================================
#===============================================
#===============================================

#./mst.sh amazon-mst-gps.txt ${WORKERS}
#sleep 30
#./mst.sh amazon-mst-gps.txt ${WORKERS}
#sleep 30
#./mst.sh amazon-mst-gps.txt ${WORKERS}
#sleep 30
#./mst.sh amazon-mst-gps.txt ${WORKERS}
#sleep 30
#./mst.sh amazon-mst-gps.txt ${WORKERS}
#sleep 30
#./mst.sh amazon-mst-gps.txt ${WORKERS}
#sleep 30
# 
#./mst.sh google-mst-gps.txt ${WORKERS}
#sleep 30
#./mst.sh google-mst-gps.txt ${WORKERS}
#sleep 30
#./mst.sh google-mst-gps.txt ${WORKERS}
#sleep 30
#./mst.sh google-mst-gps.txt ${WORKERS}
#sleep 30
#./mst.sh google-mst-gps.txt ${WORKERS}
#sleep 30
#./mst.sh google-mst-gps.txt ${WORKERS}
#sleep 30
#
#./mst.sh patents-mst-gps.txt ${WORKERS}
#sleep 30
#./mst.sh patents-mst-gps.txt ${WORKERS}
#sleep 30
#./mst.sh patents-mst-gps.txt ${WORKERS}
#sleep 30
#./mst.sh patents-mst-gps.txt ${WORKERS}
#sleep 30
#./mst.sh patents-mst-gps.txt ${WORKERS}
#sleep 30
#./mst.sh patents-mst-gps.txt ${WORKERS}
#sleep 30
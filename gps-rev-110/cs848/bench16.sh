#!/bin/bash
WORKERS=16

./pagerank.sh patents-gps-noval.txt ${WORKERS}
sleep 30    # need delay, otherwise will fail
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

./pagerank.sh livejournal-gps-noval.txt ${WORKERS}
sleep 30
./pagerank.sh livejournal-gps-noval.txt ${WORKERS}
sleep 30
./pagerank.sh livejournal-gps-noval.txt ${WORKERS}
sleep 30
./pagerank.sh livejournal-gps-noval.txt ${WORKERS}
sleep 30
./pagerank.sh livejournal-gps-noval.txt ${WORKERS}
sleep 30
./pagerank.sh livejournal-gps-noval.txt ${WORKERS}
sleep 30

./pagerank.sh orkut-gps-noval.txt ${WORKERS}
sleep 30
./pagerank.sh orkut-gps-noval.txt ${WORKERS}
sleep 30
./pagerank.sh orkut-gps-noval.txt ${WORKERS}
sleep 30
./pagerank.sh orkut-gps-noval.txt ${WORKERS}
sleep 30
./pagerank.sh orkut-gps-noval.txt ${WORKERS}
sleep 30
./pagerank.sh orkut-gps-noval.txt ${WORKERS}
sleep 30


##===============================================
##===============================================
##===============================================

./sssp.sh patents-gps-noval.txt ${WORKERS} 0
sleep 30
./sssp.sh patents-gps-noval.txt ${WORKERS} 0
sleep 30
./sssp.sh patents-gps-noval.txt ${WORKERS} 0
sleep 30
./sssp.sh patents-gps-noval.txt ${WORKERS} 0
sleep 30
./sssp.sh patents-gps-noval.txt ${WORKERS} 0
sleep 30
./sssp.sh patents-gps-noval.txt ${WORKERS} 0
sleep 30
 
./sssp.sh livejournal-gps-noval.txt ${WORKERS} 0
sleep 30
./sssp.sh livejournal-gps-noval.txt ${WORKERS} 0
sleep 30
./sssp.sh livejournal-gps-noval.txt ${WORKERS} 0
sleep 30
./sssp.sh livejournal-gps-noval.txt ${WORKERS} 0
sleep 30
./sssp.sh livejournal-gps-noval.txt ${WORKERS} 0
sleep 30
./sssp.sh livejournal-gps-noval.txt ${WORKERS} 0
sleep 30

./sssp.sh orkut-gps-noval.txt ${WORKERS} 6009554
sleep 30
./sssp.sh orkut-gps-noval.txt ${WORKERS} 6009554
sleep 30
./sssp.sh orkut-gps-noval.txt ${WORKERS} 6009554
sleep 30
./sssp.sh orkut-gps-noval.txt ${WORKERS} 6009554
sleep 30
./sssp.sh orkut-gps-noval.txt ${WORKERS} 6009554
sleep 30
./sssp.sh orkut-gps-noval.txt ${WORKERS} 6009554
sleep 30
 
#===============================================
#===============================================
#===============================================

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
 
./wcc.sh livejournal-gps-noval.txt ${WORKERS}
sleep 30
./wcc.sh livejournal-gps-noval.txt ${WORKERS}
sleep 30
./wcc.sh livejournal-gps-noval.txt ${WORKERS}
sleep 30
./wcc.sh livejournal-gps-noval.txt ${WORKERS}
sleep 30
./wcc.sh livejournal-gps-noval.txt ${WORKERS}
sleep 30
./wcc.sh livejournal-gps-noval.txt ${WORKERS}
sleep 30

./wcc.sh orkut-gps-noval.txt ${WORKERS}
sleep 30
./wcc.sh orkut-gps-noval.txt ${WORKERS}
sleep 30
./wcc.sh orkut-gps-noval.txt ${WORKERS}
sleep 30
./wcc.sh orkut-gps-noval.txt ${WORKERS}
sleep 30
./wcc.sh orkut-gps-noval.txt ${WORKERS}
sleep 30
./wcc.sh orkut-gps-noval.txt ${WORKERS}
sleep 30

#===============================================
#===============================================
#===============================================

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
# 
#./mst.sh livejournal-mst-gps.txt ${WORKERS}
#sleep 30
#./mst.sh livejournal-mst-gps.txt ${WORKERS}
#sleep 30
#./mst.sh livejournal-mst-gps.txt ${WORKERS}
#sleep 30
#./mst.sh livejournal-mst-gps.txt ${WORKERS}
#sleep 30
#./mst.sh livejournal-mst-gps.txt ${WORKERS}
#sleep 30
#./mst.sh livejournal-mst-gps.txt ${WORKERS}
#sleep 30
#
#./mst.sh orkut-mst-gps.txt ${WORKERS}
#sleep 30
#./mst.sh orkut-mst-gps.txt ${WORKERS}
#sleep 30
#./mst.sh orkut-mst-gps.txt ${WORKERS}
#sleep 30
#./mst.sh orkut-mst-gps.txt ${WORKERS}
#sleep 30
#./mst.sh orkut-mst-gps.txt ${WORKERS}
#sleep 30
#./mst.sh orkut-mst-gps.txt ${WORKERS}
#sleep 30
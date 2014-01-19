#!/bin/bash
WORKERS=16

./pagerank.sh patents-gps-noval.txt ${WORKERS}
sleep 45    # need delay, otherwise will fail
./pagerank.sh patents-gps-noval.txt ${WORKERS}
sleep 45
./pagerank.sh patents-gps-noval.txt ${WORKERS}
sleep 45
./pagerank.sh patents-gps-noval.txt ${WORKERS}
sleep 45
./pagerank.sh patents-gps-noval.txt ${WORKERS}
sleep 45
./pagerank.sh patents-gps-noval.txt ${WORKERS}
sleep 45

./pagerank.sh livejournal-gps-noval.txt ${WORKERS}
sleep 45
./pagerank.sh livejournal-gps-noval.txt ${WORKERS}
sleep 45
./pagerank.sh livejournal-gps-noval.txt ${WORKERS}
sleep 45
./pagerank.sh livejournal-gps-noval.txt ${WORKERS}
sleep 45
./pagerank.sh livejournal-gps-noval.txt ${WORKERS}
sleep 45
./pagerank.sh livejournal-gps-noval.txt ${WORKERS}
sleep 45

./pagerank.sh orkut-gps-noval.txt ${WORKERS}
sleep 45
./pagerank.sh orkut-gps-noval.txt ${WORKERS}
sleep 45
./pagerank.sh orkut-gps-noval.txt ${WORKERS}
sleep 45
./pagerank.sh orkut-gps-noval.txt ${WORKERS}
sleep 45
./pagerank.sh orkut-gps-noval.txt ${WORKERS}
sleep 45
./pagerank.sh orkut-gps-noval.txt ${WORKERS}
sleep 45


##===============================================
##===============================================
##===============================================

./sssp.sh patents-gps-noval.txt ${WORKERS} 6009554
sleep 45
./sssp.sh patents-gps-noval.txt ${WORKERS} 6009554
sleep 45
./sssp.sh patents-gps-noval.txt ${WORKERS} 6009554
sleep 45
./sssp.sh patents-gps-noval.txt ${WORKERS} 6009554
sleep 45
./sssp.sh patents-gps-noval.txt ${WORKERS} 6009554
sleep 45
./sssp.sh patents-gps-noval.txt ${WORKERS} 6009554
sleep 45
 
./sssp.sh livejournal-gps-noval.txt ${WORKERS} 0
sleep 45
./sssp.sh livejournal-gps-noval.txt ${WORKERS} 0
sleep 45
./sssp.sh livejournal-gps-noval.txt ${WORKERS} 0
sleep 45
./sssp.sh livejournal-gps-noval.txt ${WORKERS} 0
sleep 45
./sssp.sh livejournal-gps-noval.txt ${WORKERS} 0
sleep 45
./sssp.sh livejournal-gps-noval.txt ${WORKERS} 0
sleep 45

./sssp.sh orkut-gps-noval.txt ${WORKERS} 1
sleep 45
./sssp.sh orkut-gps-noval.txt ${WORKERS} 1
sleep 45
./sssp.sh orkut-gps-noval.txt ${WORKERS} 1
sleep 45
./sssp.sh orkut-gps-noval.txt ${WORKERS} 1
sleep 45
./sssp.sh orkut-gps-noval.txt ${WORKERS} 1
sleep 45
./sssp.sh orkut-gps-noval.txt ${WORKERS} 1
sleep 45
 
#===============================================
#===============================================
#===============================================

./wcc.sh patents-gps-noval.txt ${WORKERS}
sleep 45
./wcc.sh patents-gps-noval.txt ${WORKERS}
sleep 45
./wcc.sh patents-gps-noval.txt ${WORKERS}
sleep 45
./wcc.sh patents-gps-noval.txt ${WORKERS}
sleep 45
./wcc.sh patents-gps-noval.txt ${WORKERS}
sleep 45
./wcc.sh patents-gps-noval.txt ${WORKERS}
sleep 45
 
./wcc.sh livejournal-gps-noval.txt ${WORKERS}
sleep 45
./wcc.sh livejournal-gps-noval.txt ${WORKERS}
sleep 45
./wcc.sh livejournal-gps-noval.txt ${WORKERS}
sleep 45
./wcc.sh livejournal-gps-noval.txt ${WORKERS}
sleep 45
./wcc.sh livejournal-gps-noval.txt ${WORKERS}
sleep 45
./wcc.sh livejournal-gps-noval.txt ${WORKERS}
sleep 45

./wcc.sh orkut-gps-noval.txt ${WORKERS}
sleep 45
./wcc.sh orkut-gps-noval.txt ${WORKERS}
sleep 45
./wcc.sh orkut-gps-noval.txt ${WORKERS}
sleep 45
./wcc.sh orkut-gps-noval.txt ${WORKERS}
sleep 45
./wcc.sh orkut-gps-noval.txt ${WORKERS}
sleep 45
./wcc.sh orkut-gps-noval.txt ${WORKERS}
sleep 45

#===============================================
#===============================================
#===============================================

#./mst.sh patents-mst-gps.txt ${WORKERS}
#sleep 45
#./mst.sh patents-mst-gps.txt ${WORKERS}
#sleep 45
#./mst.sh patents-mst-gps.txt ${WORKERS}
#sleep 45
#./mst.sh patents-mst-gps.txt ${WORKERS}
#sleep 45
#./mst.sh patents-mst-gps.txt ${WORKERS}
#sleep 45
#./mst.sh patents-mst-gps.txt ${WORKERS}
#sleep 45
# 
#./mst.sh livejournal-mst-gps.txt ${WORKERS}
#sleep 45
#./mst.sh livejournal-mst-gps.txt ${WORKERS}
#sleep 45
#./mst.sh livejournal-mst-gps.txt ${WORKERS}
#sleep 45
#./mst.sh livejournal-mst-gps.txt ${WORKERS}
#sleep 45
#./mst.sh livejournal-mst-gps.txt ${WORKERS}
#sleep 45
#./mst.sh livejournal-mst-gps.txt ${WORKERS}
#sleep 45
#
#./mst.sh orkut-mst-gps.txt ${WORKERS}
#sleep 45
#./mst.sh orkut-mst-gps.txt ${WORKERS}
#sleep 45
#./mst.sh orkut-mst-gps.txt ${WORKERS}
#sleep 45
#./mst.sh orkut-mst-gps.txt ${WORKERS}
#sleep 45
#./mst.sh orkut-mst-gps.txt ${WORKERS}
#sleep 45
#./mst.sh orkut-mst-gps.txt ${WORKERS}
#sleep 45
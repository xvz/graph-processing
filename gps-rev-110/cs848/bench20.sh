#!/bin/bash
WORKERS=8

./pagerank.sh patents-gps-noval.txt ${WORKERS}
sleep 60    # need delay, otherwise will fail
./pagerank.sh patents-gps-noval.txt ${WORKERS}
sleep 60
./pagerank.sh patents-gps-noval.txt ${WORKERS}
sleep 60
./pagerank.sh patents-gps-noval.txt ${WORKERS}
sleep 60
./pagerank.sh patents-gps-noval.txt ${WORKERS}
sleep 60
./pagerank.sh patents-gps-noval.txt ${WORKERS}
sleep 60

./pagerank.sh patents-gps-noval.txt ${WORKERS}
sleep 60    # need delay, otherwise will fail
./pagerank.sh patents-gps-noval.txt ${WORKERS}
sleep 60
./pagerank.sh patents-gps-noval.txt ${WORKERS}
sleep 60
./pagerank.sh patents-gps-noval.txt ${WORKERS}
sleep 60
./pagerank.sh patents-gps-noval.txt ${WORKERS}
sleep 60
./pagerank.sh patents-gps-noval.txt ${WORKERS}
sleep 60


./pagerank.sh livejournal-gps-noval.txt ${WORKERS}
sleep 60
./pagerank.sh livejournal-gps-noval.txt ${WORKERS}
sleep 60
./pagerank.sh livejournal-gps-noval.txt ${WORKERS}
sleep 60
./pagerank.sh livejournal-gps-noval.txt ${WORKERS}
sleep 60
./pagerank.sh livejournal-gps-noval.txt ${WORKERS}
sleep 60
./pagerank.sh livejournal-gps-noval.txt ${WORKERS}
sleep 60

./pagerank.sh livejournal-gps-noval.txt ${WORKERS}
sleep 60
./pagerank.sh livejournal-gps-noval.txt ${WORKERS}
sleep 60
./pagerank.sh livejournal-gps-noval.txt ${WORKERS}
sleep 60
./pagerank.sh livejournal-gps-noval.txt ${WORKERS}
sleep 60
./pagerank.sh livejournal-gps-noval.txt ${WORKERS}
sleep 60
./pagerank.sh livejournal-gps-noval.txt ${WORKERS}
sleep 60


./pagerank.sh orkut-gps-noval.txt ${WORKERS}
sleep 60
./pagerank.sh orkut-gps-noval.txt ${WORKERS}
sleep 60
./pagerank.sh orkut-gps-noval.txt ${WORKERS}
sleep 60
./pagerank.sh orkut-gps-noval.txt ${WORKERS}
sleep 60
./pagerank.sh orkut-gps-noval.txt ${WORKERS}
sleep 60
./pagerank.sh orkut-gps-noval.txt ${WORKERS}
sleep 60

./pagerank.sh orkut-gps-noval.txt ${WORKERS}
sleep 60
./pagerank.sh orkut-gps-noval.txt ${WORKERS}
sleep 60
./pagerank.sh orkut-gps-noval.txt ${WORKERS}
sleep 60
./pagerank.sh orkut-gps-noval.txt ${WORKERS}
sleep 60
./pagerank.sh orkut-gps-noval.txt ${WORKERS}
sleep 60
./pagerank.sh orkut-gps-noval.txt ${WORKERS}
sleep 60


##===============================================
##===============================================
##===============================================

#./sssp.sh patents-gps-noval.txt ${WORKERS} 0
#sleep 60
#./sssp.sh patents-gps-noval.txt ${WORKERS} 0
#sleep 60
#./sssp.sh patents-gps-noval.txt ${WORKERS} 0
#sleep 60
#./sssp.sh patents-gps-noval.txt ${WORKERS} 0
#sleep 60
#./sssp.sh patents-gps-noval.txt ${WORKERS} 0
#sleep 60
#./sssp.sh patents-gps-noval.txt ${WORKERS} 0
#sleep 60
# 
#./sssp.sh patents-gps-noval.txt ${WORKERS} 0
#sleep 60
#./sssp.sh patents-gps-noval.txt ${WORKERS} 0
#sleep 60
#./sssp.sh patents-gps-noval.txt ${WORKERS} 0
#sleep 60
#./sssp.sh patents-gps-noval.txt ${WORKERS} 0
#sleep 60
#./sssp.sh patents-gps-noval.txt ${WORKERS} 0
#sleep 60
#./sssp.sh patents-gps-noval.txt ${WORKERS} 0
#sleep 60
# 
#
#./sssp.sh livejournal-gps-noval.txt ${WORKERS} 0
#sleep 60
#./sssp.sh livejournal-gps-noval.txt ${WORKERS} 0
#sleep 60
#./sssp.sh livejournal-gps-noval.txt ${WORKERS} 0
#sleep 60
#./sssp.sh livejournal-gps-noval.txt ${WORKERS} 0
#sleep 60
#./sssp.sh livejournal-gps-noval.txt ${WORKERS} 0
#sleep 60
#./sssp.sh livejournal-gps-noval.txt ${WORKERS} 0
#sleep 60
# 
#./sssp.sh livejournal-gps-noval.txt ${WORKERS} 0
#sleep 60
#./sssp.sh livejournal-gps-noval.txt ${WORKERS} 0
#sleep 60
#./sssp.sh livejournal-gps-noval.txt ${WORKERS} 0
#sleep 60
#./sssp.sh livejournal-gps-noval.txt ${WORKERS} 0
#sleep 60
#./sssp.sh livejournal-gps-noval.txt ${WORKERS} 0
#sleep 60
#./sssp.sh livejournal-gps-noval.txt ${WORKERS} 0
#sleep 60
#
#
#./sssp.sh orkut-gps-noval.txt ${WORKERS} 6009554
#sleep 60
#./sssp.sh orkut-gps-noval.txt ${WORKERS} 6009554
#sleep 60
#./sssp.sh orkut-gps-noval.txt ${WORKERS} 6009554
#sleep 60
#./sssp.sh orkut-gps-noval.txt ${WORKERS} 6009554
#sleep 60
#./sssp.sh orkut-gps-noval.txt ${WORKERS} 6009554
#sleep 60
#./sssp.sh orkut-gps-noval.txt ${WORKERS} 6009554
#sleep 60
#
#./sssp.sh orkut-gps-noval.txt ${WORKERS} 6009554
#sleep 60
#./sssp.sh orkut-gps-noval.txt ${WORKERS} 6009554
#sleep 60
#./sssp.sh orkut-gps-noval.txt ${WORKERS} 6009554
#sleep 60
#./sssp.sh orkut-gps-noval.txt ${WORKERS} 6009554
#sleep 60
#./sssp.sh orkut-gps-noval.txt ${WORKERS} 6009554
#sleep 60
#./sssp.sh orkut-gps-noval.txt ${WORKERS} 6009554
#sleep 60
 
#===============================================
#===============================================
#===============================================

#./wcc.sh patents-gps-noval.txt ${WORKERS}
#sleep 60
#./wcc.sh patents-gps-noval.txt ${WORKERS}
#sleep 60
#./wcc.sh patents-gps-noval.txt ${WORKERS}
#sleep 60
#./wcc.sh patents-gps-noval.txt ${WORKERS}
#sleep 60
#./wcc.sh patents-gps-noval.txt ${WORKERS}
#sleep 60
#./wcc.sh patents-gps-noval.txt ${WORKERS}
#sleep 60
# 
#./wcc.sh patents-gps-noval.txt ${WORKERS}
#sleep 60
#./wcc.sh patents-gps-noval.txt ${WORKERS}
#sleep 60
#./wcc.sh patents-gps-noval.txt ${WORKERS}
#sleep 60
#./wcc.sh patents-gps-noval.txt ${WORKERS}
#sleep 60
#./wcc.sh patents-gps-noval.txt ${WORKERS}
#sleep 60
#./wcc.sh patents-gps-noval.txt ${WORKERS}
#sleep 60
#
#
#./wcc.sh livejournal-gps-noval.txt ${WORKERS}
#sleep 60
#./wcc.sh livejournal-gps-noval.txt ${WORKERS}
#sleep 60
#./wcc.sh livejournal-gps-noval.txt ${WORKERS}
#sleep 60
#./wcc.sh livejournal-gps-noval.txt ${WORKERS}
#sleep 60
#./wcc.sh livejournal-gps-noval.txt ${WORKERS}
#sleep 60
#./wcc.sh livejournal-gps-noval.txt ${WORKERS}
#sleep 60
# 
#./wcc.sh livejournal-gps-noval.txt ${WORKERS}
#sleep 60
#./wcc.sh livejournal-gps-noval.txt ${WORKERS}
#sleep 60
#./wcc.sh livejournal-gps-noval.txt ${WORKERS}
#sleep 60
#./wcc.sh livejournal-gps-noval.txt ${WORKERS}
#sleep 60
#./wcc.sh livejournal-gps-noval.txt ${WORKERS}
#sleep 60
#./wcc.sh livejournal-gps-noval.txt ${WORKERS}
#sleep 60
# 
#
#./wcc.sh orkut-gps-noval.txt ${WORKERS}
#sleep 60
#./wcc.sh orkut-gps-noval.txt ${WORKERS}
#sleep 60
#./wcc.sh orkut-gps-noval.txt ${WORKERS}
#sleep 60
#./wcc.sh orkut-gps-noval.txt ${WORKERS}
#sleep 60
#./wcc.sh orkut-gps-noval.txt ${WORKERS}
#sleep 60
#./wcc.sh orkut-gps-noval.txt ${WORKERS}
#sleep 60
#
#./wcc.sh orkut-gps-noval.txt ${WORKERS}
#sleep 60
#./wcc.sh orkut-gps-noval.txt ${WORKERS}
#sleep 60
#./wcc.sh orkut-gps-noval.txt ${WORKERS}
#sleep 60
#./wcc.sh orkut-gps-noval.txt ${WORKERS}
#sleep 60
#./wcc.sh orkut-gps-noval.txt ${WORKERS}
#sleep 60
#./wcc.sh orkut-gps-noval.txt ${WORKERS}
#sleep 60

#===============================================
#===============================================
#===============================================

#./mst.sh patents-mst-gps.txt ${WORKERS}
#sleep 60
#./mst.sh patents-mst-gps.txt ${WORKERS}
#sleep 60
#./mst.sh patents-mst-gps.txt ${WORKERS}
#sleep 60
#./mst.sh patents-mst-gps.txt ${WORKERS}
#sleep 60
#./mst.sh patents-mst-gps.txt ${WORKERS}
#sleep 60
#./mst.sh patents-mst-gps.txt ${WORKERS}
#sleep 60
# 
#./mst.sh patents-mst-gps.txt ${WORKERS}
#sleep 60
#./mst.sh patents-mst-gps.txt ${WORKERS}
#sleep 60
#./mst.sh patents-mst-gps.txt ${WORKERS}
#sleep 60
#./mst.sh patents-mst-gps.txt ${WORKERS}
#sleep 60
#./mst.sh patents-mst-gps.txt ${WORKERS}
#sleep 60
#./mst.sh patents-mst-gps.txt ${WORKERS}
#sleep 60
# 
#
#./mst.sh livejournal-mst-gps.txt ${WORKERS}
#sleep 60
#./mst.sh livejournal-mst-gps.txt ${WORKERS}
#sleep 60
#./mst.sh livejournal-mst-gps.txt ${WORKERS}
#sleep 60
#./mst.sh livejournal-mst-gps.txt ${WORKERS}
#sleep 60
#./mst.sh livejournal-mst-gps.txt ${WORKERS}
#sleep 60
#./mst.sh livejournal-mst-gps.txt ${WORKERS}
#sleep 60
# 
#./mst.sh livejournal-mst-gps.txt ${WORKERS}
#sleep 60
#./mst.sh livejournal-mst-gps.txt ${WORKERS}
#sleep 60
#./mst.sh livejournal-mst-gps.txt ${WORKERS}
#sleep 60
#./mst.sh livejournal-mst-gps.txt ${WORKERS}
#sleep 60
#./mst.sh livejournal-mst-gps.txt ${WORKERS}
#sleep 60
#./mst.sh livejournal-mst-gps.txt ${WORKERS}
#sleep 60
#
#
#./mst.sh orkut-mst-gps.txt ${WORKERS}
#sleep 60
#./mst.sh orkut-mst-gps.txt ${WORKERS}
#sleep 60
#./mst.sh orkut-mst-gps.txt ${WORKERS}
#sleep 60
#./mst.sh orkut-mst-gps.txt ${WORKERS}
#sleep 60
#./mst.sh orkut-mst-gps.txt ${WORKERS}
#sleep 60
#./mst.sh orkut-mst-gps.txt ${WORKERS}
#sleep 60
#
#./mst.sh orkut-mst-gps.txt ${WORKERS}
#sleep 60
#./mst.sh orkut-mst-gps.txt ${WORKERS}
#sleep 60
#./mst.sh orkut-mst-gps.txt ${WORKERS}
#sleep 60
#./mst.sh orkut-mst-gps.txt ${WORKERS}
#sleep 60
#./mst.sh orkut-mst-gps.txt ${WORKERS}
#sleep 60
#./mst.sh orkut-mst-gps.txt ${WORKERS}
#sleep 60
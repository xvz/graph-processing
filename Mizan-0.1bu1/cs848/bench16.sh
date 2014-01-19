#!/bin/bash
WORKERS=16

./premizan.sh patents.txt ${WORKERS} 1
./premizan.sh patents.txt ${WORKERS} 1
./premizan.sh patents.txt ${WORKERS} 1
./premizan.sh patents.txt ${WORKERS} 1
./premizan.sh patents.txt ${WORKERS} 1

./premizan.sh livejournal.txt ${WORKERS} 1
./premizan.sh livejournal.txt ${WORKERS} 1
./premizan.sh livejournal.txt ${WORKERS} 1
./premizan.sh livejournal.txt ${WORKERS} 1
./premizan.sh livejournal.txt ${WORKERS} 1

./premizan.sh orkut.txt ${WORKERS} 1
./premizan.sh orkut.txt ${WORKERS} 1
./premizan.sh orkut.txt ${WORKERS} 1
./premizan.sh orkut.txt ${WORKERS} 1
./premizan.sh orkut.txt ${WORKERS} 1

#===============================================
#===============================================
#===============================================

./pagerank.sh patents.txt ${WORKERS} 1
./pagerank.sh patents.txt ${WORKERS} 1
./pagerank.sh patents.txt ${WORKERS} 1
./pagerank.sh patents.txt ${WORKERS} 1
./pagerank.sh patents.txt ${WORKERS} 1
./pagerank.sh patents.txt ${WORKERS} 1
 
./pagerank.sh patents.txt ${WORKERS} 2
./pagerank.sh patents.txt ${WORKERS} 2
./pagerank.sh patents.txt ${WORKERS} 2
./pagerank.sh patents.txt ${WORKERS} 2
./pagerank.sh patents.txt ${WORKERS} 2
./pagerank.sh patents.txt ${WORKERS} 2


./pagerank.sh livejournal.txt ${WORKERS} 1
./pagerank.sh livejournal.txt ${WORKERS} 1
./pagerank.sh livejournal.txt ${WORKERS} 1
./pagerank.sh livejournal.txt ${WORKERS} 1
./pagerank.sh livejournal.txt ${WORKERS} 1
./pagerank.sh livejournal.txt ${WORKERS} 1
 
./pagerank.sh livejournal.txt ${WORKERS} 2
./pagerank.sh livejournal.txt ${WORKERS} 2
./pagerank.sh livejournal.txt ${WORKERS} 2
./pagerank.sh livejournal.txt ${WORKERS} 2
./pagerank.sh livejournal.txt ${WORKERS} 2
./pagerank.sh livejournal.txt ${WORKERS} 2
 
 
./pagerank.sh orkut.txt ${WORKERS} 1
./pagerank.sh orkut.txt ${WORKERS} 1
./pagerank.sh orkut.txt ${WORKERS} 1
./pagerank.sh orkut.txt ${WORKERS} 1
./pagerank.sh orkut.txt ${WORKERS} 1
./pagerank.sh orkut.txt ${WORKERS} 1
 
./pagerank.sh orkut.txt ${WORKERS} 2
./pagerank.sh orkut.txt ${WORKERS} 2
./pagerank.sh orkut.txt ${WORKERS} 2
./pagerank.sh orkut.txt ${WORKERS} 2
./pagerank.sh orkut.txt ${WORKERS} 2
./pagerank.sh orkut.txt ${WORKERS} 2

#===============================================
#===============================================
#===============================================

## use src 0
#./sssp.sh patents.txt ${WORKERS} 1
#./sssp.sh patents.txt ${WORKERS} 1
#./sssp.sh patents.txt ${WORKERS} 1
#./sssp.sh patents.txt ${WORKERS} 1
#./sssp.sh patents.txt ${WORKERS} 1
#./sssp.sh patents.txt ${WORKERS} 1
# 
#./sssp.sh patents.txt ${WORKERS} 2
#./sssp.sh patents.txt ${WORKERS} 2
#./sssp.sh patents.txt ${WORKERS} 2
#./sssp.sh patents.txt ${WORKERS} 2
#./sssp.sh patents.txt ${WORKERS} 2
#./sssp.sh patents.txt ${WORKERS} 2
#
#
## use src 0
#./sssp.sh livejournal.txt ${WORKERS} 1
#./sssp.sh livejournal.txt ${WORKERS} 1
#./sssp.sh livejournal.txt ${WORKERS} 1
#./sssp.sh livejournal.txt ${WORKERS} 1
#./sssp.sh livejournal.txt ${WORKERS} 1
#./sssp.sh livejournal.txt ${WORKERS} 1
# 
#./sssp.sh livejournal.txt ${WORKERS} 2
#./sssp.sh livejournal.txt ${WORKERS} 2
#./sssp.sh livejournal.txt ${WORKERS} 2
#./sssp.sh livejournal.txt ${WORKERS} 2
#./sssp.sh livejournal.txt ${WORKERS} 2
#./sssp.sh livejournal.txt ${WORKERS} 2
#
#
## use src 1
#./sssp.sh orkut.txt ${WORKERS} 1
#./sssp.sh orkut.txt ${WORKERS} 1
#./sssp.sh orkut.txt ${WORKERS} 1
#./sssp.sh orkut.txt ${WORKERS} 1
#./sssp.sh orkut.txt ${WORKERS} 1
#./sssp.sh orkut.txt ${WORKERS} 1
# 
#./sssp.sh orkut.txt ${WORKERS} 2
#./sssp.sh orkut.txt ${WORKERS} 2
#./sssp.sh orkut.txt ${WORKERS} 2
#./sssp.sh orkut.txt ${WORKERS} 2
#./sssp.sh orkut.txt ${WORKERS} 2
#./sssp.sh orkut.txt ${WORKERS} 2

#===============================================
#===============================================
#===============================================

#./wcc.sh patents.txt ${WORKERS} 1
#./wcc.sh patents.txt ${WORKERS} 1
#./wcc.sh patents.txt ${WORKERS} 1
#./wcc.sh patents.txt ${WORKERS} 1
#./wcc.sh patents.txt ${WORKERS} 1
#./wcc.sh patents.txt ${WORKERS} 1
# 
#./wcc.sh patents.txt ${WORKERS} 2
#./wcc.sh patents.txt ${WORKERS} 2
#./wcc.sh patents.txt ${WORKERS} 2
#./wcc.sh patents.txt ${WORKERS} 2
#./wcc.sh patents.txt ${WORKERS} 2
#./wcc.sh patents.txt ${WORKERS} 2
# 
# 
#./wcc.sh livejournal.txt ${WORKERS} 1
#./wcc.sh livejournal.txt ${WORKERS} 1
#./wcc.sh livejournal.txt ${WORKERS} 1
#./wcc.sh livejournal.txt ${WORKERS} 1
#./wcc.sh livejournal.txt ${WORKERS} 1
#./wcc.sh livejournal.txt ${WORKERS} 1
# 
#./wcc.sh livejournal.txt ${WORKERS} 2
#./wcc.sh livejournal.txt ${WORKERS} 2
#./wcc.sh livejournal.txt ${WORKERS} 2
#./wcc.sh livejournal.txt ${WORKERS} 2
#./wcc.sh livejournal.txt ${WORKERS} 2
#./wcc.sh livejournal.txt ${WORKERS} 2
# 
#./wcc.sh orkut.txt ${WORKERS} 1
#./wcc.sh orkut.txt ${WORKERS} 1
#./wcc.sh orkut.txt ${WORKERS} 1
#./wcc.sh orkut.txt ${WORKERS} 1
#./wcc.sh orkut.txt ${WORKERS} 1
#./wcc.sh orkut.txt ${WORKERS} 1
# 
#./wcc.sh orkut.txt ${WORKERS} 2
#./wcc.sh orkut.txt ${WORKERS} 2
#./wcc.sh orkut.txt ${WORKERS} 2
#./wcc.sh orkut.txt ${WORKERS} 2
#./wcc.sh orkut.txt ${WORKERS} 2
#./wcc.sh orkut.txt ${WORKERS} 2

#===============================================
#===============================================
#===============================================

#./mst.sh patents-mst-mizan.txt ${WORKERS} 1
#./mst.sh patents-mst-mizan.txt ${WORKERS} 1
#./mst.sh patents-mst-mizan.txt ${WORKERS} 1
#./mst.sh patents-mst-mizan.txt ${WORKERS} 1
#./mst.sh patents-mst-mizan.txt ${WORKERS} 1
#./mst.sh patents-mst-mizan.txt ${WORKERS} 1
# 
#./mst.sh patents-mst-mizan.txt ${WORKERS} 2
#./mst.sh patents-mst-mizan.txt ${WORKERS} 2
#./mst.sh patents-mst-mizan.txt ${WORKERS} 2
#./mst.sh patents-mst-mizan.txt ${WORKERS} 2
#./mst.sh patents-mst-mizan.txt ${WORKERS} 2
#./mst.sh patents-mst-mizan.txt ${WORKERS} 2
# 
# 
#./mst.sh livejournal-mst-mizan.txt ${WORKERS} 1
#./mst.sh livejournal-mst-mizan.txt ${WORKERS} 1
#./mst.sh livejournal-mst-mizan.txt ${WORKERS} 1
#./mst.sh livejournal-mst-mizan.txt ${WORKERS} 1
#./mst.sh livejournal-mst-mizan.txt ${WORKERS} 1
#./mst.sh livejournal-mst-mizan.txt ${WORKERS} 1
# 
#./mst.sh livejournal-mst-mizan.txt ${WORKERS} 2
#./mst.sh livejournal-mst-mizan.txt ${WORKERS} 2
#./mst.sh livejournal-mst-mizan.txt ${WORKERS} 2
#./mst.sh livejournal-mst-mizan.txt ${WORKERS} 2
#./mst.sh livejournal-mst-mizan.txt ${WORKERS} 2
#./mst.sh livejournal-mst-mizan.txt ${WORKERS} 2
# 
#./mst.sh orkut-mst-mizan.txt ${WORKERS} 1
#./mst.sh orkut-mst-mizan.txt ${WORKERS} 1
#./mst.sh orkut-mst-mizan.txt ${WORKERS} 1
#./mst.sh orkut-mst-mizan.txt ${WORKERS} 1
#./mst.sh orkut-mst-mizan.txt ${WORKERS} 1
#./mst.sh orkut-mst-mizan.txt ${WORKERS} 1
# 
#./mst.sh orkut-mst-mizan.txt ${WORKERS} 2
#./mst.sh orkut-mst-mizan.txt ${WORKERS} 2
#./mst.sh orkut-mst-mizan.txt ${WORKERS} 2
#./mst.sh orkut-mst-mizan.txt ${WORKERS} 2
#./mst.sh orkut-mst-mizan.txt ${WORKERS} 2
#./mst.sh orkut-mst-mizan.txt ${WORKERS} 2
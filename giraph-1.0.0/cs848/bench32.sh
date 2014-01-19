#!/bin/bash
WORKERS=32

./pagerank.sh patents-giraph.txt ${WORKERS}
./pagerank.sh patents-giraph.txt ${WORKERS}
./pagerank.sh patents-giraph.txt ${WORKERS}
./pagerank.sh patents-giraph.txt ${WORKERS}
./pagerank.sh patents-giraph.txt ${WORKERS}
./pagerank.sh patents-giraph.txt ${WORKERS}
 
./pagerank.sh livejournal-giraph.txt ${WORKERS}
./pagerank.sh livejournal-giraph.txt ${WORKERS}
./pagerank.sh livejournal-giraph.txt ${WORKERS}
./pagerank.sh livejournal-giraph.txt ${WORKERS}
./pagerank.sh livejournal-giraph.txt ${WORKERS}
./pagerank.sh livejournal-giraph.txt ${WORKERS}

./pagerank.sh orkut-giraph.txt ${WORKERS}
./pagerank.sh orkut-giraph.txt ${WORKERS}
./pagerank.sh orkut-giraph.txt ${WORKERS}
./pagerank.sh orkut-giraph.txt ${WORKERS}
./pagerank.sh orkut-giraph.txt ${WORKERS}
./pagerank.sh orkut-giraph.txt ${WORKERS}

#===============================================
#===============================================
#===============================================

./sssp.sh patents-giraph.txt ${WORKERS} 6009554
./sssp.sh patents-giraph.txt ${WORKERS} 6009554
./sssp.sh patents-giraph.txt ${WORKERS} 6009554
./sssp.sh patents-giraph.txt ${WORKERS} 6009554
./sssp.sh patents-giraph.txt ${WORKERS} 6009554
./sssp.sh patents-giraph.txt ${WORKERS} 6009554
 
./sssp.sh livejournal-giraph.txt ${WORKERS} 0
./sssp.sh livejournal-giraph.txt ${WORKERS} 0
./sssp.sh livejournal-giraph.txt ${WORKERS} 0
./sssp.sh livejournal-giraph.txt ${WORKERS} 0
./sssp.sh livejournal-giraph.txt ${WORKERS} 0
./sssp.sh livejournal-giraph.txt ${WORKERS} 0
 
./sssp.sh orkut-giraph.txt ${WORKERS} 1
./sssp.sh orkut-giraph.txt ${WORKERS} 1
./sssp.sh orkut-giraph.txt ${WORKERS} 1
./sssp.sh orkut-giraph.txt ${WORKERS} 1
./sssp.sh orkut-giraph.txt ${WORKERS} 1
./sssp.sh orkut-giraph.txt ${WORKERS} 1

#===============================================
#===============================================
#===============================================

./wcc.sh patents-giraph.txt ${WORKERS}
./wcc.sh patents-giraph.txt ${WORKERS}
./wcc.sh patents-giraph.txt ${WORKERS}
./wcc.sh patents-giraph.txt ${WORKERS}
./wcc.sh patents-giraph.txt ${WORKERS}
./wcc.sh patents-giraph.txt ${WORKERS}
 
./wcc.sh livejournal-giraph.txt ${WORKERS}
./wcc.sh livejournal-giraph.txt ${WORKERS}
./wcc.sh livejournal-giraph.txt ${WORKERS}
./wcc.sh livejournal-giraph.txt ${WORKERS}
./wcc.sh livejournal-giraph.txt ${WORKERS}
./wcc.sh livejournal-giraph.txt ${WORKERS}
 
./wcc.sh orkut-giraph.txt ${WORKERS}
./wcc.sh orkut-giraph.txt ${WORKERS}
./wcc.sh orkut-giraph.txt ${WORKERS}
./wcc.sh orkut-giraph.txt ${WORKERS}
./wcc.sh orkut-giraph.txt ${WORKERS}
./wcc.sh orkut-giraph.txt ${WORKERS}

#===============================================
#===============================================
#===============================================

#./mst.sh patents-mst-giraph.txt ${WORKERS}
#./mst.sh patents-mst-giraph.txt ${WORKERS}
#./mst.sh patents-mst-giraph.txt ${WORKERS}
#./mst.sh patents-mst-giraph.txt ${WORKERS}
#./mst.sh patents-mst-giraph.txt ${WORKERS}
#./mst.sh patents-mst-giraph.txt ${WORKERS}
# 
#./mst.sh livejournal-mst-giraph.txt ${WORKERS}
#./mst.sh livejournal-mst-giraph.txt ${WORKERS}
#./mst.sh livejournal-mst-giraph.txt ${WORKERS}
#./mst.sh livejournal-mst-giraph.txt ${WORKERS}
#./mst.sh livejournal-mst-giraph.txt ${WORKERS}
#./mst.sh livejournal-mst-giraph.txt ${WORKERS}
# 
#./mst.sh orkut-mst-giraph.txt ${WORKERS}
#./mst.sh orkut-mst-giraph.txt ${WORKERS}
#./mst.sh orkut-mst-giraph.txt ${WORKERS}
#./mst.sh orkut-mst-giraph.txt ${WORKERS}
#./mst.sh orkut-mst-giraph.txt ${WORKERS}
#./mst.sh orkut-mst-giraph.txt ${WORKERS}

#===============================================
#===============================================
#===============================================

#./mstmizan.sh patents-mstdumb-giraph.txt ${WORKERS}
#./mstmizan.sh patents-mstdumb-giraph.txt ${WORKERS}
#./mstmizan.sh patents-mstdumb-giraph.txt ${WORKERS}
#./mstmizan.sh patents-mstdumb-giraph.txt ${WORKERS}
#./mstmizan.sh patents-mstdumb-giraph.txt ${WORKERS}
#./mstmizan.sh patents-mstdumb-giraph.txt ${WORKERS}

#./mstmizan.sh livejournal-mstdumb-giraph.txt ${WORKERS}
#./mstmizan.sh livejournal-mstdumb-giraph.txt ${WORKERS}
#./mstmizan.sh livejournal-mstdumb-giraph.txt ${WORKERS}
#./mstmizan.sh livejournal-mstdumb-giraph.txt ${WORKERS}
#./mstmizan.sh livejournal-mstdumb-giraph.txt ${WORKERS}
#./mstmizan.sh livejournal-mstdumb-giraph.txt ${WORKERS}

#./mstmizan.sh orkut-mstdumb-giraph.txt ${WORKERS}
#./mstmizan.sh orkut-mstdumb-giraph.txt ${WORKERS}
#./mstmizan.sh orkut-mstdumb-giraph.txt ${WORKERS}
#./mstmizan.sh orkut-mstdumb-giraph.txt ${WORKERS}
#./mstmizan.sh orkut-mstdumb-giraph.txt ${WORKERS}
#./mstmizan.sh orkut-mstdumb-giraph.txt ${WORKERS}

#===============================================
#===============================================
#===============================================

#./dimest.sh patents-giraph.txt ${WORKERS}
#./dimest.sh patents-giraph.txt ${WORKERS}
#./dimest.sh patents-giraph.txt ${WORKERS}
#./dimest.sh patents-giraph.txt ${WORKERS}
#./dimest.sh patents-giraph.txt ${WORKERS}
#./dimest.sh patents-giraph.txt ${WORKERS}
# 
#./dimest.sh livejournal-giraph.txt ${WORKERS}
#./dimest.sh livejournal-giraph.txt ${WORKERS}
#./dimest.sh livejournal-giraph.txt ${WORKERS}
#./dimest.sh livejournal-giraph.txt ${WORKERS}
#./dimest.sh livejournal-giraph.txt ${WORKERS}
#./dimest.sh livejournal-giraph.txt ${WORKERS}
# 
#./dimest.sh orkut-giraph.txt ${WORKERS}
#./dimest.sh orkut-giraph.txt ${WORKERS}
#./dimest.sh orkut-giraph.txt ${WORKERS}
#./dimest.sh orkut-giraph.txt ${WORKERS}
#./dimest.sh orkut-giraph.txt ${WORKERS}
#./dimest.sh orkut-giraph.txt ${WORKERS}

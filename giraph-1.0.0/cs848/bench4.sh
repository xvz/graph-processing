#!/bin/bash
WORKERS=4

./pagerank.sh amazon-giraph.txt ${WORKERS}
./pagerank.sh amazon-giraph.txt ${WORKERS}
./pagerank.sh amazon-giraph.txt ${WORKERS}
./pagerank.sh amazon-giraph.txt ${WORKERS}
./pagerank.sh amazon-giraph.txt ${WORKERS}
./pagerank.sh amazon-giraph.txt ${WORKERS}

./pagerank.sh google-giraph.txt ${WORKERS}
./pagerank.sh google-giraph.txt ${WORKERS}
./pagerank.sh google-giraph.txt ${WORKERS}
./pagerank.sh google-giraph.txt ${WORKERS}
./pagerank.sh google-giraph.txt ${WORKERS}
./pagerank.sh google-giraph.txt ${WORKERS}

./pagerank.sh patents-giraph.txt ${WORKERS}
./pagerank.sh patents-giraph.txt ${WORKERS}
./pagerank.sh patents-giraph.txt ${WORKERS}
./pagerank.sh patents-giraph.txt ${WORKERS}
./pagerank.sh patents-giraph.txt ${WORKERS}
./pagerank.sh patents-giraph.txt ${WORKERS}

#===============================================
#===============================================
#===============================================

./sssp.sh amazon-giraph.txt ${WORKERS} 0
./sssp.sh amazon-giraph.txt ${WORKERS} 0
./sssp.sh amazon-giraph.txt ${WORKERS} 0
./sssp.sh amazon-giraph.txt ${WORKERS} 0
./sssp.sh amazon-giraph.txt ${WORKERS} 0
./sssp.sh amazon-giraph.txt ${WORKERS} 0
 
./sssp.sh google-giraph.txt ${WORKERS} 0
./sssp.sh google-giraph.txt ${WORKERS} 0
./sssp.sh google-giraph.txt ${WORKERS} 0
./sssp.sh google-giraph.txt ${WORKERS} 0
./sssp.sh google-giraph.txt ${WORKERS} 0
./sssp.sh google-giraph.txt ${WORKERS} 0
 
./sssp.sh patents-giraph.txt ${WORKERS} 6009554
./sssp.sh patents-giraph.txt ${WORKERS} 6009554
./sssp.sh patents-giraph.txt ${WORKERS} 6009554
./sssp.sh patents-giraph.txt ${WORKERS} 6009554
./sssp.sh patents-giraph.txt ${WORKERS} 6009554
./sssp.sh patents-giraph.txt ${WORKERS} 6009554

#===============================================
#===============================================
#===============================================

./wcc.sh amazon-giraph.txt ${WORKERS}
./wcc.sh amazon-giraph.txt ${WORKERS}
./wcc.sh amazon-giraph.txt ${WORKERS}
./wcc.sh amazon-giraph.txt ${WORKERS}
./wcc.sh amazon-giraph.txt ${WORKERS}
./wcc.sh amazon-giraph.txt ${WORKERS}
 
./wcc.sh google-giraph.txt ${WORKERS}
./wcc.sh google-giraph.txt ${WORKERS}
./wcc.sh google-giraph.txt ${WORKERS}
./wcc.sh google-giraph.txt ${WORKERS}
./wcc.sh google-giraph.txt ${WORKERS}
./wcc.sh google-giraph.txt ${WORKERS}
 
./wcc.sh patents-giraph.txt ${WORKERS}
./wcc.sh patents-giraph.txt ${WORKERS}
./wcc.sh patents-giraph.txt ${WORKERS}
./wcc.sh patents-giraph.txt ${WORKERS}
./wcc.sh patents-giraph.txt ${WORKERS}
./wcc.sh patents-giraph.txt ${WORKERS}

#===============================================
#===============================================
#===============================================

#./mst.sh amazon-mst-giraph.txt ${WORKERS}
#./mst.sh amazon-mst-giraph.txt ${WORKERS}
#./mst.sh amazon-mst-giraph.txt ${WORKERS}
#./mst.sh amazon-mst-giraph.txt ${WORKERS}
#./mst.sh amazon-mst-giraph.txt ${WORKERS}
#./mst.sh amazon-mst-giraph.txt ${WORKERS}
# 
#./mst.sh google-mst-giraph.txt ${WORKERS}
#./mst.sh google-mst-giraph.txt ${WORKERS}
#./mst.sh google-mst-giraph.txt ${WORKERS}
#./mst.sh google-mst-giraph.txt ${WORKERS}
#./mst.sh google-mst-giraph.txt ${WORKERS}
#./mst.sh google-mst-giraph.txt ${WORKERS}
# 
#./mst.sh patents-mst-giraph.txt ${WORKERS}
#./mst.sh patents-mst-giraph.txt ${WORKERS}
#./mst.sh patents-mst-giraph.txt ${WORKERS}
#./mst.sh patents-mst-giraph.txt ${WORKERS}
#./mst.sh patents-mst-giraph.txt ${WORKERS}
#./mst.sh patents-mst-giraph.txt ${WORKERS}

#===============================================
#===============================================
#===============================================

#./mstmizan.sh amazon-mstdumb-giraph.txt ${WORKERS}
#./mstmizan.sh amazon-mstdumb-giraph.txt ${WORKERS}
#./mstmizan.sh amazon-mstdumb-giraph.txt ${WORKERS}
#./mstmizan.sh amazon-mstdumb-giraph.txt ${WORKERS}
#./mstmizan.sh amazon-mstdumb-giraph.txt ${WORKERS}
#./mstmizan.sh amazon-mstdumb-giraph.txt ${WORKERS}

#./mstmizan.sh google-mstdumb-giraph.txt ${WORKERS}
#./mstmizan.sh google-mstdumb-giraph.txt ${WORKERS}
#./mstmizan.sh google-mstdumb-giraph.txt ${WORKERS}
#./mstmizan.sh google-mstdumb-giraph.txt ${WORKERS}
#./mstmizan.sh google-mstdumb-giraph.txt ${WORKERS}
#./mstmizan.sh google-mstdumb-giraph.txt ${WORKERS}

#./mstmizan.sh patents-mstdumb-giraph.txt ${WORKERS}
#./mstmizan.sh patents-mstdumb-giraph.txt ${WORKERS}
#./mstmizan.sh patents-mstdumb-giraph.txt ${WORKERS}
#./mstmizan.sh patents-mstdumb-giraph.txt ${WORKERS}
#./mstmizan.sh patents-mstdumb-giraph.txt ${WORKERS}
#./mstmizan.sh patents-mstdumb-giraph.txt ${WORKERS}
#!/bin/bash
WORKERS=4

#./sssp.sh google-giraph.txt ${WORKERS} 0
#./sssp.sh google-giraph.txt ${WORKERS} 0
#./sssp.sh google-giraph.txt ${WORKERS} 0
# 
#./sssp.sh amazon-giraph.txt ${WORKERS} 0
#./sssp.sh amazon-giraph.txt ${WORKERS} 0
#./sssp.sh amazon-giraph.txt ${WORKERS} 0
# 
#./sssp.sh patents-giraph.txt ${WORKERS} 3858241
#./sssp.sh patents-giraph.txt ${WORKERS} 3858241
#./sssp.sh patents-giraph.txt ${WORKERS} 3858241
# 
# 
#./pagerank.sh google-giraph.txt ${WORKERS}
#./pagerank.sh google-giraph.txt ${WORKERS}
#./pagerank.sh google-giraph.txt ${WORKERS}
# 
#./pagerank.sh amazon-giraph.txt ${WORKERS}
#./pagerank.sh amazon-giraph.txt ${WORKERS}
#./pagerank.sh amazon-giraph.txt ${WORKERS}
# 
#./pagerank.sh patents-giraph.txt ${WORKERS}
#./pagerank.sh patents-giraph.txt ${WORKERS}
./pagerank.sh patents-giraph.txt ${WORKERS}

./wcc.sh google.txt ${WORKERS}
./wcc.sh google.txt ${WORKERS}
./wcc.sh google.txt ${WORKERS}
 
./wcc.sh amazon.txt ${WORKERS}
./wcc.sh amazon.txt ${WORKERS}
./wcc.sh amazon.txt ${WORKERS}
 
./wcc.sh patents.txt ${WORKERS}
./wcc.sh patents.txt ${WORKERS}
./wcc.sh patents.txt ${WORKERS}
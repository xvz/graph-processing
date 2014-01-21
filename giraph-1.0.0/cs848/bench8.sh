#!/bin/bash
WORKERS=8

./pagerank.sh amazon-giraph.txt ${WORKERS}
./pagerank.sh amazon-giraph.txt ${WORKERS}
./pagerank.sh amazon-giraph.txt ${WORKERS}
stop-all.sh; for ((i=0; i<=8; i++)); do ssh cld$i 'kill $(pgrep java)'; done; start-all.sh
sleep 60
./pagerank.sh amazon-giraph.txt ${WORKERS}
./pagerank.sh amazon-giraph.txt ${WORKERS}
./pagerank.sh amazon-giraph.txt ${WORKERS}
stop-all.sh; for ((i=0; i<=8; i++)); do ssh cld$i 'kill $(pgrep java)'; done; start-all.sh
sleep 60
 
./pagerank.sh google-giraph.txt ${WORKERS}
./pagerank.sh google-giraph.txt ${WORKERS}
./pagerank.sh google-giraph.txt ${WORKERS}
stop-all.sh; for ((i=0; i<=8; i++)); do ssh cld$i 'kill $(pgrep java)'; done; start-all.sh
sleep 60
./pagerank.sh google-giraph.txt ${WORKERS}
./pagerank.sh google-giraph.txt ${WORKERS}
./pagerank.sh google-giraph.txt ${WORKERS}
stop-all.sh; for ((i=0; i<=8; i++)); do ssh cld$i 'kill $(pgrep java)'; done; start-all.sh
sleep 60
 
./pagerank.sh patents-giraph.txt ${WORKERS}
./pagerank.sh patents-giraph.txt ${WORKERS}
stop-all.sh; for ((i=0; i<=8; i++)); do ssh cld$i 'kill $(pgrep java)'; done; start-all.sh
sleep 60
./pagerank.sh patents-giraph.txt ${WORKERS}
./pagerank.sh patents-giraph.txt ${WORKERS}
stop-all.sh; for ((i=0; i<=8; i++)); do ssh cld$i 'kill $(pgrep java)'; done; start-all.sh
sleep 60
./pagerank.sh patents-giraph.txt ${WORKERS}
./pagerank.sh patents-giraph.txt ${WORKERS}
stop-all.sh; for ((i=0; i<=8; i++)); do ssh cld$i 'kill $(pgrep java)'; done; start-all.sh
sleep 60
# 
##===============================================
##===============================================
##===============================================
# 
#./sssp.sh amazon-giraph.txt ${WORKERS} 0
#./sssp.sh amazon-giraph.txt ${WORKERS} 0
#./sssp.sh amazon-giraph.txt ${WORKERS} 0
#stop-all.sh; for ((i=0; i<=8; i++)); do ssh cld$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 60
#./sssp.sh amazon-giraph.txt ${WORKERS} 0
#./sssp.sh amazon-giraph.txt ${WORKERS} 0
#./sssp.sh amazon-giraph.txt ${WORKERS} 0
#stop-all.sh; for ((i=0; i<=8; i++)); do ssh cld$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 60
# 
#./sssp.sh google-giraph.txt ${WORKERS} 0
#./sssp.sh google-giraph.txt ${WORKERS} 0
#./sssp.sh google-giraph.txt ${WORKERS} 0
#stop-all.sh; for ((i=0; i<=8; i++)); do ssh cld$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 60
#./sssp.sh google-giraph.txt ${WORKERS} 0
#./sssp.sh google-giraph.txt ${WORKERS} 0
#./sssp.sh google-giraph.txt ${WORKERS} 0
#stop-all.sh; for ((i=0; i<=8; i++)); do ssh cld$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 60
# 
#./sssp.sh patents-giraph.txt ${WORKERS} 6009554
#./sssp.sh patents-giraph.txt ${WORKERS} 6009554
#./sssp.sh patents-giraph.txt ${WORKERS} 6009554
#stop-all.sh; for ((i=0; i<=8; i++)); do ssh cld$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 60
#./sssp.sh patents-giraph.txt ${WORKERS} 6009554
#./sssp.sh patents-giraph.txt ${WORKERS} 6009554
#./sssp.sh patents-giraph.txt ${WORKERS} 6009554
#stop-all.sh; for ((i=0; i<=8; i++)); do ssh cld$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 60
# 
##===============================================
##===============================================
##===============================================
# 
#./wcc.sh amazon-giraph.txt ${WORKERS}
#./wcc.sh amazon-giraph.txt ${WORKERS}
#./wcc.sh amazon-giraph.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=8; i++)); do ssh cld$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 60
#./wcc.sh amazon-giraph.txt ${WORKERS}
#./wcc.sh amazon-giraph.txt ${WORKERS}
#./wcc.sh amazon-giraph.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=8; i++)); do ssh cld$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 60
# 
#./wcc.sh google-giraph.txt ${WORKERS}
#./wcc.sh google-giraph.txt ${WORKERS}
#./wcc.sh google-giraph.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=8; i++)); do ssh cld$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 60
#./wcc.sh google-giraph.txt ${WORKERS}
#./wcc.sh google-giraph.txt ${WORKERS}
#./wcc.sh google-giraph.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=8; i++)); do ssh cld$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 60
# 
#./wcc.sh patents-giraph.txt ${WORKERS}
#./wcc.sh patents-giraph.txt ${WORKERS}
#./wcc.sh patents-giraph.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=8; i++)); do ssh cld$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 60
#./wcc.sh patents-giraph.txt ${WORKERS}
#./wcc.sh patents-giraph.txt ${WORKERS}
#./wcc.sh patents-giraph.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=8; i++)); do ssh cld$i 'kill $(pgrep java)'; done; start-all.sh

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
#sleep 30
#./mst.sh patents-mst-giraph.txt ${WORKERS}
#sleep 30
#./mst.sh patents-mst-giraph.txt ${WORKERS}
#sleep 30
#./mst.sh patents-mst-giraph.txt ${WORKERS}
#sleep 30
#./mst.sh patents-mst-giraph.txt ${WORKERS}
#sleep 30
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

#===============================================
#===============================================
#===============================================

#./dimest.sh amazon-giraph.txt ${WORKERS}
#./dimest.sh amazon-giraph.txt ${WORKERS}
#./dimest.sh amazon-giraph.txt ${WORKERS}
#./dimest.sh amazon-giraph.txt ${WORKERS}
#./dimest.sh amazon-giraph.txt ${WORKERS}
#./dimest.sh amazon-giraph.txt ${WORKERS}
# 
#./dimest.sh google-giraph.txt ${WORKERS}
#./dimest.sh google-giraph.txt ${WORKERS}
#./dimest.sh google-giraph.txt ${WORKERS}
#./dimest.sh google-giraph.txt ${WORKERS}
#./dimest.sh google-giraph.txt ${WORKERS}
#./dimest.sh google-giraph.txt ${WORKERS}
# 
#./dimest.sh patents-giraph.txt ${WORKERS}
#./dimest.sh patents-giraph.txt ${WORKERS}
#./dimest.sh patents-giraph.txt ${WORKERS}
#./dimest.sh patents-giraph.txt ${WORKERS}
#./dimest.sh patents-giraph.txt ${WORKERS}
#./dimest.sh patents-giraph.txt ${WORKERS}

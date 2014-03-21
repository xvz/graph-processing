#!/bin/bash
WORKERS=16

./pagerank.sh patents-adj.txt ${WORKERS}
./pagerank.sh patents-adj.txt ${WORKERS}
./pagerank.sh patents-adj.txt ${WORKERS}
stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
sleep 70
./pagerank.sh patents-adj.txt ${WORKERS}
./pagerank.sh patents-adj.txt ${WORKERS}
./pagerank.sh patents-adj.txt ${WORKERS}
stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
sleep 70

./pagerank.sh livejournal-adj.txt ${WORKERS}
./pagerank.sh livejournal-adj.txt ${WORKERS}
./pagerank.sh livejournal-adj.txt ${WORKERS}
stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
sleep 70
./pagerank.sh livejournal-adj.txt ${WORKERS}
./pagerank.sh livejournal-adj.txt ${WORKERS}
./pagerank.sh livejournal-adj.txt ${WORKERS}
stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
sleep 70

./pagerank.sh orkut-adj.txt ${WORKERS}
./pagerank.sh orkut-adj.txt ${WORKERS}
stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
sleep 70
./pagerank.sh orkut-adj.txt ${WORKERS}
./pagerank.sh orkut-adj.txt ${WORKERS}
stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
sleep 70
./pagerank.sh orkut-adj.txt ${WORKERS}
./pagerank.sh orkut-adj.txt ${WORKERS}
stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
sleep 70

#===============================================
#===============================================
#===============================================

./sssp.sh patents-adj.txt ${WORKERS} 6009554
./sssp.sh patents-adj.txt ${WORKERS} 6009554
./sssp.sh patents-adj.txt ${WORKERS} 6009554
stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
sleep 70
./sssp.sh patents-adj.txt ${WORKERS} 6009554
./sssp.sh patents-adj.txt ${WORKERS} 6009554
./sssp.sh patents-adj.txt ${WORKERS} 6009554
stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
sleep 70

./sssp.sh livejournal-adj.txt ${WORKERS} 0
./sssp.sh livejournal-adj.txt ${WORKERS} 0
./sssp.sh livejournal-adj.txt ${WORKERS} 0
stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
sleep 70
./sssp.sh livejournal-adj.txt ${WORKERS} 0
./sssp.sh livejournal-adj.txt ${WORKERS} 0
./sssp.sh livejournal-adj.txt ${WORKERS} 0
stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
sleep 70

./sssp.sh orkut-adj.txt ${WORKERS} 1
./sssp.sh orkut-adj.txt ${WORKERS} 1
stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
sleep 70
./sssp.sh orkut-adj.txt ${WORKERS} 1
./sssp.sh orkut-adj.txt ${WORKERS} 1
stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
sleep 70
./sssp.sh orkut-adj.txt ${WORKERS} 1
./sssp.sh orkut-adj.txt ${WORKERS} 1
stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
sleep 70

#===============================================
#===============================================
#===============================================

./wcc.sh patents-adj.txt ${WORKERS}
./wcc.sh patents-adj.txt ${WORKERS}
./wcc.sh patents-adj.txt ${WORKERS}
stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
sleep 70
./wcc.sh patents-adj.txt ${WORKERS}
./wcc.sh patents-adj.txt ${WORKERS}
./wcc.sh patents-adj.txt ${WORKERS}
stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
sleep 70

./wcc.sh livejournal-adj.txt ${WORKERS}
./wcc.sh livejournal-adj.txt ${WORKERS}
./wcc.sh livejournal-adj.txt ${WORKERS}
stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
sleep 70
./wcc.sh livejournal-adj.txt ${WORKERS}
./wcc.sh livejournal-adj.txt ${WORKERS}
./wcc.sh livejournal-adj.txt ${WORKERS}
stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
sleep 70

./wcc.sh orkut-adj.txt ${WORKERS}
./wcc.sh orkut-adj.txt ${WORKERS}
stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
sleep 70
./wcc.sh orkut-adj.txt ${WORKERS}
./wcc.sh orkut-adj.txt ${WORKERS}
stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
sleep 70
./wcc.sh orkut-adj.txt ${WORKERS}
./wcc.sh orkut-adj.txt ${WORKERS}
stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
sleep 70

#===============================================
#===============================================
#===============================================

#./mst.sh patents-mst-adj.txt ${WORKERS}
#./mst.sh patents-mst-adj.txt ${WORKERS}
#./mst.sh patents-mst-adj.txt ${WORKERS}
#./mst.sh patents-mst-adj.txt ${WORKERS}
#./mst.sh patents-mst-adj.txt ${WORKERS}
#./mst.sh patents-mst-adj.txt ${WORKERS}
#sleep 30
# 
#./mst.sh livejournal-mst-adj.txt ${WORKERS}
#sleep 30
#./mst.sh livejournal-mst-adj.txt ${WORKERS}
#sleep 30
#./mst.sh livejournal-mst-adj.txt ${WORKERS}
#sleep 30
#./mst.sh livejournal-mst-adj.txt ${WORKERS}
#sleep 30
#./mst.sh livejournal-mst-adj.txt ${WORKERS}
#sleep 30
#./mst.sh livejournal-mst-adj.txt ${WORKERS}
#sleep 30
# 
#./mst.sh orkut-mst-adj.txt ${WORKERS}
#sleep 30
#./mst.sh orkut-mst-adj.txt ${WORKERS}
#sleep 30
#./mst.sh orkut-mst-adj.txt ${WORKERS}
#sleep 30
#./mst.sh orkut-mst-adj.txt ${WORKERS}
#sleep 30
#./mst.sh orkut-mst-adj.txt ${WORKERS}
#sleep 30
#./mst.sh orkut-mst-adj.txt ${WORKERS}

#===============================================
#===============================================
#===============================================

#./dimest.sh patents-adj.txt ${WORKERS}
#./dimest.sh patents-adj.txt ${WORKERS}
#./dimest.sh patents-adj.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 70
#./dimest.sh patents-adj.txt ${WORKERS}
#./dimest.sh patents-adj.txt ${WORKERS}
#./dimest.sh patents-adj.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 70

#./dimest.sh livejournal-adj.txt ${WORKERS}
#./dimest.sh livejournal-adj.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 70
#./dimest.sh livejournal-adj.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 70
#./dimest.sh livejournal-adj.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 70
#./dimest.sh livejournal-adj.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 70
#./dimest.sh livejournal-adj.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 70
# 
#./dimest.sh orkut-adj.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 70
#./dimest.sh orkut-adj.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 70
#./dimest.sh orkut-adj.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 70
#./dimest.sh orkut-adj.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 70
#./dimest.sh orkut-adj.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 70
#./dimest.sh orkut-adj.txt ${WORKERS}
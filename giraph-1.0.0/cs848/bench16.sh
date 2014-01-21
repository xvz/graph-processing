#!/bin/bash
WORKERS=16

./pagerank.sh patents-giraph.txt ${WORKERS}
./pagerank.sh patents-giraph.txt ${WORKERS}
./pagerank.sh patents-giraph.txt ${WORKERS}
stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
sleep 70
./pagerank.sh patents-giraph.txt ${WORKERS}
./pagerank.sh patents-giraph.txt ${WORKERS}
./pagerank.sh patents-giraph.txt ${WORKERS}
stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
sleep 70

./pagerank.sh livejournal-giraph.txt ${WORKERS}
./pagerank.sh livejournal-giraph.txt ${WORKERS}
./pagerank.sh livejournal-giraph.txt ${WORKERS}
stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
sleep 70
./pagerank.sh livejournal-giraph.txt ${WORKERS}
./pagerank.sh livejournal-giraph.txt ${WORKERS}
./pagerank.sh livejournal-giraph.txt ${WORKERS}
stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
sleep 70

./pagerank.sh orkut-giraph.txt ${WORKERS}
./pagerank.sh orkut-giraph.txt ${WORKERS}
stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
sleep 70
./pagerank.sh orkut-giraph.txt ${WORKERS}
./pagerank.sh orkut-giraph.txt ${WORKERS}
stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
sleep 70
./pagerank.sh orkut-giraph.txt ${WORKERS}
./pagerank.sh orkut-giraph.txt ${WORKERS}
stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
sleep 70

#===============================================
#===============================================
#===============================================

./sssp.sh patents-giraph.txt ${WORKERS} 6009554
./sssp.sh patents-giraph.txt ${WORKERS} 6009554
./sssp.sh patents-giraph.txt ${WORKERS} 6009554
stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
sleep 70
./sssp.sh patents-giraph.txt ${WORKERS} 6009554
./sssp.sh patents-giraph.txt ${WORKERS} 6009554
./sssp.sh patents-giraph.txt ${WORKERS} 6009554
stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
sleep 70

./sssp.sh livejournal-giraph.txt ${WORKERS} 0
./sssp.sh livejournal-giraph.txt ${WORKERS} 0
./sssp.sh livejournal-giraph.txt ${WORKERS} 0
stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
sleep 70
./sssp.sh livejournal-giraph.txt ${WORKERS} 0
./sssp.sh livejournal-giraph.txt ${WORKERS} 0
./sssp.sh livejournal-giraph.txt ${WORKERS} 0
stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
sleep 70

./sssp.sh orkut-giraph.txt ${WORKERS} 1
./sssp.sh orkut-giraph.txt ${WORKERS} 1
stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
sleep 70
./sssp.sh orkut-giraph.txt ${WORKERS} 1
./sssp.sh orkut-giraph.txt ${WORKERS} 1
stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
sleep 70
./sssp.sh orkut-giraph.txt ${WORKERS} 1
./sssp.sh orkut-giraph.txt ${WORKERS} 1
stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
sleep 70

#===============================================
#===============================================
#===============================================

./wcc.sh patents-giraph.txt ${WORKERS}
./wcc.sh patents-giraph.txt ${WORKERS}
./wcc.sh patents-giraph.txt ${WORKERS}
stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
sleep 70
./wcc.sh patents-giraph.txt ${WORKERS}
./wcc.sh patents-giraph.txt ${WORKERS}
./wcc.sh patents-giraph.txt ${WORKERS}
stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
sleep 70

./wcc.sh livejournal-giraph.txt ${WORKERS}
./wcc.sh livejournal-giraph.txt ${WORKERS}
./wcc.sh livejournal-giraph.txt ${WORKERS}
stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
sleep 70
./wcc.sh livejournal-giraph.txt ${WORKERS}
./wcc.sh livejournal-giraph.txt ${WORKERS}
./wcc.sh livejournal-giraph.txt ${WORKERS}
stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
sleep 70

./wcc.sh orkut-giraph.txt ${WORKERS}
./wcc.sh orkut-giraph.txt ${WORKERS}
stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
sleep 70
./wcc.sh orkut-giraph.txt ${WORKERS}
./wcc.sh orkut-giraph.txt ${WORKERS}
stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
sleep 70
./wcc.sh orkut-giraph.txt ${WORKERS}
./wcc.sh orkut-giraph.txt ${WORKERS}
stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
sleep 70

#===============================================
#===============================================
#===============================================

#./mst.sh patents-mst-giraph.txt ${WORKERS}
#./mst.sh patents-mst-giraph.txt ${WORKERS}
#./mst.sh patents-mst-giraph.txt ${WORKERS}
#./mst.sh patents-mst-giraph.txt ${WORKERS}
#./mst.sh patents-mst-giraph.txt ${WORKERS}
#./mst.sh patents-mst-giraph.txt ${WORKERS}
#sleep 30
# 
#./mst.sh livejournal-mst-giraph.txt ${WORKERS}
#sleep 30
#./mst.sh livejournal-mst-giraph.txt ${WORKERS}
#sleep 30
#./mst.sh livejournal-mst-giraph.txt ${WORKERS}
#sleep 30
#./mst.sh livejournal-mst-giraph.txt ${WORKERS}
#sleep 30
#./mst.sh livejournal-mst-giraph.txt ${WORKERS}
#sleep 30
#./mst.sh livejournal-mst-giraph.txt ${WORKERS}
#sleep 30
# 
#./mst.sh orkut-mst-giraph.txt ${WORKERS}
#sleep 30
#./mst.sh orkut-mst-giraph.txt ${WORKERS}
#sleep 30
#./mst.sh orkut-mst-giraph.txt ${WORKERS}
#sleep 30
#./mst.sh orkut-mst-giraph.txt ${WORKERS}
#sleep 30
#./mst.sh orkut-mst-giraph.txt ${WORKERS}
#sleep 30
#./mst.sh orkut-mst-giraph.txt ${WORKERS}

#===============================================
#===============================================
#===============================================

#./dimest.sh patents-giraph.txt ${WORKERS}
#./dimest.sh patents-giraph.txt ${WORKERS}
#./dimest.sh patents-giraph.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 70
#./dimest.sh patents-giraph.txt ${WORKERS}
#./dimest.sh patents-giraph.txt ${WORKERS}
#./dimest.sh patents-giraph.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 70

#./dimest.sh livejournal-giraph.txt ${WORKERS}
#./dimest.sh livejournal-giraph.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 70
#./dimest.sh livejournal-giraph.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 70
#./dimest.sh livejournal-giraph.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 70
#./dimest.sh livejournal-giraph.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 70
#./dimest.sh livejournal-giraph.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 70
# 
#./dimest.sh orkut-giraph.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 70
#./dimest.sh orkut-giraph.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 70
#./dimest.sh orkut-giraph.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 70
#./dimest.sh orkut-giraph.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 70
#./dimest.sh orkut-giraph.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=16; i++)); do ssh c$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 70
#./dimest.sh orkut-giraph.txt ${WORKERS}
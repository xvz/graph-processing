#!/bin/bash
WORKERS=4

#./pagerank.sh amazon-adj.txt ${WORKERS}
#./pagerank.sh amazon-adj.txt ${WORKERS}
#./pagerank.sh amazon-adj.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=4; i++)); do ssh cloud$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 60
#./pagerank.sh amazon-adj.txt ${WORKERS}
#./pagerank.sh amazon-adj.txt ${WORKERS}
#./pagerank.sh amazon-adj.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=4; i++)); do ssh cloud$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 60
# 
#./pagerank.sh google-adj.txt ${WORKERS}
#./pagerank.sh google-adj.txt ${WORKERS}
#./pagerank.sh google-adj.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=4; i++)); do ssh cloud$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 60
#./pagerank.sh google-adj.txt ${WORKERS}
#./pagerank.sh google-adj.txt ${WORKERS}
#./pagerank.sh google-adj.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=4; i++)); do ssh cloud$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 60
# 
#./pagerank.sh patents-adj.txt ${WORKERS}
#./pagerank.sh patents-adj.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=4; i++)); do ssh cloud$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 60
#./pagerank.sh patents-adj.txt ${WORKERS}
#./pagerank.sh patents-adj.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=4; i++)); do ssh cloud$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 60
#./pagerank.sh patents-adj.txt ${WORKERS}
#./pagerank.sh patents-adj.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=4; i++)); do ssh cloud$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 60
#
#
#./pagerank.sh livejournal-adj.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=4; i++)); do ssh cloud$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 60
#./pagerank.sh livejournal-adj.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=4; i++)); do ssh cloud$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 60
./pagerank.sh livejournal-adj.txt ${WORKERS}
stop-all.sh; for ((i=0; i<=4; i++)); do ssh cloud$i 'kill $(pgrep java)'; done; start-all.sh
sleep 60
./pagerank.sh livejournal-adj.txt ${WORKERS}
stop-all.sh; for ((i=0; i<=4; i++)); do ssh cloud$i 'kill $(pgrep java)'; done; start-all.sh
sleep 60
./pagerank.sh livejournal-adj.txt ${WORKERS}
stop-all.sh; for ((i=0; i<=4; i++)); do ssh cloud$i 'kill $(pgrep java)'; done; start-all.sh
sleep 60
./pagerank.sh livejournal-adj.txt ${WORKERS}
stop-all.sh; for ((i=0; i<=4; i++)); do ssh cloud$i 'kill $(pgrep java)'; done; start-all.sh
sleep 60


# 
##===============================================
##===============================================
##===============================================
# 
#./sssp.sh amazon-adj.txt ${WORKERS} 0
#./sssp.sh amazon-adj.txt ${WORKERS} 0
#./sssp.sh amazon-adj.txt ${WORKERS} 0
#stop-all.sh; for ((i=0; i<=4; i++)); do ssh cloud$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 60
#./sssp.sh amazon-adj.txt ${WORKERS} 0
#./sssp.sh amazon-adj.txt ${WORKERS} 0
#./sssp.sh amazon-adj.txt ${WORKERS} 0
#stop-all.sh; for ((i=0; i<=4; i++)); do ssh cloud$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 60
# 
#./sssp.sh google-adj.txt ${WORKERS} 0
#./sssp.sh google-adj.txt ${WORKERS} 0
#./sssp.sh google-adj.txt ${WORKERS} 0
#stop-all.sh; for ((i=0; i<=4; i++)); do ssh cloud$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 60
#./sssp.sh google-adj.txt ${WORKERS} 0
#./sssp.sh google-adj.txt ${WORKERS} 0
#./sssp.sh google-adj.txt ${WORKERS} 0
#stop-all.sh; for ((i=0; i<=4; i++)); do ssh cloud$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 60
# 
#./sssp.sh patents-adj.txt ${WORKERS} 6009554
#./sssp.sh patents-adj.txt ${WORKERS} 6009554
#./sssp.sh patents-adj.txt ${WORKERS} 6009554
#stop-all.sh; for ((i=0; i<=4; i++)); do ssh cloud$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 60
#./sssp.sh patents-adj.txt ${WORKERS} 6009554
#./sssp.sh patents-adj.txt ${WORKERS} 6009554
#./sssp.sh patents-adj.txt ${WORKERS} 6009554
#stop-all.sh; for ((i=0; i<=4; i++)); do ssh cloud$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 60
#
#
#./sssp.sh livejournal-adj.txt ${WORKERS} 0
#stop-all.sh; for ((i=0; i<=4; i++)); do ssh cloud$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 60
./sssp.sh livejournal-adj.txt ${WORKERS} 0
stop-all.sh; for ((i=0; i<=4; i++)); do ssh cloud$i 'kill $(pgrep java)'; done; start-all.sh
sleep 60
./sssp.sh livejournal-adj.txt ${WORKERS} 0
stop-all.sh; for ((i=0; i<=4; i++)); do ssh cloud$i 'kill $(pgrep java)'; done; start-all.sh
sleep 60
./sssp.sh livejournal-adj.txt ${WORKERS} 0
stop-all.sh; for ((i=0; i<=4; i++)); do ssh cloud$i 'kill $(pgrep java)'; done; start-all.sh
sleep 60
./sssp.sh livejournal-adj.txt ${WORKERS} 0
stop-all.sh; for ((i=0; i<=4; i++)); do ssh cloud$i 'kill $(pgrep java)'; done; start-all.sh
sleep 60
./sssp.sh livejournal-adj.txt ${WORKERS} 0
stop-all.sh; for ((i=0; i<=4; i++)); do ssh cloud$i 'kill $(pgrep java)'; done; start-all.sh
sleep 60
#
# 
##===============================================
##===============================================
##===============================================
# 
#./wcc.sh amazon-adj.txt ${WORKERS}
#./wcc.sh amazon-adj.txt ${WORKERS}
#./wcc.sh amazon-adj.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=4; i++)); do ssh cloud$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 60
#./wcc.sh amazon-adj.txt ${WORKERS}
#./wcc.sh amazon-adj.txt ${WORKERS}
#./wcc.sh amazon-adj.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=4; i++)); do ssh cloud$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 60
# 
#./wcc.sh google-adj.txt ${WORKERS}
#./wcc.sh google-adj.txt ${WORKERS}
#./wcc.sh google-adj.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=4; i++)); do ssh cloud$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 60
#./wcc.sh google-adj.txt ${WORKERS}
#./wcc.sh google-adj.txt ${WORKERS}
#./wcc.sh google-adj.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=4; i++)); do ssh cloud$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 60
# 
#./wcc.sh patents-adj.txt ${WORKERS}
#./wcc.sh patents-adj.txt ${WORKERS}
#./wcc.sh patents-adj.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=4; i++)); do ssh cloud$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 60
#./wcc.sh patents-adj.txt ${WORKERS}
#./wcc.sh patents-adj.txt ${WORKERS}
#./wcc.sh patents-adj.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=4; i++)); do ssh cloud$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 60


#./wcc.sh livejournal-adj.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=4; i++)); do ssh cloud$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 60
./wcc.sh livejournal-adj.txt ${WORKERS}
stop-all.sh; for ((i=0; i<=4; i++)); do ssh cloud$i 'kill $(pgrep java)'; done; start-all.sh
sleep 60
./wcc.sh livejournal-adj.txt ${WORKERS}
stop-all.sh; for ((i=0; i<=4; i++)); do ssh cloud$i 'kill $(pgrep java)'; done; start-all.sh
sleep 60
./wcc.sh livejournal-adj.txt ${WORKERS}
stop-all.sh; for ((i=0; i<=4; i++)); do ssh cloud$i 'kill $(pgrep java)'; done; start-all.sh
sleep 60
./wcc.sh livejournal-adj.txt ${WORKERS}
stop-all.sh; for ((i=0; i<=4; i++)); do ssh cloud$i 'kill $(pgrep java)'; done; start-all.sh
sleep 60
./wcc.sh livejournal-adj.txt ${WORKERS}
stop-all.sh; for ((i=0; i<=4; i++)); do ssh cloud$i 'kill $(pgrep java)'; done; start-all.sh
sleep 60



#===============================================
#===============================================
#===============================================

#./mst.sh amazon-mst-adj.txt ${WORKERS}
#./mst.sh amazon-mst-adj.txt ${WORKERS}
#./mst.sh amazon-mst-adj.txt ${WORKERS}
#./mst.sh amazon-mst-adj.txt ${WORKERS}
#./mst.sh amazon-mst-adj.txt ${WORKERS}
#./mst.sh amazon-mst-adj.txt ${WORKERS}
# 
#./mst.sh google-mst-adj.txt ${WORKERS}
#sleep 30
#./mst.sh google-mst-adj.txt ${WORKERS}
#sleep 30
#./mst.sh google-mst-adj.txt ${WORKERS}
#sleep 30
#./mst.sh google-mst-adj.txt ${WORKERS}
#sleep 30
#./mst.sh google-mst-adj.txt ${WORKERS}
#sleep 30
#./mst.sh google-mst-adj.txt ${WORKERS}
#sleep 30
 
#./mst.sh patents-mst-adj.txt ${WORKERS}
#sleep 30
#./mst.sh patents-mst-adj.txt ${WORKERS}
#sleep 30
#./mst.sh patents-mst-adj.txt ${WORKERS}
#sleep 30
#./mst.sh patents-mst-adj.txt ${WORKERS}
#sleep 30
#./mst.sh patents-mst-adj.txt ${WORKERS}
#sleep 30
#./mst.sh patents-mst-adj.txt ${WORKERS}

#===============================================
#===============================================
#===============================================

#./mstmizan.sh amazon-mstdumb-adj.txt ${WORKERS}
#./mstmizan.sh amazon-mstdumb-adj.txt ${WORKERS}
#./mstmizan.sh amazon-mstdumb-adj.txt ${WORKERS}
#./mstmizan.sh amazon-mstdumb-adj.txt ${WORKERS}
#./mstmizan.sh amazon-mstdumb-adj.txt ${WORKERS}
#./mstmizan.sh amazon-mstdumb-adj.txt ${WORKERS}

#./mstmizan.sh google-mstdumb-adj.txt ${WORKERS}
#./mstmizan.sh google-mstdumb-adj.txt ${WORKERS}
#./mstmizan.sh google-mstdumb-adj.txt ${WORKERS}
#./mstmizan.sh google-mstdumb-adj.txt ${WORKERS}
#./mstmizan.sh google-mstdumb-adj.txt ${WORKERS}
#./mstmizan.sh google-mstdumb-adj.txt ${WORKERS}

#./mstmizan.sh patents-mstdumb-adj.txt ${WORKERS}
#./mstmizan.sh patents-mstdumb-adj.txt ${WORKERS}
#./mstmizan.sh patents-mstdumb-adj.txt ${WORKERS}
#./mstmizan.sh patents-mstdumb-adj.txt ${WORKERS}
#./mstmizan.sh patents-mstdumb-adj.txt ${WORKERS}
#./mstmizan.sh patents-mstdumb-adj.txt ${WORKERS}

##===============================================
##===============================================
##===============================================
# 
#./dimest.sh amazon-adj.txt ${WORKERS}
#./dimest.sh amazon-adj.txt ${WORKERS}
#./dimest.sh amazon-adj.txt ${WORKERS}
#./dimest.sh amazon-adj.txt ${WORKERS}
#./dimest.sh amazon-adj.txt ${WORKERS}
#./dimest.sh amazon-adj.txt ${WORKERS}
# 
#./dimest.sh google-adj.txt ${WORKERS}
#./dimest.sh google-adj.txt ${WORKERS}
#./dimest.sh google-adj.txt ${WORKERS}
#./dimest.sh google-adj.txt ${WORKERS}
#./dimest.sh google-adj.txt ${WORKERS}
#./dimest.sh google-adj.txt ${WORKERS}
# 
#./dimest.sh patents-adj.txt ${WORKERS}
#./dimest.sh patents-adj.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=4; i++)); do ssh cloud$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 60
#./dimest.sh patents-adj.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=4; i++)); do ssh cloud$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 60
#./dimest.sh patents-adj.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=4; i++)); do ssh cloud$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 60
#./dimest.sh patents-adj.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=4; i++)); do ssh cloud$i 'kill $(pgrep java)'; done; start-all.sh
#sleep 60
#./dimest.sh patents-adj.txt ${WORKERS}
#stop-all.sh; for ((i=0; i<=4; i++)); do ssh cloud$i 'kill $(pgrep java)'; done; start-all.sh

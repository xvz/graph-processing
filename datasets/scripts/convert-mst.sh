#!/bin/bash -e

cd ../raw/

FILES=("amazon" "google" "patents")

# these take a stupid long time
BIGFILES=("livejournal" "orkut")


for file in "${FILES[@]}"; do
    echo "Converting ${file}"
    ../scripts/mst-convert ${file}.txt ${file}-mst.txt 1
    ../scripts/mst-convert ${file}.txt ${file}-mstdumb.txt 2
    ../scripts/mst-convert ${file}.txt ${file}-mst-mizan.txt 3
    
    ../scripts/mizan-convert ${file}-mst.txt ${file}-mst-giraph.txt 2 1
    ../scripts/mizan-convert ${file}-mst.txt ${file}-mst-gps.txt 2 3

    ../scripts/mizan-convert ${file}-mstdumb.txt ${file}-mstdumb-giraph.txt 2 1
    ../scripts/mizan-convert ${file}-mstdumb.txt ${file}-mstdumb-gps.txt 2 3
done
 
read -p "Convert big files? (y/n): " yn

if [[ "$yn" == "y" ]]; then
    for file in "${BIGFILES[@]}"; do
        echo "Converting ${file}"
        ../scripts/mst-convert ${file}.txt ${file}-mst.txt 1
        ../scripts/mst-convert ${file}.txt ${file}-mstdumb.txt 2
        ../scripts/mst-convert ${file}.txt ${file}-mst-mizan.txt 3
        
        ../scripts/mizan-convert ${file}-mst.txt ${file}-mst-giraph.txt 2 1
        ../scripts/mizan-convert ${file}-mst.txt ${file}-mst-gps.txt 2 3

        ../scripts/mizan-convert ${file}-mstdumb.txt ${file}-mstdumb-giraph.txt 2 1
        ../scripts/mizan-convert ${file}-mstdumb.txt ${file}-mstdumb-gps.txt 2 3
    done
fi
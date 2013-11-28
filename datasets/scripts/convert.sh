#!/bin/bash -e

cd ../raw/

FILES=("amazon" "google" "patents" "road")

# these have weighted edges
SPECIALFILES=("retweet")

# these take a stupid long time
BIGFILES=("livejournal" "orkut")


for file in "${FILES[@]}"; do
    echo "Converting ${file}"
    ../scripts/mizan-convert ${file}.txt ${file}-giraph.txt 3 1
    ../scripts/mizan-convert ${file}.txt ${file}-gps-noval.txt 3 2
    ../scripts/mizan-convert ${file}.txt ${file}-gps-val.txt 3 3
done
 
for file in "${SPECIALFILES[@]}"; do
    echo "Converting ${file}"
    ../scripts/mizan-convert ${file}.txt ${file}-giraph.txt 2 1
    ../scripts/mizan-convert ${file}.txt ${file}-gps-noval.txt 2 2
    ../scripts/mizan-convert ${file}.txt ${file}-gps-val.txt 2 3
done

read -p "Convert big files? (y/n): " yn

if [[ "$yn" == "y" ]]; then
    for file in "${BIGFILES[@]}"; do
        echo "Converting ${file}"
        ../scripts/mizan-convert ${file}.txt ${file}-giraph.txt 3 1
        ../scripts/mizan-convert ${file}.txt ${file}-gps-noval.txt 3 2
        ../scripts/mizan-convert ${file}.txt ${file}-gps-val.txt 3 3
    done
fi
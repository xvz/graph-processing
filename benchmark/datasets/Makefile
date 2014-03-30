all: snap-convert snap-revert mst-convert mst-convert-old

clean:
	rm -f snap-convert
	rm -f snap-revert
	rm -f mst-convert
	rm -f mst-convert-old

snap-convert: snap-convert.cpp
	g++ -Wall snap-convert.cpp -o snap-convert

snap-revert: snap-revert.cpp
	g++ -Wall snap-revert.cpp -o snap-revert

mst-convert: mst-convert.cpp
	g++ -Wall mst-convert.cpp -o mst-convert

mst-convert-old: mst-convert-old.cpp
	g++ -std=c++0x -Wall mst-convert-old.cpp -o mst-convert-old
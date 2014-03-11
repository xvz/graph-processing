all: mizan-convert mst-convert mst-sconv

clean:
	rm -f mizan-convert
	rm -f mst-convert
	rm -f mst-sconv

mizan-convert: mizan-convert.cpp
	g++ -Wall mizan-convert.cpp -o mizan-convert

mst-convert: mst-convert.cpp
	g++ -std=c++0x -Wall mst-convert.cpp -o mst-convert

mst-sconv: mst-sconv.cpp
	g++ -Wall mst-sconv.cpp -o mst-sconv
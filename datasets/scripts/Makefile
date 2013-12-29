all: mizan-convert mst-convert

clean:
	rm -f mizan-convert
	rm -f mst-convert

mizan-convert: mizan-convert.cpp
	g++ -Wall mizan-convert.cpp -o mizan-convert

mst-convert: mst-convert.cpp
	g++ -std=c++0x -Wall mst-convert.cpp -o mst-convert
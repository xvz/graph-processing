all: mizan-convert mst-convert mst-convert-old

clean:
	rm -f mizan-convert
	rm -f mst-convert
	rm -f mst-convert-old

mizan-convert: mizan-convert.cpp
	g++ -Wall mizan-convert.cpp -o mizan-convert

mst-convert: mst-convert.cpp
	g++ -Wall mst-convert.cpp -o mst-convert

mst-convert-old: mst-convert-old.cpp
	g++ -std=c++0x -Wall mst-convert-old.cpp -o mst-convert-old
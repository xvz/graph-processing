#include <stdlib.h>
#include <fstream>
#include <iostream>
#include <string>
#include <cerrno>


#define M_TO_GIRAPH      1
#define M_TO_GPS_NOVAL   2
#define M_TO_GPS_VAL     3

using namespace std;

static void usage(char **argv) {
  cout << "usage: " << argv[0] << " input-file output-file format" << endl;
  cout << endl;
  cout << "format: 1. Mizan to Giraph" << endl;
  cout << "        2. Mizan to GPS (no values)" << endl;
  cout << "        3. Mizan to GPS (vertex + edge values)" << endl;
}

/**
 * Converts dataset/graph input formats.
 *
 * NOTE: Does not sort anything! (Sorting is not needed anyway)
 */
int main(int argc, char **argv) {
  if ( argc < 4 ) {
    usage(argv);
    return -1;
  }

  ifstream ifs(argv[1], ifstream::in);
  ofstream ofs(argv[2], ofstream::out);
  int format = atoi(argv[3]);

  if (!ifs || !ofs ||
      (format < M_TO_GIRAPH || format > M_TO_GPS_VAL) ) {
    usage(argv);
    return -1;
  }
  
  int vertex_id, edge_dst;
  int curr_id;

  // first pair of reads
  ifs >> curr_id;
  ifs >> edge_dst;

  switch (format) {
  case M_TO_GIRAPH:
    while (!ifs.eof()) {
      // format: [vertex-id, vertex-val, [[edge-dst,edge-val],...]]
      ofs << "[" << curr_id << ",0,[[" << edge_dst << ",0]";

      ifs >> vertex_id;
      ifs >> edge_dst;

      while ( vertex_id == curr_id && !ifs.eof() ) {
        ofs << ",[" << edge_dst << ",0]";

        ifs >> vertex_id;
        ifs >> edge_dst;
      }

      ofs << "]]" << endl;

      // new vertex_id found. carry over edge_dst too.
      curr_id = vertex_id;
    }
    break;

  case M_TO_GPS_NOVAL:
    while (!ifs.eof()) {
      // format: vertex-id edge-dst ...
      ofs  << curr_id << " " << edge_dst;

      ifs >> vertex_id;
      ifs >> edge_dst;

      while ( vertex_id == curr_id && !ifs.eof() ) {
        ofs << " " << edge_dst;

        ifs >> vertex_id;
        ifs >> edge_dst;
      }

      ofs << endl;

      // new vertex_id found. carry over edge_dst too.
      curr_id = vertex_id;
    }
    break;

  case M_TO_GPS_VAL:
    while (!ifs.eof()) {
      // format: vertex-id vertex-val edge-dst edge-val ...
      ofs << curr_id << " 0 " << edge_dst << " 0";

      ifs >> vertex_id;
      ifs >> edge_dst;

      while ( vertex_id == curr_id && !ifs.eof() ) {
        ofs << " " << edge_dst << " 0";

        ifs >> vertex_id;
        ifs >> edge_dst;
      }

      ofs << endl;

      // new vertex_id found. carry over edge_dst too.
      curr_id = vertex_id;
    }
    break;

  default:
    cout << "Invalid format: " << format << "!" << endl;
  }

  ifs.close();
  ofs.close();
  return 0;
}

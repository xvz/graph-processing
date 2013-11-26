#include <stdlib.h>
#include <fstream>
#include <iostream>
#include <string>
#include <cerrno>


#define M_IN_NOVAL       1
#define M_IN_VAL         2
#define M_IN_FAKE        3

#define M_TO_GIRAPH      1
#define M_TO_GPS_NOVAL   2
#define M_TO_GPS_VAL     3

using namespace std;

static long counter = 1;

static void usage(char **argv) {
  cout << "usage: " << argv[0] << " input-file output-file in-format out-format" << endl;
  cout << endl;
  cout << "in-format:  1. No values (node-id node-dst)" << endl;
  cout << "            2. Values (node-id node-dst weight)" << endl;
  cout << "            3. Same as 1, but generate unique sequential weights" << endl;
  cout << "               (i.e., fake weights are assigned sequentially in" << endl;
  cout << "                order of how vertices are listed in input file)" << endl;
  cout << endl;
  cout << "out-format: 1. Mizan to Giraph" << endl;
  cout << "            2. Mizan to GPS (no values)" << endl;
  cout << "            3. Mizan to GPS (vertex + edge values)" << endl;
}

static inline void get_edge_weight(ifstream &ifs, int in_format, long &edge_weight) {
  switch (in_format) {
  case M_IN_NOVAL:
    edge_weight = 0;
    break;

  case M_IN_VAL:
    ifs >> edge_weight;
    break;

  case M_IN_FAKE:
    edge_weight = counter;
    counter++;
    break;

  default:
    cout << "Invalid in-format: " << in_format << "!" << endl;
  }
}

/**
 * Converts dataset/graph input formats.
 *
 * NOTE: Does not sort anything! (Sorting is not needed anyway)
 */
int main(int argc, char **argv) {
  if ( argc < 5 ) {
    usage(argv);
    return -1;
  }

  ifstream ifs(argv[1], ifstream::in);
  ofstream ofs(argv[2], ofstream::out);
  int in_format = atoi(argv[3]);
  int out_format = atoi(argv[4]);

  if (!ifs || !ofs ||
      (in_format < M_IN_NOVAL || in_format > M_IN_FAKE) ||
      (out_format < M_TO_GIRAPH || out_format > M_TO_GPS_VAL) ) {
    usage(argv);
    return -1;
  }
  
  // longs, just to be safe
  long vertex_id, edge_dst, edge_weight;
  long curr_id;

  // input format is either: vertex-id edge-dst
  // or: vertex-id edge-dst edge-weight

  // first pair of reads
  ifs >> curr_id;
  ifs >> edge_dst;
  get_edge_weight(ifs, in_format, edge_weight);
  
  switch (out_format) {
  case M_TO_GIRAPH:
    while (!ifs.eof()) {
      // format: [vertex-id, vertex-val, [[edge-dst,edge-val],...]]
      ofs << "[" << curr_id << ",0,[[" << edge_dst << "," << edge_weight << "]";
      
      ifs >> vertex_id;
      ifs >> edge_dst;
      get_edge_weight(ifs, in_format, edge_weight);

      while ( vertex_id == curr_id && !ifs.eof() ) {
        ofs << ",[" << edge_dst << "," << edge_weight << "]";

        ifs >> vertex_id;
        ifs >> edge_dst;
        get_edge_weight(ifs, in_format, edge_weight);
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
      get_edge_weight(ifs, in_format, edge_weight);

      while ( vertex_id == curr_id && !ifs.eof() ) {
        ofs << " " << edge_dst;

        ifs >> vertex_id;
        ifs >> edge_dst;
        get_edge_weight(ifs, in_format, edge_weight);
      }

      ofs << endl;

      // new vertex_id found. carry over edge_dst too.
      curr_id = vertex_id;
    }
    break;

  case M_TO_GPS_VAL:
    while (!ifs.eof()) {
      // format: vertex-id vertex-val edge-dst edge-val ...
      ofs << curr_id << " 0 " << edge_dst << " " << edge_weight;

      ifs >> vertex_id;
      ifs >> edge_dst;
      get_edge_weight(ifs, in_format, edge_weight);

      while ( vertex_id == curr_id && !ifs.eof() ) {
        ofs << " " << edge_dst << " " << edge_weight;

        ifs >> vertex_id;
        ifs >> edge_dst;
        get_edge_weight(ifs, in_format, edge_weight);
      }

      ofs << endl;

      // new vertex_id found. carry over edge_dst too.
      curr_id = vertex_id;
    }
    break;

  default:
    cout << "Invalid out-format: " << out_format << "!" << endl;
  }

  ifs.close();
  ofs.close();
  return 0;
}

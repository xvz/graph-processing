#include <stdlib.h>
#include <fstream>
#include <iostream>
#include <string>
#include <cerrno>


#define M_IN_NOVAL       1
#define M_IN_VAL         2
#define M_IN_GEN_UNITY   3
#define M_IN_GEN_SEQ     4

#define M_TO_GIRAPH      1
#define M_TO_GPS_NOVAL   2
#define M_TO_GPS_VAL     3

static long counter = 1;

static void usage(char **argv) {
  std::cout << "usage: " << argv[0] << " input-file output-file in-format out-format" << std::endl;
  std::cout << std::endl;
  std::cout << "in-format:  1. No values in input file (format: node-id node-dst)" << std::endl;
  std::cout << "            2. Values in input file (format: node-id node-dst weight)" << std::endl;
  std::cout << "            3. Same as 1, but set output edge weights to 1." << std::endl;
  std::cout << "            4. Same as 1, but output unique sequential edge weights" << std::endl;
  std::cout << "               (i.e., fake weights are assigned sequentially in" << std::endl;
  std::cout << "                order of how vertices are listed in input file)" << std::endl;
  std::cout << std::endl;
  std::cout << "out-format: 1. Mizan to Giraph" << std::endl;
  std::cout << "            2. Mizan to GPS (no values/weights)" << std::endl;
  std::cout << "            3. Mizan to GPS (edge weights, no vertex value)" << std::endl;
}

static inline void get_edge_weight(std::ifstream &ifs, int in_format, long &edge_weight) {
  switch (in_format) {
  case M_IN_NOVAL:
    edge_weight = 0;
    break;

  case M_IN_VAL:
    ifs >> edge_weight;
    break;

  case M_IN_GEN_UNITY:
    edge_weight = 1;
    break;

  case M_IN_GEN_SEQ:
    edge_weight = counter;
    counter++;
    break;

  default:
    std::cout << "Invalid in-format: " << in_format << "!" << std::endl;
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

  std::ifstream ifs(argv[1], std::ifstream::in);
  std::ofstream ofs(argv[2], std::ofstream::out);
  int in_format = atoi(argv[3]);
  int out_format = atoi(argv[4]);

  if (!ifs || !ofs ||
      (in_format < M_IN_NOVAL || in_format > M_IN_GEN_SEQ) ||
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
  
  // NOTE: eof() DOES happen to work here, b/c inner while(ifs >> ...)
  // statement breaks when no data is left *and* this failure sets
  // EOF flag correctly & in time for eof() to see
  switch (out_format) {
  case M_TO_GIRAPH:
    while (!ifs.eof()) {
      // format: [vertex-id, vertex-val, [[edge-dst,edge-val],...]]
      ofs << "[" << curr_id << ",0,[[" << edge_dst << "," << edge_weight << "]";

      while (ifs >> vertex_id >> edge_dst) {
        get_edge_weight(ifs, in_format, edge_weight);
        if (vertex_id != curr_id) {
          break;
        }

        ofs << ",[" << edge_dst << "," << edge_weight << "]";
      }

      ofs << "]]\n";

      // new vertex_id found. carry over edge_dst and edge_weight too.
      curr_id = vertex_id;
    }
    break;

  case M_TO_GPS_NOVAL:
    while (!ifs.eof()) {
      // format: vertex-id edge-dst ...
      ofs << curr_id << " " << edge_dst;

      while (ifs >> vertex_id >> edge_dst) {
        get_edge_weight(ifs, in_format, edge_weight);
        if (vertex_id != curr_id) {
          break;
        }

        ofs << " " << edge_dst;
      }

      ofs << "\n";

      // new vertex_id found. carry over edge_dst and edge_weight too.
      curr_id = vertex_id;
    }
    break;

  case M_TO_GPS_VAL:
    while (!ifs.eof()) {
      // format: vertex-id edge-dst edge-val ...
      ofs << curr_id << " " << edge_dst << " " << edge_weight;

      while (ifs >> vertex_id >> edge_dst) {
        get_edge_weight(ifs, in_format, edge_weight);
        if (vertex_id != curr_id) {
          break;
        }

        ofs << " " << edge_dst << " " << edge_weight;
      }

      ofs << "\n";

      // new vertex_id found. carry over edge_dst and edge_weight too.
      curr_id = vertex_id;
    }
    break;

  default:
    std::cout << "Invalid out-format: " << out_format << "!" << std::endl;
  }

  ifs.close();
  ofs.flush();
  ofs.close();
  return 0;
}

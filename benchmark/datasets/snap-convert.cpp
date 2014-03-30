#include <stdlib.h>
#include <fstream>
#include <iostream>
#include <string>
#include <cerrno>

#define F_IN_SNAP        1
#define F_IN_SNAPWEIGHT  2
#define F_IN_GEN_UNITY   3
#define F_IN_GEN_SEQ     4

#define F_TO_ADJ         1
#define F_TO_ADJWEIGHT   2
#define F_TO_JSON        3

static long counter = 1;

static void usage(char **argv) {
  std::cout << "usage: " << argv[0] << " input-file output-file in-format out-format" << std::endl;
  std::cout << std::endl;
  std::cout << "in-format:  1. SNAP format (each line is: src dst)" << std::endl;
  std::cout << "            2. SNAP with weights (src dst weight)" << std::endl;
  std::cout << "            3. Same as 1, but output edge weights of 1." << std::endl;
  std::cout << "            4. Same as 1, but output unique sequential edge weights." << std::endl;
  std::cout << "               (i.e., weights are assigned sequentially in the order" << std::endl;
  std::cout << "                of how edges are listed in the input file)" << std::endl;
  std::cout << std::endl;
  std::cout << "out-format: 1. Adjacency list format (src dst1 dst2 ...)" << std::endl;
  std::cout << "            2. Adjacency list with weights (src dst1 weight1 dst2 weight2 ...)" << std::endl;
  std::cout << "            3. JSON ([src,0,[[dst1,weight1],[dst2,weight2],...]])" << std::endl;
  std::cout << std::endl;
  std::cout << "Note: edges with the same source ID must appear in a contiguous block!" << std::endl;
  std::cout << "      e.g., 1 0  but NOT 1 0" << std::endl;
  std::cout << "            1 2          2 3" << std::endl;
  std::cout << "            2 3          1 2" << std::endl;
}

static inline void get_edge_weight(std::ifstream &ifs, int in_format, long &edge_weight) {
  switch (in_format) {
  case F_IN_SNAP:
    edge_weight = 0;
    break;

  case F_IN_SNAPWEIGHT:
    ifs >> edge_weight;
    break;

  case F_IN_GEN_UNITY:
    edge_weight = 1;
    break;

  case F_IN_GEN_SEQ:
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
 * NOTE: Does not sort anything!
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
      (in_format < F_IN_SNAP || in_format > F_IN_GEN_SEQ) ||
      (out_format < F_TO_ADJ || out_format > F_TO_JSON) ) {
    usage(argv);
    return -1;
  }

  std::cout.sync_with_stdio(false);    // don't flush on \n
  
  // longs, just to be safe
  long vertex_id, edge_dst, edge_weight;
  long curr_id;

  // first pair of reads
  ifs >> curr_id;
  ifs >> edge_dst;
  get_edge_weight(ifs, in_format, edge_weight);
  
  // NOTE: eof() DOES happen to work here, b/c inner while(ifs >> ...)
  // statement breaks when no data is left *and* this failure sets
  // EOF flag correctly & in time for eof() to see
  switch (out_format) {
  case F_TO_ADJ:
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

  case F_TO_ADJWEIGHT:
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

  case F_TO_JSON:
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

  default:
    std::cout << "Invalid out-format: " << out_format << "!" << std::endl;
  }

  ifs.close();
  ofs.flush();
  ofs.close();
  return 0;
}

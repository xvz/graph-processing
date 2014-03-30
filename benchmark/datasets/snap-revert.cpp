#include <stdlib.h>
#include <fstream>
#include <iostream>
#include <string>
#include <cerrno>

#define F_IN_ADJ         1
#define F_IN_ADJWEIGHT   2

#define F_TO_SNAP        1
#define F_TO_SNAPWEIGHT  2

static void usage(char **argv) {
  std::cout << "usage: " << argv[0] << " input-file output-file in-format out-format" << std::endl;
  std::cout << std::endl;
  std::cout << "in-format:  1. Adjacency list format (src dst1 dst2 ...)" << std::endl;
  std::cout << "            2. Adjacency list with weights (src dst1 weight1 dst2 weight2 ...)" << std::endl;
  std::cout << std::endl;
  std::cout << "out-format: 1. SNAP format (src dst)" << std::endl;
  std::cout << "            2. SNAP with weights (src dst weight)" << std::endl;
}


static inline void write_output(std::ofstream &ofs, int out_format,
                                long vertex_id, long edge_dst, long edge_weight) {
  switch(out_format) {
  case F_TO_SNAP:
    ofs << vertex_id << " " << edge_dst << "\n";
    break;

  case F_TO_SNAPWEIGHT:
    ofs << vertex_id << " " << edge_dst << " " << edge_weight << "\n";
    break;

  default:
    std::cout << "Invalid out-format: " << out_format << "!" << std::endl;
  }
}


/**
 * Converts adjacency format to SNAP.
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
      (in_format < F_IN_ADJ || in_format > F_IN_ADJWEIGHT) ||
      (out_format < F_TO_SNAP || in_format > F_TO_SNAPWEIGHT)) {
    usage(argv);
    return -1;
  }
  
  std::cout.sync_with_stdio(false);    // don't flush on \n

  // longs, just to be safe
  long vertex_id, edge_dst, edge_weight;

  switch (in_format) {
  case F_IN_ADJ:
    while (ifs >> vertex_id) {
      while ( (ifs.peek() != '\n') && (ifs >> edge_dst) ) {
        write_output(ofs, out_format, vertex_id, edge_dst, 0);
      }
    }
    break;

  case F_IN_ADJWEIGHT:
    while (ifs >> vertex_id) {
      while ( (ifs.peek() != '\n') && (ifs >> edge_dst && ifs >> edge_weight) ) {
        write_output(ofs, out_format, vertex_id, edge_dst, edge_weight);
      }
    }
    break;

  default:
    std::cout << "Invalid in-format: " << in_format << "!" << std::endl;
  }

  ifs.close();
  ofs.flush();
  ofs.close();
  return 0;
}

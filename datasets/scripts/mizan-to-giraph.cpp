#include <stdlib.h>
#include <fstream>
#include <iostream>
#include <string>
#include <cerrno>

using namespace std;

int main(int argc, char **argv) {
  if ( argc < 3 ) {
    cout << "usage: " << argv[0] << " input-file output-file" << endl;
    return -1;
  }

  ifstream ifs(argv[1], ifstream::in);
  ofstream ofs(argv[2], ofstream::out);

  if (!ifs || !ofs) {
    cout << "usage: " << argv[0] << " input-file output-file" << endl;
    return -1;
  }
  
  int vertex_id, edge_dst;
  int curr_id;

  // first pair of reads
  ifs >> curr_id;
  ifs >> edge_dst;

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

  ifs.close();
  ofs.close();
  return 0;
}

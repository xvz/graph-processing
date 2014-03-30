/**
 * Creates an undirected graph with unique random edge weights.
 * **WARNING: input MUST be sorted---see below.**
 * **WARNING2: output graph is NOT sorted.**
 *
 * The algorithm proceeds by only storing out-edges of the graph,
 * effectively deleting any corresponding in-edges. This gives a
 * directed graph with no undirected edges.
 *
 * Here an "in-edge" is an edge (src, dst) such that src > dst.
 * If src > dst and no edge (dst, src) exists, then it is an out-edge.
 *
 * When outputting the out-edges, we output its corresponding
 * in-edge to produce an undirected graph. A unique random weight
 * is assigned to pairs of out/in-edges.
 *
 *
 * WARNING: this algorithm only works for SNAP format, where edges
 * are SORTED by source IDs and then by destination IDs.
 * Sorting by destination (after sorting by source) is *required*!
 *
 * For example,
 *   1 2
 *   1 3
 *   3 10
 *   3 10000
 *   4 1
 *   4 3
 *   4 5
 *   10 2
 *   10 3
 *   ...
 *
 * Sort using, e.g.: sort -nk1 -nk2 --parallel=N -S 3G input > output
 * This sorts by first field, then second field, both using "-n".
 * (Doing -n -k1,2 is not enough, as second field is not sorted w/ "-n")
 *
 * The output graph should also be sorted in the same manner.
 *
 * Note: use "sort -nk1 -nk2 --parallel=N -S 3G -c input" to check if
 * the input is sorted---this will save some time.
 */

#include <cstdlib>
#include <string>
#include <fstream>
#include <iostream>
#include <vector>
#include <queue>

/**
 * Class representing <src, dst> key for edge values
 */
class KeyPair {
private:
  long src;
  long dst;
public:
  KeyPair(long src, long dst) : src(src), dst(dst) {}

  long getSrc() { return src; }
  long getDst() { return dst; }

  bool operator<(const KeyPair& rhs) const {
    if (src == rhs.src) {
      return dst < rhs.dst;
    }

    return src < rhs.src;
  }

  bool operator>(const KeyPair& rhs) const {
    if (src == rhs.src) {
      return dst > rhs.dst;
    }

    return src > rhs.src;
  }

  bool operator==(const KeyPair& rhs) const {
    return src == rhs.src && dst == rhs.dst;
  }

  friend std::ostream& operator<<(std::ostream& os, const KeyPair& p) {
    return os << p.src << " " << p.dst;
  }
};

/**
 * Compare class needed for min-heap.
 */
class CompareKeyPair {
public:
  bool operator()(const KeyPair& lhs, const KeyPair& rhs) const {
    return lhs > rhs;
  }
};


/**
 * Maximal-length LFSR (i.e., PRBS) with n = 34. This provides
 * a period of 2^n -1, or 2^34 - 1 unique numbers excluding 0.
 *
 * 2^34 - 1 is ~17 billion, so uniqueness will fail if there
 * are more than 17 bil edges.
 *
 * NOTE: n = 64 can return negative values, so keep n < 64
 * when using long long.
 *
 * "state" is a previously returned value or the initial seed.
 */ 
long long prbs34(long long state) {
  // from: http://www.xilinx.com/support/documentation/application_notes/xapp052.pdf
  // also see wiki article on LFSR
  //
  // x^34 + x^27 + x^2 + x + 1
  // => 0010 0000 0100 0000 0000 0000 0000 0000 0011
  // => 0x204000003
  return (state >> 1) ^ (-(state & 1u) & 0x204000003u);
}


/**
 * Usage message
 */
static void usage(char **argv) {
  std::cout << "usage: " << argv[0] << " input-file output-file" << std::endl;
  std::cout << std::endl;
  std::cout << "Note: 1. input-file must be sorted by source ID, then destination ID." << std::endl;
  std::cout << "      2. output-file will NOT be sorted." << std::endl;
}


/**
 * Main
 */
int main(int argc, char **argv) {
  if ( argc < 3 ) {
    usage(argv);
    return -1;
  }

  std::ifstream ifs(argv[1], std::ifstream::in);
  std::ofstream ofs(argv[2], std::ofstream::out);

  if (!ifs || !ofs ) {
    usage(argv);
    return -1;
  }

  std::cout.sync_with_stdio(false);    // don't flush on \n

  long src, dst;
  long long weight;
  weight = prbs34(time(NULL));

  // our min-heap
  std::priority_queue<KeyPair, std::vector<KeyPair>, CompareKeyPair> *edges
    = new std::priority_queue<KeyPair, std::vector<KeyPair>, CompareKeyPair>();

  KeyPair u(0,0), up(0,0), v(0,0), vp(0,0);   // see below
  bool doPush;

  // NOTE: eof() is unreliable, use ">>" as check instead
  while (ifs >> src >> dst) {
    u = KeyPair(src, dst);   // see below
    up = KeyPair(dst, src);

    doPush = true;

    while (!edges->empty()) {
      // vp = (vp.src, vp.dst) is v's in-edge
      // v = (vp.dst, vp.src) is an existing out-edge
      // u = (src, dst) is potentially new out-edge
      // up = (dst, src) is in-edge associated w/ u
      vp = edges->top();
      v = KeyPair(vp.getDst(), vp.getSrc());

      // if u == vp, then don't write/push u (b/c it's v's in-edge)
      if (u == vp) {
        doPush = false;
      }

      // if u >= vp, then u is v's in-edge (=) or v's in-edge does not exist (>)
      // hence, it is safe to write out v
      //
      // NOTE: u > vp is NOT the same thing as v > (dst, src), as the first field
      // is compared *before* the second field
      if (u > vp || u == vp) {
        ofs << v << " " << weight << "\n";
        ofs << vp << " " << weight << "\n";
        weight = prbs34(weight);

        edges->pop();
      } else {
        break;
      }
    }

    // u is a new out-edge...
    if (doPush) {
      if (src == dst) {
        // self-cycle, so just write out one edge
        ofs << u << " " << weight << "\n";
        weight = prbs34(weight);

      } else if (src > dst) {
        // write it out if src >= dst, b/c (dst, src) cannot exist
        ofs << u << " " << weight << "\n";
        ofs << up << " " << weight << "\n";
        weight = prbs34(weight);

      } else {
        // otherwise, push it as its in-edge (so it's sorted correctly on min-heap)
        edges->push(up);
      }
    }
  }

  ifs.close();

  // flush remaining edges to disk
  while (!edges->empty()) {
    vp = edges->top();
    v = KeyPair(vp.getDst(), vp.getSrc());

    ofs << v << " " << weight << "\n";
    ofs << vp << " " << weight << "\n";
    weight = prbs34(weight);

    edges->pop();
  }

  ofs.flush();   // just in case...
  ofs.close();

  return 0;
}

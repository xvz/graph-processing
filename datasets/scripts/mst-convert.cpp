#include <cstdlib>
#include <string>
//#include <random>
#include <algorithm>
#include <climits>
#include <fstream>
#include <iostream>
#include <vector>
#include <map>


using namespace std;

/**
 * Class represeting <src, dst> key for edge values
 */
class KeyPair {
private:
  long src;
  long dst;
public:
  KeyPair(long src, long dst) : src(src), dst(dst) {}

  bool operator<(const KeyPair& rhs) const {
    if (src == rhs.src) {
      return dst < rhs.dst;
    }

    return src < rhs.src;
  }

  bool operator==(const KeyPair& rhs) const {
    return src == rhs.src && dst == rhs.dst;
  }

  friend ostream& operator<<(ostream& os, const KeyPair& p) {
    return os << p.src << " " << p.dst;
  }
};

/**
 * DEPRECATED.
 *
 * Provides a shuffled array of length "size", with unique elements.
 * Uses the Knuth-Fisher-Yates shuffle.
 */
//void kfy_shuffle(long *array, int size) {
//  // use this instead of srand to avoid modulus bias
//  mt19937 rng(time(0));
// 
//  for (int i = 0; i < size; i++) {
//    array[i] = i+1;
//  }
// 
//  long tmp;
//  int k;
//  for (int i = size-1; i > 0; i--) {
//    uniform_int_distrubition<int> gen(0, i);
//    k = gen(rng);
// 
//    tmp = array[i];
//    array[i] = array[k];
//    array[k] = tmp;
//  }
//}

/**
 * Usage message
 */
static void usage(char **argv) {
  cout << "usage: " << argv[0] << " input-file output-file" << endl;
}

/**
 * Main
 */
int main(int argc, char **argv) {
  if ( argc < 3 ) {
    usage(argv);
    return -1;
  }

  ifstream ifscount(argv[1], ifstream::in);
  ofstream ofs(argv[2], ofstream::out);

  if (!ifscount || !ofs ) {
    usage(argv);
    return -1;
  }

  // count number of input lines
  int len = count(istreambuf_iterator<char>(ifscount),
                  istreambuf_iterator<char>(), '\n');
  ifscount.close();

  // make unique weights (not all of these will be used
  // because we don't know what % of edges are undirected)
  vector<long> *weights = new vector<long>(len);
  for (int i = 0; i < len; i++) {
    weights->at(i) = i+1;
  }
  // shuffle using built-in Knuth-Fisher-Yates shuffle
  random_shuffle(weights->begin(), weights->end());

  // read input and fill map
  ifstream ifs(argv[1], ifstream::in);

  long src, dst;
  map<KeyPair, long> *graph = new map<KeyPair, long>();

  int i = 0;
  while (!ifs.eof()) {
    ifs >> src;
    ifs >> dst;

    // if we haven't already been added to map by a previous edge
    if (graph->find(KeyPair(dst, src)) == graph->end()) {
      // store both out-edge and in-edge, to make graph undirected,
      // and add (same) unique weight to both
      graph->insert(pair<KeyPair,long>(KeyPair(src, dst), weights->at(i)));
      graph->insert(pair<KeyPair,long>(KeyPair(dst, src), weights->at(i)));
      i++;
    }
  }
  ifs.close();

  // write output
  for (map<KeyPair, long>::iterator it=graph->begin(); it != graph->end(); ++it) {
    ofs << it->first << " " << it->second << "\n"; // endl;
  }
  ofs.close();

  return 0;
}

#include <cstdlib>
#include <string>
#include <random>
#include <algorithm>
#include <climits>
#include <fstream>
#include <iostream>
#include <vector>
#include <map>


#define M_TO_RANDOM    1
#define M_TO_VERTEXID  2
#define M_TO_NOWEIGHT  3


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

  friend std::ostream& operator<<(std::ostream& os, const KeyPair& p) {
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
  std::cout << "usage: " << argv[0] << " input-file output-file out-format" << std::endl;
  std::cout << std::endl;
  std::cout << "out-format: 1. Undirected graph, pseudo-random unique weights." << std::endl;
  std::cout << "            2. Undirected graph, deterministic non-unique weights using smallest vertex ID + 1." << std::endl;
  std::cout << "            3. For Mizan, undirected graph with no weights." << std::endl;

}

/**
 * Main
 */
int main(int argc, char **argv) {
  if ( argc < 4 ) {
    usage(argv);
    return -1;
  }

  std::ifstream ifscount(argv[1], std::ifstream::in);
  std::ofstream ofs(argv[2], std::ofstream::out);
  int out_format = atoi(argv[3]);

  if (!ifscount || !ofs || 
      (out_format < M_TO_RANDOM || out_format > M_TO_NOWEIGHT)) {
    usage(argv);
    return -1;
  }

  // count number of input lines
  int len = std::count(std::istreambuf_iterator<char>(ifscount),
                       std::istreambuf_iterator<char>(), '\n');
  ifscount.close();

  std::vector<long> *weights;

  if (out_format == M_TO_RANDOM) {
    // make unique weights (not all of these will be used
    // because we don't know what % of edges are undirected)
    weights = new std::vector<long>(len);

    for (int i = 0; i < len; i++) {
      weights->at(i) = i+1;
    }

    std::default_random_engine gen(time(NULL));

    // shuffle using built-in Knuth-Fisher-Yates shuffle
    std::shuffle(weights->begin(), weights->end(), gen);
  }

  // read input and fill map
  std::ifstream ifs(argv[1], std::ifstream::in);

  long src, dst, weight;
  std::map<KeyPair, long> *graph = new std::map<KeyPair, long>();

  int i = 0;

  switch (out_format) {
  case M_TO_RANDOM:
    while (ifs >> src >> dst) {
      // if we haven't already been added to map by a previous edge
      if (graph->find(KeyPair(dst, src)) == graph->end()) {
        // store both out-edge and in-edge, to make graph undirected,
        // and add (same) unique weight to both
        graph->insert(std::pair<KeyPair,long>(KeyPair(src, dst), weights->at(i)));
        graph->insert(std::pair<KeyPair,long>(KeyPair(dst, src), weights->at(i)));
        i++;
      }
    }
    break;

  case M_TO_VERTEXID:
    while (ifs >> src >> dst) {
      // if we haven't already been added to map by a previous edge
      if (graph->find(KeyPair(dst, src)) == graph->end()) {
        // store both out-edge and in-edge, to make graph undirected
        // and deterministic weight (min of src/dst)
        weight = ((src < dst) ? src : dst) + 1;
        graph->insert(std::pair<KeyPair,long>(KeyPair(src, dst), weight));
        graph->insert(std::pair<KeyPair,long>(KeyPair(dst, src), weight));
        i++;
      }
    }
    break;

  case M_TO_NOWEIGHT:
    while (ifs >> src >> dst) {
      // if we haven't already been added to map by a previous edge
      if (graph->find(KeyPair(dst, src)) == graph->end()) {
        // store both out-edge and in-edge, to make graph undirected
        graph->insert(std::pair<KeyPair,long>(KeyPair(src, dst), 0));
        graph->insert(std::pair<KeyPair,long>(KeyPair(dst, src), 0));
        i++;
      }
    }
    break;

  default:
    std::cout << "Invalid out-format: " << out_format << "!" << std::endl;
  }

  ifs.close();

  // write output
  switch (out_format) {
  case M_TO_RANDOM:
    // fall through

  case M_TO_VERTEXID:
    for (std::map<KeyPair, long>::iterator it=graph->begin(); it != graph->end(); ++it) {
      ofs << it->first << " " << it->second << "\n"; // std::endl;
    }
    break;

  case M_TO_NOWEIGHT:
    for (std::map<KeyPair, long>::iterator it=graph->begin(); it != graph->end(); ++it) {
      ofs << it->first << "\n"; // std::endl;
    }
    break;

  default:
    std::cout << "Invalid out-format: " << out_format << "!" << std::endl;
  }

  ofs.close();
    
  return 0;
}

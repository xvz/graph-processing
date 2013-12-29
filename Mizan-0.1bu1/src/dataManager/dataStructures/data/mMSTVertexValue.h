/*
 * mMSTVertexValue.h
 *
 * Created on: Dec 27, 2013
 * Author: Young Han
 */

#ifndef MMSTVERTEXVALUE_H_
#define MMSTVERTEXVALUE_H_

#include "IdataType.h"

/**
 * Enum constants
 */
// phases of computation
enum MSTPhase {
  PHASE_1,   // find min-weight edge
  PHASE_2A,  // question phase
  PHASE_2B,  // Q /and/ A phase
  PHASE_3A,  // send supervertex IDs
  PHASE_3B,  // receive PHASE_3A messages
  PHASE_4A,  // send edges to supervertex
  PHASE_4B   // receive/merge edges
};

// vertex types
enum MSTVertexType {
  TYPE_UNKNOWN,                 // initial state in Phase 2A
  TYPE_SUPERVERTEX,             // supervertex
  TYPE_POINTS_AT_SUPERVERTEX,   // child of supervertex
  TYPE_POINTS_AT_SUBVERTEX      // child of child of supervertex
};

/**
 * MST edge and vertex value representations
 */
class mMSTVertexValue: public IdataType {
private:
  long long weight;
  long long src;        // original source
  long long dst;        // original destination

  MSTPhase phase;       // computation phase
  MSTVertexType type;   // vertex type
  long long pointer;    // vertex's (potential) supervertex

public:
  mMSTVertexValue();
  mMSTVertexValue(long long weight, long long src, long long dst,
                  MSTPhase phase, MSTVertexType type, long long pointer);

  // NOTE: This is only for compatibility when used as a mMSTEdgeValue.
  // Once Mizan supports separate edge value types, this should be deleted!
  mMSTVertexValue(long long weight, long long src, long long dst);

  mMSTVertexValue(const mMSTVertexValue& obj);
  ~mMSTVertexValue();
  int byteSize();
  std::string toString();
  void readFromCharArray(char * input);
  char * byteEncode(int &size);
  int byteEncode2(char * buffer);
  void byteDecode(int size, char * input);
  std::size_t local_hash_value() const;
  mMSTVertexValue & operator=(const mMSTVertexValue& rhs);
  bool operator==(const IdataType& rhs) const;
  bool operator<(const IdataType& rhs) const;
  bool operator>(const IdataType &rhs) const;
  bool operator<=(const IdataType &rhs) const;
  bool operator>=(const IdataType &rhs) const;

  void cleanUp() {}

  //Class specific methods
  long long getWeight() { return weight; }
  long long getSrc() { return src; }
  long long getDst() { return dst;}

  MSTPhase getPhase() { return phase; }
  MSTVertexType getType() { return type; }
  long long getPointer() { return pointer; }

  void setWeight(long long w) { weight = w; }
  void setDst(long long d) { dst = d; }
  void setSrc(long long s) { src = s; }

  void setPhase(MSTPhase ph) { phase = ph; }
  void setType(MSTVertexType t) { type = t; }
  void setPointer(long long p) { pointer = p; }
};
#endif /* MMSTVERTEXVALUE_H_ */

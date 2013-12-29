/*
 * mMSTEdgeValue.cpp
 *
 * Created on: Dec 27, 2013
 * Author: Young Han
 */

#include "mMSTEdgeValue.h"
#include "mLong.h"

#define EDGE_VAL_LEN   3

// indices into value array
#define I_WEIGHT       0
#define I_SRC          1
#define I_DST          2

/** Constructors/Destructors **/
mMSTEdgeValue::mMSTEdgeValue() : weight(0), src(0), dst(0) {}

mMSTEdgeValue::mMSTEdgeValue(long long weight, long long src, long long dst)
  : weight(weight), src(src), dst(dst) {}

// copy constructor (same as implicit one)
mMSTEdgeValue::mMSTEdgeValue(const mMSTEdgeValue& obj) {
  weight = obj.weight;
  src = obj.src;
  dst = obj.dst;
}

mMSTEdgeValue::~mMSTEdgeValue() {}

int mMSTEdgeValue::byteSize() {
  return sizeof(long long)*EDGE_VAL_LEN;
}

std::string mMSTEdgeValue::toString() {
  // copied from mLongArray.cpp
  char outArray[31*EDGE_VAL_LEN];
  sprintf(outArray, "%lld:%lld:%lld:", weight, src, dst);
  std::string output(outArray);
  return output;
}

void mMSTEdgeValue::readFromCharArray(char * input) {
  // modified from mLongArray.cpp

  // should be constant, but whatever
  char delimiter = ':';
  mLong array[EDGE_VAL_LEN];

  int startPtr = 0;
  int endPtr = 0;
  for (int i = 0; i < EDGE_VAL_LEN; i++) {
    char tmpArray[30];
    while (input[endPtr] != delimiter) {
      endPtr++;
    }
    //12345:668512:999831
    strncpy(tmpArray, &input[startPtr], (endPtr - startPtr));
    tmpArray[endPtr - startPtr] = 0;
    array[i].readFromCharArray(tmpArray);
    endPtr++;
    startPtr = endPtr;
  }

  weight = array[I_WEIGHT].getValue();
  src = array[I_SRC].getValue();
  dst = array[I_DST].getValue();
}

char * mMSTEdgeValue::byteEncode(int &size) {
  // modified from mLongArray.cpp.. basic idea is the same
  char * output = (char *) calloc(byteSize(), sizeof(char));
  int j = 0;
  int tmpSize = 0;

  mLong array[EDGE_VAL_LEN];
  array[I_WEIGHT] = mLong(weight);
  array[I_SRC] = mLong(src);
  array[I_DST] = mLong(dst);

  for (int i = 0; i < EDGE_VAL_LEN; i++) {
    tmpSize = array[i].byteEncode2(&output[j + 1]);
    output[j] = ((char) tmpSize);
    j = j + tmpSize + 1;
  }
  size = j;
  return output;
}

int mMSTEdgeValue::byteEncode2(char * buffer) {
  // does not use byteEncode()... presumably to save on space?
  int j = 0;
  int tmpSize = 0;

  mLong array[EDGE_VAL_LEN];
  array[I_WEIGHT] = mLong(weight);
  array[I_SRC] = mLong(src);
  array[I_DST] = mLong(dst);

  for (int i = 0; i < EDGE_VAL_LEN; i++) {
    tmpSize = array[i].byteEncode2(&buffer[j + 1]);
    buffer[j] = ((char) tmpSize);
    j = j + tmpSize + 1;
  }
  return j;
}

void mMSTEdgeValue::byteDecode(int size, char * input) {
  // modified from mLongArray.cpp
  int j = 0;
  int objSize = 0;
  mLong obj;

  mLong array[EDGE_VAL_LEN];
  int i = 0;

  while (j < size) {
    if (i >= EDGE_VAL_LEN) {
      std::cout << "ERROR in mMSTEdgeValue byteDecode()!!";
      break;
    }

    objSize = ((int) input[j]);
    array[i].byteDecode(objSize, &input[j + 1]);
    j = j + objSize + 1;
    i++;
  }

  weight = array[I_WEIGHT].getValue();
  src = array[I_SRC].getValue();
  dst = array[I_DST].getValue();
}

std::size_t mMSTEdgeValue::local_hash_value() const {
  // just like mLongArray, do hash of first field.. which is long long
  // copied from mLong.cpp
  return weight;
}

mMSTEdgeValue & mMSTEdgeValue::operator=(const mMSTEdgeValue& rhs) {
  // yes, same as the implicit assignment...
  weight = rhs.weight;
  src = rhs.src;
  dst = rhs.dst;
}

/**
 * Objects are == iff all fields are equal, unlike below.
 */
bool mMSTEdgeValue::operator==(const IdataType& rhs) const {
  return (weight == ((mMSTEdgeValue&) rhs).weight &&
          src == ((mMSTEdgeValue&) rhs).src &&
          dst == ((mMSTEdgeValue&) rhs).dst);
}

/**
 * Comparison is based on the weight. If weights are same,
 * then comparison is based on source vertex ID.
 * The destination ID does not play a role.
 * TODO
 */
bool mMSTEdgeValue::operator<(const IdataType& rhs) const {
  return (weight < ((mMSTEdgeValue&) rhs).weight &&
          src < ((mMSTEdgeValue&) rhs).src &&
          dst < ((mMSTEdgeValue&) rhs).dst);

//  if (weight == rhs.weight) {
//    return (src < rhs.src);
//  }
//
//  return (weight < rhs.weight);
}

bool mMSTEdgeValue::operator>(const IdataType &rhs) const {
  return (weight > ((mMSTEdgeValue&) rhs).weight &&
          src > ((mMSTEdgeValue&) rhs).src &&
          dst > ((mMSTEdgeValue&) rhs).dst);
}

bool mMSTEdgeValue::operator<=(const IdataType &rhs) const {
  return (weight <= ((mMSTEdgeValue&) rhs).weight &&
          src <= ((mMSTEdgeValue&) rhs).src &&
          dst <= ((mMSTEdgeValue&) rhs).dst);
}

bool mMSTEdgeValue::operator>=(const IdataType &rhs) const {
  return (weight >= ((mMSTEdgeValue&) rhs).weight &&
          src >= ((mMSTEdgeValue&) rhs).src &&
          dst >= ((mMSTEdgeValue&) rhs).dst);
}

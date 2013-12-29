/*
 * mMSTVertexValue.cpp
 *
 * Created on: Dec 27, 2013
 * Author: Young Han
 */

#include "mMSTVertexValue.h"
#include "mLong.h"

#define VERTEX_VAL_LEN   6

// indices into value array
#define I_WEIGHT       0
#define I_SRC          1
#define I_DST          2
#define I_PHASE        3
#define I_TYPE         4
#define I_POINTER      5

/** Constructors/Destructors **/
mMSTVertexValue::mMSTVertexValue()
  : weight(0), src(0), dst(0), phase(PHASE_1), type(TYPE_UNKNOWN), pointer(0) {}

mMSTVertexValue::mMSTVertexValue(long long weight, long long src, long long dst,
                                 MSTPhase phase, MSTVertexType type, long long pointer)
  : weight(weight), src(src), dst(dst), phase(phase), type(type), pointer(pointer) {}

// NOTE: This is only for compatibility when used as a mMSTEdgeValue.
// Once Mizan supports separate edge value types, this should be deleted!
mMSTVertexValue::mMSTVertexValue(long long weight, long long src, long long dst)
  : weight(weight), src(src), dst(dst), phase(PHASE_1), type(TYPE_UNKNOWN), pointer(0) {}


// copy constructor (same as implicit one)
mMSTVertexValue::mMSTVertexValue(const mMSTVertexValue& obj) {
  weight = obj.weight;
  src = obj.src;
  dst = obj.dst;
  phase = obj.phase;
  type = obj.type;
  pointer = obj.pointer;
}

mMSTVertexValue::~mMSTVertexValue() {}

int mMSTVertexValue::byteSize() {
  std::cout << "byte size in vertex value called!" << std::endl;
  // all long longs, because that's what we send all values as
  return sizeof(long long)*VERTEX_VAL_LEN;
}

std::string mMSTVertexValue::toString() {
  // copied from mLongArray.cpp
  char outArray[31*VERTEX_VAL_LEN];
  // just treat everything as long longs
  sprintf(outArray, "%lld:%lld:%lld:%d:%d:%lld",
          weight, src, dst, phase, type, pointer);
  std::string output(outArray);
  return output;
}

void mMSTVertexValue::readFromCharArray(char * input) {
  // modified from mLongArray.cpp

  // should be constant, but whatever
  char delimiter = ':';
  mLong array[VERTEX_VAL_LEN];

  int startPtr = 0;
  int endPtr = 0;
  for (int i = 0; i < VERTEX_VAL_LEN; i++) {
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
  phase = (MSTPhase) array[I_PHASE].getValue();
  type = (MSTVertexType) array[I_TYPE].getValue();
  pointer = array[I_POINTER].getValue();
}

char * mMSTVertexValue::byteEncode(int &size) {
  // modified from mLongArray.cpp.. basic idea is the same
  char * output = (char *) calloc(byteSize(), sizeof(char));
  int j = 0;
  int tmpSize = 0;

  mLong array[VERTEX_VAL_LEN];
  array[I_WEIGHT] = mLong(weight);
  array[I_SRC] = mLong(src);
  array[I_DST] = mLong(dst);
  array[I_PHASE] = mLong(phase);
  array[I_TYPE] = mLong(type);
  array[I_POINTER] = mLong(pointer);

  for (int i = 0; i < VERTEX_VAL_LEN; i++) {
    tmpSize = array[i].byteEncode2(&output[j + 1]);
    output[j] = ((char) tmpSize);
    j = j + tmpSize + 1;
  }
  size = j;
  return output;
}

int mMSTVertexValue::byteEncode2(char * buffer) {
  // does not use byteEncode()... presumably to save on space?
  int j = 0;
  int tmpSize = 0;

  mLong array[VERTEX_VAL_LEN];
  array[I_WEIGHT] = mLong(weight);
  array[I_SRC] = mLong(src);
  array[I_DST] = mLong(dst);
  array[I_PHASE] = mLong(phase);
  array[I_TYPE] = mLong(type);
  array[I_POINTER] = mLong(pointer);

  for (int i = 0; i < VERTEX_VAL_LEN; i++) {
    tmpSize = array[i].byteEncode2(&buffer[j + 1]);
    buffer[j] = ((char) tmpSize);
    j = j + tmpSize + 1;
  }
  return j;
}

void mMSTVertexValue::byteDecode(int size, char * input) {
  // modified from mLongArray.cpp
  int j = 0;
  int objSize = 0;
  mLong obj;

  mLong array[VERTEX_VAL_LEN];
  int i = 0;

  while (j < size) {
    if (i >= VERTEX_VAL_LEN) {
      std::cout << "ERROR in mMSTVertexValue byteDecode()!!";
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
  phase = (MSTPhase) array[I_PHASE].getValue();
  type = (MSTVertexType) array[I_TYPE].getValue();
  pointer = array[I_POINTER].getValue();
}

std::size_t mMSTVertexValue::local_hash_value() const {
  // just like mLongArray, do hash of first field.. which is long long
  // copied from mLong.cpp
  return weight;
}

mMSTVertexValue & mMSTVertexValue::operator=(const mMSTVertexValue& rhs) {
  // yes, same as the implicit assignment...
  weight = rhs.weight;
  src = rhs.src;
  dst = rhs.dst;
  phase = rhs.phase;
  type = rhs.type;
  pointer = rhs.pointer;
}

/**
 * Comparison ops just look at all fields.
 */
bool mMSTVertexValue::operator==(const IdataType& rhs) const {
  return (weight == ((mMSTVertexValue&) rhs).weight &&
          src == ((mMSTVertexValue&) rhs).src &&
          dst == ((mMSTVertexValue&) rhs).dst &&
          phase == ((mMSTVertexValue&) rhs).phase &&
          type == ((mMSTVertexValue&) rhs).type &&
          pointer == ((mMSTVertexValue&) rhs).pointer);
}

bool mMSTVertexValue::operator<(const IdataType& rhs) const {
  return (weight < ((mMSTVertexValue&) rhs).weight &&
          src < ((mMSTVertexValue&) rhs).src &&
          dst < ((mMSTVertexValue&) rhs).dst &&
          phase < ((mMSTVertexValue&) rhs).phase &&
          type < ((mMSTVertexValue&) rhs).type &&
          pointer < ((mMSTVertexValue&) rhs).pointer);
}

bool mMSTVertexValue::operator>(const IdataType &rhs) const {
  return (weight > ((mMSTVertexValue&) rhs).weight &&
          src > ((mMSTVertexValue&) rhs).src &&
          dst > ((mMSTVertexValue&) rhs).dst &&
          phase > ((mMSTVertexValue&) rhs).phase &&
          type > ((mMSTVertexValue&) rhs).type &&
          pointer > ((mMSTVertexValue&) rhs).pointer);
}

bool mMSTVertexValue::operator<=(const IdataType &rhs) const {
  return (weight <= ((mMSTVertexValue&) rhs).weight &&
          src <= ((mMSTVertexValue&) rhs).src &&
          dst <= ((mMSTVertexValue&) rhs).dst &&
          phase <= ((mMSTVertexValue&) rhs).phase &&
          type <= ((mMSTVertexValue&) rhs).type &&
          pointer <= ((mMSTVertexValue&) rhs).pointer);
}

bool mMSTVertexValue::operator>=(const IdataType &rhs) const {
  return (weight >= ((mMSTVertexValue&) rhs).weight &&
          src >= ((mMSTVertexValue&) rhs).src &&
          dst >= ((mMSTVertexValue&) rhs).dst &&
          phase >= ((mMSTVertexValue&) rhs).phase &&
          type >= ((mMSTVertexValue&) rhs).type &&
          pointer >= ((mMSTVertexValue&) rhs).pointer);
}

/*
 * mMSTEdgeValue.h
 *
 * Created on: Dec 27, 2013
 * Author: Young Han
 */

#ifndef MMSTEDGEVALUE_H_
#define MMSTEDGEVALUE_H_

#include "IdataType.h"

/**
 * MST edge and vertex value representations
 */
class mMSTEdgeValue: public IdataType {
private:
  long long weight;
  long long src;    // original source
  long long dst;    // original destination
public:
	mMSTEdgeValue();
  mMSTEdgeValue(long long weight, long long src, long long dst);
	mMSTEdgeValue(const mMSTEdgeValue& obj);
	~mMSTEdgeValue();
	int byteSize();
	std::string toString();
	void readFromCharArray(char * input);
	char * byteEncode(int &size);
	int byteEncode2(char * buffer);
	void byteDecode(int size, char * input);
	std::size_t local_hash_value() const;
	mMSTEdgeValue & operator=(const mMSTEdgeValue& rhs);
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

  // no setters---edge value should be immutable
};
#endif /* MMSTEDGEVALUE_H_ */

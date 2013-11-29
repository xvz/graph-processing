/*
 * WCC.h
 *
 * Created on: Nov 17 2013
 * Authors: Jack Jin, Jenny Wang, Young Han
 */

#ifndef WCC_H_
#define WCC_H_

#include "../IsuperStep.h"
#include "../Icombiner.h"
#include "../dataManager/dataStructures/data/mLong.h"

#define INF      mLong(LLONG_MAX)

// combiner that takes the minimum of all messages
class WCCCombiner: public Icombiner<mLong, mLong, mLong, mLong> {
private:
  // NOTE: making this into a macro is dangerous!!
  mLong min(mLong a, mLong b) {
    return (a < b) ? a : b;
  }

public:
  void combineMessages(mLong dst, messageIterator<mLong> * messages,
                       messageManager<mLong, mLong, mLong, mLong> * mManager) {

    mLong minCompID = INF;
    while (messages->hasNext()) {
      minCompID = min(minCompID, messages->getNext());
    }

    mManager->sendMessage(dst, minCompID);
  }
};

/*
 * Template types are <K, V1, M, A> where
 *   K:  ID class
 *   V1: vertex value class
 *   M:  message value class
 *   A:  aggregation class
 *
 * For WCC, vertex and message values are both mLong
 */
class WCC: public IsuperStep<mLong, mLong, mLong, mLong> {
private:
  int maxSuperStep;

  mLong min(mLong a, mLong b) {
    return (a < b) ? a : b;
  }

public:
  /**
   * \param srcID The vertex ID of the source.
   * \param maxSS The maximum number of supersteps.
   */
  WCC(int maxSS) : maxSuperStep(maxSS) {}

  void initialize(userVertexObject<mLong, mLong, mLong, mLong> * data) {    
    // all vertices start w/ component IDs being their own vertex ID
    data->setVertexValue(data->getVertexID());
  }

  void compute(messageIterator<mLong> * messages,
               userVertexObject<mLong, mLong, mLong, mLong> * data,
               messageManager<mLong, mLong, mLong, mLong> * comm) {

    // can use getValue() to convert mLong to long long
    mLong currCompID = data->getVertexValue();
    mLong newCompID = currCompID;

    while (messages->hasNext()) {
      newCompID = min(newCompID, messages->getNext());
    }

    // if new component ID is smaller, notify neighbours
    // OR, if first supersteps, send message
    if (newCompID < currCompID || data->getCurrentSS() == 0) {
      data->setVertexValue(newCompID);

      for (int i = 0; i < data->getOutEdgeCount(); i++) {
        // (outEdgeValue is the value of an outgoing edge)
        comm->sendMessage(data->getOutEdgeID(i), newCompID);
      }
    } else {
      // TODO: Mizan never wakes up a vertex after receiving a message?!
      data->voteToHalt();
    }
  }
};
#endif /* WCC_H_ */

/*
 * SSSP.h
 *
 *  Created on: Nov 17 2013
 *     Authors: Jack Jin, Jenny Wang, Young Han
 */

#ifndef SSSP_H_
#define SSSP_H_

#include "../IsuperStep.h"
#include "../Icombiner.h"
#include "../dataManager/dataStructures/data/mLong.h"

#define INF      mLong(LLONG_MAX)
#define MIN(a,b) ((a < b) ? a : b)

// combiner that takes the minimum of all messages
class SSSPCombiner: public Icombiner<mLong, mLong, mLong, mLong> {
  void combineMessages(mLong dst, messageIterator<mLong> * messages,
                       messageManager<mLong, mLong, mLong, mLong> * mManager) {

    mLong minDist = INF;
    while (messages->hasNext()) {
      minDist = MIN(minDist, messages->getNext());
    }

    mManager->sendMessage(dst, minDist);
  }
};

/*
 * Template types are <K, V1, M, A> where
 *   K:  ID class
 *   V1: vertex value class
 *   M:  message value class
 *   A:  aggregation class
 *
 * For SSSP, vertex and message values are both mLong
 */
class SSSP: public IsuperStep<mLong, mLong, mLong, mLong> {
private:
  mLong srcID;
  int maxSuperStep;

  bool isSrc(mLong id) {
    return (id == srcID);
  }

public:
  /**
   * \param srcID The vertex ID of the source.
   * \param maxSS The maximum number of supersteps.
   */
  SSSP(mLong srcID, int maxSS) : srcID(srcID), maxSuperStep(maxSS) {}

  void initialize(userVertexObject<mLong, mLong, mLong, mLong> * data) {
    // start all vertices with INF distance
    data->setVertexValue(INF);
  }

  void compute(messageIterator<mLong> * messages,
               userVertexObject<mLong, mLong, mLong, mLong> * data,
               messageManager<mLong, mLong, mLong, mLong> * comm) {

    // can use getValue() to convert mLong to long long
    mLong currDist = data->getVertexValue();

    // potential new minimum distance
    mLong newDist = isSrc(data->getVertexID()) ? mLong(0) : INF;

    while (messages->hasNext()) {
      newDist = MIN(newDist, messages->getNext());
    }

    // if new distance is smaller, notify out edges
    if (newDist < currDist) {
      data->setVertexValue(newDist);

      // if maximum number of supersteps not reached, send messages
      // (otherwise, terminate via vote to halt)
      if (data->getCurrentSS() <= maxSuperStep) {
        for (int i = 0; i < data->getOutEdgeCount(); i++) {
          // (outEdgeValue is the value of an outgoing edge)
          comm->sendMessage(data->getOutEdgeID(i),
                            mLong(newDist.getValue() + data->getOutEdgeValue(i).getValue()));
        }
      }
    }
  
    // vertices always vote to halt after a superstep
    data->voteToHalt();
  }
};
#endif /* SSSP_H_ */

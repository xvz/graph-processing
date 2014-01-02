/*
 * MST.h
 *
 * Created on: Dec 27 2013
 * Authors: Jack Jin, Jenny Wang, Young Han
 *
 * This implementation follows the parallel Boruvka's algorithm
 * described in http://ilpubs.stanford.edu:8090/1077/
 */

#ifndef MST_H_
#define MST_H_

#include <vector>
#include "../IsuperStep.h"
#include "../IAggregator.h"
#include "../dataManager/dataStructures/data/mLong.h"
#include "../dataManager/dataStructures/data/mLongArray.h"

#include "../dataManager/dataStructures/data/mMSTVertexValue.h"

// NOTE: we don't actually use this, because Mizan does not
// support separate edge value type.
// Currently, edge value type is just the vertex value type.
#include "../dataManager/dataStructures/data/mMSTEdgeValue.h"

// This is to indicate which types should be mMSTEdgeValue.
// Note the "Val" instead of "Value", to avoid clashing types.
typedef mMSTVertexValue mMSTEdgeVal;

/******************** Message "Type" ********************/
/*
 * This is super hacky. We do this for convenience, to avoid
 * yet another complex data type. This assumes edge weights
 * are mLongs (as does mMSTEdgeValue).
 *
 * MST Messages are laid out as an array of mLongs:
 * [ TYPE, FIRST, SECOND, .... ]
 *
 * MSG_QUESTION:
 *   TYPE:   MSG_QUESTION
 *   FIRST:  source vertex ID
 *
 * MSG_ANSWER:
 *   TYPE:   MSG_ANSWER
 *   FIRST:  pointer (vertex ID)
 *   SECOND: MSG_TRUE/MSG_FALSE
 *
 * MSG_CLEAN:
 *   TYPE:   MSG_CLEAN
 *   FIRST:  source vertex ID
 *   SECOND: supervertex ID (of source)
 *
 * MSG_EDGES:  (oh boy....)
 *   TYPE:   MSG_EDGES
 *   FIRST:  size (of the two "arrays" that follow)
 *   Next 4*size fields: [vertex ID, edge weight, edge src, edge dst]
 *
 *   An explanation: the first field indicates the size of the "array"
 *   (more accurately a map) whose elements immediately follow.
 *   Each element of this array/map is a *pair* of fields, the first is
 *   the destination-vertex-IDs of an outgoing edge, and the second is
 *   the value of that outgoing edge, which is its weight, original source,
 *   and original destination. So a message would look like:
 *
 *   [ MSG_EDGES, 3, 3, x,x,x, 4, x,x,x, 5, x,x,x ]
 *                |  |    +    |    +    |    +
 *              size |    +    |    +    |    +
 *                   |    +    |    +    |    +
 *                   destination vertex ID    +
 *                        +         +         +
 *                weight, src, dst of outgoing edge
 */

// boolean values, as mLongs
#define MSG_FALSE      (mLong(0))
#define MSG_TRUE       (mLong(1))

// message sizes
#define MSG_QUESTION_LEN  2
#define MSG_ANSWER_LEN    3
#define MSG_CLEAN_LEN     3
#define MSG_EDGES_LEN     2   // NOT including adjacency list
#define MSG_EDGES_PARTS   4

// needed for MSG_EDGES
#define EDGE_VAL_LEN      3
#define I_WEIGHT          0
#define I_SRC             1
#define I_DST             2


/******************** Misc Constants ********************/
#define INF               LLONG_MAX

#define SUPERVERTEX_AGG   "supervertex"
#define COUNTER_AGG       "counter"
// TODO: hack to avoid aggregator doubling bug
#define AGG_INCREMENT     mLong(0xDEADBEEF)
#define AGG_DECREMENT     mLong(0xBEEFDEAD)

/*-------------------- MST Implementation --------------------*/
/**
 * Summation aggregator.
 */
class sumAggregator: public IAggregator<mLong> {
public:
  sumAggregator() {
    setValue(mLong(0));
  }

  void aggregate(mLong value) {
    //std::cout << "Aggregate called " << getValue().getValue() << " " << value.getValue() << std::endl;

    // TODO: hack to avoid aggregator doubling bug
    if (value == AGG_INCREMENT) {
      setValue(mLong(getValue().getValue() + 1));
      return;
    }

    if (value == AGG_DECREMENT) {
      setValue(mLong(getValue().getValue() - 1));
      return;
    }
  }

  ~sumAggregator() {}
};

// message types
enum MSTMsgType {
  MSG_INVALID,
  MSG_QUESTION,
  MSG_ANSWER,
  MSG_CLEAN,
  MSG_EDGES
};


/*
 * Template types are <K, V1, M, A> where
 *   K:  ID class
 *   V1: vertex value class
 *   M:  message value class
 *   A:  aggregation class
 *
 * For MST, vertex and edge values are both mLong
 */
class MST: public IsuperStep<mLong, mMSTVertexValue, mLongArray, mLong> {
private:
  // C++ refresher:
  // --------------------
  // This is SAFE despite mLongArray() constructor only
  // copying a POINTER to msg. This is because the copy
  // constructor is used when returning mLongArray.
  //
  // A copy constructor can be defined, or by default it
  // will do a shallow copy. Here, mLongArray's copy constructor
  // does a proper job of copying the *data* in the array.
  //
  // By default, C++ is **PASS BY VALUE**, just like Java.
  //
  // C++ can also do pass by reference (type& arg), and
  // pass by pointer (type *arg). Difference here is type &arg
  // means ptr to arg is not mutable, but type *arg means pointer
  // itself can be pointed to something else.

  /******************** Aggregator Hack ********************/
  // TODO: These are global per-worker variables used to get
  // around issues w/ sum aggregator.
  int prevSS;
  bool goPhase3A;

  /******************** COMPUTATIONAL PHASES ********************/
  /**
   * Phase 1: find minimum weight edge
   */
  void phase1(userVertexObject<mLong, mMSTVertexValue, mLongArray, mLong> * data) {
    // initialize some minimum stats
    long long minWeight = INF;
    long long minId = data->getVertexID().getValue();
    mMSTEdgeVal minEdge;
    bool foundMinEdge = false;

    long long eId = data->getVertexID().getValue();
    mMSTEdgeVal eVal;

    // find minimum weight edge
    for (int i = 0; i < data->getOutEdgeCount(); i++ ) {
      eId = data->getOutEdgeID(i).getValue();
      eVal = data->getOutEdgeValue(i);

      // NOTE: eId is not necessarily same as e.getDst(),
      // as getDst() returns the *original* destination

      // break ties by picking vertex w/ smaller destination ID
      if (eVal.getWeight() < minWeight ||
          (eVal.getWeight() == minWeight && eId < minId)) {
        minWeight = eVal.getWeight();
        minId = eId;

        // make copy of the edge (via operator=)
        minEdge = eVal;
        foundMinEdge = true;
      }
    }

    mMSTVertexValue vVal = data->getVertexValue();

    // store minimum weight edge value as vertex value
    if (foundMinEdge) {
      vVal.setWeight(minEdge.getWeight());
      vVal.setSrc(minEdge.getSrc());
      vVal.setDst(minEdge.getDst());
    } else {
      // this is an error
      std::cout << "No minimum edge for " << data->getVertexID().getValue() << " found in PHASE_1." << std::endl;
    }

    // technically part of PHASE_2A
    vVal.setPointer(minId);

    vVal.setPhase(PHASE_2A);
    data->setVertexValue(vVal);

    //std::cout << data->getVertexID().toString()
    //          << ": min edge is " << minEdge.toString()
    //          << " and value is " << vVal.toString() << std::endl;
  }

  /**
   * Phase 2A: send out questions
   * This is a special case of Phase 2B (only questions, no answers).
   */
  void phase2A(userVertexObject<mLong, mMSTVertexValue, mLongArray, mLong> * data,
               messageManager<mLong, mMSTVertexValue, mLongArray, mLong> * comm) {
    // initial setup for question phase
    mMSTVertexValue vVal = data->getVertexValue();
    MSTVertexType type = TYPE_UNKNOWN;

    // send query to pointer (potential supervertex)
    //std::cout << data->getVertexID().toString()
    //          << ": sending question to " << vVal.getPointer() << std::endl;

    // NOTE: must create new[] due to way mLongArray constructor is written
    // passing in array allocated on stack will blow up when delete[] is called
    mLong *msg = new mLong[MSG_QUESTION_LEN];
    msg[0] = mLong(MSG_QUESTION);
    msg[1] = data->getVertexID();

    comm->sendMessage(mLong(vVal.getPointer()),
                      mLongArray(MSG_QUESTION_LEN, msg));

    // update vertex value
    vVal.setType(type);
    vVal.setPhase(PHASE_2B);
    data->setVertexValue(vVal);
  }

  /**
   * Phase 2B: respond to questions with answers, and send questions
   * This phase can repeat for multiple supersteps.
   */
  void phase2B(userVertexObject<mLong, mMSTVertexValue, mLongArray, mLong> * data,
               messageManager<mLong, mMSTVertexValue, mLongArray, mLong> * comm,
               messageIterator<mLongArray> * messages) {

    // sources may be huge, so allocate from heap
    std::vector<long long> *sources = new std::vector<long long>();
    bool isPointerSupervertex = false;

    long long myId = data->getVertexID().getValue();
    mMSTVertexValue vVal = data->getVertexValue();
    MSTVertexType type = vVal.getType();
    long long pointer = vVal.getPointer();

    mLongArray message;
    MSTMsgType msgType;

    // question messages
    long long senderId;

    // answer messages
    long long supervertexId;
    mLong isSupervertex;

    while (messages->hasNext()) {
      message = messages->getNext();
      msgType = (MSTMsgType) message.getArray()[0].getValue();

      switch (msgType) {
      case MSG_QUESTION:
        senderId = message.getArray()[1].getValue();

        //std::cout << data->getVertexID().toString()
        //          << ": received question from " << senderId << std::endl;

        // save source vertex ID, so we can send response
        // to them later on (after receiving all msgs)
        sources->push_back(senderId);

        // if already done, no need to do more checks
        if (type != TYPE_UNKNOWN) {
          isPointerSupervertex = true;
          break;
        }

        // check if there is a cycle (if the vertex we picked also picked us)
        // NOTE: cycle is unique b/c pointer choice is unique
        if ( senderId == pointer ) {
          // smaller ID always wins & becomes supervertex
          //
          // NOTE: = MUST be used here, in case there is a self-cycle
          // (i.e., vertex with an edge to itself), as otherwise the
          // vertex type will be incorrectly set to non-supervertex
          if ( myId <= senderId ) {
            pointer = myId;        // I am the supervertex
            type = TYPE_SUPERVERTEX;
          } else {
            type = TYPE_POINTS_AT_SUPERVERTEX;
          }

          isPointerSupervertex = true;

          // increment counter aggregator (i.e., we're done this phase,
          // future answers messages will be ignored---see below)
          data->aggregate(COUNTER_AGG, AGG_INCREMENT);
        }

        // otherwise, type is still TYPE_UNKNOWN
        break;

      case MSG_ANSWER:
        // our pointer replied w/ possible information
        // about who our supervertex is

        // if we don't care about answers any more, break
        if (type != TYPE_UNKNOWN) {
          //std::cout << data->getVertexID().toString()
          //          << ": ignoring answers " << std::endl;
          break;
        }

        // we still care, so parse answer message
        supervertexId = message.getArray()[1].getValue();
        isSupervertex = message.getArray()[2];

        //std::cout << data->getVertexID().toString()
        //          << ": received answer from " << supervertexId
        //          << ", " << isSupervertex.getValue() << std::endl;


        if (isSupervertex == MSG_TRUE) {
          if (supervertexId != pointer) {
            // somebody propagated supervertex ID down to us
            type = TYPE_POINTS_AT_SUBVERTEX;
            pointer = supervertexId;
          } else {
            // otherwise, supervertex directly informed us
            type = TYPE_POINTS_AT_SUPERVERTEX;
          }

          // increment counter aggregator (i.e., we're done this phase)
          data->aggregate(COUNTER_AGG, AGG_INCREMENT);

          // stragglers always increment aggregator from here
          // TODO: this is a hack---if we are last one to increment
          // COUNTER_AGG to completion, record some flag variables
          if (data->getAggregatorValue(COUNTER_AGG).getValue() == 
              data->getAggregatorValue(SUPERVERTEX_AGG).getValue()) {
            prevSS = data->getCurrentSS();
            goPhase3A = true;
          }

        } else {
          // otherwise, our pointer didn't know who supervertex is,
          // so resend question to it
          mLong *msg = new mLong[MSG_QUESTION_LEN];
          msg[0] = mLong(MSG_QUESTION);
          msg[1] = mLong(myId);

          //std::cout << data->getVertexID().toString()
          //          << ": resending question to " << pointer << std::endl;

          comm->sendMessage(mLong(pointer), mLongArray(MSG_QUESTION_LEN, msg));
        }
        break;

      default:
        std::cout << "Invalid message type [" << msgType << "] in PHASE_2B." << std::endl;
      }
    }

    // send answers to all question messages we received
    //
    // NOTE: we wait until we receive all messages b/c we
    // don't know which (if any) of them will be a cycle
    if (sources->size() != 0) {
      mLong boolean = isPointerSupervertex ? MSG_TRUE : MSG_FALSE;

      mLong *msg = new mLong[MSG_ANSWER_LEN];
      msg[0] = mLong(MSG_ANSWER);
      msg[1] = mLong(pointer);
      msg[2] = boolean;

      mLongArray msgArr = mLongArray(MSG_ANSWER_LEN, msg);

      for (int i = 0; i < sources->size(); i++) {
        comm->sendMessage(mLong(sources->at(i)), msgArr);
      }
    }

    delete sources;
    sources = NULL;

    // update vertex value
    vVal.setType(type);
    vVal.setPointer(pointer);
    data->setVertexValue(vVal);

    // phase change occurs in compute()
  }


  /**
   * Phase 3A: notify neighbours of supervertex ID
   */
  void phase3A(userVertexObject<mLong, mMSTVertexValue, mLongArray, mLong> * data,
               messageManager<mLong, mMSTVertexValue, mLongArray, mLong> * comm) {

    // This is dumb... there's probably a better way.
    data->aggregate(COUNTER_AGG, AGG_DECREMENT);
    data->aggregate(SUPERVERTEX_AGG, AGG_DECREMENT);

    mMSTVertexValue vVal = data->getVertexValue();

    // send our neighbours <my ID, my supervertex's ID>
    mLong *msg = new mLong[MSG_CLEAN_LEN];
    msg[0] = mLong(MSG_CLEAN);
    msg[1] = data->getVertexID();
    msg[2] = mLong(vVal.getPointer());

    mLongArray msgArr(MSG_CLEAN_LEN, msg);

    //std::cout << data->getVertexID().toString()
    //          << ": sending MSG_CLEAN, my supervertex is " << vVal.getPointer() << std::endl;

    for (int i = 0; i < data->getOutEdgeCount(); i++) {
      comm->sendMessage(data->getOutEdgeID(i), msgArr);
    }

    // update vertex value
    vVal.setPhase(PHASE_3B);
    data->setVertexValue(vVal);
  }

  /**
   * Phase 3B: receive supervertex ID messages
   */
  void phase3B(userVertexObject<mLong, mMSTVertexValue, mLongArray, mLong> * data,
               messageManager<mLong, mMSTVertexValue, mLongArray, mLong> * comm,
               messageIterator<mLongArray> * messages) {

    // TODO: hack---after everyone executes phase 3A,
    // we can reset boolean flag to false
    goPhase3A = false;    

    mMSTVertexValue vVal = data->getVertexValue();
    long long pointer = vVal.getPointer();

    // receive messages from PHASE_3A
    mLongArray message;
    MSTMsgType msgType;

    mLong senderId;
    mLong supervertexId;
    mMSTEdgeVal eVal;
    mMSTEdgeVal eValExisting;

    // receive message from PHASE_3A
    while (messages->hasNext()) {
      message = messages->getNext();
      msgType = (MSTMsgType) message.getArray()[0].getValue();

      switch(msgType) {
      case MSG_CLEAN:
        senderId = message.getArray()[1];
        supervertexId = message.getArray()[2];

        // If supervertices are same, then we are in the same component,
        // so delete our outgoing edge to v (i.e., delete (u,v)).
        //
        // Note that v will delete edge (v, u).
        if (supervertexId.getValue() == pointer) {
          data->delOutEdge(senderId);

        } else {
          // Otherwise, delete edge (u,v) and add edge (u, v's supervertex).
          // In phase 4, this will become (u's supervertex, v's supervertex)

          // if sender is its own supervertex, no need to change edges
          if (supervertexId == senderId) {
            break;
          }

          // get value of edge (u, v)
          eVal = data->getOutEdgeValue(senderId);

          if (!data->hasOutEdge(supervertexId)) {
            // edge doesn't exist, so just add this
            data->addOutEdge(supervertexId);
            data->setOutEdgeValue(supervertexId, eVal);

          } else {
            // if edge (u, v's supervertex) already exists, pick the
            // one with the minimum weight---this saves work in phase 4B

            // get value of edge (u, v's supervertex)
            eValExisting = data->getOutEdgeValue(supervertexId);

            if (eVal.getWeight() < eValExisting.getWeight()) {
              data->setOutEdgeValue(supervertexId, eVal);
            }
          }

          // delete edge (u, v)
          data->delOutEdge(senderId);
        }
        break;
        
      default:
        std::cout << "Invalid message type [" << msgType << "] in PHASE_3B." << std::endl;
      }
    }

    // supervertices also go to phase 4A (b/c they need to wait for msgs)
    vVal.setPhase(PHASE_4A);
    data->setVertexValue(vVal);
  }


  /**
   * Phase 4A: send adjacency list to supervertex
   */
  void phase4A(userVertexObject<mLong, mMSTVertexValue, mLongArray, mLong> * data,
               messageManager<mLong, mMSTVertexValue, mLongArray, mLong> * comm) {

    mMSTVertexValue vVal = data->getVertexValue();
    MSTVertexType type = vVal.getType();
    long long pointer = vVal.getPointer();

    // terminate if not supervertex
    if (type != TYPE_SUPERVERTEX) {
      // send my supervertex all my edges, if I have any left
      int numEdges = data->getOutEdgeCount();

      if (numEdges != 0) {
        // key is destination, value is edge weight
        // adjacency list can be large, so allocate from heap
        int msgLen = MSG_EDGES_LEN + MSG_EDGES_PARTS*numEdges;
        mLong *msg = new mLong[msgLen];

        msg[0] = mLong(MSG_EDGES);
        msg[1] = mLong(numEdges);

        int offset;
        mMSTEdgeVal eVal;

        // ick... this really, really ought to be in its own class
        for (int i = 0; i < numEdges; i++) {
          offset = MSG_EDGES_PARTS*i+MSG_EDGES_LEN;
          eVal = data->getOutEdgeValue(i);

          msg[offset] = data->getOutEdgeID(i);
          msg[offset+1+I_WEIGHT] = mLong(eVal.getWeight());
          msg[offset+1+I_SRC] = mLong(eVal.getSrc());
          msg[offset+1+I_DST] = mLong(eVal.getDst());
        }

        comm->sendMessage(mLong(pointer), mLongArray(msgLen, msg));

        // NOTE: must NOT delete[] msg, as mLongArray retains a pointer to it
      }
      data->voteToHalt();

    } else {
      // we are supervertex, so move to next phase
      vVal.setPhase(PHASE_4B);
      data->setVertexValue(vVal);      
    }
  }

  /**
   * Phase 4B: receive adjacency lists
   */
  void phase4B(userVertexObject<mLong, mMSTVertexValue, mLongArray, mLong> * data,
               messageManager<mLong, mMSTVertexValue, mLongArray, mLong> * comm,
               messageIterator<mLongArray> * messages) {

    mLongArray message;
    MSTMsgType msgType;

    mLong *edges;
    int numEdges;
    int offset;
    mLong eId;
    mMSTEdgeVal eVal;
    mMSTEdgeVal eValExisting;

    // receive messages from PHASE_4A
    while (messages->hasNext()) {
      message = messages->getNext();
      msgType = (MSTMsgType) message.getArray()[0].getValue();

      switch(msgType) {
      case MSG_EDGES:
        numEdges = message.getArray()[1].getValue();
        edges = message.getArray();

        // merge children's edges (and our edges),
        // by picking ones with minimum weight
        for (int i = 0; i < numEdges; i++) {
          offset = MSG_EDGES_PARTS*i+MSG_EDGES_LEN;

          eId = edges[offset];
          eVal = mMSTEdgeVal(edges[offset+1+I_WEIGHT].getValue(),
                             edges[offset+1+I_SRC].getValue(),
                             edges[offset+1+I_DST].getValue());

          if (!data->hasOutEdge(eId)) {
            // if no out-edge exists, add new one
            data->addOutEdge(eId);
            data->setOutEdgeValue(eId, eVal);

          } else {
            // otherwise, choose one w/ minimum weight
            eValExisting = data->getOutEdgeValue(eId);

            if (eVal.getWeight() < eValExisting.getWeight()) {
              data->setOutEdgeValue(eId, eVal);
            }
          }
        }

        break;

      default:
        std::cout << "Invalid message type [" << msgType << "] in PHASE_4B." << std::endl;
      }
    }

    // all that's left now is a graph w/ supervertices
    // its children NO LONGER participate in MST

    // if no more edges, then this supervertex is done
    if (data->getOutEdgeCount() == 0) {
      data->voteToHalt();
    } else {
      // otherwise, increment total supervertex counter
      data->aggregate(SUPERVERTEX_AGG, AGG_INCREMENT);

      // and go back to phase 1
      mMSTVertexValue vVal = data->getVertexValue();
      vVal.setPhase(PHASE_1);
      data->setVertexValue(vVal);
    }
  }

public:
  /**
   * Constructor.
   *
   * \param maxSS The maximum number of supersteps. Ignored.
   */
  MST(int maxSS) {}

  void initialize(userVertexObject<mLong, mMSTVertexValue, mLongArray, mLong> * data) {
    data->setVertexValue(mMSTVertexValue());   // dummy initial value

    // if we are unconnected, just terminate
    if (data->getOutEdgeCount() == 0) {
      // TODO: is this safe to do here? otherwise move it into
      // compute with extra condition that SS is == 1
      data->voteToHalt();
      return;
    }

    mLong myId = data->getVertexID();
    mLong eId;
    long long weight;
    mMSTEdgeVal eVal;

    //std::cout << data->getVertexID().toString() << ": with edges:" << std::endl;
    for (int i = 0; i < data->getOutEdgeCount(); i++ ) {
      eId = data->getOutEdgeID(i);

      // + 1 to deal with vertex ID possibly being 0
      weight = ((myId < eId) ? myId : eId).getValue() + 1;
      eVal = mMSTEdgeVal(weight, myId.getValue(), eId.getValue());

      data->setOutEdgeValue(eId, eVal);
      //std::cout << "  " << eVal.toString() << std::endl;
    }

    // need to set up correct number of supervertices on first superstep
    data->aggregate(SUPERVERTEX_AGG, AGG_INCREMENT);

    // TODO: hack to avoid aggregator bug
    prevSS = 0;
    goPhase3A = false;
  }

  void compute(messageIterator<mLongArray> * messages,
               userVertexObject<mLong, mMSTVertexValue, mLongArray, mLong> * data,
               messageManager<mLong, mMSTVertexValue, mLongArray, mLong> * comm) {

    // PHASE_2B is special, because it can repeat an indeterminate
    // number of times. Hence, a "superbarrier" is needed.
    // This has to be done separately due to the "lagged" nature
    // of aggregated values.
    //
    // proceed to PHASE_3A iff all supervertices are done PHASE_2B
    long long numDone = data->getAggregatorValue(COUNTER_AGG).getValue();
    long long numSupervertex = data->getAggregatorValue(SUPERVERTEX_AGG).getValue();

    //std::cout << data->getVertexID().toString()
    //          << ": numDone=" << numDone
    //          << ", numSupervertex=" << numSupervertex << std::endl;

    MSTPhase phase = data->getVertexValue().getPhase();

    // TODO: first line is a hack---we proceed to phase 3A only
    // when we are the next direct superstep after COUNTER_AGG
    // was incremented to equal to SUPERVERTEX_AGG
    if ((data->getCurrentSS() == prevSS+1 && goPhase3A) &&
        phase == PHASE_2B && numDone == numSupervertex) {
      // no need to update vertex value, b/c this is beginning of a superstep
      phase = PHASE_3A;
    }

    // algorithm termination is in phase4B

    switch(phase) {
    case PHASE_1:   // find minimum-weight edge
      //std::cout << data->getVertexID().toString() << ": phase 1" << std::endl;
      phase1(data);
      // fall through

    case PHASE_2A:
      //std::cout << data->getVertexID().toString() << ": phase 2A" << std::endl;
      phase2A(data, comm);
      break;

    case PHASE_2B:
      //std::cout << data->getVertexID().toString() << ": phase 2B" << std::endl;
      phase2B(data, comm, messages);
      break;

    case PHASE_3A:
      //std::cout << data->getVertexID().toString() << ": phase 3A" << std::endl;
      phase3A(data, comm);
      break;

    case PHASE_3B:
      //std::cout << data->getVertexID().toString() << ": phase 3B" << std::endl;
      phase3B(data, comm, messages);
      // fall through

    case PHASE_4A:
      //std::cout << data->getVertexID().toString() << ": phase 4A" << std::endl;
      phase4A(data, comm);
      break;

    case PHASE_4B:
      //std::cout << data->getVertexID().toString() << ": phase 4B" << std::endl;
      phase4B(data, comm, messages);
      break;

    default:
      std::cout << "Invalid computation phase." << std::endl;
      break;
    }
  }
};
#endif /* MST_H_ */

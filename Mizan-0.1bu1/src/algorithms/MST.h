/*
 * MST.h
 *
 * Created on: Nov 17 2013
 * Authors: Jack Jin, Jenny Wang, Young Han
 *
 * This implementation follows the distributed Boruvka's algorithm
 * described in http://ilpubs.stanford.edu:8090/1077/
 */

#ifndef MST_H_
#define MST_H_

#include <map>
#include "../IsuperStep.h"
// #include "../Icombiner.h"
#include "../dataManager/dataStructures/data/mLong.h"
#include "../dataManager/dataStructures/data/mLongArray.h"


/******************** Message "Type" ********************/
/*
 * This is super-duper hacky..
 *
 * Since we don't have any clue how to implement half of the
 * functions needed to properly implement complex data types,
 * we hack one together that uses mLong arrays. Note that this
 * assumes edge weights are mLong.
 *
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
#define MSG_TRUE       (mLong(0))
#define MSG_FALSE      (mLong(1))

// message sizes
#define MSG_QUESTION_LEN  2
#define MSG_ANSWER_LEN    3
#define MSG_CLEAN_LEN     3
#define MSG_EDGES_LEN     2   // NOT including adjacency list
#define MSG_EDGES_PARTS   4

/******************** Vertex/Edge Value Types ********************/

// Vertex value & edge value are both arrays.
// They are of same type and length.
#define EDGE_VAL_LEN      3
#define VERTEX_VAL_LEN    EDGE_VAL_LEN

// Indices to value arrays.
// For vertex values, these indicate weight/src/dst
// of a picked edge. For edge values, this is that
// edge's original parameters.
#define I_WEIGHT    0
#define I_SRC       1
#define I_DST       2

// Macro shorthands for accessing *primitive type* values
#define WEIGHT(a)   (a[I_WEIGHT].getValue())
#define SRC(a)      (a[I_SRC].getValue())
#define DST(a)      (a[I_DST].getValue())

/******************** Misc Constants ********************/
#define INF         LLONG_MAX
#define RESET       mLong(LLONG_MAX)

#define SUPERVERTEX_AGG  "supervertex"
#define COUNTER_AGG      "counter"


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
    setValue(mLong(getValue().getValue() + value.getValue()));
  }
};


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
class MST: public IsuperStep<mLong, mLongArray, mLongArray, mLong> {
private:
  MSTPhase phase;
  MSTVertexType type;
  long long pointer;       // vertex ID of this vertex's (potential) supervertex

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


  /******************** COMPUTATIONAL PHASES ********************/
  /**
   * Phase 1: find minimum weight edge
   */
  void phase1(userVertexObject<mLong, mLongArray, mLongArray, mLong> * data) {
    // initialize some minimum stats
    long long minWeight = INF;
    long long minId = data->getVertexID().getValue();
    mLong minEdge[VERTEX_VAL_LEN];

    long long eId = data->getVertexID().getValue();
    mLong *eVal = NULL;

    // find minimum weight edge
    for (int i = 0; i < data->getOutEdgeCount(); i++ ) {
      eId = data->getOutEdgeID(i).getValue();
      eVal = data->getOutEdgeValue(i).getArray();

      // NOTE: eId is not necessarily same as e.getDst(),
      // as getDst() returns the *original* destination

      // break ties by picking vertex w/ smaller destination ID
      if (WEIGHT(eVal) < minWeight ||
          (WEIGHT(eVal) == minWeight && eId < minId)) {
        minWeight = WEIGHT(eVal);
        minId = eId;

        // make copy of the edge
        minEdge[I_WEIGHT] = eVal[I_WEIGHT];
        minEdge[I_SRC] = eVal[I_SRC];
        minEdge[I_DST] = eVal[I_DST];
      }
    }

    // store minimum weight edge value as vertex value
    data->setVertexValue(mLongArray(VERTEX_VAL_LEN, minEdge));

    // technically part of PHASE_2A
    pointer = minId;

    phase = PHASE_2A;
  }

  /**
   * Phase 2A: send out questions
   * This is a special case of Phase 2B (only questions, no answers).
   */
  void phase2A(userVertexObject<mLong, mLongArray, mLongArray, mLong> * data,
               messageManager<mLong, mLongArray, mLongArray, mLong> * comm) {
    // initial setup for question phase
    type = TYPE_UNKNOWN;

    // send query to pointer (potential supervertex)
    mLong msg[MSG_QUESTION_LEN] = {mLong(MSG_QUESTION), data->getVertexID()};
    comm->sendMessage(mLong(pointer), mLongArray(MSG_QUESTION_LEN, msg));

    phase = PHASE_2B;
  }

  /**
   * Phase 2B: respond to questions with answers, and send questions
   * This phase can repeat for multiple supersteps.
   */
  void phase2B(userVertexObject<mLong, mLongArray, mLongArray, mLong> * data,
               messageManager<mLong, mLongArray, mLongArray, mLong> * comm,
               messageIterator<mLongArray> * messages) {

    // sources may be huge, so allocate from heap
    std::vector<long long> *sources = new vector<long long>();
    bool isPointerSupervertex = false;

    long long myId = data->getVertexID().getValue();

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
          if ( myId < senderId ) {
            pointer = myId;        // I am the supervertex
            type = TYPE_SUPERVERTEX;
          } else {
            type = TYPE_POINTS_AT_SUPERVERTEX;
          }

          isPointerSupervertex = true;

          // increment counter aggregator (i.e., we're done this phase,
          // future answers messages will be ignored---see below)
          data->aggregate(COUNTER_AGG, mLong(1));
        }

        // otherwise, type is still TYPE_UNKNOWN
        break;

      case MSG_ANSWER:
        // our pointer replied w/ possible information
        // about who our supervertex is

        // if we don't care about answers any more, break
        if (type != TYPE_UNKNOWN) {
          break;
        }

        // we still care, so parse answer message
        supervertexId = message.getArray()[1].getValue();
        isSupervertex = message.getArray()[2];

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
          data->aggregate(COUNTER_AGG, mLong(1));

        } else {
          // otherwise, our pointer didn't know who supervertex is,
          // so resend question to it
          mLong msg[MSG_QUESTION_LEN] = {mLong(MSG_QUESTION), myId};
          comm->sendMessage(mLong(pointer), mLongArray(MSG_QUESTION_LEN, msg));
        }
        break;

      default:
        cout << "Invalid message type [" << msgType << "] in PHASE_2B." << endl;
      }
    }

    // send answers to all question messages we received
    //
    // NOTE: we wait until we receive all messages b/c we
    // don't know which (if any) of them will be a cycle
    if (sources->size() != 0) {
      mLong boolean = isPointerSupervertex ? MSG_TRUE : MSG_FALSE;

      mLong msg[MSG_ANSWER_LEN] = {mLong(MSG_ANSWER), mLong(pointer), boolean};
      mLongArray msgArr = mLongArray(MSG_ANSWER_LEN, msg);

      for (int i = 0; i < sources->size(); i++) {
        comm->sendMessage(mLong(sources->at(i)), msgArr);
      }
    }

    delete sources;

    // phase change occurs in compute()
  }


  /**
   * Phase 3A: notify neighbours of supervertex ID
   */
  void phase3A(userVertexObject<mLong, mLongArray, mLongArray, mLong> * data,
               messageManager<mLong, mLongArray, mLongArray, mLong> * comm) {

    // This is dumb... there's probably a better way.
    data->aggregate(COUNTER_AGG, mLong(-1));
    data->aggregate(SUPERVERTEX_AGG, mLong(-1));

    // send our neighbours <my ID, my supervertex's ID>
    mLong msg[MSG_CLEAN_LEN] =
      {mLong(MSG_CLEAN), data->getVertexID().getValue(), mLong(pointer)};
    mLongArray msgArr(MSG_CLEAN_LEN, msg);

    for (int i = 0; i < data->getOutEdgeCount(); i++) {
      comm->sendMessage(data->getOutEdgeID(i), msgArr);
    }

    phase = PHASE_3B;
  }

  /**
   * Phase 3B: receive supervertex ID messages
   */
  void phase3B(userVertexObject<mLong, mLongArray, mLongArray, mLong> * data,
               messageManager<mLong, mLongArray, mLongArray, mLong> * comm,
               messageIterator<mLongArray> * messages) {

    // receive messages from PHASE_3A
    mLongArray message;
    MSTMsgType msgType;

    mLong senderId;
    mLong supervertexId;
    mLong *eVal;
    mLong *eValExisting;

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
          eVal = data->getOutEdgeValue(senderId).getArray();

          if (!data->hasOutEdge(supervertexId)) {
            // edge doesn't exist, so just add this
            data->addOutEdge(supervertexId);
            data->setOutEdgeValue(supervertexId, mLongArray(EDGE_VAL_LEN, eVal));

          } else {
            // if edge (u, v's supervertex) already exists, pick the
            // one with the minimum weight---this saves work in phase 4B

            // get value of edge (u, v's supervertex)
            eValExisting = data->getOutEdgeValue(supervertexId).getArray();

            if (WEIGHT(eVal) < WEIGHT(eValExisting)) {
              data->setOutEdgeValue(supervertexId, mLongArray(EDGE_VAL_LEN, eVal));
            }
          }

          // delete edge (u, v)
          data->delOutEdge(senderId);
        }

      default:
        cout << "Invalid message type [" << msgType << "] in PHASE_3B." << endl;
      }
    }

    // supervertices also go to phase 4A (b/c they need to wait for msgs)
    phase = PHASE_4A;
  }


  /**
   * Phase 4A: send adjacency list to supervertex
   */
  void phase4A(userVertexObject<mLong, mLongArray, mLongArray, mLong> * data,
               messageManager<mLong, mLongArray, mLongArray, mLong> * comm) {

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
        mLong *eVal;

        // ick... this really, really ought to be in its own class
        for (int i = 0; i < numEdges; i++) {
          offset = MSG_EDGES_PARTS*i+MSG_EDGES_LEN;
          eVal = data->getOutEdgeValue(i).getArray();

          msg[offset] = data->getOutEdgeID(i);
          msg[offset+1+I_WEIGHT] = eVal[I_WEIGHT];
          msg[offset+1+I_SRC] = eVal[I_SRC];
          msg[offset+1+I_DST] = eVal[I_DST];
        }

        comm->sendMessage(mLong(pointer), mLongArray(msgLen, msg));

        // msg passed by value, so safe to delete
        delete msg;
      }
      data->voteToHalt();

    } else {
      // we are supervertex, so move to next phase
      phase = PHASE_4B;

      // increment total supervertex counter
      data->aggregate(SUPERVERTEX_AGG, mLong(1));
    }
  }

  /**
   * Phase 4B: receive adjacency lists
   */
  void phase4B(userVertexObject<mLong, mLongArray, mLongArray, mLong> * data,
               messageManager<mLong, mLongArray, mLongArray, mLong> * comm,
               messageIterator<mLongArray> * messages) {

    mLongArray message;
    MSTMsgType msgType;

    mLong *edges;
    int numEdges;
    int offset;
    mLong eId;
    mLong eVal[EDGE_VAL_LEN];
    mLong *eValExisting;
    
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
          eVal[I_WEIGHT] = edges[offset+1+I_WEIGHT];
          eVal[I_SRC] = edges[offset+1+I_SRC];
          eVal[I_DST] = edges[offset+1+I_DST];

          if (!data->hasOutEdge(eId)) {
            // if no out-edge exists, add new one
            data->addOutEdge(eId);
            data->setOutEdgeValue(eId, mLongArray(EDGE_VAL_LEN, eVal));

          } else {
            // otherwise, choose one w/ minimum weight
            eValExisting = data->getOutEdgeValue(eId).getArray();

            if (WEIGHT(eVal) < WEIGHT(eValExisting)) {
              data->setOutEdgeValue(eId, mLongArray(EDGE_VAL_LEN, eVal));
            }
          }
        }

        break;

      default:
        cout << "Invalid message type [" << msgType << "] in PHASE_4B." << endl;
      }
    }

    // all that's left now is a graph w/ supervertices
    // its children NO LONGER participate in MST

    // back to phase 1
    phase = PHASE_1;
  }

public:
  /**
   * Constructor.
   *
   * \param maxSS The maximum number of supersteps. Ignored.
   */
  MST(int maxSS) {}

  void initialize(userVertexObject<mLong, mLongArray, mLongArray, mLong> * data) {
    mLong val[VERTEX_VAL_LEN];       // dummy initial value
    data->setVertexValue(mLongArray(VERTEX_VAL_LEN, val));

    mLong myId = data->getVertexID();
    mLong eId;
    mLong eVal[EDGE_VAL_LEN];

    for (int i = 0; i < data->getOutEdgeCount(); i++ ) {
      eId = data->getOutEdgeID(i);
      
      eVal[I_WEIGHT] = (myId < eId) ? myId : eId;
      eVal[I_SRC] = myId;
      eVal[I_DST] = eId;

      data->setOutEdgeValue(eId, mLongArray(EDGE_VAL_LEN, eVal));
    }

    phase = PHASE_1;

    // need to set up correct number of supervertices on first superstep
    data->aggregate(SUPERVERTEX_AGG, mLong(1));
  }

  void compute(messageIterator<mLongArray> * messages,
               userVertexObject<mLong, mLongArray, mLongArray, mLong> * data,
               messageManager<mLong, mLongArray, mLongArray, mLong> * comm) {

    // PHASE_2B is special, because it can repeat an indeterminate
    // number of times. Hence, a "superbarrier" is needed.
    // This has to be done separately due to the "lagged" nature
    // of aggregated values.
    //
    // proceed to PHASE_3A iff all supervertices are done PHASE_2B
    long long numDone = data->getAggregatorValue(COUNTER_AGG).getValue();
    long long numSupervertex = data->getAggregatorValue(SUPERVERTEX_AGG).getValue();


    if (phase == PHASE_2B &&
        numDone == numSupervertex) {
      phase = PHASE_3A;
    }

    // special halting condition if only 1 supervertex is left
    if (phase == PHASE_1 && numSupervertex == 1) {
      data->voteToHalt();
      return;
    }

    switch(phase) {
    case PHASE_1:   // find minimum-weight edge
      //cout << data->getVertexID() << ": phase 1" << endl;
      phase1(data);
      // fall through

    case PHASE_2A:
      //cout << data->getVertexID() << ": phase 2A" << endl;
      phase2A(data, comm);
      break;

    case PHASE_2B:
     //cout << data->getVertexID() << ": phase 2B" << endl;
      phase2B(data, comm, messages);
      break;

    case PHASE_3A:
      //cout << data->getVertexID() << ": phase 3A" << endl;
      phase3A(data, comm);
      break;

    case PHASE_3B:
      //cout << data->getVertexID() << ": phase 3B" << endl;
      phase3B(data, comm, messages);
      // fall through

    case PHASE_4A:
      //cout << data->getVertexID() << ": phase 4A" << endl;
      phase4A(data, comm);
      break;

    case PHASE_4B:
      //cout << data->getVertexID() << ": phase 4B" << endl;
      phase4B(data, comm, messages);
      break;

    default:
      cout << "Invalid computation phase." << endl;
      break;
    }
  }
};
#endif /* MST_H_ */

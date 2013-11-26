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

use namespace std;


#define INF      mLong(LLONG_MAX)

/*-------------------- Message "Type" --------------------*/
/*
 * NOTE: This is super-duper hacky... blame the Mizan authors
 * for leaving so much UNDOCUMENTED code!
 *
 * Since we don't have any clue how to implement half of the
 * functions needed to properly implement complex data types,
 * we hack one together that uses mLong arrays.
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
 *   Next 2*size fields: [vertex ID, edge weight]
 *
 *   An explanation: the first field indicates the size of the "array"
 *   (more accurately a map) whose elements immediately follow.
 *   Each element of this array/map is a *pair* of fields, the first is
 *   the destination-vertex-IDs of an outgoing edge, and the second is
 *   the weight/value of that outgoing edge. So a message would look like:
 *
 *   [ MSG_EDGES, 3, 3, 5, 4, 2, 5, 8 ]
 *                |  |  +  |  +  |  +
 *              size |  +  |  +  |  +
 *                   |  +  |  +  |  +
 *                destination vertex ID
 *                      +     +     +
 *                 weight of outgoing edge
 */

// message types
#define MSG_QUESTION   (mLong(0))   // question for Phase 2A/B
#define MSG_ANSWER     (mLong(1))   // answer for Phase 2B
#define MSG_CLEAN      (mLong(2))   // msg for Phase 3A/B
#define MSG_EDGES      (mLong(3))   // msg for Phase 4A/B

// boolean values, as mLongs
#define MSG_TRUE       (mLong(0))
#define MSG_FALSE      (mLong(1))

// message sizes
#define MSG_QUESTION_LEN  2
#define MSG_ANSWER_LEN    3
#define MSG_CLEAN_LEN     3
#define MSG_EDGES_LEN     2   // NOT including array


// Vertex value & edge value are both arrays.
// They are of same type and length.
#define VERTEX_VAL_LEN    3
#define EDGE_VAL_LEN      3

// Indices to value arrays.
// For vertex values, these indicate src/dst/weight
// of a picked edge. For edge values, this is that
// edge's original parameters.
#define I_SRC       0
#define I_DST       1
#define I_WEIGHT    2


// phases/stages of computation
#define PHASE_0     mLong(0)
#define PHASE_1A    mLong(1)
#define PHASE_2B    mLong(2)
#define PHASE_3A    mLong(3)
#define PHASE_3B    mLong(4)
#define PHASE_4     mLong(5)


#define RESET       mLong(0xDEADBEEF)

/*-------------------- MST Implementation --------------------*/

/**
 * Counter aggregator.
 */
class countAggregator: public IAggregator<mLong> {
public:
  maxAggregator() {
    aggValue.setValue(0);
  }
  void aggregate(mLong value) {
    // TODO: Hack to reset aggregator's value
    if( value == mLong(RESET) ) {
      aggValue = 0;
    } else {
      aggValue = aggValue + value;
    }
  }
  mLong getValue() {
    return aggValue;
  }
  void setValue(mLong value) {
    this->aggValue = value;
  }
  virtual ~maxAggregator() {}
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
  enum {
    TYPE_UNKNOWN,                 // initial state in Phase 2A
    TYPE_SUPERVERTEX,             // supervertex
    TYPE_POINTS_AT_SUPERVERTEX,   // child of supervertex
    TYPE_POINTS_AT_SUBVERTEX      // child of child of supervertex
  } type;

  mLong pointer;           // vertex ID of this vertex's supervertex

  // vertex needs to store info about the minimum-weight
  // it picks, b/c the edge will be deleted from graph
  mLong pickedEdgeSrcID;   // original source ID of edge
  mLong pickedEdgeDstID;   // original destination ID of edge
  mLong pickedEdgeValue;   // original value/weight of edge

  int maxSuperStep;

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

  mLong min(mLong a, mLong b) {
    return (a < b) ? a : b;
  }

  /**
   * \param pickedEdgeSrcID Vertex ID of the original source of picked edge.
   * \param pickedEdgeDstID Vertex ID of the original destination of picked edge.
   * \param pickedEdgeValue Weight/value of picked edge.
   */
  inline void set_vertex_value( userVertexObject<mLong, mLongArray, mLongArray, mLong> * data,
                                mLong pickedEdgeSrcID,
                                mLong pickedEdgeDstID,
                                mLong pickedEdgeValue ) {

    mLong v_val[VERTEX_VAL_LEN] = {pickedEdgeSrcID, pickedEdgeDstID, pickedEdgeValue};
    data->setVertexValue( mLongArray(VERTEX_VAL_LEN, v_val) );
  }

  /**
   * Note that edge_dstID is actual destination of this edge.
   * dstID is part of edge's values, not necessarily its actual destination.
   */
  inline void set_outedge_value( userVertexObject<mLong, mLongArray, mLongArray, mLong> * data,
                                 mLong edge_dstID,
                                 mLong srcID, mLong dstID, mLong weight ) {

    mLong e_val[EDGE_VAL_LEN] = {srcID, dstID, weight};
    data->setOutEdgeValue( edge_dstID, mLongArray(EDGE_VAL_LEN, e_val) );
  }


public:
  /**
   * \param maxSS The maximum number of supersteps.
   */
  MST(int maxSS) : maxSuperStep(maxSS) {}

  void initialize(userVertexObject<mLong, mLongArray, mLongArray, mLong> * data) {
    // initially, every vertex is its own supervertex
    my_ID = data->getVertexID();

    //data->setVertexValue(data->getVertexID());
    type = SUPERVERTEX;

    set_vertex_value(data, INF, INF, INF);

    // TODO: how the hell does Mizan read in edge weights??
    for (int i = 0; i < data->getOutEdgeCount(); i++ ) {
      edge_val = data->getOutEdgeValue(i).getArray()[0];
      edge_ID = data->getOutEdgeID(i);

      set_outedge_value(data, edge_ID, my_ID, edge_ID, edge_val);
    }
    phase = PHASE_1;
  }

  void compute(messageIterator<mLong> * messages,
               userVertexObject<mLong, mLongArray, mLongArray, mLong> * data,
               messageManager<mLong, mLongArray, mLongArray, mLong> * comm) {

    // NOTE: graph is undirected, meaning there are in edges AND out edges
    mLong my_ID = data->getVertexID();

    switch( phase ) {
    case PHASE_1:   // find minimum-weight edge

      // minimum edge weight
      mLong min_weight = INF;
      // corresponding current destination ID,
      // and original src/dst IDs
      mLong min_edge_ID, min_e_src, min_e_dst;

      // values from each edge
      mLong *e_arr;
      mLong e_weight, e_src, e_dst;

      // edge's current destination ID
      // (this could equal e_dst, or differ from it, depending
      //  on if we are dealing w/ supervertices or not)
      mLong edge_ID;

      // only check out-edges
      for (int i = 0; i < data->getOutEdgeCount(); i++ ) {
        edge_ID = data->getOutEdgeID(i);

        // parse edge's value
        e_arr = data->getOutEdgeValue(i).getArray();
        e_weight = e_arr[I_WEIGHT];
        e_src = e_arr[I_SRC];
        e_dst = e_arr[I_DST];

        // break ties by picking vertex w/ smaller ID
        if ( e_weight < min_weight ||
             (e_weight == min_weight && edge_ID < min_edge_ID) ) {

          min_weight = e_weight;
          min_edge_ID = edge_ID;
          min_e_src = e_src;
          min_e_dst = e_dst;
        }
      }

      // this is set according to edge's ORIGINAL src/dst
      set_vertex_value(data, min_e_src, min_e_dst, min_weight);

      phase = PHASE_2A;
      // FALL THROUGH

    case PHASE_2A:   // PHASE_2A question phase
      // initial setup for question phase
      type = TYPE_UNKNOWN;
      pointer = min_edge_ID;

      // send message to pointer (potential supervertex)

      // TODO: maxSuperStep limit
      mLong msg_q[MSG_QUESTION_LEN] = {MSG_QUESTION, id};
      comm->sendMessage(pointer, mLongArray(MSG_QUESTION_LEN, msg_q));

      phase = PHASE_2B;
      break;
    }

    break;

  case PHASE_2B:
    mLongArray msg;
    mLong msg_type;
    mLong msg_ID;   // question
    mLong msg_supervertex_ID, msg_is_supervertex;  // answer

    vector<mLong> sources;
    boolean is_ptr_supervertex = false;

    while (messages->hasNext()) {
      msg = messages->getNext();

      msg_type = msg.getArray()[0];

      switch (msg_type) {
      case MSG_QUESTION:
        msg_ID = msg.getArray()[1];

        // save source vertex ID, so we can send response
        // to them later on (after receiving all msgs)
        sources.push_back(msg_ID);

        // check if there is a cycle
        // (aka, if the vertex we picked also picked us)
        if ( msg_ID == pointer ) {
          // smaller ID always wins & becomes supervertex
          if ( my_ID < msg_ID ) {
            pointer = my_ID;        // I am the supervertex
            type = TYPE_SUPERVERTEX;
            aggregate("counter", mLong(1));
          } else {
            type = TYPE_POINTS_AT_SUPERVERTEX;
          }

          is_ptr_supervertex = true;
        }
        // otherwise, type is still TYPE_UNKNOWN

        break;

      case MSG_ANSWER:
        // our pointer replied w/ possible information
        // about who our supervertex is
        msg_supervertex_ID = msg.getArray()[1];
        msg_is_supervertex = msg.getArray()[2];

        // ignore msgs that haven't found a supervertex
        if ( msg_is_supervertex == MSG_TRUE ) {
          if ( msg_supervertex_ID != pointer ) {
            // somebody propagated supervertex ID down to us
            type = TYPE_POINTS_AT_SUBVERTEX;
            pointer = msg_supervertex_ID;
          } else {
            // otherwise, supervertex directly informed us
            type = TYPE_POINTS_AT_SUPERVERTEX;
          }
          aggregate("counter", mLong(1));
        }

      default:
        // TODO: PANIC!!!
      }

      // send answers to all question messages we received
      //
      // NOTE: we wait until we receive all messages b/c we
      // don't know which (if any) of them will be a cycle
      mLong[MSG_ANSWER_LEN] msg_ans_arr = {MSG_ANSWER, pointer,
                                           is_prt_supervertex ? MSG_TRUE : MSG_FALSE};
      mLongArray msg_ans(MSG_ANSWER_LEN, msg_ans_arr);

      for (int i = 0; i < sources.size(); i++) {
        comm->sendMessage(sources[i], msg_ans);
      }

      // if our pointer didn't know who supervertex is, ask it again
      if ( type == TYPE_UNKNOWN ) {
        mLong msg_q[MSG_QUESTION_LEN] = {MSG_QUESTION, my_ID};
        comm->sendMessage(pointer,
                          mLongArray(MSG_QUESTION_LEN, msg_q));
      }

      // synchronize all supervertices ("super" barrier)
      // proceed to phase 3A iff all supervertices are done phase 2B)
      if ( getAggregatorValue("counter") == getAggregatorValue("max") ) {
        phase = PHASE_3A;
      } else {
        phase = PHASE_2B;
      }
      break;

    case PHASE_3A:
      // send our neighbours <my ID, my supervertex's ID>
      mLong[MSG_CLEAN_LEN] msg_clean_arr = {MSG_CLEAN, my_ID, pointer};
      mLongArray msg_clean(MSG_CLEAN_LEN, msg_clean_arr);

      for (int i = 0; i < data->getOutEdgeCount(); i++) {
        comm->sendMessage(data->getOutEdgeID(i), msg_clean);
      }

      phase = PHASE_3B;
      break;

    case PHASE_3B:
      mLongArray msg;
      mLong msg_type, msg_ID, msg_supervertex_ID;
      mLong edge_val;

      // receive message from PHASE_3A
      while (messages->hasNext()) {
        msg = messages->getNext();

        msg_type = msg.getArray()[0];
        msg_ID = msg.getArray()[1];
        msg_supervertex_ID = msg.getArray()[2];

        switch(msg_type) {
        case MSG_CLEAN:
          // If supervertices are same, then we are in the same component,
          // so delete our outgoing edge to v (i.e., delete (u,v)).
          //
          // Note that v will delete edge (v, u).
          if ( msg_supervertex_ID == pointer ) {
            data->delOutEdge(msg_ID);

          } else {
            // Otherwise, delete edge (u,v) and add edge (u, v's supervertex).
            // In phase 4, this will become (u's supervertex, v's supervertex)
            edge_val = data->getOutEdgeValue(msg_ID);
            data->delOutEdge(msg_ID);

            data->addOutEdge(msg_supervertex_ID);
            data->setOutEdgeValue(msg_supervertex_ID, edge_val);
          }

        default:
          // TODO: PANIC!!!
        }
      }

      // supervertices also go to phase 4A (b/c they need to wait for msgs)
      phase = PHASE_4A;
      break;

    case PHASE_4A:
      // send all of u's edges to its supervertex
      if ( type != SUPERVERTEX ) {
        // key is destination, value is edge weight
        int num_edges = data->getOutEdgeCount();
        mLong[] msg_edges_arr = new mLong[MSG_EDGES_LEN + 2*num_edges];

        msg_edges_arr[0] = MSG_EDGES;
        msg_edges_arr[1] = num_edges;

        for ( int i = 0; i < num_edges; i++ ) {
          msg_edges_arr[2*i+MSG_EDGES_LEN] = data->getOutEdgeID(i);
          msg_edges_arr[2*i+MSG_EDGES_LEN+1] = data->getOutEdgeValues(i);

          // since we're sending edge away, just delete it
          data->delOutEdge(data->getOutEdgeID(i));
        }

        mLongArray msg_edges(MSG_EDGES_LEN, msg_edges_arr);
        comm->sendMessage(pointer, msg_edges);

        // msg_edges passed by value, so safe to delete
        // this also deletes msg_edges_arr
        delete msg_edges;

        data->voteToHalt();

      } else {
        // we are supervertex, so go to next phase
        phase = PHASE_4B;
      }

      break;

    case PHASE_4B:
      mLong[] msg_arr;
      mLong msg_type, msg_len, msg_dst_ID, msg_edge_val;

      // map<edge destination's vertex ID, edge value>
      map<mLong, mLong> child_edges;
      mLong edge_val;

      while (messages->hasNext()) {
        msg_arr = messages->getNext().getArray();

        msg_type = msg_arr[0];
        if ( msg_type != MSG_EDGES ) {
          // TODO: PANIC!!!
        }

        msg_len = msg_arr[1];

        // merge all children's edges, by picking ones w/ minimum weight
        for ( int i = 0; i < msg_len; i++ ) {
          msg_dst_ID = msg_arr[2*i+MSG_EDGES_LEN];
          msg_edge_val = msg_arr[2*i+MSG_EDGES_LEN];

          edge_val = child_edges.find(msg_dst_ID);

          // if out edge to dst_ID doesn't exist, push it on
          if ( edge_val == map::end ) {
            child_edges[msg_dst_ID] = msg_edge_val;
          } else {
            // otherwise, set it to minimum of two
            child_edges[msg_dst_ID] = min(edge_val, msg_edge_val);
          }
        }
      }

      // add minimum weight edges to the graph
      for ( map<mLong, mLong>::iterator it = child_edges.begin();
            it != child_edges.end();
            it++ ) {
        data->addOutEdge(it->first);
        data->setOutEdgeValue(it->first, it->second);
      }

      // all that's left now is a graph w/ supervertices
      // its children NO LONGER participate in MST
      aggregate("counter", RESET);
      phase = PHASE_1;    // back to phase 1
      break;

    default:
      // TODO: PANIC!!!
    }
  }
};
#endif /* MST_H_ */

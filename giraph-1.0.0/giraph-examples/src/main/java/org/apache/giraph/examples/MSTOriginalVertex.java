/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.apache.giraph.examples;

//import com.google.common.collect.Lists;
import java.io.DataOutput;
import java.io.DataInput;
import java.io.IOException;
//import java.util.List;
import java.util.ArrayList;
import org.apache.giraph.aggregators.LongSumAggregator;
import org.apache.giraph.aggregators.IntOverwriteAggregator;
import org.apache.giraph.edge.Edge;
import org.apache.giraph.edge.MutableEdge;
import org.apache.giraph.edge.EdgeFactory;
import org.apache.giraph.graph.Vertex;
import org.apache.giraph.io.formats.TextVertexOutputFormat;
import org.apache.giraph.master.DefaultMasterCompute;
//import org.apache.giraph.worker.WorkerContext;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.io.Writable;
import org.apache.hadoop.mapreduce.TaskAttemptContext;
import org.apache.log4j.Logger;

import java.util.Iterator;

/**
 * Distributed MST implementation.
 *
 * Based on parallel Boruvka's algorithm described in
 * "Optimizing Graph Algorithms on Pregel-like Systems"
 * <http://ilpubs.stanford.edu:8090/1077/>
 *
 * Outputs vertex values that give the edges belonging to the MST.
 * These edges are outputted with weights, source, and destination.
 */
@Algorithm(
    name = "Minimum spanning tree"
)
public class MSTOriginalVertex extends Vertex<LongWritable,
    MSTOriginalVertex.MSTVertexValue,
    MSTOriginalVertex.MSTEdgeValue,
    MSTOriginalVertex.MSTMessage> {

  /** Logger */
  private static final Logger LOG =
      Logger.getLogger(MSTOriginalVertex.class);

  /** Counter aggregator name */
  private static String COUNTER_AGG = "counter";
  /** Total supervertex aggregator name */
  private static String SUPERVERTEX_AGG = "supervertex";
  /** Computation phase aggregator name */
  private static String PHASE_AGG = "phase";

  @Override
  public void compute(Iterable<MSTMessage> messages) {
    if (getSuperstep() == 0) {
      // if we are unconnected, just terminate
      if (getNumEdges() == 0) {
        voteToHalt();
        return;
      }

      // need to set up correct number of supervertices on first superstep
      aggregate(SUPERVERTEX_AGG, new LongWritable(1));
    }

    IntWritable phaseInt = getAggregatedValue(PHASE_AGG);
    MSTPhase phase = MSTPhase.VALUES[phaseInt.get()];

    // phase transitions are in master.compute()
    // algorithm termination is in phase4B

    switch(phase) {
    case PHASE_1:
      //LOG.info(getId() + ": phase 1");
      //for (Edge<LongWritable, MSTEdgeValue> edge : getEdges()) {
      //  LOG.info("  edges to " +
      //           edge.getTargetVertexId() + " with " + edge.getValue());
      //}

      phase1();
      // fall through

    case PHASE_2A:
      //LOG.info(getId() + ": phase 2A");
      phase2A();
      break;

    case PHASE_2B:
      //LOG.info(getId() + ": phase 2B");
      phase2B(messages);
      break;

    case PHASE_3A:
      //LOG.info(getId() + ": phase 3A");
      phase3A();
      break;

    case PHASE_3B:
      //LOG.info(getId() + ": phase 3B");
      phase3B(messages);
      // fall through

    case PHASE_4A:
      //LOG.info(getId() + ": phase 4A");
      phase4A();
      break;

    case PHASE_4B:
      //LOG.info(getId() + ": phase 4B");
      phase4B(messages);
      break;

    default:
      LOG.error("Invalid computation phase.");
    }
  }

  /******************** COMPUTATIONAL PHASES ********************/
  /**
   * Phase 1: find minimum weight edge
   */
  private void phase1() {
    // initialize some minimum stats
    double minWeight = Double.MAX_VALUE;
    long minId = getId().get();
    MSTEdgeValue minEdge = null;

    long eId = getId().get();
    MSTEdgeValue eVal = null;

    // find minimum weight edge
    for (Edge<LongWritable, MSTEdgeValue> e : getEdges()) {
      eId = e.getTargetVertexId().get();
      eVal = e.getValue();

      // NOTE: eId is not necessarily same as e.getDst(),
      // as getDst() returns the *original* destination

      // break ties by picking vertex w/ smaller destination ID
      //
      // NOTE: we don't bother with epsilon for == comparison,
      // because it'll fall under the "<" case
      if (eVal.getWeight() < minWeight ||
          (eVal.getWeight() == minWeight && eId < minId)) {
        minWeight = eVal.getWeight();
        minId = eId;
        // must make copy, b/c edges get invalidated upon iterating
        minEdge = new MSTEdgeValue(eVal);
      }
    }

    // store minimum weight edge value as vertex value
    if (minEdge != null) {
      getValue().setWeight(minEdge.getWeight());
      getValue().setSrc(minEdge.getSrc());
      getValue().setDst(minEdge.getDst());
    } else {
      // this is an error
      LOG.error("No minimum edge for " + getId() + " found in PHASE_1.");
    }

    // technically part of PHASE_2A
    getValue().setPointer(minId);

    // go to phase 2A

    //LOG.info(getId() + ": min edge is " + minEdge +
    //         " and value is " + getValue());
  }

  /**
   * Phase 2A: send out questions
   * This is a special case of Phase 2B (only questions, no answers).
   */
  private void phase2A() {
    getValue().setType(MSTVertexType.TYPE_UNKNOWN);

    MSTMessage msg = new MSTMessage(new MSTMsgType(MSTMsgType.MSG_QUESTION),
                                    new MSTMsgContentLong(getId().get()));

    // send query to pointer (potential supervertex)
    //LOG.info(getId() + ": sending question to " + getValue().getPointer());
    sendMessage(new LongWritable(getValue().getPointer()), msg);

    // go to phase 2B
  }

  /**
   * Phase 2B: respond to questions with answers, and send questions
   * This phase can repeat for multiple supersteps.
   *
   * @param messages Incoming messages
   */
  private void phase2B(Iterable<MSTMessage> messages) {
    ArrayList<Long> sources = new ArrayList<Long>();
    boolean isPointerSupervertex = false;

    long myId = getId().get();
    MSTVertexType type = getValue().getType();
    long pointer = getValue().getPointer();

    // if already done, our pointer is our supervertex
    if (type != MSTVertexType.TYPE_UNKNOWN) {
      isPointerSupervertex = true;
    }

    // question messages
    long senderId;

    // answer messages
    long supervertexId;
    boolean isSupervertex;

    for (MSTMessage message : messages) {
      switch(message.getType().get()) {
      case MSTMsgType.MSG_QUESTION:
        senderId = message.getValue().getFirst();

        //LOG.info(getId() + ": received question from " + senderId);

        // save source vertex ID, so we can send response
        // to them later on (after receiving all msgs)
        sources.add(senderId);

        // if already done, no need to do more checks
        if (type != MSTVertexType.TYPE_UNKNOWN) {
          break;
        }

        // check if there is a cycle (if the vertex we picked also picked us)
        // NOTE: cycle is unique b/c pointer choice is unique
        if (senderId == pointer) {
          // smaller ID always wins & becomes supervertex
          //
          // NOTE: = MUST be used here, in case there is a self-cycle
          // (i.e., vertex with an edge to itself), as otherwise the
          // vertex type will be incorrectly set to non-supervertex
          if (myId <= senderId) {
            pointer = myId;        // I am the supervertex
            type = MSTVertexType.TYPE_SUPERVERTEX;
            //LOG.info(getId() + ": I am a supervertex");
          } else {
            type = MSTVertexType.TYPE_POINTS_AT_SUPERVERTEX;
            //LOG.info(getId() + ": I point to supervertex" + senderId);
          }

          isPointerSupervertex = true;

          // increment counter aggregator (i.e., we're done this phase,
          // future answers messages will be ignored---see below)
          aggregate(COUNTER_AGG, new LongWritable(1));
        }

        // otherwise, type is still TYPE_UNKNOWN
        break;

      case MSTMsgType.MSG_ANSWER:
        // our pointer replied w/ possible information
        // about who our supervertex is

        // if we don't care about answers any more, break
        if (type != MSTVertexType.TYPE_UNKNOWN) {
          //LOG.info(getId() + ": ignoring answers");
          break;
        }

        // we still care, so parse answer message
        supervertexId = message.getValue().getFirst();
        isSupervertex = (message.getValue().getSecond() == 0) ? false : true;

        //LOG.info(getId() + ": received answer from " +
        //         supervertexId + ", " + isSupervertex);

        if (isSupervertex) {
          if (supervertexId != pointer) {
            // somebody propagated supervertex ID down to us
            type = MSTVertexType.TYPE_POINTS_AT_SUBVERTEX;
            pointer = supervertexId;
          } else {
            // otherwise, supervertex directly informed us
            type = MSTVertexType.TYPE_POINTS_AT_SUPERVERTEX;
          }

          isPointerSupervertex = true;

          // increment counter aggregator (i.e., we're done this phase)
          aggregate(COUNTER_AGG, new LongWritable(1));

        } else {
          // otherwise, our pointer didn't know who supervertex is,
          // so resend question to it
          MSTMessage msg = new MSTMessage(
                             new MSTMsgType(MSTMsgType.MSG_QUESTION),
                             new MSTMsgContentLong(myId));

          //LOG.info(getId() + ": resending question to " + pointer);
          sendMessage(new LongWritable(pointer), msg);
        }
        break;

      default:
        LOG.error("Invalid message type [" +
                  message.getType() + "] in PHASE_2B.");
      }
    }

    // send answers to all question messages we received
    //
    // NOTE: we wait until we receive all messages b/c we
    // don't know which (if any) of them will be a cycle
    if (sources.size() != 0) {
      long bool = isPointerSupervertex ? 1 : 0;

      MSTMessage msg = new MSTMessage(new MSTMsgType(MSTMsgType.MSG_ANSWER),
                                      new MSTMsgContentLong(pointer, bool));

      //LOG.info(getId() + ": sent " + pointer + ", " + isPointerSupervertex);

      for (long src : sources) {
        sendMessage(new LongWritable(src), msg);
      }
    }

    // update vertex value
    getValue().setType(type);
    getValue().setPointer(pointer);

    // phase change occurs in master.compute()
  }

  /**
   * Phase 3A: notify neighbours of supervertex ID
   */
  private void phase3A() {
    // This is dumb... there's probably a better way.
    aggregate(COUNTER_AGG, new LongWritable(-1));
    aggregate(SUPERVERTEX_AGG, new LongWritable(-1));

    // send our neighbours <my ID, my supervertex's ID>
    MSTMessage msg = new MSTMessage(new MSTMsgType(MSTMsgType.MSG_CLEAN),
                              new MSTMsgContentLong(getId().get(),
                                                    getValue().getPointer()));

    //LOG.info(getId() + ": sending MSG_CLEAN, my supervertex is " +
    //         getValue().getPointer());
    sendMessageToAllEdges(msg);

    // go to phase 3B
  }

  /**
   * Phase 3B: receive supervertex ID messages
   *
   * @param messages Incoming messages
   */
  private void phase3B(Iterable<MSTMessage> messages) {
    //for (Edge<LongWritable, MSTEdgeValue> edge : getEdges()) {
    //  LOG.info(getId() + ": before 3B...edge to " +
    //           edge.getTargetVertexId() + " with " + edge.getValue());
    //}

    long pointer = getValue().getPointer();

    long senderId;
    long supervertexId;
    MSTEdgeValue eTmp;
    MSTEdgeValue eVal;
    MSTEdgeValue eValExisting;

    // receive messages from PHASE_3A
    for (MSTMessage message : messages) {
      switch(message.getType().get()) {
      case MSTMsgType.MSG_CLEAN:
        senderId = message.getValue().getFirst();
        supervertexId = message.getValue().getSecond();

        //LOG.info(getId() + ": received MSG_CLEAN from " + senderId);

        // If supervertices are same, then we are in the same component,
        // so delete our outgoing edge to v (i.e., delete (u,v)).
        //
        // Note that v will delete edge (v, u).
        if (supervertexId == pointer) {
          removeEdges(new LongWritable(senderId));

        } else {
          // Otherwise, delete edge (u,v) and add edge (u, v's supervertex).
          // In phase 4, this will become (u's supervertex, v's supervertex)

          // if sender is its own supervertex, no need to change edges
          if (supervertexId == senderId) {
            break;
          }

          // get value of edge (u, v)
          eTmp = getEdgeValue(new LongWritable(senderId));
          if (eTmp == null) {
            LOG.error("Invalid (null) edge value in PHASE_3B.");
          }

          // have to make copy of value, b/c next getEdgeValue()
          // call will invalidate it
          eVal = new MSTEdgeValue(eTmp);

          // get value of edge (u, v's supervertex)
          eValExisting = getEdgeValue(new LongWritable(supervertexId));

          if (eValExisting == null) {
            // edge doesn't exist, so just add this
            addEdge(EdgeFactory.create(new LongWritable(supervertexId), eVal));

          } else {
            // if edge (u, v's supervertex) already exists, pick the
            // one with the minimum weight---this saves work in phase 4B
            if (eVal.getWeight() < eValExisting.getWeight()) {
              setEdgeValue(new LongWritable(supervertexId), eVal);
            }
          }

          // delete edge (u, v)
          removeEdges(new LongWritable(senderId));
        }
        break;

      default:
        LOG.error("Invalid message type [" +
                  message.getType() + "] in PHASE_3B.");
      }
    }

    //for (Edge<LongWritable, MSTEdgeValue> edge : getEdges()) {
    //  LOG.info(getId() + ": after 3B...edge to " +
    //           edge.getTargetVertexId() + " with " + edge.getValue());
    //}

    // supervertices also go to phase 4A (b/c they need to wait for msgs)
  }

  /**
   * Phase 4A: send adjacency list to supervertex
   */
  private void phase4A() {
    MSTVertexType type = getValue().getType();
    long pointer = getValue().getPointer();

    // terminate if not supervertex
    if (type != MSTVertexType.TYPE_SUPERVERTEX) {
      // send my supervertex all my edges, if I have any left
      if (getNumEdges() != 0) {
        Iterator<MutableEdge<LongWritable, MSTEdgeValue>> itr =
            getMutableEdges().iterator();

        MSTMessage msg;
        while (itr.hasNext()) {
          msg = new MSTMessage(new MSTMsgType(MSTMsgType.MSG_EDGE),
                               new MSTMsgContentEdge(itr.next()));
          sendMessage(new LongWritable(pointer), msg);

          // delete edge---this helps w/ performance & memory
          itr.remove();
        }
      }
      voteToHalt();
    }

    // otherwise, we are supervertex, so move to next phase
  }

  /**
   * Phase 4B: receive adjacency lists
   *
   * @param messages Incoming messages
   */
  private void phase4B(Iterable<MSTMessage> messages) {
    LongWritable eId;
    MSTEdgeValue eVal;
    MSTEdgeValue eValExisting;

    // receive messages from PHASE_4A
    for (MSTMessage message : messages) {
      switch(message.getType().get()) {
      case MSTMsgType.MSG_EDGE:
        // merge children's edge with our edges
        Edge<LongWritable, MSTEdgeValue> e = message.getValue().getEdge();

        eId = e.getTargetVertexId();
        eVal = e.getValue();
        eValExisting = getEdgeValue(eId);

        if (eValExisting == null) {
          // if no out-edge exists, add new one
          addEdge(e);

        } else {
          // otherwise, choose one w/ minimum weight
          if (eVal.getWeight() < eValExisting.getWeight()) {
            setEdgeValue(eId, eVal);
          }
        }

        break;

      default:
        LOG.error("Invalid message type [" +
                  message.getType() + "] in PHASE_4B.");
      }
    }

    // all that's left now is a graph w/ supervertices
    // its children NO LONGER participate in MST

    // if no more edges, then this supervertex is done
    if (getNumEdges() == 0) {
      voteToHalt();
    } else {
      // otherwise, increment total supervertex counter
      aggregate(SUPERVERTEX_AGG, new LongWritable(1));

      // and go back to phase 1
    }
  }

  /******************** MASTER/WORKER/MISC CLASSES ********************/

//  /**
//   * Worker context used with {@link MSTOriginalVertex}.
//   * For debugging purposes only.
//   */
//  public static class MSTOriginalVertexWorkerContext extends
//      WorkerContext {
//
//    @Override
//    public void preApplication()
//      throws InstantiationException, IllegalAccessException {
//      // executed before first superstep
//    }
//
//    @Override
//    public void postApplication() {
//      // executed after last superstep
//    }
//
//    @Override
//    public void preSuperstep() {
//      LOG.info("counter aggregator = " +
//               ((LongWritable) getAggregatedValue(COUNTER_AGG)).get());
//      LOG.info("supervertex number aggregator = " +
//               ((LongWritable) getAggregatedValue(SUPERVERTEX_AGG)).get());
//    }
//
//    @Override
//    public void postSuperstep() { }
//  }

  /**
   * Master compute associated with {@link MSTOriginalVertex}.
   * It registers required aggregators.
   */
  public static class MSTOriginalVertexMasterCompute extends
      DefaultMasterCompute {
    @Override
    public void initialize() throws InstantiationException,
        IllegalAccessException {
      // must use persistent aggregators, as these have to live
      // accross multiple supersteps (and phases)
      registerPersistentAggregator(COUNTER_AGG, LongSumAggregator.class);
      registerPersistentAggregator(SUPERVERTEX_AGG,
                                   LongSumAggregator.class);

      // Note that this aggregator is NOT set by workers or vertices.
      // It's only used by master to keep track of global phase.
      registerPersistentAggregator(PHASE_AGG, IntOverwriteAggregator.class);
    }

    @Override
    public void compute() {
      // special case for first superstep
      if (getSuperstep() == 0) {
        setAggregatedValue(PHASE_AGG, new IntWritable(MSTPhase.PHASE_1.get()));
        return;
      }

      IntWritable phaseInt = getAggregatedValue(PHASE_AGG);
      MSTPhase phase = MSTPhase.VALUES[phaseInt.get()];
      MSTPhase newphase = null;

      switch (phase) {
      case PHASE_1:
        // no need to set PHASE_AGG to PHASE_2A, because it's ran
        // in the same superstep as PHASE_1

        // fall through

      case PHASE_2A:
        newphase = MSTPhase.PHASE_2B;
        break;

      case PHASE_2B:
        LongWritable numDone = getAggregatedValue(COUNTER_AGG);
        LongWritable numSupervertex = getAggregatedValue(SUPERVERTEX_AGG);

        // PHASE_2B is special, because it can repeat an indeterminate
        // number of times. Hence, a "superbarrier" is needed.
        // This has to be done separately due to the "lagged" nature
        // of aggregated values.
        //
        // proceed to PHASE_3A iff all supervertices are done PHASE_2B
        if (numDone.get() == numSupervertex.get()) {
          newphase = MSTPhase.PHASE_3A;
        } else {
          newphase = MSTPhase.PHASE_2B;
        }
        break;

      case PHASE_3A:
        newphase = MSTPhase.PHASE_3B;
        break;

      case PHASE_3B:
        // same as PHASE_1, this falls through
        // fall through

      case PHASE_4A:
        newphase = MSTPhase.PHASE_4B;
        break;

      case PHASE_4B:
        newphase = MSTPhase.PHASE_1;
        break;

      default:
        LOG.error("Invalid computation phase.");
      }

      setAggregatedValue(PHASE_AGG, new IntWritable(newphase.get()));
    }
  }

  /**
   * Simple VertexOutputFormat that supports {@link MSTOriginalVertex}
   */
  public static class MSTOriginalVertexOutputFormat extends
      TextVertexOutputFormat<LongWritable,
         MSTOriginalVertex.MSTVertexValue,
         MSTOriginalVertex.MSTEdgeValue> {
    @Override
    public TextVertexWriter createVertexWriter(TaskAttemptContext context)
      throws IOException, InterruptedException {
      return new MSTOriginalVertexWriter();
    }

    /**
     * Simple VertexWriter that supports {@link MSTOriginalVertex}
     */
    public class MSTOriginalVertexWriter extends TextVertexWriter {
      @Override
      public void writeVertex(
          Vertex<LongWritable, MSTOriginalVertex.MSTVertexValue,
                 MSTOriginalVertex.MSTEdgeValue, ?> vertex)
        throws IOException, InterruptedException {
        getRecordWriter().write(
            new Text(vertex.getId().toString()),
            new Text(vertex.getValue().toOutputString()));
      }
    }
  }

  /******************** MST VERTEX VALUE INNER CLASSES ********************/
  /**
   * Current computation phase
   */
  public static enum MSTPhase {
    /** missing a javadoc comment. here it is. **/
    PHASE_1(0),  /** find min-weight edge **/
    PHASE_2A(1), /** question phase **/
    PHASE_2B(2), /** Q /and/ A phase **/
    PHASE_3A(3), /** send supervertex IDs **/
    PHASE_3B(4), /** receive PHASE_3A messages **/
    PHASE_4A(5), /** send edges to supervertex **/
    PHASE_4B(6); /** receive/merge edges **/

    /** Array of all possible enums **/
    // apparently calling values() is expensive, so store it
    static final MSTPhase[] VALUES = MSTPhase.values();

    /** Integer value **/
    private int i;

    /**
     * Default constructor.
     *
     * @param i An integer.
     */
    MSTPhase(int i) {
      this.i = i;
    }

    /**
     * Get numeric value of enum.
     *
     * @return The numeric value.
     */
    public int get() {
      return i;
    }
  }

  /**
   * Status/type of this vertex
   */
  public static enum MSTVertexType {
    /** missing a javadoc comment. here it is. **/
    TYPE_UNKNOWN(0),               /** initial state in PHASE_2A **/
    TYPE_SUPERVERTEX(1),           /** supervertex **/
    TYPE_POINTS_AT_SUPERVERTEX(2), /** child of supervertex **/
    TYPE_POINTS_AT_SUBVERTEX(3);   /** child of child of supervertex**/

    /** Array of all possible enums **/
    static final MSTVertexType[] VALUES = MSTVertexType.values();

    /** Integer value **/
    private int i;

    /**
     * Default constructor.
     *
     * @param i An integer.
     */
    MSTVertexType(int i) {
      this.i = i;
    }

    /**
     * Get numeric value of enum.
     *
     * @return The numeric value.
     */
    public int get() {
      return i;
    }
  }

  /**
   * Vertex value type used by {@link MSTOriginalVertex}.
   */
  public static class MSTVertexValue implements Writable {
    /**/
    private double weight;       /** edge weight **/
    private long src;            /** original edge source **/
    private long dst;            /** original edge destination **/
    private MSTVertexType type;  /** vertex type **/
    private long pointer;        /** (potential) supervertex **/

    /**
     * Default edge constructor.
     */
    public MSTVertexValue() {
      type = MSTVertexType.TYPE_UNKNOWN;
      // rest all 0s
    }

    /**
     * Edge constructor. Objects passed in must NOT be modified.
     *
     * @param weight Weight.
     * @param src Original source vertex.
     * @param dst Original destination vertex.
     * @param type Vertex type.
     * @param pointer Pointer/supervertex.
     */
    public MSTVertexValue(double weight, long src, long dst,
                          MSTVertexType type, long pointer) {
      this.weight = weight;
      this.src = src;
      this.dst = dst;
      this.type = type;
      this.pointer = pointer;
    }

    /**
     * Copy constructor.
     *
     * @param val MSTVertexValue to be copied.
     */
    public MSTVertexValue(MSTVertexValue val) {
      this.weight = val.weight;
      this.src = val.src;
      this.dst = val.dst;
      this.type = val.type;
      this.pointer = val.pointer;
    }

    public double getWeight() {
      return weight;
    }

    public long getSrc() {
      return src;
    }

    public long getDst() {
      return dst;
    }

    public MSTVertexType getType() {
      return type;
    }

    public long getPointer() {
      return pointer;
    }

    // vertex value can have setters
    public void setWeight(double weight) {
      this.weight = weight;
    }

    public void setSrc(long src) {
      this.src = src;
    }

    public void setDst(long dst) {
      this.dst = dst;
    }

    public void setType(MSTVertexType type) {
      this.type = type;
    }

    public void setPointer(long pointer) {
      this.pointer = pointer;
    }

    @Override
    public void readFields(DataInput in) throws IOException {
      // less wasteful than casting to *Writable object and
      // using their readFields()
      weight = in.readDouble();
      src = in.readLong();
      dst = in.readLong();
      type = MSTVertexType.VALUES[in.readInt()];
      pointer = in.readLong();
    }

    @Override
    public void write(DataOutput out) throws IOException {
      out.writeDouble(weight);
      out.writeLong(src);
      out.writeLong(dst);
      out.writeInt(type.get());
      out.writeLong(pointer);
    }

    @Override
    public String toString() {
      return "weight=" + weight + " src=" + src + " dst=" + dst +
        " type=" + type + " pointer=" + pointer;
    }

    /**
     * Returns string for outputing relevant stored data.
     *
     * @return String with weight, src, and dst only.
     */
    public String toOutputString() {
      return "weight=" + weight + " src=" + src + " dst=" + dst;
    }
  }

  /******************** MST EDGE VALUE INNER CLASSES ********************/
  /**
   * Edge value type used by {@link MSTOriginalVertex}.
   */
  public static class MSTEdgeValue implements Writable {
    /**/
    private double weight; /** edge weight **/
    private long src;      /** original edge source **/
    private long dst;      /** original edge destination **/

    /**
     * Default edge constructor.
     */
    public MSTEdgeValue() {
      // all 0s
    }

    /**
     * Edge constructor.
     *
     * @param weight Weight.
     * @param src Original source vertex.
     * @param dst Original destination vertex.
     */
    public MSTEdgeValue(double weight, long src, long dst) {
      this.weight = weight;
      this.src = src;
      this.dst = dst;
    }

    /**
     * Copy constructor.
     *
     * @param val MSTEdgeValue to be copied.
     */
    public MSTEdgeValue(MSTEdgeValue val) {
      this.weight = val.weight;
      this.src = val.src;
      this.dst = val.dst;
    }

    public double getWeight() {
      return weight;
    }

    public long getSrc() {
      return src;
    }

    public long getDst() {
      return dst;
    }

    @Override
    public void readFields(DataInput in) throws IOException {
      // less wasteful than casting to *Writable object and
      // using their readFields()
      weight = in.readDouble();
      src = in.readLong();
      dst = in.readLong();
    }

    @Override
    public void write(DataOutput out) throws IOException {
      out.writeDouble(weight);
      out.writeLong(src);
      out.writeLong(dst);
    }

    @Override
    public String toString() {
      return "weight=" + weight + " src=" + src + " dst=" + dst;
    }
  }


  /******************** MST MESSAGE INNER CLASSES ********************/

  /**
   * Message type used by {@link MSTOriginalVertex}.
   *
   * Essentially a wrapper class containing a type, and a
   * MSTMsgContent value.
   */
  public static class MSTMessage implements Writable {
    /** private variables **/
    private MSTMsgType type;       /** message type **/
    private MSTMsgContent value;   /** message content/value **/

    /**
     * Default constructor.
     */
    public MSTMessage() {
      this.type = new MSTMsgType(MSTMsgType.MSG_INVALID);
      // TODO: ??? or should we use MSTMsgContentLong??
      this.value = new MSTMsgContentLong();
    }

    /**
     * Message constructor.
     *
     * @param type Message type.
     * @param value Message value.
     */
    public MSTMessage(MSTMsgType type, MSTMsgContent value) {
      this.type = type;
      this.value = value;
    }

    public MSTMsgType getType() {
      return type;
    }

    public MSTMsgContent getValue() {
      return value;
    }

    @Override
    public void readFields(DataInput in) throws IOException {
      type.readFields(in);

      switch(type.get()) {
      case MSTMsgType.MSG_EDGE:
        value = new MSTMsgContentEdge();
        break;
      default:
        value = new MSTMsgContentLong();
        break;
      }
      value.readFields(in);
    }

    @Override
    public void write(DataOutput out) throws IOException {
      type.write(out);
      value.write(out);
    }

    @Override
    public String toString() {
      return "message: type=" + type.toString() + " value=" + value.toString();
    }
  }

  /**
   * Possible message types.
   */
  public static class MSTMsgType implements Writable {
    // NOTE: cannot use enum, b/c this must be *mutable*!!
    // (i.e., "type" field must be able to change dynamically)
    /** valid values **/
    public static final int MSG_INVALID = 0;  /**/
    public static final int MSG_QUESTION = 1; /**/
    public static final int MSG_ANSWER = 2;   /**/
    public static final int MSG_CLEAN = 3;    /**/
    public static final int MSG_EDGE = 4;    /**/

    /** A type. **/
    private int type;

    /**
     * Default constructor.
     */
    MSTMsgType() {
      this.type = MSG_INVALID;
    }

    /**
     * Value constructor.
     *
     * @param type A type. Must be between one of MSG_INVALID, ..., MSG_EDGE.
     */
    MSTMsgType(int type) {
      this.type = type;
    }

    /**
     * Returns type.
     *
     * @return The type.
     */
    public int get() {
      return type;
    }

    @Override
    public void readFields(DataInput in) throws IOException {
      type = in.readInt();
    }

    @Override
    public void write(DataOutput out) throws IOException {
      out.writeInt(type);
    }

    @Override
    public String toString() {
      String out;
      switch (type) {
      case MSG_QUESTION:
        out = "MSG_QUESTION";
        break;
      case MSG_ANSWER:
        out = "MSG_ANSWER";
        break;
      case MSG_CLEAN:
        out = "MSG_CLEAN";
        break;
      case MSG_EDGE:
        out = "MSG_EDGE";
        break;
      default:
        out = "MSG_INVALID";
        break;
      }

      return out;
    }
  }

  /**
   * MST message content interface. Supports all types of
   * messages, but not all functions will be implemented.
   */
  public interface MSTMsgContent extends Writable {
    // NOTE: these types are not generic because it's unnecessary
    // and requires too much coding effort

    /**
     * Get first field of message content.
     *
     * @return First field of message
     */
    long getFirst();

    /**
     * Get second field of message content.
     *
     * @return Second field of message
     */
    long getSecond();

    /**
     * Get an edge from the message content.
     *
     * @return Edge stored in message
     */
    Edge<LongWritable, MSTEdgeValue> getEdge();
  }

  /**
   * Message value class for all but MSG_EDGE.
   */
  public static class MSTMsgContentLong implements MSTMsgContent {
    /**
     * First field is different depending on message type.
     *   MSG_QUESTION: source vertex ID
     *   MSG_ANSWER:   pointer vertex ID
     *   MSG_CLEAN:    source vertex ID
     */
    private long first;

    /**
     * Second field is different depending on message type.
     *   MSG_QUESTION: N/A
     *   MSG_ANSWER:   true (1) or false (0)
     *   MSG_CLEAN:    supervertex ID (of source vertex)
     */
    private long second;

    /**
     * Default constructor.
     */
    public MSTMsgContentLong() {
      // all 0s
    }

    /**
     * Constructor for MSG_QUESTION, which does not require second field.
     *
     * @param first First and only field.
     */
    public MSTMsgContentLong(long first) {
      this.first = first;
    }

    /**
     * Constructor for all message types except MSG_QUESTION, MSG_EDGE.
     *
     * @param first First field.
     * @param second Second field.
     */
    public MSTMsgContentLong(long first, long second) {
      this.first = first;
      this.second = second;
    }

    public long getFirst() {
      return first;
    }

    public long getSecond() {
      return second;
    }

    /**
     * Irrelevant for this type of message.
     *
     * @return null
     */
    public Edge<LongWritable, MSTEdgeValue> getEdge() {
      return null;
    }

    @Override
    public void readFields(DataInput in) throws IOException {
      first = in.readLong();
      second = in.readLong();
    }

    @Override
    public void write(DataOutput out) throws IOException {
      out.writeLong(first);
      out.writeLong(second);
    }

    @Override
    public String toString() {
      return "first=" + first + " second=" + second;
    }
  }

  /**
   * Message value class for MSG_EDGE.
   *
   * This extends MSTEdgeValue to avoid storing unnecessary objects.
   */
  public static class MSTMsgContentEdge
    extends MSTEdgeValue implements MSTMsgContent {

    /** Actual destination of this edge **/
    // this need not be same as the "original edge destination"
    private long edgeDst;

    /**
     * Default constructor.
     */
    public MSTMsgContentEdge() {
      super();
    }

    /**
     * Constructor taking in an edge.
     * This makes a deep copy, so removal after this call is safe.
     *
     * @param edge An edge.
     */
    public MSTMsgContentEdge(Edge<LongWritable, MSTEdgeValue> edge) {
      super(edge.getValue());
      edgeDst = edge.getTargetVertexId().get();
    }

    /**
     * Irrelevant for this type of message.
     *
     * @return 0
     */
    public long getFirst() {
      return 0;
    }

    /**
     * Irrelevant for this type of message.
     *
     * @return 0
     */
    public long getSecond() {
      return 0;
    }

    /**
     * Returns the edge.
     *
     * @return An edge.
     */
    public Edge<LongWritable, MSTEdgeValue> getEdge() {
      // MSTEdgeValue cast is a slight hack
      return EdgeFactory.create(new LongWritable(edgeDst),
                                new MSTEdgeValue((MSTEdgeValue) this));
    }

    @Override
    public void readFields(DataInput in) throws IOException {
      super.readFields(in);
      edgeDst = in.readLong();
    }

    @Override
    public void write(DataOutput out) throws IOException {
      super.write(out);
      out.writeLong(edgeDst);
    }
  }
}

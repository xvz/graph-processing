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
import org.apache.giraph.edge.Edge;
import org.apache.giraph.edge.EdgeFactory;
import org.apache.giraph.graph.Vertex;
import org.apache.giraph.io.formats.TextVertexOutputFormat;
import org.apache.giraph.master.DefaultMasterCompute;
//import org.apache.giraph.worker.WorkerContext;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.io.Writable;
import org.apache.hadoop.mapreduce.TaskAttemptContext;
import org.apache.log4j.Logger;

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
public class MinimumSpanningTreeVertex extends Vertex<LongWritable,
    MinimumSpanningTreeVertex.MSTEdgeValue,
    MinimumSpanningTreeVertex.MSTEdgeValue,
    MinimumSpanningTreeVertex.MSTMessage> {

  /** Logger */
  private static final Logger LOG =
      Logger.getLogger(MinimumSpanningTreeVertex.class);
  /** Counter aggregator name */
  private static String COUNTER_AGG = "counter";
  /** Total supervertex aggregator name */
  private static String SUPERVERTEX_AGG = "supervertex";

  /** Current computation phase **/
  private static enum MSTPhase {
    /** missing a javadoc comment. here it is. **/
    PHASE_1,  /** find min-weight edge **/
    PHASE_2A, /** question phase **/
    PHASE_2B, /** Q /and/ A phase **/
    PHASE_3A, /** send supervertex IDs **/
    PHASE_3B, /** receive PHASE_3A messages **/
    PHASE_4A, /** send edges to supervertex **/
    PHASE_4B; /** receive/merge edges **/
  }

  /** Status/type of this vertex **/
  private static enum MSTVertexType {
    /** missing a javadoc comment. here it is. **/
    TYPE_UNKNOWN,               /** initial state in PHASE_2A **/
    TYPE_SUPERVERTEX,           /** supervertex **/
    TYPE_POINTS_AT_SUPERVERTEX, /** child of supervertex **/
    TYPE_POINTS_AT_SUBVERTEX;   /** child of child of supervertex**/
  }

  /** A phase **/
  private MSTPhase phase;
  /** A status/type **/
  private MSTVertexType type;

  /** A pointer (potential supervertex) **/
  private long pointer;


  @Override
  public void compute(Iterable<MSTMessage> messages) {
    if (getSuperstep() == 0) {
      phase = MSTPhase.PHASE_1;

      // need to set up correct number of supervertices on first superstep
      aggregate(SUPERVERTEX_AGG, new LongWritable(1));
    }

    // PHASE_2B is special, because it can repeat an indeterminate
    // number of times. Hence, a "superbarrier" is needed.
    // This has to be done separately due to the "lagged" nature
    // of aggregated values.
    //
    // proceed to PHASE_3A iff all supervertices are done PHASE_2B
    LongWritable numDone = getAggregatedValue(COUNTER_AGG);
    LongWritable numSupervertex = getAggregatedValue(SUPERVERTEX_AGG);

    if (phase == MSTPhase.PHASE_2B) {
      if (numDone.get() == numSupervertex.get()) {
        this.phase = MSTPhase.PHASE_3A;
      }
    }

    // special halting condition if only 1 supervertex is left
    if (phase == MSTPhase.PHASE_1 && numSupervertex.get() == 1) {
      voteToHalt();
      return;
    }

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
      break;
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
      setValue(minEdge);
    }

    // technically part of PHASE_2A
    this.pointer = minId;

    this.phase = MSTPhase.PHASE_2A;

    //LOG.info(getId() + ": min edge is " + minEdge +
    //         " and value is " + getValue());
  }

  /**
   * Phase 2A: send out questions
   * This is a special case of Phase 2B (only questions, no answers).
   */
  private void phase2A() {
    this.type = MSTVertexType.TYPE_UNKNOWN;

    MSTMessage msg = new MSTMessage(new MSTMsgType(MSTMsgType.MSG_QUESTION),
                                    new MSTMsgContentLong(getId().get()));

    // send query to pointer (potential supervertex)
    //LOG.info(getId() + ": sending question to " + pointer);
    sendMessage(new LongWritable(pointer), msg);

    this.phase = MSTPhase.PHASE_2B;
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

    for (MSTMessage message : messages) {
      switch(message.getType().get()) {
      case MSTMsgType.MSG_QUESTION:
        long senderId = message.getValue().getFirst();

        //LOG.info(getId() + ": received question from " + senderId);

        // save source vertex ID, so we can send response
        // to them later on (after receiving all msgs)
        sources.add(senderId);

        // if already done, no need to do more checks
        if (this.type != MSTVertexType.TYPE_UNKNOWN) {
          isPointerSupervertex = true;
          break;
        }

        // check if there is a cycle (if the vertex we picked also picked us)
        // NOTE: cycle is unique b/c edge weights are unique
        if (senderId == this.pointer) {
          // smaller ID always wins & becomes supervertex
          if (getId().get() < senderId) {
            this.pointer = getId().get();        // I am the supervertex
            this.type = MSTVertexType.TYPE_SUPERVERTEX;
          } else {
            this.type = MSTVertexType.TYPE_POINTS_AT_SUPERVERTEX;
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
        if (this.type != MSTVertexType.TYPE_UNKNOWN) {
          //LOG.info(getId() + ": ignoring answers");
          break;
        }

        // we still care, so parse answer message
        long supervertexId = message.getValue().getFirst();
        boolean isSupervertex =
          (message.getValue().getSecond() == 0) ? false : true;

        //LOG.info(getId() + ": received answer from " +
        //         supervertexId + ", " + isSupervertex);

        if (isSupervertex) {
          if (supervertexId != pointer) {
            // somebody propagated supervertex ID down to us
            this.type = MSTVertexType.TYPE_POINTS_AT_SUBVERTEX;
            this.pointer = supervertexId;
          } else {
            // otherwise, supervertex directly informed us
            this.type = MSTVertexType.TYPE_POINTS_AT_SUPERVERTEX;
          }

          // increment counter aggregator (i.e., we're done this phase)
          aggregate(COUNTER_AGG, new LongWritable(1));

        } else {
          // otherwise, our pointer didn't know who supervertex is,
          // so resend question to it
          MSTMessage msg = new MSTMessage(
                             new MSTMsgType(MSTMsgType.MSG_QUESTION),
                             new MSTMsgContentLong(getId().get()));

          //LOG.info(getId() + ": resending question to " + pointer);

          sendMessage(new LongWritable(pointer), msg);
        }
        break;

      default:
        LOG.error("Invalid message type [" +
                  message.getType() + "] in PHASE_2B.");
        break;
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

      for (long src : sources) {
        sendMessage(new LongWritable(src), msg);
      }
    }

    // phase change occurs in compute()
  }

  /**
   * Phase 3A: notify neighbours of supervertex ID
   */
  private void phase3A() {
    // Reset aggregator counters in worker, to reduce contention.
    // This is dumb... there's probably a better way.
    aggregate(COUNTER_AGG, new LongWritable(-1));
    aggregate(SUPERVERTEX_AGG, new LongWritable(-1));

    // send our neighbours <my ID, my supervertex's ID>
    MSTMessage msg = new MSTMessage(new MSTMsgType(MSTMsgType.MSG_CLEAN),
                              new MSTMsgContentLong(getId().get(), pointer));

    //LOG.info(getId() + ": sending MSG_CLEAN, my supervertex is " + pointer);

    sendMessageToAllEdges(msg);

    this.phase = MSTPhase.PHASE_3B;
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

    // receive messages from PHASE_3A
    for (MSTMessage message : messages) {
      switch(message.getType().get()) {
      case MSTMsgType.MSG_CLEAN:
        long senderId = message.getValue().getFirst();
        long supervertexId = message.getValue().getSecond();

        //LOG.info(getId() + ": received MSG_CLEAN from " + senderId);

        // If supervertices are same, then we are in the same component,
        // so delete our outgoing edge to v (i.e., delete (u,v)).
        //
        // Note that v will delete edge (v, u).
        if (supervertexId == this.pointer) {
          removeEdges(new LongWritable(senderId));

        } else {
          // Otherwise, delete edge (u,v) and add edge (u, v's supervertex).
          // In phase 4, this will become (u's supervertex, v's supervertex)

          // if sender is its own supervertex, no need to change edges
          if (supervertexId == senderId) {
            break;
          }

          // get value of edge (u, v)
          MSTEdgeValue tmp = getEdgeValue(new LongWritable(senderId));
          if (tmp == null) {
            LOG.error("Invalid (null) edge value in PHASE_3B.");
          }

          // have to make copy of value, b/c next getEdgeValue()
          // call will invalidate it
          MSTEdgeValue eVal = new MSTEdgeValue(tmp);

          // get value of edge (u, v's supervertex)
          MSTEdgeValue eValExisting =
            getEdgeValue(new LongWritable(supervertexId));

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
    this.phase = MSTPhase.PHASE_4A;
  }

  /**
   * Phase 4A: send adjacency list to supervertex
   */
  private void phase4A() {
    // terminate if not supervertex
    if (type != MSTVertexType.TYPE_SUPERVERTEX) {
      // send my supervertex all my edges, if I have any left
      if (getNumEdges() != 0) {
        MSTMessage msg = new MSTMessage(
                           new MSTMsgType(MSTMsgType.MSG_EDGES),
                           new MSTMsgContentEdges(getNumEdges(), getEdges()));

        sendMessage(new LongWritable(pointer), msg);
      }
      voteToHalt();

    } else {
      // we are supervertex, so move to next phase
      this.phase = MSTPhase.PHASE_4B;

      // increment total supervertex counter
      aggregate(SUPERVERTEX_AGG, new LongWritable(1));
    }
  }

  /**
   * Phase 4B: receive adjacency lists
   *
   * @param messages Incoming messages
   */
  private void phase4B(Iterable<MSTMessage> messages) {
    // receive messages from PHASE_4A
    for (MSTMessage message : messages) {
      switch(message.getType().get()) {
      case MSTMsgType.MSG_EDGES:
        ArrayList<Edge<LongWritable, MSTEdgeValue>> edges =
          message.getValue().getEdges();

        LongWritable eId;
        MSTEdgeValue eVal;
        MSTEdgeValue eValExisting;

        // merge children's edges (and our edges),
        // by picking ones with minimum weight
        for (Edge<LongWritable, MSTEdgeValue> e : edges) {
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
        }

        break;

      default:
        LOG.error("Invalid message type in PHASE_4B.");
      }
    }

    // all that's left now is a graph w/ supervertices
    // its children NO LONGER participate in MST

    // back to phase 1
    this.phase = MSTPhase.PHASE_1;
  }

  /******************** MASTER/WORKER/MISC CLASSES ********************/

//  /**
//   * Worker context used with {@link MinimumSpanningTreeVertex}.
//   * For debugging purposes only.
//   */
//  public static class MinimumSpanningTreeVertexWorkerContext extends
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
   * Master compute associated with {@link MinimumSpanningTreeVertex}.
   * It registers required aggregators.
   */
  public static class MinimumSpanningTreeVertexMasterCompute extends
      DefaultMasterCompute {
    @Override
    public void initialize() throws InstantiationException,
        IllegalAccessException {
      // must use persistent aggregators, as these have to live
      // accross multiple supersteps (and phases)
      registerPersistentAggregator(COUNTER_AGG, LongSumAggregator.class);
      registerPersistentAggregator(SUPERVERTEX_AGG,
                                   LongSumAggregator.class);
    }
  }

  /**
   * Simple VertexOutputFormat that supports {@link MinimumSpanningTreeVertex}
   */
  public static class MinimumSpanningTreeVertexOutputFormat extends
      TextVertexOutputFormat<LongWritable,
         MinimumSpanningTreeVertex.MSTEdgeValue,
         MinimumSpanningTreeVertex.MSTEdgeValue> {
    @Override
    public TextVertexWriter createVertexWriter(TaskAttemptContext context)
      throws IOException, InterruptedException {
      return new MinimumSpanningTreeVertexWriter();
    }

    /**
     * Simple VertexWriter that supports {@link MinimumSpanningTreeVertex}
     */
    public class MinimumSpanningTreeVertexWriter extends TextVertexWriter {
      @Override
      public void writeVertex(
          Vertex<LongWritable, MinimumSpanningTreeVertex.MSTEdgeValue,
                 MinimumSpanningTreeVertex.MSTEdgeValue, ?> vertex)
        throws IOException, InterruptedException {
        getRecordWriter().write(
            new Text(vertex.getId().toString()),
            new Text(vertex.getValue().toString()));
      }
    }
  }

  /******************** MST EDGE VALUE INNER CLASSES ********************/
  /**
   * Edge value type used by {@link MinimumSpanningTreeVertex}.
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
     * Edge constructor. Objects passed in must NOT be modified.
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
   * Message type used by {@link MinimumSpanningTreeVertex}.
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
      case MSTMsgType.MSG_EDGES:
        value = new MSTMsgContentEdges();
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
    /** valid values **/
    public static final int MSG_INVALID = 0;  /**/
    public static final int MSG_QUESTION = 1; /**/
    public static final int MSG_ANSWER = 2;   /**/
    public static final int MSG_CLEAN = 3;    /**/
    public static final int MSG_EDGES = 4;    /**/

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
     * @param type A type. Must be between one of MSG_INVALID, ..., MSG_EDGES.
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
      case MSG_EDGES:
        out = "MSG_EDGES";
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
     * Get the edges from the message content.
     *
     * @return Edges stored in message
     */
    ArrayList<Edge<LongWritable, MSTEdgeValue>> getEdges();
  }

  /**
   * Message value class for all but MSG_EDGES.
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
     * Constructor for all message types except MSG_QUESTION, MSG_EDGES.
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
    public ArrayList<Edge<LongWritable, MSTEdgeValue>> getEdges() {
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
   * Message value class for MSG_EDGES.
   */
  public static class MSTMsgContentEdges implements MSTMsgContent {
    /** Adjacency list to send. Only used for MSG_EDGES message type. **/
    // NOTE: we use array b/c there are too many requirements w/ OutEdges
    private ArrayList<Edge<LongWritable, MSTEdgeValue>> edges;

    /**
     * Default constructor.
     */
    public MSTMsgContentEdges() {
      edges = new ArrayList<Edge<LongWritable, MSTEdgeValue>>();
    }

    /**
     * Constructor taking in edges.
     * This makes a copy of the edges, so passing in getEdges() is safe.
     *
     * @param numEdges Number of edges.
     * @param edges Iterator for edges.
     */
    public MSTMsgContentEdges(int numEdges,
                         Iterable<Edge<LongWritable, MSTEdgeValue>> edges) {

      // NOTE: we don't actually store numEdges, as it's not needed
      this.edges = new ArrayList<Edge<LongWritable, MSTEdgeValue>>(numEdges);

      long eId;
      MSTEdgeValue eVal;

      // TODO: would it be more efficient just to keep iterator reference,
      // given that messages are almost always written shortly after creation?
      for (Edge<LongWritable, MSTEdgeValue> e : edges) {
        // not safe to keep reference, so create copy
        eId = e.getTargetVertexId().get();
        eVal = e.getValue();

        this.edges.add(EdgeFactory.create(new LongWritable(eId),
                                          new MSTEdgeValue(eVal)));
      }

      //LOG.info("initialized w/ edges: " + this.edges.size() + " " + numEdges);
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

    public ArrayList<Edge<LongWritable, MSTEdgeValue>> getEdges() {
      return edges;
    }

    @Override
    public void readFields(DataInput in) throws IOException {
      int numEdges = in.readInt();
      edges = new ArrayList<Edge<LongWritable, MSTEdgeValue>>(numEdges);

      LongWritable id;
      MSTEdgeValue val;

      for (int i = 0; i < numEdges; i++) {
        // not safe to keep reference, so create copy
        id = new LongWritable();
        val = new MSTEdgeValue();

        id.readFields(in);
        val.readFields(in);

        edges.add(EdgeFactory.create(id, val));
      }

      //LOG.info("read some edges: " + (edges == null) +
      //         " " + edges.size() + " " + numEdges);
      //
      //if (edges.size() > 0) {
      //  for (Edge<LongWritable, MSTEdgeValue> edge : edges) {
      //    LOG.info("  edges to " +
      //             edge.getTargetVertexId() + " with " + edge.getValue());
      //  }
      //}
    }

    @Override
    public void write(DataOutput out) throws IOException {
      out.writeInt(edges.size());

      for (Edge<LongWritable, MSTEdgeValue> e : edges) {
        e.getTargetVertexId().write(out);
        e.getValue().write(out);
      }

      //LOG.info("wrote some edges: " + (edges == null) + " " +  edges.size());
      //if (edges.size() > 0) {
      //  for (Edge<LongWritable, MSTEdgeValue> edge : edges) {
      //    LOG.info("  edges to " +
      //             edge.getTargetVertexId() + " with " + edge.getValue());
      //  }
      //}
    }
  }
}

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
import java.util.Map;
import java.util.HashMap;
import org.apache.giraph.aggregators.LongSumResetAggregator;
import org.apache.giraph.edge.Edge;
import org.apache.giraph.edge.EdgeFactory;
import org.apache.giraph.graph.Vertex;
import org.apache.giraph.io.formats.TextVertexOutputFormat;
import org.apache.giraph.master.DefaultMasterCompute;
//import org.apache.giraph.worker.WorkerContext;
import org.apache.hadoop.io.DoubleWritable;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.io.Writable;
import org.apache.hadoop.mapreduce.TaskAttemptContext;
import org.apache.log4j.Logger;

/**
 * Distributed MST implementation.
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
    // PHASE_2B is special, because it can repeat an indeterminate
    // number of times. Hence, a "superbarrier" is needed.
    // This has to be done separately due to the "lagged" nature
    // of aggregated values.
    //
    // proceed to PHASE_3A iff all supervertices are done PHASE_2B
    if (phase == MSTPhase.PHASE_2B) {
      if (getAggregatedValue(COUNTER_AGG) ==
          getAggregatedValue(SUPERVERTEX_AGG)) {
        this.phase = MSTPhase.PHASE_3A;
      }
    }

    switch(phase) {
    case PHASE_1:
      phase1();
      // fall through

    case PHASE_2A:
      phase2A();
      break;

    case PHASE_2B:
      phase2B(messages);
      break;

    case PHASE_3A:
      phase3A();
      break;

    case PHASE_3B:
      phase3B(messages);
      break;

    case PHASE_4A:
      phase4A();
      break;

    case PHASE_4B:
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
      if (eVal.getWeight().get() < minWeight ||
          (eVal.getWeight().get() == minWeight && eId < minId)) {
        minWeight = eVal.getWeight().get();
        minId = eId;

        // create another copy (not just an extra reference) to be safe
        minEdge = new MSTEdgeValue(eVal.getWeight(),
                                   eVal.getSrc(), eVal.getDst());
      }
    }

    // store minimum weight edge value as vertex value
    if (minEdge != null) {
      setValue(minEdge);
    }

    // technically part of PHASE_2A
    this.pointer = eId;

    this.phase = MSTPhase.PHASE_2A;
  }

  /**
   * Phase 2A: send out questions
   */
  private void phase2A() {
    this.type = MSTVertexType.TYPE_UNKNOWN;

    LongWritable ptr = new LongWritable(this.pointer);
    MSTMessage msg = new MSTMessage(MSTMsgType.MSG_QUESTION,
                                    new MSTMsgContentLong(getId()));

    // send query to pointer (potential supervertex)
    sendMessage(ptr, msg);

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
      switch(message.getType()) {
      case MSG_QUESTION:
        long senderId = message.getValue().getFirst().get();

        // save source vertex ID, so we can send response
        // to them later on (after receiving all msgs)
        sources.add(senderId);

        // check if there is a cycle (aka, if the vertex we
        // picked also picked us)
        // NOTE: cycle is unique b/c edge weights are unique
        if (senderId == this.pointer) {
          // smaller ID always wins & becomes supervertex
          if (getId().get() < senderId) {
            this.pointer = getId().get();        // I am the supervertex
            this.type = MSTVertexType.TYPE_SUPERVERTEX;

            // increment counter aggregator (i.e., we're done this phase,
            // b/c supervertex ignores MSG_ANSWER messages: see below)
            aggregate(COUNTER_AGG, new LongWritable(1));
          } else {
            this.type = MSTVertexType.TYPE_POINTS_AT_SUPERVERTEX;
          }

          isPointerSupervertex = true;
        }

        // otherwise, type is still TYPE_UNKNOWN
        break;

      case MSG_ANSWER:
        // our pointer replied w/ possible information
        // about who our supervertex is
        long supervertexId = message.getValue().getFirst().get();
        boolean isSupervertex =
          (message.getValue().getSecond().get() == 0) ? false : true;

        // ignore messages that haven't found a supervertex,
        // or all messages if we're already a supervertex
        if (isSupervertex && this.type != MSTVertexType.TYPE_SUPERVERTEX) {
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
        }
        break;

      default:
        LOG.error("Invalid message type in PHASE_2B.");
        break;
      }
    }

    // send answers to all question messages we received
    //
    // NOTE: we wait until we receive all messages b/c we
    // don't know which (if any) of them will be a cycle
    if (sources.size() != 0) {
      LongWritable ptr = new LongWritable(this.pointer);
      LongWritable bool = new LongWritable(isPointerSupervertex ? 1 : 0);

      MSTMessage msg = new MSTMessage(MSTMsgType.MSG_ANSWER,
                                      new MSTMsgContentLong(ptr, bool));

      for (long src : sources) {
        sendMessage(new LongWritable(src), msg);
      }
    }

    // if our pointer didn't know who supervertex is, ask it again
    if (type == MSTVertexType.TYPE_UNKNOWN) {
      LongWritable ptr = new LongWritable(this.pointer);
      MSTMessage msg = new MSTMessage(MSTMsgType.MSG_QUESTION,
                                      new MSTMsgContentLong(getId()));
      sendMessage(ptr, msg);
    }

    // phase change occurs in compute()
  }

  /**
   * Phase 3A: notify neighbours of supervertex ID
   */
  private void phase3A() {
    // Reset aggregator counters in worker, to reduce contention.
    // NOTE: this is not thread-safe but reset is commutative,
    // so this is safe... but inefficient.
    aggregate(COUNTER_AGG, LongSumResetAggregator.RESET);
    aggregate(SUPERVERTEX_AGG, LongSumResetAggregator.RESET);

    // send our neighbours <my ID, my supervertex's ID>
    LongWritable ptr = new LongWritable(pointer);
    MSTMessage msg = new MSTMessage(MSTMsgType.MSG_CLEAN,
                         new MSTMsgContentLong(getId(), ptr));

    sendMessageToAllEdges(msg);

    this.phase = MSTPhase.PHASE_3B;
  }

  /**
   * Phase 3B: receive supervertex ID messages
   *
   * @param messages Incoming messages
   */
  private void phase3B(Iterable<MSTMessage> messages) {
    // receive messages from PHASE_3A
    for (MSTMessage message : messages) {
      switch(message.getType()) {
      case MSG_CLEAN:
        long senderId = message.getValue().getFirst().get();
        long supervertexId = message.getValue().getSecond().get();

        // If supervertices are same, then we are in the same component,
        // so delete our outgoing edge to v (i.e., delete (u,v)).
        //
        // Note that v will delete edge (v, u).
        if (supervertexId == this.pointer) {
          removeEdges(new LongWritable(senderId));
        } else {
          // Otherwise, delete edge (u,v) and add edge (u, v's supervertex).
          // In phase 4, this will become (u's supervertex, v's supervertex)
          MSTEdgeValue val = getEdgeValue(new LongWritable(senderId));
          if (val == null) {
            LOG.error("Invalid (null) edge value in PHASE_3B.");
          }

          removeEdges(new LongWritable(senderId));

          addEdge(EdgeFactory.create(new LongWritable(supervertexId), val));
        }
        break;

      default:
        LOG.error("Invalid message type in PHASE_3B.");
      }
    }

    // supervertices also go to phase 4A (b/c they need to wait for msgs)
    this.phase = MSTPhase.PHASE_4A;
  }

  /**
   * Phase 4A: send adjacency list to supervertex
   */
  private void phase4A() {
    // send all of my edges to my supervertex
    if (type != MSTVertexType.TYPE_SUPERVERTEX) {
      LongWritable ptr = new LongWritable(pointer);
      MSTMessage msg = new MSTMessage(MSTMsgType.MSG_EDGES,
                                      new MSTMsgContentEdges(getEdges()));
      sendMessage(ptr, msg);
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
    Map<LongWritable, MSTEdgeValue> edgeMap =
      new HashMap<LongWritable, MSTEdgeValue>();

    // get existing edges and move them to map
    // using Iterator's remove() is dangerous here, so just use two for loops
    for (Edge<LongWritable, MSTEdgeValue> e : getEdges()) {
      edgeMap.put(e.getTargetVertexId(), e.getValue());
    }
    for (LongWritable key : edgeMap.keySet()) {
      removeEdges(key);
    }

    // receive messages from PHASE_4B
    for (MSTMessage message : messages) {
      switch(message.getType()) {
      case MSG_EDGES:
        Iterable<Edge<LongWritable, MSTEdgeValue>> edges =
          message.getValue().getEdges();

        // merge children's edges (and our edges),
        // by picking ones with minimum weight
        for (Edge<LongWritable, MSTEdgeValue> e : edges) {
          LongWritable eId = e.getTargetVertexId();
          MSTEdgeValue eVal = e.getValue();

          MSTEdgeValue eValExisting = edgeMap.get(eId);

          // if out edge to eId exists, choose one w/ min weight
          // (this check is not same as containsKey(), but edge
          //  values should never be null)
          if (eValExisting != null) {
            if (eVal.getWeight().get() < eValExisting.getWeight().get()) {
              edgeMap.put(eId, eVal);
            }
          } else {
            // otherwise, just add it
            edgeMap.put(eId, eVal);
          }
        }

        break;

      default:
        LOG.error("Invalid message type in PHASE_4B.");
      }
    }

    // add back all the edges
    for (Map.Entry<LongWritable, MSTEdgeValue> entry : edgeMap.entrySet()) {
      addEdge(EdgeFactory.create(entry.getKey(), entry.getValue()));
    }

    // all that's left now is a graph w/ supervertices
    // its children NO LONGER participate in MST

    // back to phase 1
    this.phase = MSTPhase.PHASE_1;
  }

  /******************** MASTER/WORKER/MISC CLASSES ********************/

//  /**
//   * Worker context used with {@link MinimumSpanningTreeVertex}.
//   */
//  public static class MinimumSpanningTreeWorkerContext extends
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
//    public void preSuperstep() { }
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
      registerPersistentAggregator(COUNTER_AGG, LongSumResetAggregator.class);
      registerPersistentAggregator(SUPERVERTEX_AGG,
                                   LongSumResetAggregator.class);
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
    private DoubleWritable weight; /** edge weight **/
    private LongWritable src;      /** original edge source **/
    private LongWritable dst;      /** original edge destination **/

    /**
     * Default edge constructor.
     */
    public MSTEdgeValue() {
    }

    /**
     * Edge constructor.
     *
     * @param weight Weight.
     * @param src Original source vertex.
     * @param dst Original destination vertex.
     */
    public MSTEdgeValue(DoubleWritable weight,
                        LongWritable src, LongWritable dst) {
      this.weight = weight;
      this.src = src;
      this.dst = dst;
    }

    public DoubleWritable getWeight() {
      return weight;
    }

    public LongWritable getSrc() {
      return src;
    }

    public LongWritable getDst() {
      return dst;
    }

    @Override
    public void readFields(DataInput in) throws IOException {
      weight = new DoubleWritable();
      src = new LongWritable();
      dst = new LongWritable();

      weight.readFields(in);
      src.readFields(in);
      dst.readFields(in);
    }

    @Override
    public void write(DataOutput out) throws IOException {
      weight.write(out);
      src.write(out);
      dst.write(out);
    }

    @Override
    public String toString() {
      return "weight: " + weight.toString() +
        " src: " + src.toString() + " dst: " + dst.toString();
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
    /** private variables. what else can I say? **/
    private MSTMsgType type;       /** message type **/
    private MSTMsgContent value;   /** message content/value **/

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
      type = MSTMsgType.MSG_QUESTION;    // temporary value
      type.readFields(in);

      switch(type) {
      case MSG_EDGES:
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
      return "type: " + type.toString() + " " + value.toString();
    }
  }

  /**
   * Enum for possible message types.
   */
  public static enum MSTMsgType implements Writable {
    // values here are passed to constructor when
    // the corresponding constant is created
    /** enum constants **/
    MSG_QUESTION(0), /**/
    MSG_ANSWER(1),   /**/
    MSG_CLEAN(2),    /**/
    MSG_EDGES(3);    /**/

    /** A. Type. Why does this even warrant a comment? **/
    private int type;

    /**
     * Enum constructor.
     *
     * @param type A type, duh.
     */
    MSTMsgType(int type) {
      this.type = type;
    }

    @Override
    public void readFields(DataInput in) throws IOException {
      type = in.readInt();
    }

    @Override
    public void write(DataOutput out) throws IOException {
      out.writeInt(type);
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
    LongWritable getFirst();

    /**
     * Get second field of message content.
     *
     * @return Second field of message
     */
    LongWritable getSecond();

    /**
     * Get the edges from the message content.
     *
     * @return Edges stored in message
     */
    Iterable<Edge<LongWritable, MSTEdgeValue>> getEdges();
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
    private LongWritable first;

    /**
     * Second field is different depending on message type.
     *   MSG_QUESTION: N/A
     *   MSG_ANSWER:   true (1) or false (0)
     *   MSG_CLEAN:    supervertex ID (of source vertex)
     */
    private LongWritable second;

    /**
     * Default constructor.
     */
    public MSTMsgContentLong() {
    }

    /**
     * Constructor for MSG_QUESTION, which does not require second field.
     *
     * @param first First and only field.
     */
    public MSTMsgContentLong(LongWritable first) {
      this.first = first;
      this.second = null;
    }

    /**
     * Constructor for all message types except MSG_QUESTION, MSG_EDGES.
     *
     * @param first First field.
     * @param second Second field.
     */
    public MSTMsgContentLong(LongWritable first, LongWritable second) {
      this.first = first;
      this.second = second;
    }

    public LongWritable getFirst() {
      return first;
    }

    public LongWritable getSecond() {
      return second;
    }

    /**
     * Irrelevant for this type of message.
     *
     * @return null
     */
    public Iterable<Edge<LongWritable, MSTEdgeValue>> getEdges() {
      return null;
    }

    @Override
    public void readFields(DataInput in) throws IOException {
      first = new LongWritable();
      second = new LongWritable();

      first.readFields(in);
      second.readFields(in);
    }

    @Override
    public void write(DataOutput out) throws IOException {
      first.write(out);
      second.write(out);
    }

    @Override
    public String toString() {
      return "first: " + first.toString() + " second: " + second.toString();
    }
  }

  /**
   * Message value class for MSG_EDGES.
   */
  public static class MSTMsgContentEdges implements MSTMsgContent {
    /**
     * Only used for MSG_EDGES message type
     */
    private Iterable<Edge<LongWritable, MSTEdgeValue>> edges;

    /**
     * Default constructor.
     */
    public MSTMsgContentEdges() {
    }

    /**
     * Constructor taking in edges.
     *
     * @param edges Edges.
     */
    public MSTMsgContentEdges(Iterable<Edge<LongWritable, MSTEdgeValue>>
                              edges) {
      this.edges = edges;
    }

    /**
     * Irrelevant for this type of message.
     *
     * @return null
     */
    public LongWritable getFirst() {
      return null;
    }

    /**
     * Irrelevant for this type of message.
     *
     * @return null
     */
    public LongWritable getSecond() {
      return null;
    }

    public Iterable<Edge<LongWritable, MSTEdgeValue>> getEdges() {
      return edges;
    }

    @Override
    public void readFields(DataInput in) throws IOException {
      int numEdges = in.readInt();

      //Collection<Edge<I,E>> edgeCollection;

      for (int i = 0; i < numEdges; i++) {
        break;
        // use EdgeFactory to instantiate an edge??
        //        Edge<LongWritable,MSTEdgeValue> edge = new Edge<I,E>();
        //        edge.readFields(in);
        // TODO add to collection and store iterable
      }
    }

    @Override
    public void write(DataOutput out) throws IOException {
      // TODO: write size??
      int numEdges = 0;
      out.writeInt(numEdges);

      for (Edge<LongWritable, MSTEdgeValue> edge : edges) {
        edge.getTargetVertexId().write(out);
        edge.getValue().write(out);
      }
    }
  }
}

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

import java.io.DataOutput;
import java.io.DataInput;
import java.io.IOException;
import java.util.Arrays;
import org.apache.giraph.graph.Vertex;
import org.apache.giraph.io.formats.TextVertexOutputFormat;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.io.Writable;
import org.apache.hadoop.mapreduce.TaskAttemptContext;
import org.apache.log4j.Logger;

/**
 * Demonstrates the Flajolet-Martin diameter estimation algorithm.
 *
 * See Algorithm 1 of "HADI: Mining Radii of Large Graphs" by Kang et al.
 * <http://math.cmu.edu/~ctsourak/tkdd10.pdf>
 *
 * Output contains enough information to estimate local radii and diameter.
 */
@Algorithm(
    name = "Diameter estimation"
)
public class DiameterEstimationVertex extends Vertex<LongWritable,
    DiameterEstimationVertex.LongArrayWritable, NullWritable,
    DiameterEstimationVertex.LongArrayWritable> {

  /** Number of supersteps for this test */
  public static final int MAX_SUPERSTEPS = 30;

  /** K is number of bitstrings to use,
      larger K = more concentrated estimate **/
  public static final int K = 32;

  /** Logger */
  private static final Logger LOG =
      Logger.getLogger(DiameterEstimationVertex.class);

  /** Bit shift constant **/
  private static final long V62 = 62;
  /** Bit shift constant **/
  private static final long V1 = 1;

  @Override
  public void compute(Iterable<LongArrayWritable> messages) {
    // initialization
    if (getSuperstep() == 0) {
      long[] value = new long[K];
      int finalBitCount = 63;
      long rndVal = 0;

      for (int j = 0; j < value.length; j++) {
        rndVal = createRandomBM(finalBitCount);
        value[j] = V1 << (V62 - rndVal);
      }

      LongArrayWritable arr = new LongArrayWritable(value);
      sendMessageToAllEdges(arr);
      setValue(arr);

      //LOG.info(getId() + ": setting initial value to " + arr);
      return;
    }

    //LOG.info(getId() + ": initial value " + getValue());

    // get direct reference to vertex value's array
    long[] newBitmask = getValue().get();

    boolean isChanged = false;
    long[] tmpBitmask;
    long tmp;

    for (LongArrayWritable message : messages) {
      //LOG.info(getId() + ": got a message " + message);
      tmpBitmask = message.get();

      // both arrays are of length K
      for (int i = 0; i < K; i++) {
        tmp = newBitmask[i];      // store old value

        // NOTE: this modifies vertex value directly
        newBitmask[i] = newBitmask[i] | tmpBitmask[i];

        // check if there's a change
        isChanged = isChanged || (tmp != newBitmask[i]);
      }
    }

    //LOG.info(getId() + ": final value: " + getValue());

    // if steady state or max supersteps met, terminate
    if (!isChanged || (getSuperstep() >= MAX_SUPERSTEPS)) {
      //LOG.info(getId() + ": voting to halt");
      voteToHalt();

    } else {
      // otherwise, send our neighbours our bitstrings
      //LOG.info(getId() + ": not halting... sending messages");
      sendMessageToAllEdges(getValue());
    }
  }

  // Source: Mizan, which took this from Pegasus
  /**
   * Creates random bitstring.
   *
   * @param sizeBitmask Number of bits.
   * @return Random bit index.
   */
  private int createRandomBM(int sizeBitmask) {
    int j;

    // random() gives double in [0,1)---just like in Mizan
    // NOTE: we use the default seed set by java.util.Random()
    double curRandom = Math.random();
    double threshold = 0;

    for (j = 0; j < sizeBitmask - 1; j++) {
      threshold += Math.pow(2.0, -1.0 * j - 1.0);

      if (curRandom < threshold) {
        break;
      }
    }

    return j;
  }

  /**
   * Simple VertexOutputFormat that supports {@link DiameterEstimationVertex}
   */
  public static class DiameterEstimationVertexOutputFormat extends
      TextVertexOutputFormat<LongWritable,
        DiameterEstimationVertex.LongArrayWritable, NullWritable> {
    @Override
    public TextVertexWriter createVertexWriter(TaskAttemptContext context)
      throws IOException, InterruptedException {
      return new DiameterEstimationVertexWriter();
    }

    /**
     * Simple VertexWriter that supports {@link DiameterEstimationVertex}
     */
    public class DiameterEstimationVertexWriter extends TextVertexWriter {
      @Override
      public void writeVertex(
          Vertex<LongWritable, DiameterEstimationVertex.LongArrayWritable,
          NullWritable, ?> vertex)
        throws IOException, InterruptedException {
        getRecordWriter().write(
            new Text(vertex.getId().toString()),
            new Text(vertex.getValue().toString()));
      }
    }
  }

  /**
   * Vertex value and message type used by {@link DiameterEstimationVertex}.
   */
  public static class LongArrayWritable implements Writable {
    // NOTE: it's just easier to write our own, rather than
    // extending ArrayWritable and dealing with Writable elements

    /** The array of longs. **/
    private long[] array;

    /**
     * Default constructor.
     */
    public LongArrayWritable() {
      array = new long[0];
    }

    /**
     * Array constructor. Does not deep copy.
     *
     * @param array Array of longs, of length K.
     */
    public LongArrayWritable(long[] array) {
      this.array = array;
    }

    /**
     * Setter that does not deep copy.
     *
     * @param array Array.
     */
    public void set(long[] array) { this.array = array; }

    /**
     * Getter.
     *
     * @return Array.
     */
    public long[] get() { return array; }

    @Override
    public void readFields(DataInput in) throws IOException {
      array = new long[in.readInt()];
      for (int i = 0; i < array.length; i++) {
        array[i] = in.readLong();
      }
    }

    @Override
    public void write(DataOutput out) throws IOException {
      out.writeInt(array.length);
      for (int i = 0; i < array.length; i++) {
        out.writeLong(array[i]);
      }
    }

    @Override
    public String toString() {
      return Arrays.toString(array);
    }

    // Not actually needed, but implemented anyway
    @Override
    public boolean equals(Object o) {
      if (this == o) { return true; }
      if (!(o instanceof LongArrayWritable)) { return false; }

      LongArrayWritable rhs = (LongArrayWritable) o;
      return Arrays.equals(this.array, rhs.array);
    }

    @Override
    public int hashCode() {
      return Arrays.hashCode(array);
    }
  }
}

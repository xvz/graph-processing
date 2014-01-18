package gps.examples.dimest;

import org.apache.commons.cli.CommandLine;

import gps.graph.NullEdgeVertex;
import gps.graph.NullEdgeVertexFactory;
import gps.node.GPSJobConfiguration;
import gps.node.GPSNodeRunner;
import gps.writable.LongArrayWritable;


import java.util.Arrays;


/**
 * GPS implementation of Flajolet-Martin diameter estimation.
 *
 * @author Young
 */
public class DiameterEstimationVertex extends NullEdgeVertex<LongArrayWritable, LongArrayWritable> {

  public static int DEFAULT_NUM_MAX_ITERATIONS = 100;
  public static int numMaxIterations;

  /** K is number of bitstrings to use,
      larger K = more concentrated estimate **/
  public static final int K = 32;

  /** Bit shift constant **/
  private static final int V62 = 62;
  /** Bit shift constant **/
  private static final int V1 = 1;

  public DiameterEstimationVertex(CommandLine line) {
    String otherOptsStr = line.getOptionValue(GPSNodeRunner.OTHER_OPTS_OPT_NAME);
    System.out.println("otherOptsStr: " + otherOptsStr);
    numMaxIterations = DEFAULT_NUM_MAX_ITERATIONS;
    if (otherOptsStr != null) {
      String[] split = otherOptsStr.split("###");
      for (int index = 0; index < split.length; ) {
        String flag = split[index++];
        String value = split[index++];
        if ("-max".equals(flag)) {
          numMaxIterations = Integer.parseInt(value);
          System.out.println("numMaxIterations: " + numMaxIterations);
        }
      }
    }
  }

  @Override
  public void compute(Iterable<LongArrayWritable> incomingMessages, int superstepNo) {
    if (superstepNo == 1) {
      long[] value = new long[K];
      int finalBitCount = 63;
      long rndVal = 0;

      for (int j = 0; j < value.length; j++) {
        rndVal = createRandomBM(finalBitCount);
        value[j] = V1 << (V62 - rndVal);
      }

      LongArrayWritable arr = new LongArrayWritable(value);
      sendMessages(getNeighborIds(), arr);
      setValue(arr);

      //System.out.println(getId() + ": done superstep 1... " + getValue());
      return;
    }

    //System.out.println(getId() + ": normal superstep... " + getValue());

    // get direct reference to vertex value's array
    long[] newBitmask = getValue().get();

    // Some vertices have in-edges but no out-edges, so they're NOT
    // listed in the input graphs (from SNAP). This causes a new
    // vertex to be added during the 2nd superstep, and its value
    // to be non-initialized (i.e., empty array []). Since such
    // vertices have no out-edges, we can just halt.
    if (newBitmask.length == 0) {
      voteToHalt();
      return;
    }

    boolean isChanged = false;
    long[] tmpBitmask;
    long tmp;

    for (LongArrayWritable message : incomingMessages) {
      tmpBitmask = message.get();
      
//      if (tmpBitmask.length == 0) {
//        System.out.println(getId() + ": got empty message??");
//      } else {
//        System.out.println(getId() + ": got " + message);
//      }

      // both arrays are of length K
      for (int i = 0; i < K; i++) {
        tmp = newBitmask[i];      // store old value

        // NOTE: this modifies vertex value directly
        newBitmask[i] = newBitmask[i] | tmpBitmask[i];

        // check if there's a change
        isChanged = isChanged || (tmp != newBitmask[i]);
      }
    }

    //System.out.println(getId() + ": final array is " + getValue());

    // if steady state or max supersteps met, terminate
    if (!isChanged || (superstepNo >= numMaxIterations)) {
      //System.out.println(getId() + ": voting to halt");
      voteToHalt();

    } else {
      //System.out.println(getId() + ": not halting... sending message");

      // otherwise, send our neighbours our bitstrings
      sendMessages(getNeighborIds(), getValue());
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

  @Override
  public LongArrayWritable getInitialValue(int id) {
    return new LongArrayWritable();
  }

  /**
   * Factory class for {@link DiameterEstimationVertex}.
   *
   * @author Young
   */
  public static class DiameterEstimationVertexFactory extends NullEdgeVertexFactory<LongArrayWritable, LongArrayWritable> {

    @Override
    public NullEdgeVertex<LongArrayWritable, LongArrayWritable> newInstance(CommandLine commandLine) {
      return new DiameterEstimationVertex(commandLine);
    }
  }

  public static class JobConfiguration extends GPSJobConfiguration {

    @Override
    public Class<?> getVertexFactoryClass() {
      return DiameterEstimationVertexFactory.class;
    }

    @Override
    public Class<?> getVertexClass() {
      return DiameterEstimationVertex.class;
    }

    @Override
    public Class<?> getVertexValueClass() {
      return LongArrayWritable.class;
    }

    @Override
    public Class<?> getMessageValueClass() {
      return LongArrayWritable.class;
    }
  }
}

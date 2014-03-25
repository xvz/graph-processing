package gps.examples.pagerank;

import org.apache.commons.cli.CommandLine;

import gps.globalobjects.BooleanANDGlobalObject;
import gps.globalobjects.DoubleMaxGlobalObject;
import gps.globalobjects.DoubleSumGlobalObject;
import gps.globalobjects.FloatSumGlobalObject;
import gps.globalobjects.GlobalObjectsMap;
import gps.globalobjects.IntMaxGlobalObject;
import gps.globalobjects.IntSumGlobalObject;
import gps.globalobjects.LongSumGlobalObject;
import gps.graph.NullEdgeVertex;
import gps.graph.NullEdgeVertexFactory;
import gps.node.GPSJobConfiguration;
import gps.node.GPSNodeRunner;
import gps.writable.DoubleWritable;

/**
 * GPS implementation of PageRank algorithm.
 *
 * @author semihsalihoglu
 */
public class PageRankVertex extends NullEdgeVertex<DoubleWritable, DoubleWritable> {

  public static int DEFAULT_NUM_MAX_ITERATIONS = 30;
  public static int numMaxIterations;

  public PageRankVertex(CommandLine line) {
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
  public void compute(Iterable<DoubleWritable> incomingMessages, int superstepNo) {
    // NOTE: We follow GraphLab's alternative way of computing PageRank,
    // which is to not divide by |V|. To get the probability value at
    // each vertex, take its PageRank value and divide by |V|.

    //int numVertices = ((IntSumGlobalObject) getGlobalObjectsMap().getGlobalObject(
    //  GlobalObjectsMap.NUM_TOTAL_VERTICES)).getValue().getValue();

    if (superstepNo == 1) {
      setValue(new DoubleWritable(1.0));
      //setValue(new DoubleWritable((double) 1 / (double) numVertices));
      sendMessages(getNeighborIds(), getValue());
      return;
    }

    double oldVal = getValue().getValue();
    double sum = 0.0;
    for (DoubleWritable messageValue : incomingMessages) {
      sum += messageValue.getValue();
    }

    double currentState = 0.85 * sum  + 0.15;
    //double currentState = 0.85 * sum/getNeighborIds().length  + 0.15 / (double) numVertices;

    setValue(new DoubleWritable(currentState));

    // Termination condition based on max supersteps
    int[] neighborIds = getNeighborIds();
    // FIX: divide by sender's out-degree rather than receiver's out-degree
    // (i.e., don't do "currentState = 0.85 * sum / neighborIds.length + ...")
    DoubleWritable messageValue = new DoubleWritable(currentState / neighborIds.length);
    sendMessages(neighborIds, messageValue);
    
    if (superstepNo == numMaxIterations) {
      voteToHalt();
    }
  }

  @Override
  public DoubleWritable getInitialValue(int id) {
    return new DoubleWritable(0.1);
  }

  /**
   * Factory class for {@link PageRankVertex}.
   *
   * @author semihsalihoglu
   */
  public static class PageRankVertexFactory extends NullEdgeVertexFactory<DoubleWritable, DoubleWritable> {

    @Override
    public NullEdgeVertex<DoubleWritable, DoubleWritable> newInstance(CommandLine commandLine) {
      return new PageRankVertex(commandLine);
    }
  }

  public static class JobConfiguration extends GPSJobConfiguration {

    @Override
    public Class<?> getVertexFactoryClass() {
      return PageRankVertexFactory.class;
    }

    @Override
    public Class<?> getVertexClass() {
      return PageRankVertex.class;
    }

    @Override
    public Class<?> getVertexValueClass() {
      return DoubleWritable.class;
    }

    @Override
    public Class<?> getMessageValueClass() {
      return DoubleWritable.class;
    }
  }
}

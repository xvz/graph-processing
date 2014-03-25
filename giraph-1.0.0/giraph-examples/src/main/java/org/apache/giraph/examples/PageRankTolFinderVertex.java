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

import java.io.IOException;
import org.apache.giraph.conf.IntConfOption;
import org.apache.giraph.aggregators.DoubleMaxAggregator;
import org.apache.giraph.graph.Vertex;
import org.apache.giraph.io.formats.TextVertexOutputFormat;
import org.apache.giraph.master.DefaultMasterCompute;
import org.apache.hadoop.io.DoubleWritable;
import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.io.LongWritable;
//import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.TaskAttemptContext;
import org.apache.log4j.Logger;

/**
 * PageRank implementation that finds when the maximum error deltas
 * (between two supersteps) "plateaus".
 *
 * In other words, think of a plot of error-delta vs. superstep-number.
 * The goal is to determine when the function flattens out---this is
 * roughly where we should stop, as additional supersteps won't get
 * us any better of a convergence.
 *
 * As this "break even" point is different for different graphs, this
 * function helps determine what tolerance value should be used.
 */
@Algorithm(
    name = "PageRank Tolerance Finder"
)
public class PageRankTolFinderVertex extends Vertex<LongWritable,
    DoubleWritable, NullWritable, DoubleWritable> {
  /** Max number of supersteps */
  public static final IntConfOption MAX_SUPERSTEPS =
    new IntConfOption("PageRankTolFinderVertex.maxSS", 100);

  /** Logger */
  private static final Logger LOG =
      Logger.getLogger(PageRankTolFinderVertex.class);

  /** Max aggregator name */
  private static String MAX_AGG = "max";

  @Override
  public void compute(Iterable<DoubleWritable> messages) {
    // NOTE: We follow GraphLab's alternative way of computing PageRank,
    // which is to not divide by |V|. To get the probability value at
    // each vertex, take its PageRank value and divide by |V|.

    double oldVal = getValue().get();

    if (getSuperstep() == 0) {
      // FIX: initial value is 1/|V| (or 1), not 0.15/|V| (or 0.15)
      DoubleWritable vertexValue = new DoubleWritable(1.0);
      //new DoubleWritable(0.15f / getTotalNumVertices());
      setValue(vertexValue);

    } else {
      double sum = 0;
      for (DoubleWritable message : messages) {
        sum += message.get();
      }
      DoubleWritable vertexValue = new DoubleWritable(0.15f + 0.85f * sum);
      //new DoubleWritable((0.15f / getTotalNumVertices()) + 0.85f * sum);
      setValue(vertexValue);
    }

    aggregate(MAX_AGG,
              new DoubleWritable(Math.abs(oldVal - getValue().get())));

    // Termination condition based on max supersteps
    if (getSuperstep() < MAX_SUPERSTEPS.get(getConf())) {
      long edges = getNumEdges();
      sendMessageToAllEdges(new DoubleWritable(getValue().get() / edges));
    } else {
      voteToHalt();
    }
  }

  /**
   * Master compute associated with {@link PageRankTolFinderVertex}.
   * It registers required aggregators.
   */
  public static class PageRankTolFinderVertexMasterCompute extends
      DefaultMasterCompute {
    @Override
    public void initialize() throws InstantiationException,
        IllegalAccessException {
      registerAggregator(MAX_AGG, DoubleMaxAggregator.class);
    }

    @Override
    public void compute() {
      // this is result of aggregators from the *previous* superstep
      if (getSuperstep() > 0) {
        LOG.info("SS " + (getSuperstep() - 1) + " max change: " +
                 ((DoubleWritable) getAggregatedValue(MAX_AGG)).get());
      }
    }
  }

  /**
   * Simple VertexOutputFormat that supports {@link PageRankTolFinderVertex}
   */
  public static class PageRankTolFinderVertexOutputFormat extends
      TextVertexOutputFormat<LongWritable, DoubleWritable, NullWritable> {
    @Override
    public TextVertexWriter createVertexWriter(TaskAttemptContext context)
      throws IOException, InterruptedException {
      return new PageRankTolFinderVertexWriter();
    }

    /**
     * Simple VertexWriter that supports {@link PageRankTolFinderVertex}
     */
    public class PageRankTolFinderVertexWriter extends TextVertexWriter {
      @Override
      public void writeVertex(
          Vertex<LongWritable, DoubleWritable, NullWritable, ?> vertex)
        throws IOException, InterruptedException {
        // don't need to output anything---we don't care about results
        //getRecordWriter().write(
        //    new Text(vertex.getId().toString()),
        //    new Text(vertex.getValue().toString()));
      }
    }
  }
}

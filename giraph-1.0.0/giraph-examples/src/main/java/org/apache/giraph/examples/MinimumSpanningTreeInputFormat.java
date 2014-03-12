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

import com.google.common.collect.Lists;
import org.apache.giraph.edge.Edge;
import org.apache.giraph.edge.EdgeFactory;
import org.apache.hadoop.io.LongWritable;
import org.apache.giraph.examples.MinimumSpanningTreeVertex.MSTVertexValue;
import org.apache.giraph.examples.MinimumSpanningTreeVertex.MSTEdgeValue;
import org.apache.hadoop.io.Text;
import org.apache.giraph.io.formats.TextVertexInputFormat;
import org.apache.hadoop.mapreduce.InputSplit;
import org.apache.hadoop.mapreduce.TaskAttemptContext;

import java.io.IOException;
import java.util.List;
import java.util.regex.Pattern;

/**
 * Simple text-based {@link org.apache.giraph.io.VertexInputFormat} for
 * {@link org.apache.giraph.examples.MinimumSpanningTreeVertex}.
 *
 * Inputs have long ids, double edge weights, and no vertex values.
 *
 * Each line consists of:
 * vertex neighbor1 neighbor1-weight neighbor2 neighbor2-weight ...
 *
 * Values can be separated by spaces or tabs.
 */
public class MinimumSpanningTreeInputFormat extends
    TextVertexInputFormat<LongWritable, MSTVertexValue, MSTEdgeValue> {
  /** Separator of the vertex and neighbors */
  private static final Pattern SEPARATOR = Pattern.compile("[\t ]");

  @Override
  public TextVertexReader createVertexReader(InputSplit split,
      TaskAttemptContext context)
    throws IOException {
    return new MinimumSpanningTreeVertexReader();
  }

  /**
   * Vertex reader associated with {@link MinimumSpanningTreeInputFormat}.
   */
  public class MinimumSpanningTreeVertexReader extends
    TextVertexReaderFromEachLineProcessed<String[]> {
    /**
     * Cached vertex id for the current line
     */
    private LongWritable id;

    @Override
    protected String[] preprocessLine(Text line) throws IOException {
      String[] tokens = SEPARATOR.split(line.toString());
      id = new LongWritable(Long.parseLong(tokens[0]));
      return tokens;
    }

    @Override
    protected LongWritable getId(String[] tokens) throws IOException {
      return id;
    }

    @Override
    protected MSTVertexValue getValue(String[] tokens) throws IOException {
      // ignore tokens and return dummy MSTVertexValue
      // (this will be replaced during computation)
      return new MSTVertexValue();
    }

    @Override
    protected Iterable<Edge<LongWritable, MSTEdgeValue>> getEdges(
        String[] tokens) throws IOException {

      // divide by 2, to account for edge weights
      List<Edge<LongWritable, MSTEdgeValue>> edges =
          Lists.newArrayListWithCapacity((tokens.length - 1) / 2);

      long src = id.get();
      long dst;
      double weight;

      for (int i = 1; i < tokens.length - 1; i += 2) {
        dst = Long.parseLong(tokens[i]);
        weight = Double.parseDouble(tokens[i + 1]);

        edges.add(EdgeFactory.create(new LongWritable(dst),
                                     new MSTEdgeValue(weight, src, dst)));
      }

      return edges;
    }
  }
}

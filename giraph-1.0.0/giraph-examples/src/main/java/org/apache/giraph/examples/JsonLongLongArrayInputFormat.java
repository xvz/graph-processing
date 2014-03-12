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
import org.apache.giraph.graph.Vertex;
import org.apache.giraph.io.formats.TextVertexInputFormat;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.io.Text;
import org.apache.giraph.examples.DiameterEstimationVertex.LongArrayWritable;
import org.apache.hadoop.mapreduce.InputSplit;
import org.apache.hadoop.mapreduce.TaskAttemptContext;
import org.json.JSONArray;
import org.json.JSONException;

import java.io.IOException;
import java.util.List;

/**
 * ***DEPRECATED***
 * We no longer use Json format for input. Instead, we use simple
 * text input format. See the new DiameterEstimationInputFormat.
 * ***DEPRECATED***
 *
 * VertexInputFormat that reads in <code>long</code> vertex IDs,
 * <code>double</code> vertex values and <code>float</code>
 * out-edge weights, and <code>double</code> message types,
 * specified in JSON format. Output graph has <code>long</code>
 * vertex IDs, but dimest-specific vertex value, out-edge weight
 * and message types.
 */
public class JsonLongLongArrayInputFormat extends
  TextVertexInputFormat<LongWritable, LongArrayWritable, NullWritable> {

  @Override
  public TextVertexReader createVertexReader(InputSplit split,
      TaskAttemptContext context) {
    return new JsonLongLongArrayReader();
  }

 /**
  * VertexReader that features <code>LongArrayWritable</code> vertex
  * values and <code>NullWritable</code> out-edge weights. The
  * files should be in the following JSON format:
  * JSONArray(<vertex id>, <vertex value>,
  *   JSONArray(JSONArray(<dest vertex id>, <edge value>), ...))
  * Here is an example with vertex id 1, vertex value 4.3, and two edges.
  * First edge has a destination vertex 2, edge value 2.1.
  * Second edge has a destination vertex 3, edge value 0.7.
  * [1,4.3,[[2,2.1],[3,0.7]]]
  *
  * Vertex value and edge weights must be present but are ignored.
  */
  class JsonLongLongArrayReader extends
    TextVertexReaderFromEachLineProcessedHandlingExceptions<JSONArray,
    JSONException> {

    @Override
    protected JSONArray preprocessLine(Text line) throws JSONException {
      return new JSONArray(line.toString());
    }

    @Override
    protected LongWritable getId(JSONArray jsonVertex) throws JSONException,
              IOException {
      return new LongWritable(jsonVertex.getLong(0));
    }

    @Override
    protected LongArrayWritable getValue(JSONArray jsonVertex) throws
      JSONException, IOException {
      // ignore whatever is in jsonVertex, and return dummy LongArrayWritable
      // instead (this will be replaced during computation)
      return new LongArrayWritable();
    }

    @Override
    protected Iterable<Edge<LongWritable, NullWritable>> getEdges(
        JSONArray jsonVertex) throws JSONException, IOException {

      JSONArray jsonEdgeArray = jsonVertex.getJSONArray(2);
      List<Edge<LongWritable, NullWritable>> edges =
          Lists.newArrayListWithCapacity(jsonEdgeArray.length());

      long dst;

      for (int i = 0; i < jsonEdgeArray.length(); ++i) {
        JSONArray jsonEdge = jsonEdgeArray.getJSONArray(i);
        dst = jsonEdge.getLong(0);
        edges.add(EdgeFactory.create(new LongWritable(dst),
                                     NullWritable.get()));
      }
      return edges;
    }

    @Override
    protected Vertex<LongWritable, LongArrayWritable,
                     NullWritable, LongArrayWritable>
    handleException(Text line, JSONArray jsonVertex, JSONException e) {
      throw new IllegalArgumentException(
          "Couldn't get vertex from line " + line, e);
    }

  }
}

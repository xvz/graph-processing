package gps.examples.sssp;

import org.apache.commons.cli.CommandLine;

import gps.graph.NullEdgeVertex;
import gps.graph.NullEdgeVertexFactory;
import gps.node.GPSJobConfiguration;
import gps.node.GPSNodeRunner;
import gps.writable.IntWritable;

// NOTE: this is different from SingleSourceAllVerticesShortestPathVertex,
// in that we don't use the boolean shortcut method.
//
// Instead, this is a modification of gps.examples.edgevaluesssp.EdgeValueSSSPVertex,
// where edge values are all 1. This matches the implementations in Giraph and GPS.
public class SSSPVertex extends NullEdgeVertex<IntWritable, IntWritable> {

	private static int DEFAULT_SOURCE_ID = 0;
	private int sourceId;
	public SSSPVertex() {
	}
	
	public SSSPVertex(CommandLine line) {
		String otherOptsStr = line.getOptionValue(GPSNodeRunner.OTHER_OPTS_OPT_NAME);
		System.out.println("otherOptsStr: " + otherOptsStr);
		sourceId = DEFAULT_SOURCE_ID;
		if (otherOptsStr != null) {
			String[] split = otherOptsStr.split("###");
			for (int index = 0; index < split.length; ) {
				String flag = split[index++];
				String value = split[index++];
				if ("-root".equals(flag)) {
					sourceId = Integer.parseInt(value);
					System.out.println("sourceId: " + sourceId);
				}
			}
		}
	}

	@Override
	public void compute(Iterable<IntWritable> messageValues, int superstepNo) {
		int previousDistance = getValue().getValue();
		if (superstepNo == 1) {
			if (previousDistance == Integer.MAX_VALUE) {
				voteToHalt();
			} else {
				sendMessages(getNeighborIds(),
                     new IntWritable(getValue().getValue() + 1));
			}
		} else {
			int minValue = previousDistance;
			int messageValueInt;
			for (IntWritable messageValue : messageValues) {
				messageValueInt = messageValue.getValue();
				if (messageValueInt < minValue) {
					minValue = messageValueInt;
				}
			}
			int currentDistance = minValue;
			if (currentDistance < previousDistance) {
				IntWritable newState = new IntWritable(currentDistance);
				setValue(newState);
				sendMessages(getNeighborIds(),
                     new IntWritable(getValue().getValue() + 1));
			} else {
				voteToHalt();
			}
		}
	}

	@Override
	public IntWritable getInitialValue(int id) {
		return id == sourceId ? new IntWritable(0) : new IntWritable(Integer.MAX_VALUE);
	}

	/**
	 * Factory class for {@link SSSPVertex}.
	 * 
	 * @author semihsalihoglu
	 */
	public static class SSSPVertexFactory
		extends NullEdgeVertexFactory<IntWritable, IntWritable> {
 
		@Override
		public NullEdgeVertex<IntWritable, IntWritable> newInstance(CommandLine commandLine) {
			return new SSSPVertex(commandLine);
		}
	}
	
	public static class JobConfiguration extends GPSJobConfiguration {

		@Override
		public Class<?> getVertexFactoryClass() {
			return SSSPVertexFactory.class;
		}

		@Override
		public Class<?> getVertexClass() {
			return SSSPVertex.class;
		}

		@Override
		public Class<?> getVertexValueClass() {
			return IntWritable.class;
		}

		@Override
		public Class<?> getMessageValueClass() {
			return IntWritable.class;
		}
	}
}

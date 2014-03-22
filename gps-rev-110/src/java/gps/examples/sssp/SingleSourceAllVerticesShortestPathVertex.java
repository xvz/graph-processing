package gps.examples.sssp;

import org.apache.commons.cli.CommandLine;

import gps.graph.NullEdgeVertex;
import gps.graph.NullEdgeVertexFactory;
import gps.node.GPSJobConfiguration;
import gps.node.GPSNodeRunner;
import gps.writable.BooleanWritable;
import gps.writable.IntWritable;

public class SingleSourceAllVerticesShortestPathVertex extends NullEdgeVertex<IntWritable, BooleanWritable> {

	private static int DEFAULT_ROOT_ID = 0;
	private int root;
	protected boolean isFLPS = false;
	protected IntWritable numRecentlyUpdatedVertices;

	public SingleSourceAllVerticesShortestPathVertex(CommandLine line) {
		String otherOptsStr = line.getOptionValue(GPSNodeRunner.OTHER_OPTS_OPT_NAME);
		System.out.println("otherOptsStr: " + otherOptsStr);
		root = DEFAULT_ROOT_ID;
		if (otherOptsStr != null) {
			String[] split = otherOptsStr.split("###");
			for (int index = 0; index < split.length; ) {
				String flag = split[index++];
				String value = split[index++];
				if ("root".equals(flag)) {
					root = Integer.parseInt(value);
					System.out.println("sourceId: " + root);
				}
			}
		}
	}

	@Override
	public void compute(Iterable<BooleanWritable> messageValues, int superstepNo) {
		performRegularLabelPropagation(messageValues, superstepNo);
	}

	protected void performRegularLabelPropagation(Iterable<BooleanWritable> messageValues, int superstepNo) {
		int previousDistance = getValue().getValue();
		if (superstepNo == 1) {
			if (previousDistance == Integer.MAX_VALUE) {
				if (!isFLPS) {
					voteToHalt();
				}
			} else {
				sendMessages(getNeighborIds(), new BooleanWritable());
				if (isFLPS) {
					numRecentlyUpdatedVertices.value++;
					voteToHalt();
				}
			}
		} else {
			if (previousDistance != Integer.MAX_VALUE) {
				if (!isFLPS) {
					voteToHalt();
				}
			} else if (messageValues.iterator().hasNext()) {
        // BUGFIX: distance 1 will occur at superstep 2, so *subtract* 1
				setValue(new IntWritable(superstepNo - 1));
				sendMessages(getNeighborIds(), new BooleanWritable());
				if (isFLPS) {
					numRecentlyUpdatedVertices.value++;
					voteToHalt();
				}
			}
		}
	}

	@Override
	public IntWritable getInitialValue(int id) {
		return id == root ? new IntWritable(0) : new IntWritable(Integer.MAX_VALUE);
	}
	
	/**
	 * Factory class for {@link SingleSourceAllVerticesShortestPathVertex}.
	 * 
	 * @author semihsalihoglu
	 */
	public static class SingleSourceAllVerticesShortestPathVertexFactory extends NullEdgeVertexFactory<IntWritable, BooleanWritable> {

		@Override
		public NullEdgeVertex<IntWritable, BooleanWritable> newInstance(CommandLine commandLine) {
			return new SingleSourceAllVerticesShortestPathVertex(commandLine);
		}
	}

	public static class JobConfiguration extends GPSJobConfiguration {

		@Override
		public Class<?> getVertexFactoryClass() {
			return SingleSourceAllVerticesShortestPathVertexFactory.class;
		}

		@Override
		public Class<?> getVertexClass() {
			return SingleSourceAllVerticesShortestPathVertex.class;
		}

		@Override
		public Class<?> getVertexValueClass() {
			return IntWritable.class;
		}

		@Override
		public Class<?> getMessageValueClass() {
			return BooleanWritable.class;
		}
	}
}
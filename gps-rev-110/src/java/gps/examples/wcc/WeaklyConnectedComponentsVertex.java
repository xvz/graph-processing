package gps.examples.wcc;

import org.apache.commons.cli.CommandLine;

import gps.graph.NullEdgeVertex;
import gps.graph.NullEdgeVertexFactory;
import gps.node.GPSJobConfiguration;
import gps.node.GPSNodeRunner;
import gps.writable.IntWritable;

public class WeaklyConnectedComponentsVertex extends NullEdgeVertex<IntWritable, IntWritable>{

	private int minValue;
	//public static int DEFAULT_NUM_MAX_ITERATIONS = 999;
	public static int numMaxIterations;
	public WeaklyConnectedComponentsVertex(CommandLine line) {
		//String otherOptsStr = line.getOptionValue(GPSNodeRunner.OTHER_OPTS_OPT_NAME);
		//System.out.println("otherOptsStr: " + otherOptsStr);
		//numMaxIterations = DEFAULT_NUM_MAX_ITERATIONS;
		//if (otherOptsStr != null) {
		//  String[] split = otherOptsStr.split("###");
		//  for (int index = 0; index < split.length; ) {
		//  	String flag = split[index++];
		//  	String value = split[index++];
		//  	if ("-nmi".equals(flag)) {
		//  		numMaxIterations = Integer.parseInt(value);
		//  		System.out.println("numMaxIterations: " + numMaxIterations);
		//  	}
		//  }
		//}
	}
	@Override
	public void compute(Iterable<IntWritable> messageValues, int superstepNo) {
		if (superstepNo == 1) {
			setValue(new IntWritable(getId()));
			sendMessages(getNeighborIds(), getValue());
		} else {
			minValue = getValue().getValue();
			for (IntWritable message : messageValues) {
				if (message.getValue() < minValue) {
					minValue = message.getValue();
				}
			}
			if (minValue < getValue().getValue()) {
				setValue(new IntWritable(minValue));
				sendMessages(getNeighborIds(), getValue());
			} else {
				voteToHalt();
			}

      // No superstep termination conditions---run to completion instead
			//if (superstepNo == numMaxIterations) {
			//	voteToHalt();
			//}
		}
	}

	@Override
	public IntWritable getInitialValue(int id) {
		return new IntWritable(getId());
	}
	
	public static class WeaklyConnectedComponentsVertexFactory extends
		NullEdgeVertexFactory<IntWritable, IntWritable> {

		@Override
		public NullEdgeVertex<IntWritable, IntWritable> newInstance(CommandLine commandline) {
			return new WeaklyConnectedComponentsVertex(commandline);
		}
	}

	public static class JobConfiguration extends GPSJobConfiguration {

		@Override
		public Class<?> getVertexFactoryClass() {
			return WeaklyConnectedComponentsVertexFactory.class;
		}

		@Override
		public Class<?> getVertexClass() {
			return WeaklyConnectedComponentsVertex.class;
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

package gps.node.worker.dynamic.greedy;

import static gps.node.worker.GPSWorkerExposedGlobalVariables.*;
import gps.communication.MessageSenderAndReceiverFactory;
import gps.graph.Graph;
import gps.graph.VertexFactory;
import gps.messages.storage.ArrayBackedIncomingMessageStorage;
import gps.node.GPSJobConfiguration;
import gps.node.MachineConfig;
import gps.node.worker.AbstractGPSWorker;
import gps.writable.MinaWritable;
import gps.writable.NullWritable;

import org.apache.commons.cli.CommandLine;
import org.apache.hadoop.fs.FileSystem;

public abstract class BaseGreedyDynamicGPSWorkerImpl<V extends MinaWritable,
	E extends MinaWritable, M extends MinaWritable> extends AbstractGPSWorker<V, E, M> {

	public static int[] machineCommunicationHistogram;
	protected boolean[] fasterMachines;
	protected final int edgeThreshold;
	protected int benefitThreshold;
	protected int superstepNoToStopDynamism;

	public BaseGreedyDynamicGPSWorkerImpl(int localMachineId, CommandLine commandLine,
		FileSystem fileSystem, MachineConfig machineConfig, Graph<V, E> graphPartition,
		VertexFactory<V, E, M> vertexFactory, int graphSize, int outgoingBufferSizes,
		String outputFileName, MessageSenderAndReceiverFactory messageSenderAndReceiverFactory,
		ArrayBackedIncomingMessageStorage<M> incomingMessageStorage, int benefitThreshold,
		int edgeThreshold, long pollingTime, int maxMessagesToTransmitConcurrently,
		int numVerticesFrequencyToCheckOutgoingBuffers,
		int sleepTimeWhenOutgoingBuffersExceedThreshold,
		int largeVertexPartitioningOutdegreeThreshold, boolean runPartitioningSuperstep,
		boolean combine, Class<M> messageRepresentativeInstance,
		Class<E> representativeEdgeInstance, GPSJobConfiguration jobConfiguration,
		int numProcessorsForHandlingIO, int superstepNoToStopDynamism) {
		super(localMachineId, commandLine, fileSystem, machineConfig, graphPartition, vertexFactory,
			graphSize, outgoingBufferSizes, outputFileName, messageSenderAndReceiverFactory,
			incomingMessageStorage, pollingTime, maxMessagesToTransmitConcurrently,
			numVerticesFrequencyToCheckOutgoingBuffers,
			sleepTimeWhenOutgoingBuffersExceedThreshold, largeVertexPartitioningOutdegreeThreshold,
			runPartitioningSuperstep, combine, messageRepresentativeInstance,
			representativeEdgeInstance, jobConfiguration, numProcessorsForHandlingIO);
		this.benefitThreshold = benefitThreshold;
		this.edgeThreshold = edgeThreshold;
		machineCommunicationHistogram = new int[getNumWorkers()];
//		incomingMessageStorage.setMachineCommunicationHistogram(machineCommunicationHistogram);
		fasterMachines = new boolean[getNumWorkers()];
		this.superstepNoToStopDynamism = superstepNoToStopDynamism;
	}

	@Override
	protected void doExtraWorkBeforeVertexComputation() {
		if (currentSuperstepNo > superstepNoToStopDynamism) {
			return;
		}
		machineCommunicationHistogram = new int[getNumWorkers()];
//		System.out.println("Starting to dump machineCommunicationHistogram...");
//		for (int i = 0; i < getNumWorkers(); ++i) {
//			getLogger().info("" + machineCommunicationHistogram[i]);
//		}
//		System.out.println("End of dumping machineCommunicationHistogram...");
//		for (int i = 0; i < getNumWorkers(); ++i) {
//			machineCommunicationHistogram[i] = 0;
//		}
	}
//
//	protected Byte putVertexIntoVerticesToMoveIfMaxCommunicationMachineIsNotLocalMachine(
//		int nodeId, Map<Integer, Byte> vertexIdMachineIdMap) {
//		byte maxCommunicationMachineId = findIdOfMaxCommunicatedMachine();
//		if (maxCommunicationMachineId != getLocalMachineId()
//			&& machineCommunicationHistogram[maxCommunicationMachineId]
//			  >= (machineCommunicationHistogram[getLocalMachineId()] + benefitThreshold)) {
//			vertexIdMachineIdMap.put(nodeId, maxCommunicationMachineId);
//			return maxCommunicationMachineId;
//		} else {
//			return null;
//		}
//	}

	protected byte findIdOfMaxCommunicatedMachine() {
//		System.out.println("Finding maxCommunicationMachine...");
//		System.out.println("0: " + machineCommunicationHistogram[0]);
		int maxIndex = 0;
		int maxValue = machineCommunicationHistogram[0];
		int numEqualMachines = 1;
		for (int i = 1; i < machineCommunicationHistogram.length; ++i) {
			int valueOfCurrentMachine = machineCommunicationHistogram[i];
//			System.out.println(i + ": " + machineCommunicationHistogram[i]);
			if (valueOfCurrentMachine > maxValue) {
				maxValue = valueOfCurrentMachine;
				maxIndex = i;
				numEqualMachines = 1;
			} else if (valueOfCurrentMachine == maxValue) {
				numEqualMachines++;
				if (Math.random() <= ((double) 1.0 / (double) numEqualMachines)) {
					maxIndex = i;
				}
			}
		}
//		System.out.println("End of finding maxCommunicationMachine...");
		return (byte) maxIndex;
	}
}
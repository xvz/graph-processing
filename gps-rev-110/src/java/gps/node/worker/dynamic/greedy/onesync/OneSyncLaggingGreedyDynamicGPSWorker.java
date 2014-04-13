package gps.node.worker.dynamic.greedy.onesync;

import static gps.node.worker.GPSWorkerExposedGlobalVariables.currentSuperstepNo;
import static gps.node.worker.GPSWorkerExposedGlobalVariables.getCurrentSuperstepNo;
import static gps.node.worker.GPSWorkerExposedGlobalVariables.getLocalMachineId;
import static gps.node.worker.GPSWorkerExposedGlobalVariables.getMachineStats;
import static gps.node.worker.GPSWorkerExposedGlobalVariables.getNumWorkers;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.apache.commons.cli.CommandLine;
import org.apache.hadoop.fs.FileSystem;
import org.apache.log4j.Logger;
import org.apache.mina.core.buffer.IoBuffer;

import cern.colt.map.OpenIntIntHashMap;

import gps.communication.MessageSenderAndReceiverFactory;
import gps.graph.Graph;
import gps.graph.NullEdgeVertex;
import gps.graph.VertexFactory;
import gps.messages.IncomingBufferedMessage;
import gps.messages.MessageTypes;
import gps.messages.storage.ArrayBackedIncomingMessageStorage;
import gps.node.GPSJobConfiguration;
import gps.node.MachineConfig;
import gps.node.MachineStats.StatName;
import gps.node.worker.StaticGPSMessageSender;
import gps.node.worker.dynamic.VertexWrapper;
import gps.node.worker.dynamic.greedy.BaseGreedyDynamicGPSWorkerImpl;
import gps.writable.MinaWritable;

public class OneSyncLaggingGreedyDynamicGPSWorker<VW extends MinaWritable, EW extends MinaWritable,
	MW extends MinaWritable> extends BaseGreedyDynamicGPSWorkerImpl<VW, EW, MW> {

	private static Logger logger = Logger.getLogger(OneSyncLaggingGreedyDynamicGPSWorker.class);

	private int numVerticesReceived;
	private int numExceptionVerticesReceived; // Should be same across all workers

	private OneSyncDynamicMessageSender messageSender;
	private int[] potentialNumVerticesToSendForCurrentSuperstep;
	private int[] potentialNumVerticesToSendForNextSuperstep;
	private Set<Integer> potentialVertexIdsToSendForCurrentSuperstep;
	private Set<Integer> potentialVertexIdsToSendForNextSuperstep;
	private List<Map<Integer, Byte>> potentialVerticesToSendForCurrentSuperstepBuckets;
	private List<Map<Integer, Byte>> potentialVerticesToSendForNextSuperstepBuckets;
	private Map<Integer, Byte> verticesSentInPreviousSuperstep = new HashMap<Integer, Byte>();
	private Map<Integer, Byte> verticesSentInCurrentSuperstep = new HashMap<Integer, Byte>();
	private OpenIntIntHashMap relabelsMap;
	private int[] potentialNumVerticesToReceive;
	private int[][][] shuffledVertices;
	private int[][] shuffledVerticesIndices;
	private int numHighBenefitVerticesSent = 0;
	private ReceivedVertexDataWrapper<VW> receivedVertexDataWrapper;
	private int numEdgesInTheBeginning;
	private boolean shouldPutOnlyLargeVertices = false;
	private int minNumberOfEdgesForLargeVertices;
	private boolean[] denseMachines;

	private OneSyncDynamicMessagesParserThread<VW, MW> oneSyncDynamicMessagesParserThread;

	private int maxNumVerticesToSendPerSuperstep;

	public OneSyncLaggingGreedyDynamicGPSWorker(int localMachineId, CommandLine commandLine,
		FileSystem fileSystem, MachineConfig machineConfig, Graph<VW, EW> graphPartition,
		VertexFactory<VW, EW, MW> vertexFactory, int graphSize, int outgoingDataBufferSizes,
		String outputFileName, MessageSenderAndReceiverFactory messageSenderAndReceiverFactory,
		ArrayBackedIncomingMessageStorage<MW> incomingMessageStorage, int benefitThreshold,
		int edgeThreshold, long controlMessagesWaitTime, int maxMessagesToTransmitConcurrently,
		int numVerticesFrequencyToCheckOutgoingBuffers,
		int sleepTimeWhenOutgoingBuffersExceedThreshold,
		int superstepNoToStopDynamism, Class<VW> vertexRepresentativeInstance,
		Class<MW> messageRepresentativeInstance, Class<EW> edgeRepresentativeInstance,
		GPSJobConfiguration jobConfiguration, int largeVertexPartitioningOutdegreeThreshold,
		boolean runPartitioningSuperstep, boolean combine, int numProcessorsForHandlingIO,
		int minNumberOfEdgesForLargeVertices, int maxNumVerticesToSendPerSuperstep,
		boolean isNoDataParsing) throws InstantiationException, IllegalAccessException {
		super(localMachineId, commandLine, fileSystem, machineConfig, graphPartition, vertexFactory,
			graphSize, outgoingDataBufferSizes, outputFileName, messageSenderAndReceiverFactory,
            incomingMessageStorage, benefitThreshold, edgeThreshold, controlMessagesWaitTime,
            maxMessagesToTransmitConcurrently, numVerticesFrequencyToCheckOutgoingBuffers,
            sleepTimeWhenOutgoingBuffersExceedThreshold, largeVertexPartitioningOutdegreeThreshold,
            runPartitioningSuperstep, combine, messageRepresentativeInstance,
            edgeRepresentativeInstance, jobConfiguration, numProcessorsForHandlingIO,
            superstepNoToStopDynamism);
		potentialNumVerticesToSendForCurrentSuperstep = new int[getNumWorkers()];
		potentialNumVerticesToSendForNextSuperstep = new int[getNumWorkers()];
		potentialNumVerticesToReceive = new int[getNumWorkers()];
		potentialVertexIdsToSendForCurrentSuperstep = new HashSet<Integer>();
		potentialVertexIdsToSendForNextSuperstep = new HashSet<Integer>();
		potentialVerticesToSendForCurrentSuperstepBuckets = new ArrayList<Map<Integer, Byte>>();
		potentialVerticesToSendForNextSuperstepBuckets = new ArrayList<Map<Integer, Byte>>();
		for (int i = 0; i < 8; i++) {
			potentialVerticesToSendForCurrentSuperstepBuckets.add(new HashMap<Integer, Byte>());
			potentialVerticesToSendForNextSuperstepBuckets.add(new HashMap<Integer, Byte>());
		}
		relabelsMap = new OpenIntIntHashMap();// new HashMap<Integer, Integer>();
		this.receivedVertexDataWrapper = new ReceivedVertexDataWrapper<VW>();
		this.messageSender = new OneSyncDynamicMessageSender(machineConfig,
			machineCommunicationHistogram, outgoingDataBufferSizes, messageSenderAndReceiver,
			localMachineId, superstepNoToStopDynamism);
		this.oneSyncDynamicMessagesParserThread = new OneSyncDynamicMessagesParserThread<VW, MW>(
			incomingMessageStorage, incomingBufferedDataAndControlMessages, controlMessageStats,
			receivedVertexDataWrapper, vertexRepresentativeInstance, messageRepresentativeInstance,
			graphPartition, vertex, edgeRepresentativeInstance.newInstance(),
			jobConfiguration, isNoDataParsing);
		this.minNumberOfEdgesForLargeVertices = minNumberOfEdgesForLargeVertices;
		this.maxNumVerticesToSendPerSuperstep = maxNumVerticesToSendPerSuperstep;
		this.denseMachines = new boolean[getNumWorkers()];
		for (int i = 0; i < getNumWorkers(); ++i) {
			this.denseMachines[i] = false;
		}
	}

	@Override
	protected void startMessageParserThreads() {
		this.oneSyncDynamicMessagesParserThread.start();
	}

	@Override 
	protected boolean shouldSkipVertex(int localId) {
		if (currentSuperstepNo == 1 || currentSuperstepNo > (superstepNoToStopDynamism + 2)) {
			return false;
		}
		return verticesSentInPreviousSuperstep.containsKey(graphPartition.getGlobalId(localId));
	}

	@Override
	protected void doExtraWorkBeforeStartingSuperstep() throws InterruptedException {
//		benefitThreshold = Math.max(1, benefitThreshold - 1);
		logger.info("Start of dumping denseMachines. superstepNo: "  + getCurrentSuperstepNo());
		for (int i = 0; i < getNumWorkers(); ++i) {
			if (i != getLocalMachineId()) {
				logger.info("machineId: " + i + " isDense: " + denseMachines[i]);
			}
		}
		logger.info("End of dumping denseMachines. superstepNo: "  + getCurrentSuperstepNo());

		if (currentSuperstepNo > (superstepNoToStopDynamism + 2)) {
			return;
		}
		if (currentSuperstepNo == 1 || !isDenseMachine()) {
			if (currentSuperstepNo > 1) {
				logger.info("graphPartition.getNumEdges(): " + graphPartition.getNumEdges() +
					" is less than (1.05 * numEdgesInTheBeginning): "
					+ (1.05 * numEdgesInTheBeginning) + " numEdgesInTheBeginning: "
					+ numEdgesInTheBeginning);
			}
			shouldPutOnlyLargeVertices = false;
		} else {
			shouldPutOnlyLargeVertices = true;
		}
		int numVerticesProcessed = 0;
		for (int idOfVertexSentInPreviousSuperstep : verticesSentInPreviousSuperstep.keySet()) {
			numVerticesProcessed++;
			if ((numVerticesProcessed % numVerticesFrequencyToCheckOutgoingBuffers) == 0) {
				waitTillOutgoingBuffersDecreaseBelowMaxMessagesToTransmitConcurrently();
			}
			int newIdOfVertexSentInPreviousSuperstep = relabelsMap.get(
				idOfVertexSentInPreviousSuperstep);
			int localId = graphPartition.getLocalId(idOfVertexSentInPreviousSuperstep);
			// This should be sending the messages
			vertex.setLocalId(localId);
			vertex.compute(incomingMessageStorage.getMessageValuesForCurrentSuperstep(localId),
				currentSuperstepNo);
			boolean isActive = graphPartition.isActiveOfLocalId(localId);
			if (isActive == NullEdgeVertex.ACTIVE) {
				numActiveNodesForNextSuperstep++;
			}
//			logger.info("sending VertexId: " + newIdOfVertexSentInPreviousSuperstep + " state: "
//				+ graphPartition.getValueOfLocalId(localId));
			messageSender.sendVertexData(newIdOfVertexSentInPreviousSuperstep,
				graphPartition.getOriginalIdOfLocalId(localId),
				graphPartition.getNeighborIdsOfLocalId(localId),
				graphPartition.getValueOfLocalId(localId),
				graphPartition.isActiveOfLocalId(localId),
				verticesSentInPreviousSuperstep.get(idOfVertexSentInPreviousSuperstep));
		}
		messageSender.sendRemainingVertexDataBuffers();
	}

	private boolean isDenseMachine() {
		return ((double) graphPartition.getNumEdges() >= 1.01 * numEdgesInTheBeginning);
	}

	@Override
	protected void doExtraWorkAfterVertexComputation(int vertexId, int localId) {
		if (currentSuperstepNo > superstepNoToStopDynamism) {
			return;
		}
		if (potentialVertexIdsToSendForCurrentSuperstep.contains(vertexId)) {
			logger.debug("PotentialVerticesToSendForCurrentSuperstep contains vertexId: "
				+ vertexId + " currentSuperstepNo");
			return;
		}
		int neighborsSize = graphPartition.getNeighborIdsOfLocalId(localId).length;
		if (graphPartition.isActiveOfLocalId(localId) == NullEdgeVertex.ACTIVE
			&& ((shouldPutOnlyLargeVertices && neighborsSize > minNumberOfEdgesForLargeVertices)
				|| (!shouldPutOnlyLargeVertices && neighborsSize < edgeThreshold))) {
			byte maxCommunicationMachineId = findIdOfMaxCommunicatedMachine();
			if (!shouldPutOnlyLargeVertices &&
				denseMachines[maxCommunicationMachineId] &&
				(neighborsSize > (minNumberOfEdgesForLargeVertices / 3))) {
//				logger.info("not sending vertex: id: " + vertexId + " with " + neighborsSize
//					+ " edges to machineId: " + maxCommunicationMachineId +
//					" because the machine is dense. superstepNo: " + getCurrentSuperstepNo());
				return;
			}
//			logger.info("vertexId: " + vertexId + " maxCommunicationMachineId: "
//				+ maxCommunicationMachineId + " communication: " + machineCommunicationHistogram[maxCommunicationMachineId]);
//			if (maxCommunicationMachineId != getLocalMachineId() && (machineCommunicationHistogram[maxCommunicationMachineId]
//			  - (machineCommunicationHistogram[getLocalMachineId()]) >= Math.max(benefitThreshold, (superstepNoToStopDynamism - currentSuperstepNo)))) {
//			Math.max(benefitThreshold, (neighborsSize / 4))
			int benefit = machineCommunicationHistogram[maxCommunicationMachineId]
				     - (machineCommunicationHistogram[getLocalMachineId()]);
			if (maxCommunicationMachineId != getLocalMachineId() && (benefit >= benefitThreshold)) {
//				logger.info("adding vertexId: " + vertexId + " to potential vertices to send.");
				addVertexIdToCorrectBenefitGroup(potentialVerticesToSendForNextSuperstepBuckets,
					vertexId, maxCommunicationMachineId, benefit, neighborsSize);
//				highPotentialVerticesToSendForNextSuperstep.put(vertexId, maxCommunicationMachineId);
				if (potentialNumVerticesToSendForNextSuperstep[maxCommunicationMachineId] < maxNumVerticesToSendPerSuperstep) {
					potentialVertexIdsToSendForNextSuperstep.add(vertexId);
					potentialNumVerticesToSendForNextSuperstep[maxCommunicationMachineId]++;
				}
			}
		}
	}

	private void addVertexIdToCorrectBenefitGroup(
		List<Map<Integer, Byte>> potentialVerticesToSendBenefitBuckets, int vertexId,
		byte maxCommunicationMachineId, int benefit, int neighborsSize) {
//		if (shouldPutOnlyLargeVertices) {
			if (benefit >= 320) {
				potentialVerticesToSendBenefitBuckets.get(0).put(vertexId, maxCommunicationMachineId);
			} else if (benefit >= 160) {
				potentialVerticesToSendBenefitBuckets.get(1).put(vertexId, maxCommunicationMachineId);
			} else if (benefit >= 80) {
				potentialVerticesToSendBenefitBuckets.get(2).put(vertexId, maxCommunicationMachineId);
			} else if (benefit >= 40) {
				potentialVerticesToSendBenefitBuckets.get(3).put(vertexId, maxCommunicationMachineId);
			} else if (benefit >= 20) {
				potentialVerticesToSendBenefitBuckets.get(4).put(vertexId, maxCommunicationMachineId);
			} else if (benefit >= 10) {
				potentialVerticesToSendBenefitBuckets.get(5).put(vertexId, maxCommunicationMachineId);
			} else if (benefit >= 5) {
				potentialVerticesToSendBenefitBuckets.get(6).put(vertexId, maxCommunicationMachineId);
			} else {
				potentialVerticesToSendBenefitBuckets.get(7).put(vertexId, maxCommunicationMachineId);			
			}
//		} else {
//			if (neighborsSize >= 320) {
//				potentialVerticesToSendBenefitBuckets.get(7).put(vertexId,
//					maxCommunicationMachineId);
//			} else if (neighborsSize >= 160) {
//				potentialVerticesToSendBenefitBuckets.get(6).put(vertexId,
//					maxCommunicationMachineId);
//			} else if (neighborsSize >= 80) {
//				potentialVerticesToSendBenefitBuckets.get(5).put(vertexId,
//					maxCommunicationMachineId);
//			} else if (neighborsSize >= 40) {
//				potentialVerticesToSendBenefitBuckets.get(4).put(vertexId,
//					maxCommunicationMachineId);
//			} else if (neighborsSize >= 20) {
//				potentialVerticesToSendBenefitBuckets.get(3).put(vertexId,
//					maxCommunicationMachineId);
//			} else if (neighborsSize >= 10) {
//				potentialVerticesToSendBenefitBuckets.get(2).put(vertexId,
//					maxCommunicationMachineId);
//			} else if (neighborsSize >= 5) {
//				potentialVerticesToSendBenefitBuckets.get(1).put(vertexId,
//					maxCommunicationMachineId);
//			} else {
//				potentialVerticesToSendBenefitBuckets.get(0).put(vertexId,
//					maxCommunicationMachineId);
//			}
//		}
	}

	@Override
	protected void doExtraWorkAfterFinishingSuperstepComputation() {
		if (currentSuperstepNo > superstepNoToStopDynamism + 1) {
			return;
		}
		if (currentSuperstepNo <= superstepNoToStopDynamism) {
			for (int i = 0; i < getNumWorkers(); ++i) {
				if (i == getLocalMachineId()) {
					continue;
				} else {
					potentialNumVerticesToSendForNextSuperstep[i] = Math.min(
						potentialNumVerticesToSendForNextSuperstep[i],
						maxNumVerticesToSendPerSuperstep);
				}
			}
			logger.info("sending potential num vertices to send to machines. machine isDense: "
				+ isDenseMachine());
			messageSender.sendPotentialNumVerticesToSendMessages(currentSuperstepNo,
				potentialNumVerticesToSendForNextSuperstep, isDenseMachine());
		}
		if (currentSuperstepNo == 1) {
			this.numEdgesInTheBeginning = graphPartition.getNumEdges();
			return;
		}
		int[] numVerticesToSendToEachWorker = new int[getNumWorkers()];
		for (int i = 0; i < getNumWorkers(); ++i) {
			numVerticesToSendToEachWorker[i] = Math.min(
				potentialNumVerticesToSendForCurrentSuperstep[i], potentialNumVerticesToReceive[i]);
		}
		int[] numVerticesAlreadySent = new int[getNumWorkers()];
		for (Map<Integer, Byte> potentialVerticesToSendForCurrentSuperstepBucket
			: potentialVerticesToSendForCurrentSuperstepBuckets) {
			for (int idOfPotentialVertexToSend : potentialVerticesToSendForCurrentSuperstepBucket.keySet()) {
				byte toMachineId = potentialVerticesToSendForCurrentSuperstepBucket.get(
					idOfPotentialVertexToSend);
				if (numVerticesAlreadySent[toMachineId] < numVerticesToSendToEachWorker[toMachineId]) {
					numHighBenefitVerticesSent++;
					verticesSentInCurrentSuperstep.put(idOfPotentialVertexToSend, toMachineId);
					numVerticesAlreadySent[toMachineId]++;
				}
			}
		}
		messageSender.broadcastShuffledVertexIds(currentSuperstepNo,
			verticesSentInCurrentSuperstep);
	}

	@Override
	protected void doExtraWorkAfterReceivingAllFinalDataSentMessages() throws InterruptedException,
		IOException {
		if (currentSuperstepNo > superstepNoToStopDynamism + 2) {
			return;
		}
//		for (int idOfVertexSentInPreviousSuperstep : verticesSentInPreviousSuperstep.keySet()) {
////			graphPartition.moveFromReservedIdToRegularId(idOfVertexSentInPreviousSuperstep);
//		}
		long timeBefore = System.currentTimeMillis();
		for (int idOfVertexReceivedInPreviousSuperstep :
			receivedVertexDataWrapper.verticesReceived.keySet()) {
			VertexWrapper<VW> vertexWrapper =
				receivedVertexDataWrapper.verticesReceived.get(
					idOfVertexReceivedInPreviousSuperstep);
			logger.debug("putting vertex: id: " + idOfVertexReceivedInPreviousSuperstep
				+ " originalId: " + vertexWrapper.originalId + " state: " + vertexWrapper.state);
			graphPartition.put(idOfVertexReceivedInPreviousSuperstep,
				vertexWrapper.originalId,
				vertexWrapper.state, vertexWrapper.neighborIds, vertexWrapper.isActive,
				true /* is replacement */);
			incomingMessageStorage.adjustArraySizesForNewVertex(
				idOfVertexReceivedInPreviousSuperstep, currentSuperstepNo);
		}
		getMachineStats().updateStatForSuperstep(StatName.TOTAL_PARSING_VERTICES_RECEIVED_TIME,
			getCurrentSuperstepNo(), (double) (System.currentTimeMillis() - timeBefore));
		potentialNumVerticesToReceive = new int[getNumWorkers()];
		timeBefore = System.currentTimeMillis();
		parseExceptionFiles();
		getMachineStats().updateStatForSuperstep(StatName.TOTAL_PARSING_EXCEPTION_MESSAGES_TIME,
			getCurrentSuperstepNo(), (double) (System.currentTimeMillis() - timeBefore));
		timeBefore = System.currentTimeMillis();
		graphPartition.relabelIds(relabelsMap);
		getMachineStats().updateStatForSuperstep(StatName.TOTAL_RELABELING_TIME,
			getCurrentSuperstepNo(), (double) (System.currentTimeMillis() - timeBefore));
		dumpDataStructures();
		getMachineStats().updateStatForSuperstep(StatName.NUM_VERTICES_SENT_IN_PREVIOUS_SUPERSTEP,
			getCurrentSuperstepNo(), (double) verticesSentInPreviousSuperstep.size());
		getMachineStats().updateStatForSuperstep(
			StatName.NUM_VERTICES_RECEIVED_IN_PREVIOUS_SUPERSTEP, getCurrentSuperstepNo(),
			(double) receivedVertexDataWrapper.verticesReceived.size());
		getMachineStats().updateStatForSuperstep(StatName.NUM_VERTICES_SENT,
			getCurrentSuperstepNo(), (double) verticesSentInCurrentSuperstep.size());
		getMachineStats().updateStatForSuperstep(StatName.NUM_VERTICES_RECEIVED,
			getCurrentSuperstepNo(), (double) numVerticesReceived);
		getMachineStats().updateStatForSuperstep(StatName.NUM_EXCEPTION_VERTICES_RECEIVED,
			getCurrentSuperstepNo(), (double) numExceptionVerticesReceived);
		getMachineStats().updateStatForSuperstep(StatName.NUM_VERTEX_DATA_RECEIVED,
			getCurrentSuperstepNo(), (double) OneSyncDynamicMessagesParserThread.numVertexDataReceived);
		getMachineStats().updateStatForSuperstep(StatName.NUM_HIGH_BENEFIT_VERTICES_SENT,
			getCurrentSuperstepNo(), (double) numHighBenefitVerticesSent);
		numHighBenefitVerticesSent = 0;

		receivedVertexDataWrapper.verticesReceived.clear();

		Map<Integer, Byte> tmp = verticesSentInCurrentSuperstep;
		verticesSentInCurrentSuperstep = verticesSentInPreviousSuperstep;
		verticesSentInPreviousSuperstep = tmp;
		verticesSentInCurrentSuperstep.clear();

		potentialNumVerticesToSendForCurrentSuperstep = potentialNumVerticesToSendForNextSuperstep;
		potentialNumVerticesToSendForNextSuperstep = new int[getNumWorkers()];

		Set<Integer> tmpSet = potentialVertexIdsToSendForCurrentSuperstep;
		potentialVertexIdsToSendForCurrentSuperstep = potentialVertexIdsToSendForNextSuperstep;
		potentialVertexIdsToSendForNextSuperstep = tmpSet;
		potentialVertexIdsToSendForNextSuperstep.clear();
		
		List<Map<Integer, Byte>> tmpListOfList = potentialVerticesToSendForCurrentSuperstepBuckets;
		potentialVerticesToSendForCurrentSuperstepBuckets = potentialVerticesToSendForNextSuperstepBuckets;
		potentialVerticesToSendForNextSuperstepBuckets = tmpListOfList;
		for (Map<Integer, Byte> potentialVerticesToSendForNextSuperstepBucket : potentialVerticesToSendForNextSuperstepBuckets) {
			potentialVerticesToSendForNextSuperstepBucket.clear();			
		}

		numVerticesReceived = 0;
		numExceptionVerticesReceived = 0;
		OneSyncDynamicMessagesParserThread.numVertexDataReceived = 0;
	}

	@Override
	protected Logger getLogger() {
		return logger;
	}

	private void parseExceptionFiles() {
		shuffledVertices = new int[getNumWorkers()][getNumWorkers()][];
		shuffledVerticesIndices = new int[getNumWorkers()][];
		for (int i = 0; i < getNumWorkers(); ++i) {
			shuffledVerticesIndices[i] = new int[getNumWorkers()];
			for (int j = 0; j < getNumWorkers(); ++j) {
				if (j == i) {
					continue;
				}
				shuffledVertices[i][j] = new int[10];
			}
		}
		for (IncomingBufferedMessage incomingBufferedMessage :
			receivedVertexDataWrapper.exceptionFilesAndPotentialVerticesToSendMessages) {
			MessageTypes type = incomingBufferedMessage.getType();
			IoBuffer ioBuffer = incomingBufferedMessage.getIoBuffer();
			int fromMachineId = incomingBufferedMessage.getFromMachineId();
			switch(type) {
			case EXCEPTIONS_MAP:
				while (ioBuffer.hasRemaining()) {
					numExceptionVerticesReceived++;
					int vertexId = ioBuffer.getInt();
					byte toMachineId = ioBuffer.get();
					int nextArrayIndex = shuffledVerticesIndices[fromMachineId][toMachineId];
					int currentArrayLength = shuffledVertices[fromMachineId][toMachineId].length;
					if (nextArrayIndex == currentArrayLength) {
						int newArrayLength = currentArrayLength > 1000000 ?
							(int) (currentArrayLength * 1.4) : currentArrayLength * 2;
						int[] newArray = new int[newArrayLength];
						for (int i = 0; i < currentArrayLength; ++i) {
							newArray[i] = shuffledVertices[fromMachineId][toMachineId][i];
						}
						shuffledVertices[fromMachineId][toMachineId] = newArray;
					}
					shuffledVertices[fromMachineId][toMachineId][nextArrayIndex] = vertexId;
					shuffledVerticesIndices[fromMachineId][toMachineId]++;
				}
				break;
			case POTENTIAL_NUM_VERTICES_TO_SEND:
				int numPotentialVerticesToReceive = ioBuffer.getInt();
				denseMachines[fromMachineId] = (ioBuffer.get() == (byte) 1);
				getLogger().info("Received a Potential num vertices to send message from "
					+ " machineId: " + fromMachineId + " numVerticesToReceive: "
					+ numPotentialVerticesToReceive);
				potentialNumVerticesToReceive[fromMachineId] = numPotentialVerticesToReceive;
				break;
			default:
				getLogger().error("Unhandled message type in" +
					" exceptionFilesAndPotentialVerticesToSendMesssages list. type: " + type);
			}
		}
		relabelsMap.clear();
		getLogger().debug("------Logging the number of vertex exchanging. superstepNo: "
			+ currentSuperstepNo + "------");
		for (int i = 0; i < getNumWorkers(); ++i) {
			for (int j = 0; j < getNumWorkers(); ++j) {
				getLogger().debug("from: " + i + " to: " + j + ": " + shuffledVerticesIndices[i][j]);
			}
		}
		getLogger().debug("------End of logging the number of vertex exchanging.------");

		getLogger().debug("------Logging the actual vertex exchanging.------");
		int firstVertex;
		int secondVertex;
		for (int i = 0; i < getNumWorkers(); ++i) {
			for (int j = 0; j < getNumWorkers(); ++j) {
				for (int k = 0; k < shuffledVerticesIndices[i][j]; ++k) {
					if (i < j) {
						firstVertex = shuffledVertices[i][j][k];
						try {
							secondVertex = shuffledVertices[j][i][k];
							relabelsMap.put(firstVertex, secondVertex);
							relabelsMap.put(secondVertex, firstVertex);
						} catch (ArrayIndexOutOfBoundsException e) {
							logger.error("i: " + i + " j: " + j + " k: " + k + " shuffledVerticesIndices[i][j]: "
								+ shuffledVerticesIndices[i][j] + " shuffledVerticesIndices[j][i]: " + shuffledVerticesIndices[j][i]);
						}
					}
//					getLogger().debug("from: " + i + " to: " + j + ": " + shuffledVertices[i][j][k]);
				}
			}
		}
//		getLogger().debug("------End of logging the number of vertex exchanging.------");
//
//		getLogger().debug("------Logging the relabels map.------");
//		for (int fromVertex : relabelsMap.keySet()) {
//			getLogger().debug(fromVertex + "-->" + relabelsMap.get(fromVertex));
//		}
//		getLogger().debug("------End of logging the relabels map.------");

		receivedVertexDataWrapper.exceptionFilesAndPotentialVerticesToSendMessages.clear();
	}

	private void dumpDataStructures() {
		getLogger().info("----Dump of Dynamism DataStructures superstepNo: "
			+ currentSuperstepNo + "--------");
		getLogger().info("verticesSentInPreviousSuperstep size: "
			+ verticesSentInPreviousSuperstep.size());
		getLogger().info("verticesSentInCurrentSuperstep size: "
			+ verticesSentInCurrentSuperstep.size());
		getLogger().info("----Dump of PotentialVerticesToReceive&Send--------");
		int numVerticesToSendForNextSuperstep = 0; 
		for (int i = 0; i < getNumWorkers(); ++i) {
			if (i == getLocalMachineId()) {
				continue;
			}
			getLogger().info("fromMachineId: " + i + " numVertices: "
				+ potentialNumVerticesToReceive[i]);
			getLogger().info("toMachineId: " + i + " numVertices: "
				+ potentialNumVerticesToSendForNextSuperstep[i]);
			numVerticesToSendForNextSuperstep += Math.min(potentialNumVerticesToReceive[i],
				potentialNumVerticesToSendForNextSuperstep[i]);
		}
		getLogger().info("numVerticesToSendForNextSuperstep: " + numVerticesToSendForNextSuperstep);
		getLogger().info("----End of Dump of PotentialVerticesToReceive--------");
		getLogger().info("----End of Dump of Dynamism DataStructures superstepNo: "
			+ currentSuperstepNo + "--------");
	}

	@Override
	protected StaticGPSMessageSender getMessageSender() {
//		logger.info("inside getMessageSender(). this.messageSender.class: " + this.messageSender.getClass().getCanonicalName());
		return this.messageSender;
	}

	@Override
	protected void finishedParsingInputSplits() {
		this.oneSyncDynamicMessagesParserThread.setIncomingMessageStorage(incomingMessageStorage);
	}
}

// Unused code:

//private void doInitialGreedyPartitioning() throws InterruptedException {
//	int numWorkers = getNumWorkers();
//	int[] machineCommunicationHistogram = new int[numWorkers];
//	int[] partitions = new int[graphPartition.size()];
//	int[] potentialPartitions = new int[graphPartition.size()];
//	int[] potentialNumVerticesToExchange = new int[numWorkers];
//	int localMachineId = getLocalMachineId();
//	for (int localId = 0; localId < graphPartition.size(); ++localId) {
//		partitions[localId] = localMachineId;
//		potentialPartitions[localId] = localMachineId;
//	}
//	for (int j = 0; j < 1; ++j) {
//		for (int localId = 0; localId < graphPartition.size(); ++localId) {
//			if (shouldSkipVertex(localId)) {
//				continue;
//			}
//			if ((localId % numVerticesFrequencyToCheckOutgoingBuffers) == 0) {
//				waitTillOutgoingBuffersDecreaseBelowMaxMessagesToTransmitConcurrently();
//			}
//			for (int i = 0; i < getNumWorkers(); ++i) {
//				machineCommunicationHistogram[i] = 0;
//			}
//			int[] neighborIdsOfLocalId = graphPartition.getNeighborIdsOfLocalId(localId);
//			for (int neighborId : neighborIdsOfLocalId) {
//				machineCommunicationHistogram[neighborId % numWorkers]++;
//			}
//			byte maxCommunicationMachineId =
//				findIdOfMaxCommunicatedMachine(machineCommunicationHistogram);
//			if (maxCommunicationMachineId != localMachineId) {
//				potentialPartitions[localMachineId] = maxCommunicationMachineId;
//				potentialNumVerticesToExchange[maxCommunicationMachineId]++;
//			}
//		}
//		messageSenderAndReceiver.sendPotentialNumVerticesToSendMessages(currentSuperstepNo,
//			potentialNumVerticesToSendForNextSuperstep);
//	}
//}
//
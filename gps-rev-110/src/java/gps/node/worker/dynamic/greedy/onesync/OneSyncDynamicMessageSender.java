package gps.node.worker.dynamic.greedy.onesync;

import static gps.node.worker.GPSWorkerExposedGlobalVariables.getNumWorkers;
import gps.communication.MessageSenderAndReceiverForWorker;
import gps.graph.NullEdgeVertex;
import gps.messages.MessageTypes;
import gps.messages.OutgoingBufferedMessage;
import gps.node.MachineConfig;
import gps.node.Utils;
import gps.node.worker.GPSWorkerExposedGlobalVariables;
import gps.node.worker.StaticGPSMessageSender;
import gps.node.worker.dynamic.greedy.BaseGreedyDynamicGPSWorkerImpl;
import gps.writable.MinaWritable;

import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;

import org.apache.log4j.Logger;
import org.apache.mina.core.buffer.IoBuffer;

public class OneSyncDynamicMessageSender extends StaticGPSMessageSender {

	private static Logger logger = Logger.getLogger(OneSyncDynamicMessageSender.class);

	private HashMap<Integer, IoBuffer> outgoingVertexDataMap;

//	private final int[] machineCommunicationHistogram;

	protected final MachineConfig machineConfig;

	private final int localMachineId;

	private final int superstepNoToStopDynamism;

	public OneSyncDynamicMessageSender(MachineConfig machineConfig,
		int[] machineCommunicationHistogram, int outgoingBufferSizes,
		MessageSenderAndReceiverForWorker messageSenderAndReceiverForWorker, int localMachineId,
		int superstepNoToStopDynamism) {
		super(machineConfig, outgoingBufferSizes, messageSenderAndReceiverForWorker);
		this.machineConfig = machineConfig;
//		this.machineCommunicationHistogram = machineCommunicationHistogram;
		this.localMachineId = localMachineId;
		this.superstepNoToStopDynamism = superstepNoToStopDynamism;
		outgoingVertexDataMap = new HashMap<Integer, IoBuffer>();
		for (int machineId : machineConfig.getWorkerIds()) {
			outgoingVertexDataMap.put(machineId, IoBuffer.allocate(outgoingBufferSizes));
		}
	}

	public void sendDataMessage(MinaWritable messageValue, int toNodeId) {
		int machineIdOfNeighbor = toNodeId % getNumWorkers();
		if (GPSWorkerExposedGlobalVariables.getCurrentSuperstepNo() < (superstepNoToStopDynamism - 2)) {
			BaseGreedyDynamicGPSWorkerImpl.machineCommunicationHistogram[machineIdOfNeighbor]++;
		}	
		putMessageToIoBuffer(outgoingDataBuffersMap, messageValue, toNodeId, machineIdOfNeighbor,
			MessageTypes.DATA);
	}

	public void broadcastShuffledVertexIds(int superstepNo,
		Map<Integer, Byte> verticesSentInCurrentSuperstep) {
		int[] randomPermutation = Utils.getRandomPermutation(machineConfig.getWorkerIds().size());
		List<Integer> allMachineIds = new LinkedList<Integer>(machineConfig.getWorkerIds());
		for (int i : randomPermutation) {
			int toMachineId = allMachineIds.get(i);
			getLogger().info("Sending " + MessageTypes.EXCEPTIONS_MAP + " message toMachineId:" + toMachineId);
			messageSenderAndReceiverForWorker.sendBufferedMessage(constructExceptionsMapMessage(
				superstepNo, verticesSentInCurrentSuperstep), toMachineId);
		}	
	}

	public void sendPotentialNumVerticesToSendMessages(int superstepNo,
		int[] potentialNumVerticesToSend, boolean isDenseMachine) {
		int[] randomPermutation = Utils.getRandomPermutation(machineConfig.getWorkerIds().size());
		List<Integer> allMachineIds = new LinkedList<Integer>(machineConfig.getWorkerIds());
		for (int i : randomPermutation) {
			int toMachineId = allMachineIds.get(i);
			if (toMachineId == localMachineId) {
				continue;
			}
			getLogger().info("Sending " + MessageTypes.POTENTIAL_NUM_VERTICES_TO_SEND
				+ " message toMachineId:" + toMachineId);
			// 			messageSenderAndReceiverForWorker.sendBufferedMessage(
//			constructPotentialNumVerticesToSendMessage(superstepNo,
//				potentialNumVerticesToSend[i]), toMachineId);
			messageSenderAndReceiverForWorker.sendBufferedMessage(
				constructPotentialNumVerticesToSendMessage(superstepNo,
					potentialNumVerticesToSend[toMachineId], isDenseMachine), toMachineId);
		}		
	}

	private OutgoingBufferedMessage constructPotentialNumVerticesToSendMessage(int superstepNo,
		int potentialNumVerticesToSend, boolean isDenseMachine) {
		IoBuffer ioBuffer = IoBuffer.allocate(5);
		ioBuffer.putInt(potentialNumVerticesToSend);
		ioBuffer.put(isDenseMachine ? (byte) 1 : (byte) 0);
		return new OutgoingBufferedMessage(MessageTypes.POTENTIAL_NUM_VERTICES_TO_SEND,
			superstepNo, ioBuffer);
	}

	private OutgoingBufferedMessage constructExceptionsMapMessage(int superstepNo,
		Map<Integer, Byte> verticesSentInCurrentSuperstep) {
		IoBuffer ioBuffer = IoBuffer.allocate(5 * verticesSentInCurrentSuperstep.size());
		for (int vertexIdToMove : verticesSentInCurrentSuperstep.keySet()) {
			ioBuffer.putInt(vertexIdToMove);
			ioBuffer.put(verticesSentInCurrentSuperstep.get(vertexIdToMove));
		}
		return new OutgoingBufferedMessage(MessageTypes.EXCEPTIONS_MAP, superstepNo, ioBuffer);
	}

	public void sendVertexData(int vertexId, int originalVertexId, int[] neighborIds,
		MinaWritable state,
		boolean isActive, int toMachineId) {
		IoBuffer ioBuffer = outgoingVertexDataMap.get(toMachineId);
		int sizeOfMessage = 13 + neighborIds.length * 4 + state.numBytes();
		if (sizeOfMessage > 64000) {
			getLogger().info("sizeOfMessage is larger than 64000: " + sizeOfMessage);
		}
		ioBuffer = sendIfNotEnoughSpaceOnBuffer(toMachineId, ioBuffer, sizeOfMessage,
			outgoingVertexDataMap, MessageTypes.VERTEX_SHUFFLING_WITH_DATA);
		ioBuffer.putInt(vertexId);
		ioBuffer.putInt(originalVertexId);
		state.write(ioBuffer);
//		ioBuffer.putDouble(state);
		ioBuffer.put(isActive == NullEdgeVertex.ACTIVE ? NullEdgeVertex.ACTIVE_AS_BYTE : NullEdgeVertex.INACTIVE_AS_BYTE);
		ioBuffer.putInt(neighborIds.length);
		for (int neighborId : neighborIds) {
			ioBuffer.putInt(neighborId);
		}
	}

	public void sendRemainingVertexDataBuffers() {
		sendRemainingIoBuffers(outgoingVertexDataMap, MessageTypes.VERTEX_SHUFFLING_WITH_DATA,
			false /* don't skip local machine id */);
	}

	private IoBuffer sendIfNotEnoughSpaceOnBuffer(int toMachineId, IoBuffer ioBuffer,
		int sizeOfMessage, Map<Integer, IoBuffer> ioBufferMap, MessageTypes messageType) {
		if (ioBuffer.remaining() < sizeOfMessage) {
			ioBuffer = sendOutgoingBufferAndAllocateNewBuffer(ioBufferMap, toMachineId,
				messageType, sizeOfMessage);
		}
		return ioBuffer;
	}
	
	public Logger getLogger() {
		return logger;
	}
}
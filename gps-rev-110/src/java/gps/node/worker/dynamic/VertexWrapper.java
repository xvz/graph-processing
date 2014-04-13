package gps.node.worker.dynamic;

import gps.writable.MinaWritable;

public class VertexWrapper<V extends MinaWritable> {
	public int originalId;
	public int[] neighborIds;
	public V state;
	public boolean isActive;
	public byte toOrFromMachineId;
}

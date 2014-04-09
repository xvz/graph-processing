package gps.node;

import gps.communication.MessageSenderAndReceiverFactory;
import gps.communication.mina.MinaMessageSenderAndReceiverFactory;
import gps.graph.ArrayBackedGraph;
import gps.graph.Graph;
import gps.graph.Master;
import gps.graph.NullEdgeVertex;
import gps.graph.VertexFactory;
import gps.messages.storage.ArrayBackedIncomingMessageStorage;
import gps.node.master.GPSMaster;
import gps.node.worker.AbstractGPSWorker;
import gps.node.worker.StaticGPSWorkerImpl;
import gps.node.worker.dynamic.greedy.twosync.TwoSyncGreedyDynamicGPSWorker;
import gps.writable.MinaWritable;

import java.io.IOException;
import java.lang.management.ManagementFactory;
import java.lang.reflect.Constructor;
import java.util.List;

import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.Option;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;
import org.apache.commons.cli.PosixParser;
import org.apache.hadoop.fs.FileSystem;
import org.apache.log4j.Logger;
import org.apache.log4j.PropertyConfigurator;

/**
 * Main class that starts either a {@link AbstractGPSWorker} instance or {@link GPSMaster}.
 * 
 * @author semihsalihoglu
 */
public class GPSNodeRunner {

	private static Logger logger = Logger.getLogger(GPSNodeRunner.class);

	public static final int DEFAULT_DYNAMISM_BENEFIT_THRESHOLD = 3;
	public static final int DEFAULT_OUTGOING_BUFFER_SIZES = 100000;
	public static final int DEFAULT_EDGE_THRESHOLD = 15000;
	public static final int DEFAULT_DYNAMISM_MIN_NUMBER_OF_EDGES_FOR_LARGE_VERTICES_THRESHOLD = 100;
	public static final int DEFAULT_MAX_NUMBER_OF_VERTICES_TO_SEND_PER_SUPERSTEP = 5000;
	public static final int DEFAULT_MAX_MESSAGES_TO_TRANSMIT_CONCURRENTLY = 1;
	public static final int DEFAULT_NUM_VERTICES_FREQUENCY_TO_CHECK_OUTGOING_BUFFERS = 1;
	public static final int DEFAULT_SLEEP_TIME_WHEN_OUTGOING_BUFFERS_EXCEED_THRESHOLD = 5;
	public static final int DEFAULT_LARGE_VERTEX_PARTITIONING_OUTDEGREE_THRESHOLD = -1;
	public static final int DEFAULT_SUPERSTEP_NO_TO_STOP_DYNAMISM = 15;
	public static final int DEFAULT_NUM_PROCESSORS_FOR_HANDLING_NETWORK_IO = 1;

	public static final String MACHINE_ID_OPT_NAME = "machineid";
	public static final String MACHINE_ID_SHORT_OPT_NAME = "mid";
	public static final String MACHINE_CONFIG_FILE_OPT_NAME = "machineconfigfile";
	public static final String MACHINE_CONFIG_FILE_SHORT_OPT_NAME = "mcfg";
	public static final String PARTITION_FILE_OPT_NAME = "partitionfile";
	public static final String PARTITION_FILE_SHORT_OPT_NAME = "pf";
	public static final String INPUT_FILES_OPT_NAME = "inputfiles";
	public static final String INPUT_FILES_SHORT_OPT_NAME = "ifs";
	public static final String IS_DYNAMIC_OPT_NAME = "dynamic";
	public static final String IS_DYNAMIC_SHORT_OPT_NAME = "d";
	public static final String OUTPUT_FILE_NAME_SHORT_OPT_NAME = "ofp";
	public static final String OUTPUT_FILE_NAME_OPT_NAME = "outputfileprefix";
	public static final String MASTER_OUTPUT_FILE_NAME_SHORT_OPT_NAME = "mofp";
	public static final String MASTER_OUTPUT_FILE_NAME_OPT_NAME = "masteroutputfileprefix";
	public static final String DYNAMISM_BENEFIT_THRESHOLD_SHORT_OPT_NAME = "dbthr";
	public static final String DYNAMISM_BENEFIT_THRESHOLD_OPT_NAME = "dynamismbenefitthreshold";
	public static final String DYNAMISM_MIN_NUMBER_OF_EDGES_FOR_LARGE_VERTICES_SHORT_OPT_NAME = "dmneflv";
	public static final String DYNAMISM_MIN_NUMBER_OF_EDGES_FOR_LARGE_VERTICES_OPT_NAME = "dynamismminnumberofedgesforlargevertices";
	public static final String DYNAMISM_MAX_NUMBER_OF_VERTICES_TO_SEND_PER_SUPERSTEP_SHORT_OPT_NAME = "dmnvtsps";
	public static final String DYNAMISM_MAX_NUMBER_OF_VERTICES_TO_SEND_PER_SUPERSTEP_OPT_NAME = "dynamismmaxnumberofverticestosendpersuperstep";
	public static final String DYNAMISM_EDGE_THRESHOLD_SHORT_OPT_NAME = "dethr";
	public static final String DYNAMISM_EDGE_THRESHOLD_OPT_NAME = "dynamismedgethreshold";
	public static final String LOG4J_CONFIG_FILE_SHORT_OPT_NAME = "log4jconf";
	public static final String LOG4J_CONFIG_FILE_OPT_NAME = "log4jconfig";
	public static final String OUTGOING_DATA_BUFFER_SIZES_SHORT_OPT_NAME = "obs";
	public static final String OUTGOING_DATA_BUFFER_SIZES_OPT_NAME = "outgoingbuffersizes";
	public static final String CONTROL_MESSAGES_POLLING_TIME_SHORT_OPT_NAME = "pt";
	public static final String CONTROL_MESSAGES_POLLING_TIME_OPT_NAME = "pollingtime";
	public static final String MAX_MESSAGES_TO_TRANSMIT_CONCURRENTLY_SHORT_OPT_NAME = "mmttc";
	public static final String MAX_MESSAGES_TO_TRANSMIT_CONCURRENTLY_OPT_NAME =
		"maxmessagestotransmitconcurrently";
	public static final String NUM_VERTICES_FREQUENCY_TO_CHECK_OUTGOING_BUFFERS_SHORT_OPT_NAME
		= "nvftcob";
	public static final String NUM_VERTICES_FREQUENCY_TO_CHECK_OUTGOING_BUFFERS_OPT_NAME =
		"numverticesfrequencytocheckoutgoingbuffers";
	public static final String SLEEP_TIME_WHEN_OUTGOING_BUFFERS_EXCEED_THRESHOLD_SHORT_OPT_NAME
		= "stwobet";
	public static final String SLEEP_TIME_WHEN_OUTGOING_BUFFERS_EXCEED_THRESHOLD_OPT_NAME =
		"sleeptimewhenoutgoingbuffersexceedthreshold";
	public static final String LARGE_VERTEX_PARTITIONING_OUTDEGREE_THRESHOLD_SHORT_OPT_NAME
		= "lalp";
	public static final String LARGE_VERTEX_PARTITIONING_OUTDEGREE_THRESHOLD_OPT_NAME
		= "largeadjacencylistpartitioning";
	public static final String SUPERSTEP_NO_TO_STOP_DYNAMISM_SHORT_OPT_NAME = "sntsd";
	public static final String SUPERSTEP_NO_TO_STOP_DYNAMISM_OPT_NAME = "superstepnotostopdynamism";
//	public static final String RUN_PARTITIONING_SUPERSTEP_SHORT_OPT_NAME = "rps";
//	public static final String RUN_PARTITIONING_SUPERSTEP_OPT_NAME = "runpartitioningsuperstep";
	public static final String COMBINE_SHORT_OPT_NAME = "c";
	public static final String COMBINE_OPT_NAME = "combine";
	public static final String OTHER_OPTS_SHORT_OPT_NAME = "o";
	public static final String OTHER_OPTS_OPT_NAME = "other";
	public static final String NUM_PROCESSORS_FOR_HANDLING_NETWORK_IO_OPTS_SHORT_OPT_NAME = "npfhnio";
	public static final String NUM_PROCESSORS_FOR_HANDLING_NETWORK_IO_OPTS_OPT_NAME = "numprocessorsforhandlingnetworkio";
	public static final String IS_NO_DATA_PARSING_OPTS_SHORT_OPT_NAME = "ndp";
	public static final String IS_NO_DATA_PARSING_OPTS_OPT_NAME = "no";

	public static final String JOB_CONFIGURATION_CLASS_NAME_SHORT_OPT_NAME = "jc";
	public static final String JOB_CONFIGURATION_CLASS_NAME_OPT_NAME = "jobconfiguration";
	
	private static int numEdges = 0;

	public static void main(String[] args) throws Throwable {
		logger.info("Classpath: " + System.getProperty("java.class.path"));
		CommandLine line = parseAndAssertCommandLines(args);
		logger.info(Utils.getStatsLoggingHeader("Argument list"));
		List<String> jvmArgumentList = ManagementFactory.getRuntimeMXBean().getInputArguments();
		for(int i=0; i < jvmArgumentList.size(); i++) {
			logger.info(jvmArgumentList.get(i));
		}
		for (Option option : line.getOptions()) {
			logger.info(option.getLongOpt() + ":" + option.getValue());
		}
		logger.info(Utils.getStatsLoggingHeader("End of argument list"));
		logger.info("Launching GPSNodeRunner: Total memory: "
			+ Runtime.getRuntime().totalMemory() + " Free memory: "
			+ Runtime.getRuntime().freeMemory());
		PropertyConfigurator.configure(line.getOptionValue(LOG4J_CONFIG_FILE_OPT_NAME));
		FileSystem fileSystem = null;
		try {
			fileSystem = Utils.getFileSystem(Utils.getHadoopConfFiles(line));
		} catch (IOException e) {
			System.err.println("Could not access the hdfs file system. Exiting...");
			e.printStackTrace();
			System.exit(-1);
		}

		int localMachineId = Integer.parseInt(line.getOptionValue(MACHINE_ID_OPT_NAME));
		MachineConfig machineConfig = new MachineConfig().load(fileSystem, line.getOptionValue(
			MACHINE_CONFIG_FILE_OPT_NAME));
		MessageSenderAndReceiverFactory messageSenderAndReceiverFactory =
			new MinaMessageSenderAndReceiverFactory();
		long controlMessageWaitTime = line.hasOption(CONTROL_MESSAGES_POLLING_TIME_OPT_NAME) ?
			Long.parseLong(line.getOptionValue(CONTROL_MESSAGES_POLLING_TIME_SHORT_OPT_NAME))
			: 1000;
		int numberOfProcessorsForHandlingNetworkIO =
			line.hasOption(NUM_PROCESSORS_FOR_HANDLING_NETWORK_IO_OPTS_OPT_NAME) ?
			Integer.parseInt(line.getOptionValue(NUM_PROCESSORS_FOR_HANDLING_NETWORK_IO_OPTS_OPT_NAME))
			: DEFAULT_NUM_PROCESSORS_FOR_HANDLING_NETWORK_IO;
		String outputFileName = line.getOptionValue(OUTPUT_FILE_NAME_OPT_NAME);	
		
		logger.info("JC: " + line.getOptionValue(
			JOB_CONFIGURATION_CLASS_NAME_OPT_NAME));
		String jcStringValue = line.getOptionValue(JOB_CONFIGURATION_CLASS_NAME_OPT_NAME);
		if (jcStringValue.contains("###")) {
			jcStringValue = jcStringValue.replace("###", "$");
		}
		GPSJobConfiguration gpsJobConfiguration =
			(GPSJobConfiguration) Class.forName(jcStringValue).newInstance();
		logger.info("GPSJobConfiguration: " + gpsJobConfiguration);
		if (localMachineId != Utils.MASTER_ID) {
			// Starting GPSWorker
			logger.info("Started GPSWorker...");
			startGPSWorker(fileSystem, line, messageSenderAndReceiverFactory, localMachineId,
				machineConfig, outputFileName, controlMessageWaitTime,
				gpsJobConfiguration,
				numberOfProcessorsForHandlingNetworkIO);
		} else {
			Master master = (Master)
				((Constructor<?>) gpsJobConfiguration.getMasterClass().getConstructor(
					CommandLine.class)).newInstance(line);
			logger.info("Constructing GPSMaster. localMachineId: " + localMachineId);
			String masterOutputFileName = line.hasOption(MASTER_OUTPUT_FILE_NAME_OPT_NAME) ?
				line.getOptionValue(MASTER_OUTPUT_FILE_NAME_OPT_NAME) :
					line.getOptionValue(OUTPUT_FILE_NAME_OPT_NAME).replace("machine-stats", "") + "output.master";
			GPSMaster gpsMaster = new GPSMaster(fileSystem, machineConfig,
				messageSenderAndReceiverFactory, controlMessageWaitTime, outputFileName, line,
				line.hasOption(IS_DYNAMIC_OPT_NAME), master, masterOutputFileName,
				numberOfProcessorsForHandlingNetworkIO);
			gpsMaster.startMaster(line);
		}
	}

	@SuppressWarnings("unchecked")
	private static <V extends MinaWritable, E extends MinaWritable, M extends MinaWritable>
		void startGPSWorker(FileSystem fileSystem, CommandLine line,
		MessageSenderAndReceiverFactory messageSenderAndReceiverFactory, int localMachineId,
		MachineConfig machineConfig, String outputFileName, long controlMessagePollingTime,
		GPSJobConfiguration jobConfiguration, int numberOfProcessorsForHandlingNetworkIO)
		throws Throwable {
		VertexFactory<V, E, M> vertexFactory = (VertexFactory<V, E, M>)
			jobConfiguration.getVertexFactoryClass().newInstance();
		Class<V> vertexRepresentativeInstance =
			(Class<V>) jobConfiguration.getVertexValueClass();
		Class<E> edgeRepresentativeInstance =
			(Class<E>) jobConfiguration.getEdgeValueClass();
		Class<M> messageRepresentativeInstance =
			(Class<M>) jobConfiguration.getMessageValueClass();
		Graph<V, E> graphPartition = new ArrayBackedGraph<V, E>(localMachineId,
			machineConfig.getWorkerIds().size(), vertexRepresentativeInstance,
			vertexFactory.newInstance(line), edgeRepresentativeInstance);
//		if (!line.hasOption(RUN_PARTITIONING_SUPERSTEP_OPT_NAME)) {
//			parseGraphPartition(fileSystem, line.getOptionValue(PARTITION_FILE_OPT_NAME), vertexFactory,
//				graphPartition, line);
//		}
		NullEdgeVertex.graphPartition = graphPartition;
		int outgoingDataBufferSizes =
			line.hasOption(OUTGOING_DATA_BUFFER_SIZES_OPT_NAME) ? Integer
				.parseInt(line.getOptionValue(OUTGOING_DATA_BUFFER_SIZES_OPT_NAME)) : DEFAULT_OUTGOING_BUFFER_SIZES;

		// TODO(semih): Remove this graphSize variable.
		int graphSize = 100000;
		AbstractGPSWorker<V, E, M> gpsWorker = null;
		ArrayBackedIncomingMessageStorage<M> incomingMessageStorage =
			new ArrayBackedIncomingMessageStorage<M>(graphPartition, messageRepresentativeInstance,
				line.hasOption(COMBINE_OPT_NAME), machineConfig.getWorkerIds().size());
		int maxMessagesToTransmitConcurrently =
			line.hasOption(MAX_MESSAGES_TO_TRANSMIT_CONCURRENTLY_OPT_NAME) ?
			Integer.parseInt(line.getOptionValue(MAX_MESSAGES_TO_TRANSMIT_CONCURRENTLY_OPT_NAME))
			: DEFAULT_MAX_MESSAGES_TO_TRANSMIT_CONCURRENTLY;
		int numVerticesFrequencyToCheckOutgoingBuffers = line.hasOption(NUM_VERTICES_FREQUENCY_TO_CHECK_OUTGOING_BUFFERS_OPT_NAME) ?
			Integer.parseInt(line.getOptionValue(NUM_VERTICES_FREQUENCY_TO_CHECK_OUTGOING_BUFFERS_OPT_NAME)) :
				DEFAULT_NUM_VERTICES_FREQUENCY_TO_CHECK_OUTGOING_BUFFERS;
		int sleepTimeWhenOutgoingBuffersExceedThreshold = line.hasOption(SLEEP_TIME_WHEN_OUTGOING_BUFFERS_EXCEED_THRESHOLD_OPT_NAME) ?
			Integer.parseInt(line.getOptionValue(SLEEP_TIME_WHEN_OUTGOING_BUFFERS_EXCEED_THRESHOLD_OPT_NAME)) :
				DEFAULT_SLEEP_TIME_WHEN_OUTGOING_BUFFERS_EXCEED_THRESHOLD;
		int largeVertexPartitioningOutdegreeThreshold = line.hasOption(
			LARGE_VERTEX_PARTITIONING_OUTDEGREE_THRESHOLD_OPT_NAME) ?
			Integer.parseInt(line.getOptionValue(LARGE_VERTEX_PARTITIONING_OUTDEGREE_THRESHOLD_OPT_NAME)) :
				DEFAULT_LARGE_VERTEX_PARTITIONING_OUTDEGREE_THRESHOLD;
		boolean isNoDataParsing = line.hasOption(IS_NO_DATA_PARSING_OPTS_OPT_NAME) ?
			Boolean.parseBoolean(line.getOptionValue(IS_NO_DATA_PARSING_OPTS_OPT_NAME)) : false;
		if (!line.hasOption(IS_DYNAMIC_OPT_NAME)) {
			// TODO(semih): Remove the run partitioning superstep argument. It shows up
			// in another location further below.
			gpsWorker = new StaticGPSWorkerImpl<V, E, M>(localMachineId, line, fileSystem, machineConfig,
				graphPartition, vertexFactory, graphSize, outgoingDataBufferSizes,  outputFileName,
				messageSenderAndReceiverFactory, incomingMessageStorage, controlMessagePollingTime,
				maxMessagesToTransmitConcurrently, numVerticesFrequencyToCheckOutgoingBuffers,
				sleepTimeWhenOutgoingBuffersExceedThreshold, messageRepresentativeInstance,
				largeVertexPartitioningOutdegreeThreshold,
				true /* run partitioning superstep */,
				line.hasOption(COMBINE_OPT_NAME), messageRepresentativeInstance,
				edgeRepresentativeInstance, jobConfiguration,
				numberOfProcessorsForHandlingNetworkIO, isNoDataParsing)
				.setNumEdgesInPartition(numEdges);
		} else {
			int dynamismBenefitThreshold = -1;
			int superstepNoToStopDynamism = line.hasOption(SUPERSTEP_NO_TO_STOP_DYNAMISM_OPT_NAME) ?
				Integer.parseInt(line.getOptionValue(SUPERSTEP_NO_TO_STOP_DYNAMISM_OPT_NAME)) :
					DEFAULT_SUPERSTEP_NO_TO_STOP_DYNAMISM;
			if (line.hasOption(DYNAMISM_BENEFIT_THRESHOLD_OPT_NAME)) {
				dynamismBenefitThreshold =
					Integer.parseInt(line.getOptionValue(DYNAMISM_BENEFIT_THRESHOLD_OPT_NAME));
			} else {
				dynamismBenefitThreshold = DEFAULT_DYNAMISM_BENEFIT_THRESHOLD;
			}
			int dynamismEdgeThreshold = DEFAULT_EDGE_THRESHOLD;
			if (line.hasOption(DYNAMISM_EDGE_THRESHOLD_OPT_NAME)) {
				dynamismEdgeThreshold =
					Integer.parseInt(line.getOptionValue(DYNAMISM_EDGE_THRESHOLD_OPT_NAME));
			}
			int minNumberOfEdgesForLargeVertices =
				DEFAULT_DYNAMISM_MIN_NUMBER_OF_EDGES_FOR_LARGE_VERTICES_THRESHOLD;
			if (line.hasOption(DYNAMISM_MIN_NUMBER_OF_EDGES_FOR_LARGE_VERTICES_OPT_NAME)) {
				minNumberOfEdgesForLargeVertices = Integer.parseInt(
					line.getOptionValue(DYNAMISM_MIN_NUMBER_OF_EDGES_FOR_LARGE_VERTICES_OPT_NAME));
			}
			int maxNumberOfVerticesToSendPerSuperstep = DEFAULT_MAX_NUMBER_OF_VERTICES_TO_SEND_PER_SUPERSTEP;
			if (line.hasOption(DYNAMISM_MAX_NUMBER_OF_VERTICES_TO_SEND_PER_SUPERSTEP_OPT_NAME)) {
				maxNumberOfVerticesToSendPerSuperstep = Integer.parseInt(line.getOptionValue(
					DYNAMISM_MAX_NUMBER_OF_VERTICES_TO_SEND_PER_SUPERSTEP_OPT_NAME));
			}
			logger.info("Dynamism benefit threshold: " + dynamismBenefitThreshold);
			logger.info("Dynamism edge threshold: " + dynamismEdgeThreshold);
			gpsWorker = new TwoSyncGreedyDynamicGPSWorker<V, E, M>(localMachineId, line,
				fileSystem, machineConfig, graphPartition, vertexFactory, graphSize,
				outgoingDataBufferSizes, outputFileName, messageSenderAndReceiverFactory,
				incomingMessageStorage, dynamismBenefitThreshold, dynamismEdgeThreshold,
				controlMessagePollingTime, maxMessagesToTransmitConcurrently,
				numVerticesFrequencyToCheckOutgoingBuffers, 
				sleepTimeWhenOutgoingBuffersExceedThreshold, superstepNoToStopDynamism,
				vertexRepresentativeInstance, messageRepresentativeInstance,
				edgeRepresentativeInstance, jobConfiguration,
				largeVertexPartitioningOutdegreeThreshold,
				true /* run partitioning superstep */,
				line.hasOption(COMBINE_OPT_NAME), numberOfProcessorsForHandlingNetworkIO,
				minNumberOfEdgesForLargeVertices, maxNumberOfVerticesToSendPerSuperstep,
				isNoDataParsing)
				.setNumEdgesInPartition(numEdges);
		}
		gpsWorker.startWorker();
	}

//	private static void parseGraphPartition(FileSystem fileSystem, String partitionFile,
//		VertexFactory vertexFactory, Graph graphPartition, CommandLine commandLine)
//		throws IOException {
//		BufferedReader bufferedReader =
//			new BufferedReader(new InputStreamReader(fileSystem.open(new Path(partitionFile))));
//		String line;
//		Integer source;
//		Vertex<MinaWritable, MinaWritable, MinaWritable> newInstance =
//			vertexFactory.newInstance(commandLine);
//		while ((line = bufferedReader.readLine()) != null) {
//			String[] split = line.split("\\s+");
//			try {
//				source = Integer.parseInt(split[0]);
////				if (!graphPartition.contains(source)) {
//				graphPartition.put(source, newInstance.getInitialValue(source));
////				}
//				for (int i = 1; i < split.length; ++i) {
//					graphPartition.addNeighbor(source, Integer.parseInt(split[i]));
//					numEdges++;
//				}
//			} catch (NumberFormatException e) {
//				logger.error("Unexpected exception:" + e.getMessage());
//				System.exit(-1);
//			}
//		}
//		graphPartition.finishedParsingGraph();
//		System.out.println("numNodes: " + graphPartition.size());
//		System.out.println("numEdges: " + numEdges);
//	}

	private static CommandLine parseAndAssertCommandLines(String[] args) {
		CommandLineParser parser = new PosixParser();
		Options options = new Options();
		options.addOption(Utils.HADOOP_CONF_FILES_SHORT_OPT_NAME, Utils.HADOOP_CONF_FILES_OPT_NAME,
			true, "full path name of the hadoop configuration files that is needed to access hdfs " +
			"programmatically. These are usually the locations of the core-site and/or " +
			"mapred-site");
		options.addOption(MACHINE_ID_SHORT_OPT_NAME, MACHINE_ID_OPT_NAME, true,
			"required id of this machine loading GPSNode");
		options.addOption(MACHINE_CONFIG_FILE_SHORT_OPT_NAME, MACHINE_CONFIG_FILE_OPT_NAME, true,
			"required location of the machine configuration file");
		options.addOption(PARTITION_FILE_SHORT_OPT_NAME, PARTITION_FILE_OPT_NAME, true,
			"required location of the graph partition file");
		options.addOption(INPUT_FILES_SHORT_OPT_NAME, INPUT_FILES_OPT_NAME, true,
			"list of input files");
		options.addOption(IS_DYNAMIC_SHORT_OPT_NAME, IS_DYNAMIC_OPT_NAME, false,
			"dynamicly shuffle nodes.");
		options.addOption(OUTPUT_FILE_NAME_SHORT_OPT_NAME, OUTPUT_FILE_NAME_OPT_NAME, true,
			"required output file name");
		options.addOption(MASTER_OUTPUT_FILE_NAME_SHORT_OPT_NAME, MASTER_OUTPUT_FILE_NAME_OPT_NAME,
			true, "master output file name");
		options.addOption(DYNAMISM_BENEFIT_THRESHOLD_SHORT_OPT_NAME,
			DYNAMISM_BENEFIT_THRESHOLD_OPT_NAME, true,
			"benefit threshold for moving nodes. default is 1.");
		options.addOption(DYNAMISM_MIN_NUMBER_OF_EDGES_FOR_LARGE_VERTICES_OPT_NAME,
			DYNAMISM_MIN_NUMBER_OF_EDGES_FOR_LARGE_VERTICES_SHORT_OPT_NAME, true,
			"dynamism minimum number of edges needed to consider a vertex a large vertex. used for controlling balancing of the edges.");
		options.addOption(DYNAMISM_MAX_NUMBER_OF_VERTICES_TO_SEND_PER_SUPERSTEP_OPT_NAME,
			DYNAMISM_MAX_NUMBER_OF_VERTICES_TO_SEND_PER_SUPERSTEP_SHORT_OPT_NAME, true,
			"dynamism maximum number of vertices to send per superstep per worker. used for controlling balancing of the workers.");
		options.addOption(DYNAMISM_EDGE_THRESHOLD_SHORT_OPT_NAME, DYNAMISM_EDGE_THRESHOLD_OPT_NAME,
			true, "edge threshold for moving nodes. default is 1");
		options.addOption(LOG4J_CONFIG_FILE_SHORT_OPT_NAME, LOG4J_CONFIG_FILE_OPT_NAME, true,
			"required log4j config file name");
		options.addOption(LOG4J_CONFIG_FILE_SHORT_OPT_NAME, LOG4J_CONFIG_FILE_OPT_NAME, true,
			"required log4j config file name");
		options.addOption(OUTGOING_DATA_BUFFER_SIZES_SHORT_OPT_NAME,
			OUTGOING_DATA_BUFFER_SIZES_OPT_NAME, true,
			"size of the outgoing buffers. default is 64K.");
		options.addOption(CONTROL_MESSAGES_POLLING_TIME_SHORT_OPT_NAME,
			CONTROL_MESSAGES_POLLING_TIME_OPT_NAME, true,
			"the frequency for the main worker thread to poll control messages in milliseconds."
			+ " for example when checking whether or not all data has been sent successfully.");
		options.addOption(MAX_MESSAGES_TO_TRANSMIT_CONCURRENTLY_SHORT_OPT_NAME,
			MAX_MESSAGES_TO_TRANSMIT_CONCURRENTLY_OPT_NAME, true,
			"max number of outgoing buffers to transmit concurrently.");
		options.addOption(NUM_VERTICES_FREQUENCY_TO_CHECK_OUTGOING_BUFFERS_SHORT_OPT_NAME,
			NUM_VERTICES_FREQUENCY_TO_CHECK_OUTGOING_BUFFERS_OPT_NAME, true,
			"each this many vertices the worker will check whether there are many outgoing buffers not sent");
		options.addOption(SLEEP_TIME_WHEN_OUTGOING_BUFFERS_EXCEED_THRESHOLD_SHORT_OPT_NAME,
			SLEEP_TIME_WHEN_OUTGOING_BUFFERS_EXCEED_THRESHOLD_OPT_NAME, true,
			"how long to sleep when there are many outgoing unsent buffers.");
		options.addOption(LARGE_VERTEX_PARTITIONING_OUTDEGREE_THRESHOLD_SHORT_OPT_NAME,
			LARGE_VERTEX_PARTITIONING_OUTDEGREE_THRESHOLD_OPT_NAME, true,
			"num outgoing edges a vertex should have to partitioned across all machines.");
		options.addOption(SUPERSTEP_NO_TO_STOP_DYNAMISM_SHORT_OPT_NAME,
			SUPERSTEP_NO_TO_STOP_DYNAMISM_OPT_NAME, true,
			"the superstep no to stop dynamism and keep using the static partitioning.");
		options.addOption(COMBINE_SHORT_OPT_NAME, COMBINE_OPT_NAME, false,
			"whether to combine messages as they are being parsed.");
		options.addOption(OTHER_OPTS_SHORT_OPT_NAME,
			OTHER_OPTS_OPT_NAME, true, "other application specific opts.");
		options.addOption(NUM_PROCESSORS_FOR_HANDLING_NETWORK_IO_OPTS_SHORT_OPT_NAME,
			NUM_PROCESSORS_FOR_HANDLING_NETWORK_IO_OPTS_OPT_NAME, true, "number of processors to" +
					"handle network io.");
		options.addOption(IS_NO_DATA_PARSING_OPTS_OPT_NAME,
			IS_NO_DATA_PARSING_OPTS_SHORT_OPT_NAME, true,
			"whether data parsing should be done or not. for partitioning experiments.");
		options.addOption(JOB_CONFIGURATION_CLASS_NAME_OPT_NAME,
			JOB_CONFIGURATION_CLASS_NAME_SHORT_OPT_NAME, true,
			"name of the job configuration file.");
		try {
			CommandLine line = parser.parse(options, args);
			assert line.hasOption(MACHINE_ID_OPT_NAME) : MACHINE_ID_SHORT_OPT_NAME + "or "
				+ MACHINE_CONFIG_FILE_OPT_NAME + " option is required";
			// Check machine id is a valid byte
			Byte.parseByte(line.getOptionValue(MACHINE_ID_OPT_NAME));
			assert line.hasOption(MACHINE_CONFIG_FILE_OPT_NAME) : MACHINE_CONFIG_FILE_SHORT_OPT_NAME
				+ "or " + MACHINE_CONFIG_FILE_OPT_NAME + " option is required";
			assert line.hasOption(OUTPUT_FILE_NAME_OPT_NAME) : OUTPUT_FILE_NAME_SHORT_OPT_NAME
				+ "or " + OUTPUT_FILE_NAME_OPT_NAME + " option is required";
			assert line.hasOption(LOG4J_CONFIG_FILE_OPT_NAME) : LOG4J_CONFIG_FILE_SHORT_OPT_NAME
				+ "or " + LOG4J_CONFIG_FILE_OPT_NAME + " option is required";
			return line;
		} catch (ParseException e) {
			logger.error("Unexpected exception:" + e.getMessage());
			System.exit(-1);
			return null;
		}
	}
}
#!/usr/bin/env python

###############
# Constants
###############
BYTE_PER_GB = 1024*1024*1024.0
KB_PER_GB = 1024*1024.0

MS_PER_SEC = 1000.0
SEC_PER_MIN = 60.0

ALGS = ('pagerank', 'sssp', 'wcc', 'mst')
ALG_MST = 'mst'
ALG_PREMIZAN = 'premizan'
GRAPHS = ('livejournal', 'orkut', 'arabic', 'twitter', 'uk0705')
MACHINES = ('16', '32', '64', '128')

SYSTEMS = ('giraph', 'gps', 'graphlab', 'mizan')
SYS_GIRAPH, SYS_GPS, SYS_GRAPHLAB, SYS_MIZAN = SYSTEMS

SYS_MODES = (('0','1'),      # Giraph: byte array, hash map
             ('0','1','2'),  # GPS: none, LALP, dynamic
             ('0','1'),      # GraphLab: sync, async
             ('0',))         # Mizan: static
SYSMODE_HASH = '1'           # premizan hash partitioning

# combination of all systems and their sys modes
ALL_SYS = [(system, sysmode)
            for system, sysmodes in zip(SYSTEMS, SYS_MODES)
            for sysmode in sysmodes]


# conversion modes
MODES = (0, 1, 2)
MODE_TIME, MODE_MEM, MODE_NET = MODES

# names for relevant statistics (indexed by "mode")
STATS = (('run', 'io'),                      # time
         ('mem_min', 'mem_max', 'mem_avg'),  # memory
         ('eth_recv', 'eth_sent'))           # net

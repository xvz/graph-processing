#!/usr/bin/env python

"""Batch parser that extracts and prints out results for given log files."""

import os, sys, glob
import argparse, itertools

# do some parallel computing
#from joblib import Parallel, delayed

###############
# Constants
###############
BYTE_PER_GB = 1024*1024*1024.0
KB_PER_GB = 1024*1024.0

MS_PER_SEC = 1000.0

ALG_PREMIZAN = 'premizan'

SYSTEMS = ('giraph', 'gps', 'mizan', 'graphlab')
SYS_GIRAPH, SYS_GPS, SYS_MIZAN, SYS_GRAPHLAB = SYSTEMS


###############
# Parse args
###############
def check_system(system):
    try:
        s = int(system)
        if (s < 0) or (s >= len(SYSTEMS)):
            raise argparse.ArgumentTypeError('Invalid system')
        return s
    except:
        raise argparse.ArgumentTypeError('Invalid system')

def check_cores(cores):
    try:
        c = int(cores)
        if c < 1:
            raise argparse.ArgumentTypeError('Invalid core count')
        return c
    except:
        raise argparse.ArgumentTypeError('Invalid core count')

parser = argparse.ArgumentParser(description='Outputs experimental data for specified log files.')
parser.add_argument('system', type=check_system,
                    help='system: 0 for Giraph, 1 for GPS, 2 for Mizan, 3 for GraphLab (invalid system will result in invalid time values)')
parser.add_argument('log', type=str, nargs='+',
                    help='an experiment\'s time log file, can be a regular expression (e.g. pagerank_orkut-adj.txt_16_0_20140101-123050_time.txt or page*or*_0_*time.txt)')
parser.add_argument('--master', action='store_true', default=False,
                    help='get mem/net statistics for the master rather than the worker machines')
#parser.add_argument('--cores', type=check_cores, dest='n_cores', default=4,
#                    help='number of cores to use (> 0), default=4')

system = SYSTEMS[parser.parse_args().system]
logs_re = parser.parse_args().log
do_master = parser.parse_args().master
#n_cores = parser.parse_args().n_cores

logs = [f for re in logs_re for f in glob.glob(re)]


###############
# Main parsers
###############
def time_parser(log_prefix, system, alg):
    """Parses running and IO times for a single run.

    Arguments:
    log_prefix -- the prefix of one experiment run's log files (str)
    system -- the system tested (str)
    alg -- the algorithm tested (str)

    Returns:
    A tuple (running time, IO time) or (0,0) if logs files are
    missing.
    """

    log_files = glob.glob(log_prefix + '_time.txt')
    if len(log_files) != 1:
        return (0,0)

    log_file = log_files[0]

    io = run = total = 0

    if system == SYS_GIRAPH:
        io = 0
        for line in open(log_file):
            if "Setup " in line:
                io = io + float(line.split()[5].split('=')[1])
            elif "Input superstep " in line:
                io = io + float(line.split()[6].split('=')[1])
            elif "Shutdown " in line:
                io = io + float(line.split()[5].split('=')[1])
            elif "Total (mil" in line:
                total = float(line.split()[5].split('=')[1])

        return ((total - io)/(MS_PER_SEC), io/(MS_PER_SEC))

    elif system == SYS_GPS:
        start = computestart = end = 0
        for line in open(log_file):
            if "SYSTEM_START_TIME " in line:
                start = float(line.split()[1])
            elif "START_TIME " in line:
                computestart = float(line.split()[1])
            elif "-1-LATEST_STATUS_TIMESTAMP " in line:
                end = float(line.split()[1])

        return ((end - computestart)/(MS_PER_SEC),
                (computestart - start)/(MS_PER_SEC))

    elif system == SYS_GRAPHLAB:
        for line in open(log_file):
            if "TOTAL TIME (sec)" in line:
                total = float(line.split()[3])
            elif "Finished Running engine" in line:
                run = float(line.split()[4])

        return (run, (total - run))

    elif system == SYS_MIZAN:
        if alg == ALG_PREMIZAN:
            for line in open(log_file):
                if "TOTAL TIME (sec)" in line:
                    io = float(line.split()[3])

            return (0.0, io)
        else:
            for line in open(log_file):
                if "TIME: Total Running Time without IO =" in line:
                    run = float(line.split()[7])
                elif "TIME: Total Running Time =" in line:
                    total = float(line.split()[5])

            return (run, (total - run))


def mem_parser(log_prefix, machines):
    """Parses memory usage of a single run.

    Arguments:
    log_prefix -- the prefix of one experiment run's log files (str)
    machines -- number of machines tested (int)

    Returns:
    A tuple (minimum mem, avg mem, maximum mem), where "mem" corresponds to
    the max memory used at each machine (GB), or (0,0,0) if logs are missing.
    """

    if do_master:
        log_files = glob.glob(log_prefix + '_0_mem.txt')
        if len(log_files) != 1:
            return (0,0,0)
    else:
        log_files = [f for f in glob.glob(log_prefix + '_*_mem.txt') if "_0_mem.txt" not in f]
        if len(log_files) < machines:
            return (0,0,0)

    def parse(log):
        """Parses a single log file for mem stats.

        Returns: the max memory usage in GB.
        """
        # note that this "mems" is the memory usage (per second) of a SINGLE machine
        mems = [float(line.split()[2]) for line in open(log).readlines()]
        return (max(mems) - min(mems))/KB_PER_GB

    # list of each machine's maximum memory usage
    mems = [parse(log) for log in log_files]

    return (min(mems), sum(mems)/len(mems), max(mems))


def net_parser(log_prefix, machines):
    """Parses network usage of a single run.

    Arguments:
    log_prefix -- the prefix of one experiment run's log files (str)
    machines -- number of machines tested (int)

    Returns:
    A tuple (eth recv, eth sent), where eth recv/sent is the total network data
    received/sent across all worker machines (GB), or (0,0) if logs are missing.
    """

    if do_master:
        log_files = glob.glob(log_prefix + '_0_nbt.txt')
        if len(log_files) != 1:
            return (0,0)
    else:
        log_files = [f for f in glob.glob(log_prefix + '_*_nbt.txt') if "_0_nbt.txt" not in f]
        if len(log_files) < machines:
            return (0,0)

    def parse(log):
        """Parses a single log file for net stats.

        Returns: (recv, sent) tuple in GB.
        """

        # bash equivalent:
        # recv=$((-$(cat "$log" | grep "eth0" | awk '{print $2}' | tr '\n' '+')0))
        # sent=$((-$(cat "$log" | grep "eth0" | awk '{print $10}' | tr '\n' '+')0))
        recv = 0
        sent = 0

        for line in open(log).readlines():
            # lines appear as initial followed by final, so this does the correct computation
            if "eth0" in line:
                recv = float(line.split()[1]) - recv
                sent = float(line.split()[9]) - sent

        return (recv/BYTE_PER_GB, sent/BYTE_PER_GB)

    eth = [parse(log) for log in log_files]
    eth = zip(*eth)
    return (sum(eth[0]), sum(eth[1]))


def check_files(log_prefix, machines):
    """Ensures all log files are present.

    Arguments:
    log_prefix -- the prefix of one experiment run's log files (str)
    machines -- number of machines tested (int)

    Returns:
    A tuple of a boolean and a string. The booleand is False if there
    is a critical missing log, and True otherwise. The string gives the
    source of the error, or a warning for missing CPU/net logs.
    """
    
    logname = os.path.basename(log_prefix)

    if len(glob.glob(log_prefix + '_time.txt')) == 0:
        return (False, "\n  ERROR: " + logname + "_time.txt missing!")

    stats = ['nbt', 'mem', 'cpu', 'net']

    if do_master:
        for stat in stats:            
            if len(glob.glob(log_prefix + '_0_' + stat + '.txt')) == 0:
                return (False, "\n  ERROR: " + logname + "_0_" + stat + ".txt missing!")
    else:
        for stat in stats:            
            # machines+1, as the master has those log files too
            if len(glob.glob(log_prefix + '_*_' + stat + '.txt')) < machines+1:
                return (False, "\n  ERROR: " + logname + "_*_" + stat + ".txt missing!")

    return (True, "")


###############
# Output data
###############
def single_iteration(log):
    """Outputs results for one run of an experiment.

    Arguments: time log file name.
    Returns: results for the run as an output friendly string.
    """

    # cut via range, in case somebody decides to put _time.txt in the path
    logname = os.path.basename(log)[:-len('_time.txt')]
    alg, _, machines, _, _ = logname.split('_')

    # header string
    if (system == SYS_MIZAN) and (alg != ALG_PREMIZAN):
        header = logname + " (excludes premizan time)"
    elif (system == SYS_GIRAPH) and (len(glob.glob(log)) != 0):
        header = logname + " (cancelled job)"
        for line in open(log):
            if "Job complete: " in line:
                header = logname + " (" + line.split()[6] + ")"
                break
    else:
        header = logname

    log_prefix = log[:-len('_time.txt')]

    is_ok, err_str = check_files(log_prefix, int(machines))

    if is_ok:
        time_run, time_io = time_parser(log_prefix, system, alg)
        mem_min, mem_avg, mem_max = mem_parser(log_prefix, int(machines))
        eth_recv, eth_sent = net_parser(log_prefix, int(machines))
         
        stats = (time_run+time_io, time_io, time_run, mem_min, mem_avg, mem_max, eth_recv, eth_sent)
        separator = "------------+------------+------------+--------------------------------+---------------------------"
        return header + err_str + "\n" + separator + "\n  %8.2fs |  %8.2fs |  %8.2fs | %7.3f / %7.3f / %7.3f GB |  %8.3f / %8.3f GB \n" % stats + separator
    else:
        return header + err_str


# no point in doing parallel computation b/c # of logs parsed is usually not very large
#out = Parallel(n_jobs=n_cores)(delayed(single_iteration)(log) for log in logs)

# output results serially
print("")
print("==================================================================================================")
print(" Total time | Setup time | Comp. time |   Memory usage (min/avg/max)  | Total net I/O (recv/sent) ")
print("============+============+============+===============================+===========================")
print("")
for log in logs:
    print(single_iteration(log))
    print("")

# another friendly reminder of what each thing is...
print("============+============+============+================================+===========================")
print(" Total time | Setup time | Comp. time |    Memory usage (min/avg/max)  | Total net I/O (recv/sent) ")
print("===================================================================================================")
print("")

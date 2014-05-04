#!/usr/bin/env python
import sys, glob
import argparse, itertools
import numpy as np

# do some parallel computing
from joblib import Parallel, delayed

from constants import *

# store script dir (so we know where logs are)
SCRIPT_DIR=sys.path[0]

###############
# Parse args
###############
def check_mode(mode):
    try:
        m = int(mode)
        if (m < 0) or (m >= len(MODES)):
            raise argparse.ArgumentTypeError('Invalid mode')
        return m
    except:
        raise argparse.ArgumentTypeError('Invalid mode')

def check_cores(cores):
    try:
        c = int(cores)
        if c < 1:
            raise argparse.ArgumentTypeError('Invalid core count')
        return c
    except:
        raise argparse.ArgumentTypeError('Invalid core count')

parser = argparse.ArgumentParser(description='Generates experimental data (means and confidence intervals) from all log files.')
parser.add_argument('mode', type=check_mode,
                    help='mode to use: 0 for time, 1 for memory, 2 for network')
parser.add_argument('--master', action='store_true', default=False,
                    help='get mem/net statistics for the master rather than the worker machines (only relevant for mode=1,2)')
parser.add_argument('--cores', type=check_cores, dest='n_cores', default=4,
                    help='number of cores to use (> 0), default=4')

mode = parser.parse_args().mode
do_master = parser.parse_args().master
n_cores = parser.parse_args().n_cores

###############
# Main parsers
###############
def time_parser(log_prefix, system, alg):
    """Parses running (computation), IO (setup), and total times for a single run.

    Arguments:
    log_prefix -- the prefix of one experiment run's log files (str)
    system -- the system tested (str)
    alg -- the algorithm tested (str)

    Returns:
    A tuple (computation time, IO time, total time) or (0,0,0) if log files are missing.
    """

    log_files = glob.glob(log_prefix + '_time.txt')
    if len(log_files) != 1:
        return (0,0,0)

    log_file = log_files[0]

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

        return ((total - io)/(MS_PER_SEC*SEC_PER_MIN),
                io/(MS_PER_SEC*SEC_PER_MIN),
                total/(MS_PER_SEC*SEC_PER_MIN))

    elif system == SYS_GPS:
        for line in open(log_file):
            if "SYSTEM_START_TIME " in line:
                start = float(line.split()[1])
            elif "START_TIME " in line:
                computestart = float(line.split()[1])
            elif "-1-LATEST_STATUS_TIMESTAMP " in line:
                end = float(line.split()[1])

        return ((end - computestart)/(MS_PER_SEC*SEC_PER_MIN),
                (computestart - start)/(MS_PER_SEC*SEC_PER_MIN),
                (end - start)/(MS_PER_SEC*SEC_PER_MIN))

    elif system == SYS_GRAPHLAB:
        for line in open(log_file):
            if "TOTAL TIME (sec)" in line:
                total = float(line.split()[3])
            elif "Finished Running engine" in line:
                run = float(line.split()[4])

        return (run/SEC_PER_MIN, (total - run)/SEC_PER_MIN, total/SEC_PER_MIN)

    elif system == SYS_MIZAN:
        if alg == ALG_PREMIZAN:
            for line in open(log_file):
                if "TOTAL TIME (sec)" in line:
                    io = float(line.split()[3])

            return (0.0, io/SEC_PER_MIN, io/SEC_PER_MIN)
        else:
            for line in open(log_file):
                if "TIME: Total Running Time without IO =" in line:
                    run = float(line.split()[7])
                elif "TIME: Total Running Time =" in line:
                    total = float(line.split()[5])

            return (run/SEC_PER_MIN, (total - run)/SEC_PER_MIN, total/SEC_PER_MIN)


def mem_parser(log_prefix, machines):
    """Parses memory usage of a single run.

    Arguments:
    log_prefix -- the prefix of one experiment run's log files (str)
    machines -- number of machines tested (int)

    Returns:
    A tuple (minimum mem, maximum mem, avg mem), where "mem" corresponds to
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
    mems = np.array([parse(log) for log in log_files])

    return (np.min(mems), np.max(mems), np.mean(mems))


def net_parser(log_prefix, machines):
    """Parses network usage of a single run.

    Arguments:
    log_prefix -- the prefix of one experiment run's log files (str)
    machines -- number of machines tested (int)

    Returns:
    A tuple (min recv, max recv, avg recv, min sent, max sent, avg sent),
    where recv/sent is the network data received/sent across worker machines (GB),
    or (0,0,0,0,0,0) if logs are missing.
    """

    if do_master:
        log_files = glob.glob(log_prefix + '_0_nbt.txt')
        if len(log_files) != 1:
            return (0,0,0,0,0,0)
    else:
        log_files = [f for f in glob.glob(log_prefix + '_*_nbt.txt') if "_0_nbt.txt" not in f]
        if len(log_files) < machines:
            return (0,0,0,0,0,0)

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
    eth = np.array(zip(*eth))
    return (np.min(eth[0]), np.max(eth[0]), np.mean(eth[0]),
            np.min(eth[1]), np.max(eth[1]), np.mean(eth[1]))


def experiment_parser(exp_prefix, machines, system, alg):
    """Parses multiple runs of a single experiment.

    Arguments:
    exp_prefix -- the prefix of the experiment's log files (str)
    machines -- number of machines tested (str)
    system -- the system tested (str)
    alg -- the algorithm tested (str)

    Returns:
    List of tuples, with each tuple indexed according to STATS[mode].
    Each tuple gives the individual results for one experiment run
    (so, e.g., 5 runs per experiment gives a list of 5 tuples).
    Missing logs will result in tuples of 0s.
    """

    # NOTE: the difference between "experiment" and "run"
    # is whether or not the prefix name has a timestamp.
    #
    # E.g., pagerank_orkut-adj.txt_16_0 is an experiment, while
    # pagerank_orkut-adj.txt_16_0_20140101-123050 is one run of
    # that experiment.

    parser_funcs = (time_parser, mem_parser, net_parser)
    other_args = ([system, alg], [int(machines)], [int(machines)])

    # match all runs of this experiment
    # NOTE: use sorted(glob.glob(...)) to get runs in order of their log names
    exp_logs = glob.glob(exp_prefix + '_*_time.txt')

    if len(exp_logs) == 0:
        return [(0,)*len(STATS[mode])];

    # stripping _time.txt gives prefix for a single run
    return [parser_funcs[mode](run_prefix[:-len('_time.txt')], *other_args[mode])
            for run_prefix in exp_logs]


###############
# Output data
###############
def single_iteration(system, sysmode, machines, alg, graph):
    """Outputs results for one experiment.

    Arguments: all strings (are all elements of constant lists).
    Returns: list of strings, indexed by STATS[mode], each with 'varname = value\nvarname = value'
    """

    output_varname = system + '_' + sysmode + '_' + machines + '_' + alg + '_' + graph
    exp_prefix = SCRIPT_DIR + '/../' + system + '/' + machines + '/' + alg + '_' + graph + '*' + '_' + machines + '_' + sysmode

    results = experiment_parser(exp_prefix, machines, system, alg)
    results = zip(*results)        # [(a,b),(c,d)] -> [(a,c),(b,d)]

    # line to be printed synchronously/sequentially
    # NOTE: to see results of each run, put np.mean/np.std as strings instead
    return [output_varname + '_' + stat + '_avg = ' + str(np.mean(results[i])) + '\n' +
            output_varname + '_' + stat + '_ci = ' + str(np.std(results[i])*(1.96/np.sqrt(5)))
            for i,stat in enumerate(STATS[mode])]

# do parallel computation
out = Parallel(n_jobs=n_cores)(delayed(single_iteration)(system, sysmode, machines, alg, graph)
                               for ((system,sysmode), machines, alg, graph) in itertools.product(ALL_SYS, MACHINES, ALGS, GRAPHS))

# premizan is a special case
out = out + Parallel(n_jobs=n_cores)(delayed(single_iteration)(SYS_MIZAN, SYSMODE_HASH, machines, ALG_PREMIZAN, graph)
                                     for machines, graph in itertools.product(MACHINES, GRAPHS))

# output results serially
for arr in out:
    for line in arr:
        print(line)
    print("")

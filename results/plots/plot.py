#!/usr/bin/env python
import os, sys
import argparse, itertools
import numpy as np

from constants import *

SCRIPT_DIR=sys.path[0]

###############
# Parse args
###############
def check_mode(mode):
    try:
        m = int(mode)
        if not m in MODES:
            raise argparse.ArgumentTypeError('Invalid mode')
        return m
    except:
        raise argparse.ArgumentTypeError('Invalid mode')

parser = argparse.ArgumentParser(description='Plots parsed experimental data values.')
parser.add_argument('mode', type=check_mode,
                    help='mode to use: 0 for time, 1 for memory, 2 for network')

# additional data selection options
parser.add_argument('--master', action='store_true', default=False,
                    help='plot mem/net statistics for the master rather than the worker machines (mode=1,2)')
parser.add_argument('--premizan', action='store_true', default=False,
                    help='plot mem/net statistics for premizan, Mizan\'s graph partitioner (mode=1,2)')

# additional mode selection options
parser.add_argument('--total-time', action='store_true', default=False,
                    help='plot total time (stacked bars) instead of separate setup and computation times (mode=0)')

memnet_group = parser.add_mutually_exclusive_group()
memnet_group.add_argument('--plot-sum', action='store_true', default=False,
                          help='plot only sum of usage across worker machines (mode=1,2)')
memnet_group.add_argument('--plot-avg', action='store_true', default=False,
                          help='plot only average usage, instead of min, max, avg (mode=1,2)')
memnet_group.add_argument('--plot-max', action='store_true', default=False,
                          help='plot only maximum usage, instead of min, max, avg (mode=1,2)')

# save related items
parser.add_argument('--save-png', action='store_true', default=False,
                    help='save plots as PNG files (200 DPI) instead of displaying them')
eps_group = parser.add_mutually_exclusive_group()
eps_group.add_argument('--save-eps', action='store_true', default=False,
                       help='save plots as EPS files instead of displaying them')
eps_group.add_argument('--save-paper', action='store_true', default=False,
                       help='save plots as EPS files for paper (uses large text labels)')

mode = parser.parse_args().mode
do_master = parser.parse_args().master
do_premizan = parser.parse_args().premizan

do_time_tot = parser.parse_args().total_time
do_sum_only = parser.parse_args().plot_sum
do_avg_only = parser.parse_args().plot_avg
do_max_only = parser.parse_args().plot_max

save_png = parser.parse_args().save_png
save_eps = parser.parse_args().save_eps
save_paper = parser.parse_args().save_paper
save_file = True if (save_png or save_eps or save_paper) else False

# save_paper is just a special case of save_eps
if save_paper:
    save_eps = True

# import data
if mode == MODE_TIME:
    from data_time import *

elif mode == MODE_MEM:
    if do_master:
        from data_mem_master import *
    else:
        from data_mem import *

elif mode == MODE_NET:
    if do_master:
        from data_net_master import *
    else:
        from data_net import *

# we have to import matplotlib.pyplot here, as its backend
# will get reset if we don't import matplotlib first
import matplotlib
matplotlib.rcParams['figure.max_open_warning'] = 42

if save_file:
    # using tight_layout requires Agg, so we can't use PS
    matplotlib.use('Agg')

import matplotlib.pyplot as plt
from matplotlib.ticker import MultipleLocator
from matplotlib.ticker import MaxNLocator
from matplotlib.patches import Rectangle

###############
# Format data
###############
# Genneral conventions:
#
# For each plot, bars represent a particular system in a partciular mode.
# Bars are clustered/grouped by the number of machines used in the experiment.
# Finally, plots are separated into different figures based on algorithm + graph.
#
# Additionally, each "mode" (time, mem, or net) can have multiple different
# "plot types". These are just extra figures that display more data.
#
# E.g., using gen-data's output variable names:
#
# <giraph_0>_<16>_<pagerank_livejournal>_<run_avg>
# single bar   ^         figure            value
#          bar group


## Matrix for one alg and one graph, with rows indexed by system + system mode
## and columns indexed by number of machines
#alg_graph_run_avg = [[system + '_' + sysmode + '_' + machines + '_alg_graph_run_avg'
#                      for machines in MACHINES]
#                     for (system,sysmode) in ALL_SYS]
#
## Tuple of matrices for a particular algorithm
#alg_run_avg = [[[system + '_' sysmode + '_' + machines + '_alg_' + graph + '_run_avg'
#                 for machines in MACHINES]
#                for (system,sysmode) in ALL_SYS]
#               for graph in GRAPHS]
#
## Tuple of tuples of matrics for one particular statistic
#run_avg = = [[[[system + '_' + sysmode + '_' + machines + '_' + alg + '_' + graph + '_run_avg'
#                for (system,sysmode) in ALL_SYS]
#               for machines in MACHINES]
#              for graph in GRAPHS]
#             for alg in ALGS]

# Use eval to get the value of the variable name given by the string
stats_dict = {stat + suffix: megatuple
              for (stat,suffix) in itertools.product(STATS[mode],('_avg', '_ci'))
              for megatuple in
              np.array([[[[[eval(system + '_' + sysmode + '_' + machines + '_' + alg + '_' + graph + '_' + stat + suffix)
                            for machines in MACHINES]
                           for (system,sysmode) in ALL_SYS]
                          for graph in GRAPHS]
                         for alg in ALGS]])}

# Premizan is special case. Each entry is a tuple of matrices,
# whose rows are all 0s except for the Mizan row. This Mizan row
# holds premizan stats.
#
# This setup is only relevant for plotting time (which needs permizan
# as an extra I/O add-on for Mizan).
#
# "+" between matrices joins Mizan row (premizan data) with the 0s matrix.
# TODO: constants hacked in..
premizan_dict = {stat + suffix: megatuple
                 for (stat,suffix) in itertools.product(STATS[mode],('_avg', '_ci'))
                 for megatuple in
                 np.array([[[[0]*len(MACHINES)]*(len(ALL_SYS)-3)      # Giraph, GPS
                            + [[eval(SYS_MIZAN + '_' + SYSMODE_HASH + '_' + machines + '_' + ALG_PREMIZAN + '_' + graph + '_' + stat + suffix)
                                for machines in MACHINES]]
                            + [[0]*len(MACHINES)]*2                   # GraphLab
                            for graph in GRAPHS]])}


# Simple way to handle premizan: just plot 0s for all the other systems.
# HACK: yes, we're changing the constant ALGS...
if do_premizan:
    stats_dict = {key: np.array([val]) for key, val in premizan_dict.iteritems()}
    premizan_dict = {key: np.array([[[0]*len(MACHINES)]*len(ALL_SYS)]*len(GRAPHS)) for key in premizan_dict}
    ALGS = ('premizan',)


####################
# Plot constants
####################
## Things to plot + save-file suffix
# defaults
TIME_TYPE = ('time',)
MEM_TYPE = ('mem',)
NET_TYPE = ('recv', 'sent')

# options
if do_time_tot:
    TIME_TYPE = ('time_tot',)

# master is single machine, so min = max = avg = sum
if not do_master:
    if do_sum_only:
        MEM_TYPE = ('mem_sum',)
        NET_TYPE = ('recv_sum','sent_sum')
    elif do_avg_only:
        MEM_TYPE = ('mem_avg',)
        NET_TYPE = ('recv_avg','sent_avg')
    elif do_max_only:
        MEM_TYPE = ('mem_max',)
        NET_TYPE = ('recv_max','sent_max')

PLOT_TYPES = (TIME_TYPE, MEM_TYPE, NET_TYPE)


## decoration (np.array needed for advanced indexing)
# more chars = denser patterns; can also mix and match different ones
PATTERNS = np.array(('..','*',             # Giraph
                     '///','o','\\\\\\',   # GPS
                     'xx',                 # Mizan
                     '++', 'O'))           # GraphLab

# old: #ff7f00 (orange), #1f78b4 (blue), #7ac36a (darker green)
COLORS = np.array(('#faa75b','#faa75b',            # Giraph
                   '#5a9bd4','#5a9bd4','#5a9bd4',  # GPS
                   '#b2df8a',                      # Mizan
                   '#eb65aa','#eb65aa'))           # GraphLab

COLOR_PREMIZAN = '#737373'
COLOR_IO = (0.9, 0.9, 0.9)
COLOR_ERR = (0.3, 0.3, 0.3)

## labels
LEGEND_LABELS = ('Giraph (byte array)', 'Giraph (hash map)',
                 'GPS (none)', 'GPS (LALP)', 'GPS (dynamic)',
                 'Mizan (static)',
                 'Graphlab (sync)', 'GraphLab (async)')

# all possible graph labels
# must be an array, b/c we use np's list slicing
GRAPH_LABELS = np.array((('LJ (16)', 'LJ (32)', 'LJ (64)', 'LJ (128)'),
                         ('OR (16)', 'OR (32)', 'OR (64)', 'OR (128)'),
                         ('AR (16)', 'AR (32)', 'AR (64)', 'AR (128)'),
                         ('TW (16)', 'TW (32)', 'TW (64)', 'TW (128)'),
                         ('UK (16)', 'UK (32)', 'UK (64)', 'UK (128)')))

if save_paper:
    FONTSIZE = 20
    VAL_FONTSIZE = 4
    F_FONTSIZE = 12    # for "F" of failed bars
elif save_file:
    FONTSIZE = 12
    VAL_FONTSIZE = 3   # for text values on top of bars
    F_FONTSIZE = 11
else:
    FONTSIZE = 12      # 12 is default
    VAL_FONTSIZE = 8
    F_FONTSIZE = 12

## misc values
# left/right margins of each bar group
BAR_MARGIN = 0.05

# how much extra space to leave at the top of each plot
YMAX_FACTOR = 1.05

# location of bar groups (changes depending on # of machines)
IND = np.array([np.arange(len(g))+BAR_MARGIN for g in GRAPH_LABELS])


####################
# Plot functions
####################
# label formats indexed by mode
LABEL_FORMAT = ('%0.2f', '%0.2f', '%0.1f')

def autolabel(bar):
    """Labels a bar with text values."""
    # get_y() needed to output proper total time
    height = bar.get_height() + bar.get_y()

    # values will never be small enough to cause issues w/ this comparison
    if height == 0:
        plt.text(bar.get_x()+bar.get_width()/2, 0, 'F',
                 ha='center', va='bottom', fontsize=F_FONTSIZE)
    else:
        if not save_paper:
            plt.text(bar.get_x()+bar.get_width()/2.0, height*1.005, LABEL_FORMAT[mode]%float(height),
                     ha='center', va='bottom', fontsize=VAL_FONTSIZE)


def plot_time_tot(plt, fig, ai, gi, si, mi, ind, width):
    """Plots total computation time (separated into I/O, premizan, and computation time).

    Arguments:
    plt -- matplotlib.pyplot being used
    fig -- figure object (matplotlib.figure)
    ai -- algorithm index (int)
    gi -- graph index (int)
    si -- system indices, for plotting all or a subset of the systems (list)
    mi -- machine indices, for plotting all or a subset of the machines (list)
    ind -- left x-location of each bar group (list)
    width -- width of each bar (int)

    Returns:
    Tuple of axes.
    """

    # TODO: strings are hard coded...

    # this is generated implicitly by default, but we need to return it
    ax = plt.subplot()

    # don't show premizan bar if comuptation time is 0 (i.e., failed run)
    premizan_avg = np.array([[0.0 if stats_dict['run_avg'][ai,gi,si][i,j] == 0 else val
                              for j,val in enumerate(arr)]
                             for i,arr in enumerate(premizan_dict['io_avg'][gi,si])])

    premizan_ci = np.array([[0.0 if stats_dict['run_avg'][ai,gi,si][i,j] == 0 else val
                             for j,val in enumerate(arr)]
                            for i,arr in enumerate(premizan_dict['io_ci'][gi,si])])

    # add premizan's CI in quadrature, since they're independent variables
    tot_ci = np.sqrt(np.power(stats_dict['tot_ci'][ai,gi,si], 2) + np.power(premizan_ci, 2))


    # Each (implicit) iteration plots one system+sysmode in different groups (= # of machines).
    # "+" does element-wise add as everything is an np.array.
    plt_tot = [plt.bar(ind + width*i, avg[mi], width, color=col, hatch=pat,
                       ecolor=COLOR_ERR, yerr=ci[mi], align='edge', bottom=pm[mi])
               for i,(avg,ci,pm,col,pat) in enumerate(zip(stats_dict['tot_avg'][ai,gi,si],
                                                          tot_ci,
                                                          premizan_avg,
                                                          COLORS[si],
                                                          PATTERNS[si]))]

    plt_io = [plt.bar(ind + width*i, avg[mi], width, color=COLOR_IO,
                      ecolor=COLOR_ERR, align='edge')
              for i,(avg) in enumerate(stats_dict['io_avg'][ai,gi,si])]

    # we slice everything explicitly, b/c si need not start at 0
    plt_pm = [plt.bar(ind + width*i, avg[mi], width, color=COLOR_PREMIZAN,
                      ecolor=COLOR_ERR, align='edge', bottom=io[mi])
              for i,(avg,io) in enumerate(zip(premizan_avg,
                                              stats_dict['io_avg'][ai,gi,si]))]

    # label with total time (if not for paper.. otherwise it clutters things)
    for bars in plt_tot:
        for bar in bars:
            autolabel(bar)

    #plt.ylim(ymax=np.max(stats_dict['run_avg'][ai,gi,si] + stats_dict['run_ci'][ai,gi,si]
    #                     + premizan_dict['io_avg'][gi,si]
    #                     + stats_dict['io_avg'][ai,gi,si])*YMAX_FACTOR)

    plt.ylabel('Total time (mins)')

    return (ax,)


#def plot_time_run(plt, fig, ai, gi, si, mi, ind, width):
#    """Plots computation time only.
#
#    Arguments:
#    plt -- matplotlib.pyplot being used
#    fig -- figure object (matplotlib.figure)
#    ai -- algorithm index (int)
#    gi -- graph index (int)
#    si -- system indices, for plotting all or a subset of the systems (list)
#    mi -- machine indices, for plotting all or a subset of the machines (list)
#    ind -- left x-location of each bar group (list)
#    width -- width of each bar (int)
#
#    Returns:
#    Tuple of axes.
#    """
#
#    ax = plt.subplot()
#
#    plt_run = [plt.bar(ind + width*i, avg[mi], width, color=col, hatch=pat,
#                       ecolor=COLOR_ERR, yerr=ci[mi], align='edge')
#               for i,(avg,ci,col,pat) in enumerate(zip(stats_dict['run_avg'][ai,gi,si],
#                                                       stats_dict['run_ci'][ai,gi],
#                                                       COLORS,
#                                                       PATTERNS))]
#
#    # label bars with computation times
#    for bars in plt_run:
#        for bar in bars:
#            autolabel(bar)
#
#    #plt.ylim(ymax=np.max(stats_dict['run_avg'][ai,gi,si] + stats_dict['run_ci'][ai,gi,si])*YMAX_FACTOR)
#
#    plt.ylabel('Computation time (mins)')
#    return (ax,)


def plot_time_split(plt, fig, ai, gi, si, mi, ind, width):
    """Plots I/O + premizan time and computation times in vertically separated subplots.

    This is basically a variant of plot_time_tot, where we don't stack the computation
    time on top of the I/O bars.

    Arguments:
    plt -- matplotlib.pyplot being used
    fig -- figure object (matplotlib.figure)
    ai -- algorithm index (int)
    gi -- graph index (int)
    si -- system indices, for plotting all or a subset of the systems (list)
    mi -- machine indices, for plotting all or a subset of the machines (list)
    ind -- left x-location of each bar group (list)
    width -- width of each bar (int)

    Returns:
    Tuple of axes.
    """

    ax_run = plt.subplot(211)
    plt_run = [plt.bar(ind + width*i, avg[mi], width, color=col, hatch=pat,
                       ecolor=COLOR_ERR, yerr=ci[mi], align='edge')
               for i,(avg,ci,col,pat) in enumerate(zip(stats_dict['run_avg'][ai,gi,si],
                                                       stats_dict['run_ci'][ai,gi,si],
                                                       COLORS[si],
                                                       PATTERNS[si]))]

    # label bars with their values
    for bars in plt_run:
        for bar in bars:
            autolabel(bar)

    # using sharey ensures both y-axis are of same scale... but it can waste a lot of space
    #ax_io = plt.subplot(2, 1, 2, sharey=ax_run)
    ax_io = plt.subplot(212)

    plt_io = [plt.bar(ind + width*i, avg[mi], width, color=COLOR_IO, hatch=pat,
                      ecolor=COLOR_ERR, yerr=ci[mi], align='edge')
              for i,(avg,ci,pat) in enumerate(zip(stats_dict['io_avg'][ai,gi,si],
                                                  stats_dict['io_ci'][ai,gi,si],
                                                  PATTERNS[si]))]

    # don't show premizan bar if comuptation time is 0 (i.e., failed run)
    premizan_avg = np.array([[0.0 if stats_dict['run_avg'][ai,gi,si][i,j] == 0 else val
                              for j,val in enumerate(arr)]
                             for i,arr in enumerate(premizan_dict['io_avg'][gi,si])])

    premizan_ci = np.array([[0.0 if stats_dict['run_avg'][ai,gi,si][i,j] == 0 else val
                             for j,val in enumerate(arr)]
                            for i,arr in enumerate(premizan_dict['io_ci'][gi,si])])


    plt_pm = [plt.bar(ind + width*i, avg[mi], width, color=COLOR_PREMIZAN, hatch=pat,
                      ecolor=COLOR_ERR, yerr=ci[mi], align='edge', bottom=io[mi])
              for i,(avg,ci,io,pat) in enumerate(zip(premizan_avg,
                                                     premizan_ci,
                                                     stats_dict['io_avg'][ai,gi,si],
                                                     PATTERNS[si]))]

    # label bars with their values
    for bars in plt_pm:
        for bar in bars:
            autolabel(bar)


    # set proper ymax
    #ax_run.set_ylim(ymax=np.max(stats_dict['run_avg'][ai,gi,si] + stats_dict['run_ci'][ai,gi,si])*YMAX_FACTOR)
    #ax_io.set_ylim(ymax=np.max(premizan_dict['io_avg'][gi,si] + premizan_dict['io_ci'][gi,si]
    #                           + stats_dict['io_avg'][ai,gi,si])*YMAX_FACTOR)

    ax_run.set_ylabel('Computation (mins)')
    ax_io.set_ylabel('Setup (mins)')

    # remove upper y-label to avoid overlap
    nbins = len(ax_run.get_yticklabels())
    ax_io.yaxis.set_major_locator(MaxNLocator(nbins=nbins, prune='upper'))

    return (ax_run, ax_io)


def plot_mem_net(plt, fig, ai, gi, si, mi, ind, width, is_mem, is_recv=True):
    """Plots memory usage or network usage.

    Arguments:
    plt -- matplotlib.pyplot being used
    fig -- figure object (matplotlib.figure)
    ai -- algorithm index (int)
    gi -- graph index (int)
    si -- system indices, for plotting all or a subset of the systems (list)
    mi -- machine indices, for plotting all or a subset of the machines (list)
    ind -- left x-location of each bar group (list)
    width -- width of each bar (int)
    is_mem -- True for memory usage, False for network usage (boolean)
    is_recv -- True for incoming network I/O, False for outgoing (boolean)

    Returns:
    Tuple of axes.
    """

    if is_mem:
        STAT_NAME = 'mem'
        LABEL_STR = 'memory usage'
    else:
        if is_recv:
            STAT_NAME = 'recv'
            LABEL_STR = 'incoming network I/O'
        else:
            STAT_NAME = 'sent'
            LABEL_STR = 'outgoing network I/O'


    ax = plt.subplot()

    if do_master:
        # master is a single machine, so min/max/sum = avg
        plt_avg = [plt.bar(ind + width*i, avg[mi], width, color=col, hatch=pat,
                           ecolor=COLOR_ERR, yerr=ci[mi], align='edge')
                   for i,(avg,ci,col,pat) in enumerate(zip(stats_dict[STAT_NAME + '_avg_avg'][ai,gi,si]*MB_PER_GB,
                                                           stats_dict[STAT_NAME + '_avg_ci'][ai,gi,si]*MB_PER_GB,
                                                           COLORS[si],
                                                           PATTERNS[si]))]

        # label all bars
        for bars in plt_avg:
            for bar in bars:
                autolabel(bar)

    else:
        def plot_helper(name, colors, alpha=1.0, is_sum=False):
            """Helper function to plot min, max, avg, or sum, depending on arguments.

            Arguments:
            name -- name of the statistic: min, max, or avg (string)
            colors -- list of colors, must have length = len(COLORS) (np.array)
            alpha -- level of transparency, none by default (float)
            is_sum -- True to compute the sum/total, False otherwise (boolean)
            """

            # If sum/total memory/netwok is requested, then we set number of machines correctly.
            # Otherwise, num_machines is set to all 1s, so that element-wise multiplication of
            # whichever statistic and num_machines just yields the original statistic.
            #
            # CI is also multiplied, b/c # of machines is a constant and has no error.
            if is_sum:
                num_machines = np.array([int(m) for m in MACHINES])
            else:
                num_machines = np.ones(len(MACHINES))

            # NOTE: alpha not supported in ps/eps
            p = [plt.bar(ind + width*i, np.multiply(avg[mi],num_machines[mi]), width,
                         color=col, hatch=pat, alpha=alpha,
                         ecolor=COLOR_ERR, yerr=np.multiply(ci[mi],num_machines[mi]), align='edge')
                 for i,(avg,ci,col,pat) in enumerate(zip(stats_dict[STAT_NAME + '_' + name + '_avg'][ai,gi,si],
                                                         stats_dict[STAT_NAME + '_' + name + '_ci'][ai,gi,si],
                                                         colors[si],
                                                         PATTERNS[si]))]

            # label all bars
            for bars in p:
                for bar in bars:
                    autolabel(bar)


        if do_sum_only:
            plot_helper('avg', COLORS, 1.0, True)
        elif do_avg_only:
            plot_helper('avg', COLORS)
        elif do_max_only:
            plot_helper('max', COLORS)
        else:
            # order is important: min should overlay avg, etc.
            # NOTE: used to use 0.6 alpha for min/max, but with patterns it doesn't look as good
            plot_helper('max', np.array(['#e74c3c']*len(COLORS)))
            plot_helper('avg', COLORS)
            plot_helper('min', np.array(['#27ae60']*len(COLORS)))


    # for worker's memory usage, plot the larger graphs to have same ymax
    if is_mem and not (do_sum_only or do_master or do_premizan) and not GRAPHS[gi] in [GRAPH_LJ, GRAPH_OR]:
        plt.ylim(ymax=14.0)

    #plt.ylim(ymax=np.max(stats_dict[STAT_NAME + '_max_avg'][ai,gi,si] + stats_dict[STAT_NAME + '_max_ci'][ai,gi,si])*YMAX_FACTOR)

    if do_master:
        plt.ylabel('Total ' + LABEL_STR + ' (MB)')
    else:
        if do_sum_only:
            plt.ylabel('Total ' + LABEL_STR + ' (GB)')
        elif do_avg_only:
            plt.ylabel('Average ' + LABEL_STR + ' (GB)')
        elif do_max_only:
            plt.ylabel('Maximum ' + LABEL_STR + ' (GB)')
        else:
            plt.ylabel('Min/avg/max ' + LABEL_STR + ' (GB)')

    return (ax,)


def plot_mem(plt, fig, ai, gi, si, mi, ind, width):
    """Wrapper function for plot_mem_net"""
    return plot_mem_net(plt, fig, ai, gi, si, mi, ind, width, True)

def plot_net_recv(plt, fig, ai, gi, si, mi, ind, width):
    """Wrapper function for plot_mem_net"""
    return plot_mem_net(plt, fig, ai, gi, si, mi, ind, width, False, True)

def plot_net_sent(plt, fig, ai, gi, si, mi, ind, width):
    """Wrapper function for plot_mem_net"""
    return plot_mem_net(plt, fig, ai, gi, si, mi, ind, width, False, False)


####################
# Generate plots
####################
PLOT_FUNCS = ((plot_time_tot if do_time_tot else plot_time_split,),  # time
              (plot_mem,),                                           # memory
              (plot_net_recv, plot_net_sent))                        # net

fignum = 0

for plt_type,save_suffix in enumerate(PLOT_TYPES[mode]):
    # iterate over all algs (ai = algorithm index)
    for ai,alg in enumerate(ALGS):
        # Not all systems do WCC or DMST, so we have to handle it separately.
        # This removes bars from each group of bars, so change bar width
        # to compensate for # of systems as well.
        # (si = system indices, which slices rows of the matrix)
        si = np.arange(len(ALL_SYS))         # all systems by default
        if (alg == ALG_MST):
            si = np.arange(3)                # only Giraph (hashmap, byte array) and GPS (none)
        elif (alg == ALG_WCC):
            si = np.arange(len(ALL_SYS)-1)   # all except GraphLab async
        elif (alg == ALG_PREMIZAN):
            si = np.arange(5,6)              # only Mizan
 
        width = (1.0 - 2.0*BAR_MARGIN)/len(si)
 
        # iterate over all graphs (gi = graph index)
        for gi,graph in enumerate(GRAPHS):
            # Not all machine setups can run uk0705, so we remove 16/32's empty bars.
            # This will make the plot thinner (removes 2 groups of bars).
            # (mi = machine indices, which silces columns of the matrix)
            if save_paper:
                mi = np.arange(1,4)             # for paper, only plot 32, 64, 128
            else:
                mi = np.arange(len(MACHINES))   # all machines by default

            if (alg == ALG_PREMIZAN):
                if (graph == GRAPH_UK):
                    continue                    # no UK results
                elif (graph == GRAPH_TW):
                    mi = np.arange(3,4)         # only 128 machines
            elif (alg == ALG_MST):
                if (graph == GRAPH_UK):
                    # NOTE: using 3,4 causes divide by zero warning in ticker.py
                    mi = np.arange(3,4)         # only 128 machines
                elif (graph == GRAPH_TW):
                    mi = np.arange(2,4)         # only 64 and 128 machines
            else:
                if (graph == GRAPH_UK):
                    mi = np.arange(2,4)         # only 64 and 128 machines
 
            # each alg & graph is a separate figure---easier to handle than subplots
            fignum += 1
 
            # shrink width down if there are bars or groups of bars missing
            width_ratio = (7.0-len(GRAPH_LABELS[gi]))/(7.0-len(mi))
            if save_paper:
                fig = plt.figure(fignum, figsize=(6.5*width_ratio,7), facecolor='w')
            else:
                fig = plt.figure(fignum, figsize=(6.0*width_ratio,6), facecolor='w')
 
            # mode specific plot function
            axes = PLOT_FUNCS[mode][plt_type](plt, fig, ai, gi, si, mi, IND[gi,mi], width)
 
            # title only for the first (upper-most) axis
            if not save_file:
                axes[0].set_title(alg + ' ' + graph)
 
            # If there's only one axis, we can just use plt.stuff()...
            # But with mutliple axes we need to go through each one using axis.set_stuff()
            for ax in axes:
                ax.set_ylim(ymin=0)                 # zero y-axis
                ax.minorticks_on()                  # enable all minor ticks
 
                for item in ([ax.title, ax.xaxis.label, ax.yaxis.label] +
                             ax.get_xticklabels() + ax.get_yticklabels()):
                    item.set_fontsize(FONTSIZE)
 
                # turn off major and minor x-axis ticks (leaves minor y-ticks on)
                ax.tick_params(axis='x', which='both', bottom='off', top='off')
 
                ax.grid(True, which='major', axis='y')
 
                # draw vertical lines to separate bar groups
                vlines_mi = np.array(mi)[np.arange(1,len(mi))]
                ax.vlines(IND[gi,vlines_mi]-BAR_MARGIN, 0, ax.get_ylim()[1], colors='k', linestyles='dotted')
 
            # only label x-axis of last (bottom-most) axis
            for ax in axes[:-1]:
                ax.tick_params(labelbottom='off')
 
            # ha controls where labels are aligned to (left, center, or right)
            plt.xticks(IND[gi,mi]+width*len(si)/2, GRAPH_LABELS[gi,mi], rotation=30, ha='center')
 
 
            #ml = MultipleLocator(5)
            #plt.axes().yaxis.set_minor_locator(ml)
 
            plt.tight_layout()
            plt.subplots_adjust(hspace = 0.001)
 
            save_name = alg + '_' + graph + '_' + save_suffix
            if do_master:
                save_name = save_name + '_master'
 
            if save_eps:
                plt.savefig(SCRIPT_DIR + '/figs/' + save_name + '.eps', format='eps',
                            bbox_inches='tight', pad_inches=0.05)
 
            # TODO: save_png causes error on exit (purely cosmetic: trying to close a non-existent canvas)
            if save_png:
                plt.savefig(SCRIPT_DIR + '/figs/' + save_name + '.png', format='png',
                            dpi=200, bbox_inches='tight', pad_inches=0.05)


## Separate plot with the legend
# values are tuned to give perfect size output for fontsize of 20
fignum += 1
plt.figure(fignum, figsize=(4,3.6), facecolor='w')
ax = plt.subplot()
width = (1.0-2.0*BAR_MARGIN)/3
plt_legend = [plt.bar(0 + width*i, avg[0], width, color=col, hatch=pat)
              for i,(avg,col,pat) in enumerate(zip(stats_dict[STATS[mode][0] + '_avg'][0,0],
                                                   COLORS,
                                                   PATTERNS))]

ax.legend(plt_legend[0:len(plt_legend)], LEGEND_LABELS, fontsize=20,
          loc=3, bbox_to_anchor=[-0.1,-0.1], borderaxespad=0.0).draw_frame(False)

for bars in plt_legend:
    for bar in bars:
        bar.set_visible(False)

plt.axis('off')
plt.tight_layout()

if save_eps:
    plt.savefig(SCRIPT_DIR + '/figs/legend.eps', format='eps', bbox_inches='tight', pad_inches=0)

if save_png:
    plt.savefig(SCRIPT_DIR + '/figs/legend.png', format='png', dpi=200, bbox_inches='tight', pad_inches=0)


# collapsed legend
fignum += 1
plt.figure(fignum, figsize=(10.9,1.4), facecolor='w')
ax = plt.subplot()
width = (1.0-2.0*BAR_MARGIN)/3
plt_legend = [plt.bar(0 + width*i, avg[0], width, color=col, hatch=pat)
              for i,(avg,col,pat) in enumerate(zip(stats_dict[STATS[mode][0] + '_avg'][0,0],
                                                   COLORS,
                                                   PATTERNS))]

# create empty rectangle so we have Giraph in one column, GPS in another, etc.
blank = Rectangle((0, 0), 1, 1, fc="w", fill=False, edgecolor='none', linewidth=0)
ax.legend(plt_legend[0:2] + [blank] + plt_legend[2:len(plt_legend)],
          list(LEGEND_LABELS[0:2]) + [""] + list(LEGEND_LABELS[2:]),
          fontsize=20, ncol=3,
          loc=3, bbox_to_anchor=[-0.03, -0.5], borderaxespad=0.0).draw_frame(False)

for bars in plt_legend:
    for bar in bars:
        bar.set_visible(False)

plt.axis('off')
plt.tight_layout()

if save_eps:
    plt.savefig(SCRIPT_DIR + '/figs/legend-horiz.eps', format='eps', bbox_inches='tight', pad_inches=0)

if save_png:
    plt.savefig(SCRIPT_DIR + '/figs/legend-horiz.png', format='png', dpi=200, bbox_inches='tight', pad_inches=0)


# show all plots
if not save_file:
    plt.show()

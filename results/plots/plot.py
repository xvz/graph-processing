#!/usr/bin/env python
import os, sys
import argparse, itertools
import numpy as np

from constants import *


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

parser = argparse.ArgumentParser(description='Generates experimental data from log files.')
parser.add_argument('mode', type=check_mode,
                    help='mode to use: 0 for time, 1 for memory, 2 for network')
parser.add_argument('--master', action='store_true', default=False,
                    help='plot mem/net statistics for the master rather than the worker machines (only relevant for mode=1,2)')
parser.add_argument('--premizan', action='store_true', default=False,
                    help='plot mem/net statistics for premizan only (only relevant for mode=1,2)')
parser.add_argument('--save-eps', action='store_true', default=False,
                    help='save plots as EPS files instead of displaying them')
parser.add_argument('--save-png', action='store_true', default=False,
                    help='save plots as PNG files (200 DPI) instead of displaying them')

mode = parser.parse_args().mode
do_master = parser.parse_args().master
do_premizan = parser.parse_args().premizan
save_eps = parser.parse_args().save_eps
save_png = parser.parse_args().save_png


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
if save_eps:
    import matplotlib
    # using tight_layout will cause this to be Agg...
    matplotlib.use('PS')

import matplotlib.pyplot as plt
from matplotlib.ticker import MultipleLocator


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


## Matrix for one alg and one graph, with rows indexed by sysemt + system mode
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
                 np.array([[[[0]*len(MACHINES)]*(len(ALL_SYS)-3)
                            + [[eval(SYS_MIZAN + '_' + SYSMODE_HASH + '_' + machines + '_' + ALG_PREMIZAN + '_' + graph + '_' + stat + suffix)
                                for machines in MACHINES]]
                            + [[0]*len(MACHINES)]*2
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
PLOT_TYPES = (('tot', 'run'),    # time 
              ('mem',),          # mem
              ('recv', 'sent'))  # net

# decoration
PATTERNS = ('.','*',       # Giraph
            '/','o','//',    # GPS
            'x',            # Mizan
            '\\', '\\\\')   # GraphLab

# old: #ff7f00 (orange), #1f78b4 (blue), #7ac36a (darker green)
COLORS = ('#faa75b','#faa75b',            # Giraph
          '#5a9bd4','#5a9bd4','#5a9bd4',  # GPS
          '#b2df8a',                      # Mizan
          '#eb65aa','#eb65aa')            # GraphLab

COLOR_PREMIZAN = '#737373'
COLOR_IO = (0.9, 0.9, 0.9)
COLOR_ERR = (0.3, 0.3, 0.3)

FIG_SIZE = (6,6)

# labels
LEGEND_LABELS = ('Giraph (byte array)', 'Giraph (hash map)',
                 'GPS (none)', 'GPS (LALP)', 'GPS (dynamic)',
                 'Mizan (static)',
                 'Graphlab (sync)', 'GraphLab (async)')

GRAPH_LABELS = (('LJ (16)', 'LJ (32)', 'LJ (64)', 'LJ (128)'),
                ('OR (16)', 'OR (32)', 'OR (64)', 'OR (128)'),
                ('AR (16)', 'AR (32)', 'AR (64)', 'AR (128)'),
                ('TW (16)', 'TW (32)', 'TW (64)', 'TW (128)'),
                ('UK (16)', 'UK (32)', 'UK (64)', 'UK (128)'))


# fontsizes (12 is default)
FONTSIZE = 12
VAL_FONTSIZE = 4   # for text values on top of bars

# left/right margins of each bar group
BAR_MARGIN = 0.05

# location of bar groups
ind = [np.arange(len(g))+BAR_MARGIN for g in GRAPH_LABELS]


####################
# Plot functions
####################
# label formats indexed by mode
LABEL_FORMAT = ('%0.2f', '%0.2f', '%0.1f')

def autolabel(bars):
    """Labels all bars with text values."""
    for bar in bars:
        # get_y() needed to output proper total time
        height = bar.get_height() + bar.get_y()
        plt.text(bar.get_x()+bar.get_width()/2.0, height*1.005, LABEL_FORMAT[mode]%float(height),
                 ha='center', va='bottom', fontsize=VAL_FONTSIZE)


def plot_time_tot(plt, fignum, ai, gi, si, width):
    """Plots total computation time (separated into I/O, premizan, and running time).
    
    Arguments:
    plt -- matplotlib.pyplot being used
    fignum -- figure number (int)
    ai -- algorithm index (int)
    gi -- graph index (int)
    si -- system indices, for plotting all or a subset of the systems (list/range)
    width -- width of each bar

    Returns:
    Tuple of plots (each of which is a list of bars/rectangles).
    Specifically, bars for running time, bars for I/O, and bars for premizan.
    """

    # TODO: strings are hard coded...

    # Each (implicit) iteration plots one system+sysmode in different groups (=workers).
    # "+" does element-wise add as everything is an np.array.
    # Only need to slice first array in zip()---the rest will get shortened automatically.
    plt_run = [plt.bar(ind[gi] + width*i, avg, width, color=col, hatch=pat,
                       ecolor=COLOR_ERR, yerr=ci, align='edge', bottom=io)
               for i,(avg,col,pat,ci,io) in enumerate(zip(stats_dict['run_avg'][ai,gi,si],
                                                          COLORS,
                                                          PATTERNS,
                                                          stats_dict['run_ci'][ai,gi],
                                                          stats_dict['io_avg'][ai,gi]+premizan_dict['io_avg'][gi]))]

    plt_io = [plt.bar(ind[gi] + width*i, avg, width, color=COLOR_IO,
                      ecolor=COLOR_ERR, yerr=ci, align='edge')
              for i,(avg,ci) in enumerate(zip(stats_dict['io_avg'][ai,gi,si],
                                              stats_dict['io_ci'][ai,gi]))]

    plt_pm = [plt.bar(ind[gi] + width*i, avg, width, color=COLOR_PREMIZAN,
                      ecolor=COLOR_ERR, yerr=ci, align='edge', bottom=io)
              for i,(avg,ci,io) in enumerate(zip(premizan_dict['io_avg'][gi,si],
                                                 premizan_dict['io_ci'][gi],
                                                 stats_dict['io_avg'][ai,gi]))]

    # label bars with their values
    for bars in plt_run:
        autolabel(bars)

    plt.ylabel('Total time (minutes)', fontsize=FONTSIZE)
    return (plt_run, plt_io, plt_pm)


def plot_time_run(plt, fignum, ai, gi, si, width):
    """Plots running time.
    
    Arguments:
    plt -- matplotlib.pyplot being used
    fignum -- figure number (int)
    ai -- algorithm index (int)
    gi -- graph index (int)
    si -- system indices, for plotting all or a subset of the systems (list/range)
    width -- width of each bar

    Returns:
    Singular tuple of one plot (running time).
    """

    plt_run = [plt.bar(ind[gi] + width*i, avg, width, color=col, hatch=pat,
                       ecolor=COLOR_ERR, yerr=ci, align='edge')
               for i,(avg,col,pat,ci) in enumerate(zip(stats_dict['run_avg'][ai,gi,si],
                                                       COLORS,
                                                       PATTERNS,
                                                       stats_dict['run_ci'][ai,gi]))]

    # label bars with their values
    for bars in plt_run:
        autolabel(bars)

    plt.ylabel('Running time (minutes)', fontsize=FONTSIZE)
    return (plt_run,)


def plot_mem(plt, fignum, ai, gi, si, width):
    """Plots memory usage (GB per worker).
    
    Arguments:
    plt -- matplotlib.pyplot being used
    fignum -- figure number (int)
    ai -- algorithm index (int)
    gi -- graph index (int)
    si -- system indices, for plotting all or a subset of the systems (list/range)
    width -- width of each bar

    Returns:
    Tuple of plots: (max memory, avg memory, min memory).
    """

    if do_master:
        plt_avg = [plt.bar(ind[gi] + width*i, avg, width, color=col, hatch=pat,
                           ecolor=COLOR_ERR, yerr=ci, align='edge')
                   for i,(avg,col,pat,ci) in enumerate(zip(stats_dict['mem_avg_avg'][ai,gi,si]*MB_PER_GB,
                                                           COLORS,
                                                           PATTERNS,
                                                           stats_dict['mem_avg_ci'][ai,gi]*MB_PER_GB))]

        plt_min = plt_max = plt_avg   # master is a single machine, so min/max = avg

    else:
        # NOTE: alpha not supported in ps/eps
        plt_max = [plt.bar(ind[gi] + width*i, avg, width, color='#e74c3c', alpha=0.6,
                           ecolor=COLOR_ERR, yerr=ci, align='edge')
                   for i,(avg,col,pat,ci) in enumerate(zip(stats_dict['mem_max_avg'][ai,gi,si],
                                                           COLORS,
                                                           PATTERNS,
                                                           stats_dict['mem_max_ci'][ai,gi]))]

        plt_avg = [plt.bar(ind[gi] + width*i, avg, width, color=col, hatch=pat,
                           ecolor=COLOR_ERR, yerr=ci, align='edge')
                   for i,(avg,col,pat,ci) in enumerate(zip(stats_dict['mem_avg_avg'][ai,gi,si],
                                                           COLORS,
                                                           PATTERNS,
                                                           stats_dict['mem_avg_ci'][ai,gi]))]
    
        plt_min = [plt.bar(ind[gi] + width*i, avg, width, color='#27ae60', alpha=0.6,
                           ecolor=COLOR_ERR, yerr=ci, align='edge')
                   for i,(avg,col,pat,ci) in enumerate(zip(stats_dict['mem_min_avg'][ai,gi,si],
                                                           COLORS,
                                                           PATTERNS,
                                                           stats_dict['mem_min_ci'][ai,gi]))]

    # label bars with their values
    for plt_mem in (plt_max, plt_avg, plt_min):
        for bars in plt_mem:
            autolabel(bars)

    if do_master:
        plt.ylabel('Memory usage at master (MB)', fontsize=FONTSIZE)
    else:
        plt.ylabel('Min/avg/max memory usage (GB per worker)', fontsize=FONTSIZE)

    return (plt_max, plt_avg, plt_min)


def plot_net_recv(plt, fignum, ai, gi, si, width):
    """Plots total incoming network usage, summed over all workers.
    
    Arguments:
    plt -- matplotlib.pyplot being used
    fignum -- figure number (int)
    ai -- algorithm index (int)
    gi -- graph index (int)
    si -- system indices, for plotting all or a subset of the systems (list/range)
    width -- width of each bar

    Returns:
    Singular tuple of one plot (network received).
    """

    if do_master:
        plt_recv = [plt.bar(ind[gi] + width*i, avg, width, color=col, hatch=pat,
                            ecolor=COLOR_ERR, yerr=ci, align='edge')
                    for i,(avg,col,pat,ci) in enumerate(zip(stats_dict['eth_recv_avg'][ai,gi,si]*MB_PER_GB,
                                                            COLORS,
                                                            PATTERNS,
                                                            stats_dict['eth_recv_ci'][ai,gi]*MB_PER_GB))]
    else:
        plt_recv = [plt.bar(ind[gi] + width*i, avg, width, color=col, hatch=pat,
                            ecolor=COLOR_ERR, yerr=ci, align='edge')
                    for i,(avg,col,pat,ci) in enumerate(zip(stats_dict['eth_recv_avg'][ai,gi,si],
                                                            COLORS,
                                                            PATTERNS,
                                                            stats_dict['eth_recv_ci'][ai,gi]))]
    
    # label bars with their values
    for bars in plt_recv:
        autolabel(bars)

    if do_master:
        plt.ylabel('Total incoming network I/O (MB)', fontsize=FONTSIZE)
    else:
        plt.ylabel('Total incoming network I/O (GB)', fontsize=FONTSIZE)

    return (plt_recv,)


def plot_net_sent(plt, fignum, ai, gi, si, width):
    """Plots total outgoing network usage, summed over all workers.
    
    Arguments:
    plt -- matplotlib.pyplot being used
    fignum -- figure number (int)
    ai -- algorithm index (int)
    gi -- graph index (int)
    si -- system indices, for plotting all or a subset of the systems (list/range)
    width -- width of each bar

    Returns:
    Singular tuple of one plot (network sent).
    """

    if do_master:
        plt_sent = [plt.bar(ind[gi] + width*i, avg, width, color=col, hatch=pat,
                            ecolor=COLOR_ERR, yerr=ci, align='edge')
                    for i,(avg,col,pat,ci) in enumerate(zip(stats_dict['eth_sent_avg'][ai,gi,si]*MB_PER_GB,
                                                            COLORS,
                                                            PATTERNS,
                                                            stats_dict['eth_sent_ci'][ai,gi]*MB_PER_GB))]
    else:
        plt_sent = [plt.bar(ind[gi] + width*i, avg, width, color=col, hatch=pat,
                            ecolor=COLOR_ERR, yerr=ci, align='edge')
                    for i,(avg,col,pat,ci) in enumerate(zip(stats_dict['eth_sent_avg'][ai,gi,si],
                                                            COLORS,
                                                            PATTERNS,
                                                            stats_dict['eth_sent_ci'][ai,gi]))]
    
    # label bars with their values
    for bars in plt_sent:
        autolabel(bars)

    if do_master:
        plt.ylabel('Total outgoing network I/O (MB)', fontsize=FONTSIZE)
    else:
        plt.ylabel('Total outgoing network I/O (GB)', fontsize=FONTSIZE)

    return (plt_sent,)


####################
# Generate plots
####################
plot_funcs = ((plot_time_tot, plot_time_run),   # time
              (plot_mem,),                      # memory
              (plot_net_recv, plot_net_sent))   # net


fignum = 0

# iterate over all plot types
for plt_type,save_suffix in enumerate(PLOT_TYPES[mode]):
    # iterate over all algs (ai = algorithm index)
    for ai,alg in enumerate(ALGS):
        # not all systems do mst, so we have to handle it separately
        # change bar width to compensate for # of systems as well
        # (si = system indices, for slicing array)
        if (alg == ALG_MST):
            si = np.arange(3)              # only Giraph (hashmap, byte array) and GPS (none)
            width = (1.0 - 2.0*BAR_MARGIN)/3
        else:
            si = np.arange(len(ALL_SYS))   # all systems
            width = (1.0 - 2.0*BAR_MARGIN)/len(ALL_SYS)
     
        # iterate over all graphs (gi = graph index)
        for gi,graph in enumerate(GRAPHS):
            # each alg & graph is a separate figure---easier to handle than subplots
            fignum += 1
            plt.figure(fignum, figsize=FIG_SIZE, facecolor='w')
     
            # mode specific plot function
            plots = plot_funcs[mode][plt_type](plt, fignum, ai, gi, si, width)
     
            # generic labels that apply to all plots
            plt.title(alg + ' ' + graph)
            # ha controls where labels are aligned to (left, center, or right)
            plt.xticks(ind[gi]+width*len(plots[0])/2, GRAPH_LABELS[gi],
                       rotation=35, ha='right', fontsize=FONTSIZE)
            plt.yticks(fontsize=FONTSIZE)
            # turn off major and minor x-axis ticks
            plt.tick_params(axis='x', which='both', bottom='off', top='off')
            #plt.yticks(np.arange(0,30,10))
         
            plt.ylim(ymin=0)
            # TODO: make this dynamic wrt y-range
            ml = MultipleLocator(5)
            plt.axes().yaxis.set_minor_locator(ml)
            plt.grid(True, which='major', axis='y')
            plt.tight_layout()

            if save_eps:
                plt.savefig('./figs/' + alg + '_' + graph + '_' + save_suffix + '.eps',
                            format='eps')
            
            # TODO: save_png causes error on exit (purely cosmetic: trying to close a non-existent canvas)
            if save_png:
                plt.savefig('./figs/' + alg + '_' + graph + '_' + save_suffix + '.png',
                            format='png', dpi=200)


# plot just for the legend
# TODO: fix
fignum += 1
plt.figure(fignum, figsize=(6,6), facecolor='w')
width = (1.0-2.0*BAR_MARGIN)/3
legend_plt = [plt.bar(0 + width*i, avg[0], width, color=col, hatch=pat)
              for i,(avg,col,pat) in enumerate(zip(stats_dict[STATS[mode][0] + '_avg'][0,0],
                                                   COLORS,
                                                   PATTERNS))]

plt.legend(legend_plt[0:len(legend_plt)], LEGEND_LABELS, fontsize=FONTSIZE, loc=3)

for bars in legend_plt:
    for bar in bars:
        bar.set_visible(False)

plt.tight_layout()


# show all plots
if (not save_eps) and (not save_png):
    plt.show()

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
        if not m in [0,2]:
            raise argparse.ArgumentTypeError('Invalid mode')
        return m
    except:
        raise argparse.ArgumentTypeError('Invalid mode')

parser = argparse.ArgumentParser(description='Plots parsed experimental data values.')
parser.add_argument('mode', type=check_mode,
                    help='mode to use: 0 for time (split), 2 for network (sum/total)')

# save related items
parser.add_argument('--save-png', action='store_true', default=False,
                    help='save plots as PNG files (200 DPI) instead of displaying them')
eps_group = parser.add_mutually_exclusive_group()
eps_group.add_argument('--save-eps', action='store_true', default=False,
                       help='save plots as EPS files instead of displaying them')
eps_group.add_argument('--save-paper', action='store_true', default=False,
                       help='save plots as EPS files for paper (uses large text labels)')

mode = parser.parse_args().mode
do_master = False
do_premizan = False

do_time_tot = False
do_sum_only = True
do_avg_only = False
do_max_only = False

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
matplotlib.rcParams['figure.max_open_warning'] = 41

if save_file:
    # using tight_layout requires Agg, so we can't use PS
    matplotlib.use('Agg')

import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
from matplotlib.ticker import MultipleLocator
from matplotlib.ticker import MaxNLocator

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
TIME_TYPE = ('time_cut',)
MEM_TYPE = ('mem_cut',)
NET_TYPE = ('recv_cut', 'sent_cut')

# options
if do_time_tot:
    TIME_TYPE = ('time_tot_cut',)

# master is single machine, so min = max = avg = sum
if not do_master:
    if do_sum_only:
        MEM_TYPE = ('mem_sum_cut',)
        NET_TYPE = ('recv_sum_cut','sent_sum_cut')
    elif do_avg_only:
        MEM_TYPE = ('mem_avg_cut',)
        NET_TYPE = ('recv_avg_cut','sent_avg_cut')
    elif do_max_only:
        MEM_TYPE = ('mem_max_cut',)
        NET_TYPE = ('recv_max_cut','sent_max_cut')

PLOT_TYPES = (TIME_TYPE, MEM_TYPE, NET_TYPE)


## decoration
# more chars = denser patterns; can also mix and match different ones
PATTERNS = ('..','*',             # Giraph
            '///','o','\\\\\\',   # GPS
            'xx',                 # Mizan
            '++', 'O')            # GraphLab

# old: #ff7f00 (orange), #1f78b4 (blue), #7ac36a (darker green)
COLORS = ('#faa75b','#faa75b',            # Giraph
          '#5a9bd4','#5a9bd4','#5a9bd4',  # GPS
          '#b2df8a',                      # Mizan
          '#eb65aa','#eb65aa')            # GraphLab

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

def autolabel(bar, yshift=0):
    """Labels a bar with text values.

       yshift - shifts label's y-location by +yshift
    """
    # get_y() needed to output proper total time
    height = bar.get_height() + bar.get_y()

    # values will never be small enough to cause issues w/ this comparison
    if height == 0:
        plt.text(bar.get_x()+bar.get_width()/2.0, 0, 'F',
                 ha='center', va='bottom', fontsize=F_FONTSIZE)
    else:
        if not save_paper:
            plt.text(bar.get_x()+bar.get_width()/2.0, height*1.005 + yshift, LABEL_FORMAT[mode]%float(height),
                     ha='center', va='bottom', fontsize=VAL_FONTSIZE)


def plot_time_split(plt, fig, ai, gi, si, mi, ind, width):
    """Plots I/O + premizan time and computation times in vertically separated subplots.

    This is basically a variant of plot_time_tot, where we don't stack the computation
    time on top of the I/O bars.

    Arguments:
    plt -- matplotlib.pyplot being used
    fig -- figure object (matplotlib.figure)
    ai -- algorithm index (int)
    gi -- graph index (int)
    si -- system indices, for plotting all or a subset of the systems (list/range)
    mi -- machine indices, for plotting all or a subset of the machines (list/range)
    ind -- left x-location of each bar group (list/range)
    width -- width of each bar (int)

    Returns:
    Tuple of axes.
    """

    ## plot setup times first, so we can apply xlabels
    ax_io = plt.subplot(212)

    plt_io = [plt.bar(ind + width*i, avg[mi], width, color=COLOR_IO, hatch=pat,
                      ecolor=COLOR_ERR, yerr=ci[mi], align='edge')
              for i,(avg,ci,pat) in enumerate(zip(stats_dict['io_avg'][ai,gi,si],
                                                  stats_dict['io_ci'][ai,gi],
                                                  PATTERNS))]
     
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
                                                     stats_dict['io_avg'][ai,gi],
                                                     PATTERNS))]
     
    # label bars with their values
    for bars in plt_pm:
        for bar in bars:
            autolabel(bar)
     
    ax_io.set_ylim(ymin=0)

    # ha controls where labels are aligned to (left, center, or right)
    plt.xticks(IND[gi,mi]+width*len(si)/2, GRAPH_LABELS[gi,mi], rotation=35, ha='center')

    ## Plot running time with y-ais cuts
    ycut_top_lims = [[(0,0), (0,0), (0,0), (105, 120)],
                     [(0,0), (0,0), (0,0), (0,0)],
                     [(0,0), (0,0), (0,0), (80, 95)]]
    ycut_bot_lims = [[(0,0), (0,0), (0,0), (0, 35)],
                     [(0,0), (0,0), (0,0), (0,0)],
                     [(0,0), (0,0), (0,0), (0, 9)]]


    # start, end, spacing for top and bottom
    yrange = [(9, 11, 1), (0, 2, 1)]

    if ALGS[ai] == ALG_PR:
        yrange = [(110, 121, 10), (0, 32, 10)]
    elif ALGS[ai] == ALG_WCC:
        yrange = [(85, 96, 10), (0, 9, 2)]

    # large subplot, with no visible spines
    ax_run = plt.subplot(211)
    ax_run.spines['bottom'].set_visible(False)
    ax_run.spines['top'].set_visible(False)
    ax_run.spines['left'].set_visible(False)
    ax_run.spines['right'].set_visible(False)


    # label x & y-axis so we can do tight_layout right away
    ax_run.set_ylabel('Computation (mins)')
    ax_io.set_ylabel('Setup (mins)')

    plt.tight_layout()


    # broken y-axis sub-plots within large subplot
    gs = gridspec.GridSpec(8,1)
    axs = [fig.add_subplot(gs[0,:]), fig.add_subplot(gs[1:4,:])]

    for ax in axs:
        p = [ax.bar(ind + width*i, avg[mi], width, color=col, hatch=pat,
                    ecolor=COLOR_ERR, yerr=ci[mi], align='edge')
             for i,(avg,ci,col,pat) in enumerate(zip(stats_dict['run_avg'][ai,gi,si],
                                                     stats_dict['run_ci'][ai,gi],
                                                     COLORS,
                                                     PATTERNS))]

        for bars in p:
            for bar in bars:
                # Super hacky way to get labels to show up in roughly the correct place...
                #
                # If bar value exceeds bottom subplot's ymax, then it's in the upper subplot, so:
                # - use an offset that zeros the height (i.e., label appears at y = 0)
                # - then add on where it should roughly be
                #   (4/3 of bottom subplot's max-y is top of the plot)
                if (bar.get_height() + bar.get_y()) > ycut_bot_lims[ai][gi][1]:
                    autolabel(bar, ycut_bot_lims[ai][gi][1]/0.81-(bar.get_height()+bar.get_y())*1.005)
                else:
                    autolabel(bar)


    # cut y-axis and add diagonal cut lines
    # (from http://matplotlib.org/examples/pylab_examples/broken_axis.html)
    axs[0].set_ylim(*(ycut_top_lims[ai][gi]))
    axs[1].set_ylim(*(ycut_bot_lims[ai][gi]))

    # hide spines between axs[0] and axs[1]
    axs[0].spines['bottom'].set_visible(False)
    axs[1].spines['top'].set_visible(False)
    axs[0].xaxis.tick_top()
    axs[0].tick_params(labeltop='off')
    axs[1].xaxis.tick_bottom()

    d = .015 # how big to make the diagonal lines in axes coordinates

    # arguments to pass plot, just so we don't keep repeating them
    kwargs = dict(transform=axs[0].transAxes, color='k', clip_on=False)
    axs[0].plot((-d,+d),(-d,+d), **kwargs)      # top-left diagonal
    axs[0].plot((1-d,1+d),(-d,+d), **kwargs)    # top-right diagonal

    kwargs.update(transform=axs[1].transAxes)  # switch to the bottom axes
    # mathematically this should just be d/4.0, but for whatever reason
    # it doesn't give a parallel line, so need d/2.2 for the bottom y coord
    axs[1].plot((-d,+d),(1-d/2.2,1+d/4.0), **kwargs)   # bottom-left diagonal
    axs[1].plot((1-d,1+d),(1-d/2.2,1+d/4.0), **kwargs) # bottom-right diagonal

    # HACK: get the topmost subplot's y ticks, so that ylabels are properly
    # spaced away from the axes. Multiply by 10 to get at least one digit's
    # worth of spacing. Hide tick labels by setting them to "white"
    # (b/c we only use white bg).
    ax_run.set_xticks([])
    ax_run.set_yticks([0, max(axs[1].get_yticks())*5])
    ax_run.tick_params(axis='both', colors='white')

    # hide bottom subplot's tick labels using this trick
    # this avoids misalignments with top subplot
    axs[1].set_xticklabels(['']*len(axs[1].get_xticks()))

    # fix y-tick intervals
    axs[0].yaxis.set_ticks(np.arange(*yrange[0]))
    axs[1].yaxis.set_ticks(np.arange(*yrange[1]))

    # enable minor ticks for all subplots
    for ax in axs + [ax_io]:
        ax.minorticks_on()

        # turn off major and minor x-axis ticks (leaves minor y-ticks on)
        ax.tick_params(axis='x', which='both', bottom='off', top='off')

        # add grid lines
        ax.grid(True, which='major', axis='y')

        # draw vertical lines to separate bar groups
        vlines_mi = np.array(mi)[np.arange(1,len(mi))]
        ax.vlines(IND[gi,vlines_mi]-BAR_MARGIN, 0, ax.get_ylim()[1], colors='k', linestyles='dotted')

    for ax in axs + [ax_io, ax_run]:
        for item in ([ax.title, ax.xaxis.label, ax.yaxis.label] +
                     ax.get_xticklabels() + ax.get_yticklabels()):
            item.set_fontsize(FONTSIZE)

    plt.subplots_adjust(hspace = 0.1)

    # shift setup times's subplot up (we can't use subplots_adjust again)
    bbox = ax_io.get_position()
    ax_io.set_position([bbox.x0, bbox.y0 + 0.024, bbox.x1-bbox.x0, bbox.y1-bbox.y0])

    # remove upper y-label to avoid overlap
    nbins = len(axs[1].get_yticklabels())
    ax_io.yaxis.set_major_locator(MaxNLocator(nbins=nbins, prune='upper'))

    return (ax_run, ax_io)


def plot_net(plt, fig, ai, gi, si, mi, ind, width, is_recv=True):
    """Plots network usage.

    Arguments:
    plt -- matplotlib.pyplot being used
    fig -- figure object (matplotlib.figure)
    ai -- algorithm index (int)
    gi -- graph index (int)
    si -- system indices, for plotting all or a subset of the systems (list/range)
    mi -- machine indices, for plotting all or a subset of the machines (list/range)
    ind -- left x-location of each bar group (list/range)
    width -- width of each bar (int)
    is_recv -- True for incoming network I/O, False for outgoing (boolean)

    Returns:
    Tuple of axes.
    """

    if is_recv:
        STAT_NAME = 'recv'
        LABEL_STR = 'incoming network I/O'
    else:
        STAT_NAME = 'sent'
        LABEL_STR = 'outgoing network I/O'


    # limits to cut at, indexed by ai and then gi
    # NOTE: this assumes ALG_PR has index 0, GRAPH_LJ has index 0, etc.
    if is_recv:
        ycut_top_lims = [[(1000, 1500), (7300, 7800), (5150, 5400), (4300,7000),  (13300,13800)],
                         [(1600, 2100), (600, 950),   (1800, 2800), (4050, 4600), (0,0)]]
        ycut_bot_lims = [[(0, 220), (0, 540), (0, 1600), (0, 2200), (0,6400)],
                         [(0, 170), (0, 140), (0, 860), (0, 1800), (0,0)]]
        yrange = [[[(1100, 1501, 200), (0, 201, 50)],
                   [(7400, 7801, 200), (0, 501, 100)],
                   [(5200, 5401, 100), (0, 1601, 300)],
                   [(5000, 7001, 1000), (0, 2201, 400)],
                   [(13400, 13801, 200), (0, 6001, 1000)]],
                  [[(1700, 2101, 200), (0, 180, 40)],
                   [(750, 951, 200), (0, 130, 30)],
                   [(2000, 2801, 400), (0, 801, 200)],
                   [(4200, 4601, 200), (0, 2000, 400)],
                   [(0,0,0), (0,0,0)]]]

    else:
        ycut_top_lims = [[(1000, 1500), (7200, 7700), (5120, 5400), (4200, 7000), (13300,13800)],
                         [(1500, 2000), (600, 900),   (1700, 2800), (3950, 4500), (0,0)]]
        ycut_bot_lims = [[(0, 220), (0, 540), (0, 1600), (0, 2200), (0,6400)],
                         [(0, 220), (0, 130), (0, 850),  (0, 1800), (0,0)]]
        yrange = [[[(1100, 1501, 200), (0, 201, 50)],
                   [(7300, 7701, 200), (0, 501, 100)],
                   [(5200, 5401, 100), (0, 1601, 300)],
                   [(5000, 7001, 1000), (0, 2201, 400)],
                   [(13400, 13801, 200), (0, 6001, 1000)]],
                  [[(1600, 2001, 200), (0, 201, 50)],
                   [(700, 901, 100), (0, 130, 30)],
                   [(2000, 2801, 400), (0, 801, 200)],
                   [(4100, 4501, 200), (0, 2000, 400)],
                   [(0,0,0), (0,0,0)]]]


    # to get shared x/ylabels for multiple subplots, first create a big subplot,
    # then add each smaller subplot... catch is that big subplot must have no axes
    ax_ret = fig.add_subplot(111)
    ax_ret.spines['bottom'].set_visible(False)
    ax_ret.spines['top'].set_visible(False)
    ax_ret.spines['left'].set_visible(False)
    ax_ret.spines['right'].set_visible(False)

    gs = gridspec.GridSpec(4,1)
    axs = [fig.add_subplot(gs[0,:]), fig.add_subplot(gs[1:,:])]

    def plot_helper(name, colors, alpha=1.0, is_sum=False):
        """Helper function to plot min, max, avg, or sum, depending on arguments.

        Arguments:
        name -- name of the statistic: min, max, or avg (string)
        colors -- list of colors, must have length = len(COLORS) (list)
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

        # plot data on all axes (=> single axis for non-broken y-axis, or two for broken)
        for ax in axs:
            # NOTE: alpha not supported in ps/eps
            p = [ax.bar(ind + width*i, np.multiply(avg[mi],num_machines[mi]), width,
                        color=col, hatch=pat, alpha=alpha,
                        ecolor=COLOR_ERR, yerr=np.multiply(ci[mi],num_machines[mi]), align='edge')
                 for i,(avg,ci,col,pat) in enumerate(zip(stats_dict[STAT_NAME + '_' + name + '_avg'][ai,gi,si],
                                                         stats_dict[STAT_NAME + '_' + name + '_ci'][ai,gi],
                                                         colors,
                                                         PATTERNS))]

            # label all bars
            for bars in p:
                for bar in bars:
                    if (bar.get_height() + bar.get_y()) > ycut_bot_lims[ai][gi][1]:
                        autolabel(bar, ycut_bot_lims[ai][gi][1]/0.82-(bar.get_height()+bar.get_y()))
                    else:
                        autolabel(bar)

        # cut y-axis and add diagonal cut lines
        # (from http://matplotlib.org/examples/pylab_examples/broken_axis.html)
        axs[0].set_ylim(*(ycut_top_lims[ai][gi]))
        axs[1].set_ylim(*(ycut_bot_lims[ai][gi]))

        # hide spines between axs[0] and axs[1]
        axs[0].spines['bottom'].set_visible(False)
        axs[1].spines['top'].set_visible(False)
        axs[0].xaxis.tick_top()
        axs[0].tick_params(labeltop='off')
        axs[1].xaxis.tick_bottom()

        d = .015 # how big to make the diagonal lines in axes coordinates

        # arguments to pass plot, just so we don't keep repeating them
        kwargs = dict(transform=axs[0].transAxes, color='k', clip_on=False)
        axs[0].plot((-d,+d),(-d,+d), **kwargs)      # top-left diagonal
        axs[0].plot((1-d,1+d),(-d,+d), **kwargs)    # top-right diagonal

        kwargs.update(transform=axs[1].transAxes)  # switch to the bottom axes
        # mathematically this should just be d/4.0, but for whatever reason
        # it doesn't give a parallel line, so need d/2.2 for the bottom y coord
        axs[1].plot((-d,+d),(1-d/2.2,1+d/4.0), **kwargs)   # bottom-left diagonal
        axs[1].plot((1-d,1+d),(1-d/2.2,1+d/4.0), **kwargs) # bottom-right diagonal

        # HACK: get the topmost subplot's y ticks, so that ylabels will be properly
        # spaced away from the axes. Use exp/log to get enough digits for spacing.
        # Hide tick labels by setting them to "white" (b/c we only use white bg).
        ax_ret.set_xticks([])
        if GRAPHS[gi] == GRAPH_LJ:
            ax_ret.set_yticks([0,10**(np.around(np.log10(max(axs[1].get_yticks())))+1)])
        else:
            ax_ret.set_yticks([0,10**(np.around(np.log10(max(axs[1].get_yticks()))))+0.1])
        ax_ret.tick_params(axis='both', colors='white')

        # fix y-tick intervals
        axs[0].yaxis.set_ticks(np.arange(*yrange[ai][gi][0]))
        axs[1].yaxis.set_ticks(np.arange(*yrange[ai][gi][1]))

        # enable minor ticks
        for ax in axs:
            ax.minorticks_on()

            # turn off major and minor x-axis ticks (leaves minor y-ticks on)
            ax.tick_params(axis='x', which='both', bottom='off', top='off')

            # add grid lines
            ax.grid(True, which='major', axis='y')

            # draw vertical lines to separate bar groups
            vlines_mi = np.array(mi)[np.arange(1,len(mi))]
            ax.vlines(IND[gi,vlines_mi]-BAR_MARGIN, 0, ax.get_ylim()[1], colors='k', linestyles='dotted')

        # ha controls where labels are aligned to (left, center, or right)
        plt.xticks(IND[gi,mi]+width*len(si)/2, GRAPH_LABELS[gi,mi], rotation=35, ha='center')

        plt.tight_layout()
        plt.subplots_adjust(hspace = 0.05)

    if do_sum_only:
        plot_helper('avg', COLORS, 1.0, True)
    elif do_avg_only:
        plot_helper('avg', COLORS)
    elif do_max_only:
        plot_helper('max', COLORS)
    else:
        # order is important: min should overlay avg, etc.
        # NOTE: used to use 0.6 alpha for min/max, but with patterns it doesn't look as good
        plot_helper('max', ['#e74c3c']*len(COLORS))
        plot_helper('avg', COLORS)
        plot_helper('min', ['#27ae60']*len(COLORS))


    if do_sum_only:
        ax_ret.set_ylabel('Total ' + LABEL_STR + ' (GB)')
    elif do_avg_only:
        ax_ret.set_ylabel('Average ' + LABEL_STR + ' (GB)')
    elif do_max_only:
        ax_ret.set_ylabel('Maximum ' + LABEL_STR + ' (GB)')
    else:
        ax_ret.set_ylabel('Min/avg/max ' + LABEL_STR + ' (GB)')

    for ax in axs + [ax_ret]:
        for item in ([ax.title, ax.xaxis.label, ax.yaxis.label] +
                     ax.get_xticklabels() + ax.get_yticklabels()):
            item.set_fontsize(FONTSIZE)

    return (ax_ret,)


def plot_mem(plt, fig, ai, gi, si, mi, ind, width):
    """Does nothing"""
    return ()

def plot_net_recv(plt, fig, ai, gi, si, mi, ind, width):
    """Wrapper function for plot_net"""
    return plot_net(plt, fig, ai, gi, si, mi, ind, width, True)

def plot_net_sent(plt, fig, ai, gi, si, mi, ind, width):
    """Wrapper function for plot_net"""
    return plot_net(plt, fig, ai, gi, si, mi, ind, width, False)


####################
# Generate plots
####################
PLOT_FUNCS = ((plot_time_split,),              # time
              (plot_mem,),                     # memory
              (plot_net_recv, plot_net_sent))  # net

fignum = 0

# y-axis only needs to be cut for these algs and graphs
# HACK: to ensure correct indices, use None in place of things
# that should not be plotted
if mode == MODE_TIME:
    ALGS = (ALG_PR, None, ALG_WCC)
    GRAPHS = (None, None, None, GRAPH_TW)

elif mode == MODE_NET:
    ALGS = (ALG_PR, ALG_SSSP)


for plt_type,save_suffix in enumerate(PLOT_TYPES[mode]):
    # iterate over all algs (ai = algorithm index)
    for ai,alg in enumerate(ALGS):
        if alg == None:
            continue

        # Not all systems do WCC or DMST, so we have to handle it separately.
        # This removes bars from each group of bars, so change bar width
        # to compensate for # of systems as well.
        # (si = system indices, which slices rows of the matrix)
        si = np.arange(len(ALL_SYS))         # all systems by default
        if (alg == ALG_MST):
            si = np.arange(3)                # only Giraph (hashmap, byte array) and GPS (none)
        elif (alg == ALG_WCC):
            si = np.arange(len(ALL_SYS)-1)   # all except GraphLab async

        width = (1.0 - 2.0*BAR_MARGIN)/len(si)

        if mode == MODE_NET:
            # skip TW for PageRank
            if alg == ALG_PR:
                GRAPHS = (GRAPH_LJ, GRAPH_OR, GRAPH_AR, GRAPH_TW, GRAPH_UK)
            else:
                GRAPHS = (GRAPH_LJ, GRAPH_OR, GRAPH_AR, GRAPH_TW, None)

        # iterate over all graphs (gi = graph index)
        for gi,graph in enumerate(GRAPHS):
            if graph == None:
                continue

            # Not all machine setups can run uk0705, so we remove 16/32's empty bars.
            # This will make the plot thinner (removes 2 groups of bars).
            # (mi = machine indices, which silces columns of the matrix)
            if save_paper:
                mi = np.arange(1,4)             # for paper, only plot 32,64, 128
            else:
                mi = np.arange(len(MACHINES))   # all machines by default

            if (alg == ALG_MST):
                if (graph == GRAPH_UK):
                    # NOTE: using 3,4 causes divide by zero warning in ticker.py
                    mi = np.arange(3,4)         # only 128 machines, but also show 64
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

            save_name = alg + '_' + graph + '_' + save_suffix
            if do_master:
                save_name = save_name + '_master'

            if save_eps:
                plt.savefig('./figs/' + save_name + '.eps', format='eps',
                            bbox_inches='tight', pad_inches=0.05)

            # TODO: save_png causes error on exit (purely cosmetic: trying to close a non-existent canvas)
            if save_png:
                plt.savefig('./figs/' + save_name + '.png', format='png',
                            dpi=200, bbox_inches='tight', pad_inches=0.05)


# show all plots
if not save_file:
    plt.show()

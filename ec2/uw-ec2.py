#!/usr/bin/env python

# Authors: Young Han, Khaled Ammar
#          {young.han, kammar} @ uwaterloo . ca
#
# For any bugs or comments, please contact the authors
#
# This is very loosely based off of GraphLab's gl_ec2.py file.
# Some functionality may be similar.
#
# For valid boto filters, see e.g.:
# http://docs.aws.amazon.com/AWSEC2/latest/CommandLineReference/ApiReference-cmd-DescribeInstances.html

import os, sys
import argparse
import time
import boto.ec2
import subprocess
import xml.dom.minidom


####################
# Constants
####################
SCRIPT_DIR = sys.path[0] + '/'

ACTIONS = ('launch', 'terminate', 'start', 'stop', 'connect',
           'init', 'create-sg', 'create-kp', 'get-logs')
# ACTION_FUNCS is defined below

# special cluster names used in our experiments
EXP_NAMES = ('cloud', 'cld', 'cw', 'cx', 'cy', 'cz')
EXP_NUMS = (4, 8, 16, 32, 64, 128)

# default master/slave AMI images (us-west-2)
AMI_MASTER = 'ami-3faed30f'
AMI_SLAVE = 'ami-9d1b6cad'

# default key pair, security group, instance type
DEFAULT_KEY = 'uwbench'
DEFAULT_PEM = SCRIPT_DIR + DEFAULT_KEY + '.pem'
DEFAULT_INSTANCE = 'm1.xlarge'
DEFAULT_SG = 'uwbench'

# default region & availability zone
DEFAULT_REGION = 'us-west-2'
DEFAULT_AZ = 'us-west-2c'

# for non-Ubuntu images (e.g., Fedora), this would be ec2-user
EC2_USER = 'ubuntu'
EC2_DRY_RUN_SUCCESS = 412   # status code (see AWS API)

####################
# Helper functions
####################
def get_args():
    '''Parses arguments.

    Returns:
    Parsed input arguments.
    '''

    # from: https://stackoverflow.com/questions/3853722
    class SmartFormatter(argparse.HelpFormatter):
        def _split_lines(self, text, width):
            # this is the RawTextHelpFormatter._split_lines
            if text.startswith('R|'):
                return text[2:].splitlines()
            return argparse.HelpFormatter._split_lines(self, text, width)

    parser = argparse.ArgumentParser(description="Automates EC2 operations.",
                                     formatter_class=SmartFormatter)

    parser.add_argument('action', choices=ACTIONS,
                        help="R|Action to perform: \n"
                             "launch    - launch a new cluster\n"
                             "terminate - terminate an existing cluster\n"
                             "start     - start a stopped cluster (on-demand instances only)\n"
                             "stop      - stop a running cluster (on-demand instances only)\n"
                             "connect   - connect to the master of a running cluster\n"
                             "init      - initialize a cluster\n"
                             "create-sg - create a new security group\n"
                             "create-kp - create a new EC2 key pair (saved in " + SCRIPT_DIR + ")\n"
                             "get-logs  - grab ~/benchmark/<system>/logs/*.tar.gz to\n"
                             "            " + SCRIPT_DIR + "../results/<system>/<num-slaves>/\n"
                             "            for all systems (giraph, gps, graphlab, mizan)")

    def check_slaves(num_slaves):
        try:
            ns = int(num_slaves)
            if ns < 1:
                raise argparse.ArgumentTypeError('Invalid number of slaves')
            return ns
        except:
            raise argparse.ArgumentTypeError('Invalid number of slaves')

    parser.add_argument('-n', '--num-slaves', type=check_slaves, default=4,
                        help="Number of worker/slave machines (default: 4)")
    parser.add_argument('-p', '--spot-price', metavar="PRICE", type=float, default=None,
                        help="If specified, launches a cluster as spot instances with the given maximum price (in dollars)")

    parser.add_argument('-i', '--identity-file', metavar="PEM_KEY", default=DEFAULT_PEM,
                        help="Local pem key file for SSHing to EC2 instances (default: %s)" % DEFAULT_PEM)
    parser.add_argument('-k', '--key-pair', metavar="KEY_NAME", default=DEFAULT_KEY,
                        help="Name of key pair on AWS (default: %s)" % DEFAULT_KEY)

    parser.add_argument('-t', '--instance-type', metavar="INSTANCE_TYPE", default=DEFAULT_INSTANCE,
                        help="Instance type, used by 'launch' (default: %s)" % DEFAULT_INSTANCE)
    parser.add_argument('-g', '--security-group', metavar="SECURITY_GROUP", default=DEFAULT_SG,
                        help="Name of security group (default: %s)" % DEFAULT_SG)
    parser.add_argument('-r', '--region', metavar="REGION", default=DEFAULT_REGION,
                        help="EC2 region to use (default: %s)" % DEFAULT_REGION)
    parser.add_argument('-z', '--zone', metavar="AZ", default=DEFAULT_AZ,
                        help="Availability zone to use (default: %s)" % DEFAULT_AZ)

    parser.add_argument('--ami-master', metavar="AMI_ID", default=AMI_MASTER,
                        help="Master AMI image (default: %s)" % AMI_MASTER)
    parser.add_argument('--ami-slave', metavar="AMI_ID", default=AMI_SLAVE,
                        help="Slave AMI image (default: %s)" % AMI_SLAVE)
    parser.add_argument('--persist-master-vol', action='store_true', default=False,
                        help="Do not delete the master's EBS volume on termination")

    args = parser.parse_args()

    # add cluster index as an extra key/value pair
    setattr(args, 'cluster_name', get_cluster_name(args.num_slaves))
    return args


def get_cluster_name(num_slaves):
    '''Generates a cluster name based on the number of slaves.

    If num_slaves is 4, 8, 16, 32, 64, or 128, it will return
    the machine names we used in our experiments.

    Naming conventions is always cluster_name + machine_id.
    For example, if the cluster_name is "cw" and there are 16
    slave machines, then the hostname of the master is cw0,
    while the slaves are cw1, cw2, ..., cw16.

    Arguments:
    num_slaves -- number of slaves (int)

    Returns:
    A cluster name (string).
    '''

    if num_slaves in EXP_NUMS:
        return EXP_NAMES[EXP_NUMS.index(num_slaves)]
    else:
        return 'c' + str(num_slaves) + 'x'  # totally creative


def exists(instance):
    '''Determine if instance is terminating/terminated or not.

    Arguments:
    instance -- An EC2 instance (boto.ec2.instance.Instance)

    Returns:
    True if instance is not terminating/terminated. False otherwise.
    '''

    # see: http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-lifecycle.html
    return not (instance.state in  ['shutting-down', 'terminated'])


def wait_for_status_exit(conn, instance_ids, state, message):
    '''Wait for instances to exit a particular state.

    Prints 'message' together with a timer for every 5 seconds waited.
    Uses 5 second polling intervals.

    Arguments:
    conn -- EC2 connection instance (boto.ec2.connection.EC2Connection)
    instance_ids -- list of instance IDS (list)
    state -- instance state to wait for all instances to NOT have (string)
    message -- message to print out (string)
    '''

    sec = 0
    while True:
        sys.stdout.write("\r%s(waited %is)" % (message, sec))
        sys.stdout.flush()

        remaining_instances = conn.get_only_instances(instance_ids, filters={'instance-state-name': state})
        if len(remaining_instances) == 0:
            break

        time.sleep(5)
        sec += 5

    print("\nDone.")


def launch_instances(conn, args, num_slaves, launch_master):
    '''Create/launch a specific number of properly tagged instances.

    All instances, spot requests, and EBS volumes are assigned common tags:
    1. cluster -- the cluster name
    2. master -- True if instance is the master, False otherwise

    Instances and EBS volumes are additonally assigned a "name" tag
    during init_cluster().

    Arguments:
    conn -- EC2 connection instance (boto.ec2.connection.EC2Connection)
    args -- Command-line arguments (argparse.Namespace)
    num_slaves -- Number of slaves: must be >0 and <= args.num_slaves (int)
    launch_master -- True to launch a master, False otherwise (bool)

    Returns:
    Tuple of master and slave instance ids: ([master-id], [slave-id, slave-id, ...]),
    or ([], []) if the launch failed.
    '''

    ## Define tags
    master_tag = {'cluster': args.cluster_name, 'master': 'True'}
    slave_tag = {'cluster': args.cluster_name, 'master': 'False'}

    ## Check if images actually exist
    try:
        conn.get_all_images(image_ids=[args.ami_master, args.ami_slave])
    except:
        print("ERROR: Could not find AMIs!")
        return ([], [])

    # common launch settings
    launch_config = dict(key_name = args.key_pair,
                         instance_type = args.instance_type,
                         security_groups = [args.security_group],
                         placement = args.zone)

    ## Launch instances
    if args.spot_price == None:
        # if no spot price specified, launch things on-demand
        print("Requesting %s%d slaves as on-demand instances."
              % ("master and " if launch_master else "", num_slaves))

        # do a test/dry run so failures won't occur half way
        # (an example is when quota is exceeded)
        try:
            conn.run_instances(args.ami_slave,
                               min_count = num_slaves + (1 if launch_master else 0),
                               max_count = num_slaves + (1 if launch_master else 0),
                               dry_run = True,
                               **launch_config)
        except boto.exception.EC2ResponseError as e:
            if e.status != EC2_DRY_RUN_SUCCESS:
                print("\nInstance requests failed:")
                print(xml.dom.minidom.parseString(e.body).toprettyxml(indent="  "))
                return ([], [])

        if launch_master:
            master_res = conn.run_instances(args.ami_master, **launch_config)
            master_instance_ids = [i.id for i in master_res.instances]
        else:
            master_instance_ids = []

        slave_res = conn.run_instances(args.ami_slave,
                                       min_count = num_slaves,
                                       max_count = num_slaves,
                                       **launch_config)
        slave_instance_ids = [i.id for i in slave_res.instances]

    else:
        print("Requesting %s%d slaves as spot instances with price $%.3f."
              % ("master and " if launch_master else "", num_slaves, args.spot_price))

        # unlike instances, spot requests can be cancelled
        # additionally, dry run does NOT detect "max spot instance count exceeded"
        try:
            # get requests and request ids
            master_reqs = slave_reqs = []   # for except clause

            if launch_master:
                master_reqs = conn.request_spot_instances(args.spot_price,
                                                          args.ami_master,
                                                          launch_group = args.cluster_name,
                                                          **launch_config)
                master_req_ids = [req.id for req in master_reqs]
            else:
                master_req_ids = []

            slave_reqs = conn.request_spot_instances(args.spot_price,
                                                     args.ami_slave,
                                                     count = num_slaves,
                                                     launch_group = args.cluster_name,
                                                     **launch_config)
            slave_req_ids = [req.id for req in slave_reqs]

        except boto.exception.EC2ResponseError as e:
            print("\nSpot requests failed:")
            print(xml.dom.minidom.parseString(e.body).toprettyxml(indent="  "))

            master_req_ids = [req.id for req in master_reqs]
            slave_req_ids = [req.id for req in slave_reqs]

            sys.stdout.write("Cancelling all requests... ")
            if len(master_req_ids + slave_req_ids) > 0:
                sys.stdout.flush()
                conn.cancel_spot_instance_requests(master_req_ids + slave_req_ids)
            print("Done.")

            return ([],[])

        # tag spot requests
        time.sleep(5)         # wait for requests to actually exist
        sys.stdout.write("  Tagging spot requests... ")
        sys.stdout.flush()
        if launch_master:
            conn.create_tags(master_req_ids, master_tag)
        conn.create_tags(slave_req_ids, slave_tag)
        print("Done.")

        print("  Waiting for spot instances to be granted...")

        # wait for all requests to become active/fulfilled
        sec = 0
        while True:
            # get remaining open requests (this is needed to get updated info)
            if launch_master:
                pending_master_reqs = conn.get_all_spot_instance_requests(master_req_ids, filters={'state': 'open'})
            else:
                pending_master_reqs = []

            pending_slave_reqs = conn.get_all_spot_instance_requests(slave_req_ids, filters={'state': 'open'})

            # If any one request is no longer "pending" while being "open", then
            # the cluster cannot be started in any reasonable amount of time.
            # This can be due to price too low, insufficient capacity to launch entire group, etc.
            #
            # Safest bet is to cancel all requests (no instances will be up, due to launch-group-constraint)
            for r in pending_master_reqs + pending_slave_reqs:
                if not (r.status.code in ['pending-evaluation', 'pending-fulfillment']):
                    print("\nERROR: Request %s returned non-pending status %s!" % (r.id, r.status.code))
                    print("Spot requests failed!")

                    sys.stdout.write("Cancelling all requests... ")
                    sys.stdout.flush()
                    conn.cancel_spot_instance_requests(master_req_ids + slave_req_ids)
                    print("Done.")
                    return ([], [])

            # check if all requests have been fulfilled
            if len(pending_master_reqs) == 0 and len(pending_slave_reqs) == 0:
                if launch_master:
                    print("\nMaster and all %i slaves granted." % num_slaves)
                else:
                    print("\nAll %i slaves granted." % num_slaves)
                break

            elif len(pending_slave_reqs) == 0 and launch_master:
                sys.stdout.write("\r  Master not granted yet... (waited %is)" % sec)
                sys.stdout.flush()
            else:
                sys.stdout.write("\r  %i of %i slaves granted... (waited %is)" %
                                 (num_slaves - len(pending_slave_reqs), num_slaves, sec))
                sys.stdout.flush()

            time.sleep(5)
            sec += 5

        # get instance ids from requests
        # NOTE: must retreive them again to get updated request info
        if launch_master:
            master_reqs = conn.get_all_spot_instance_requests(master_req_ids)
            master_instance_ids = [r.instance_id for r in master_reqs]
        else:
            master_instance_ids = []

        slave_reqs = conn.get_all_spot_instance_requests(slave_req_ids)
        slave_instance_ids = [r.instance_id for r in slave_reqs]


    ## Tag instances
    sys.stdout.write("Tagging instances... ")
    sys.stdout.flush()
    if launch_master:
        conn.create_tags(master_instance_ids, master_tag)
    conn.create_tags(slave_instance_ids, slave_tag)
    print("Done.")

    ## Wait for instances to become 'running'
    wait_for_status_exit(conn, master_instance_ids + slave_instance_ids,
                         'pending', "Waiting for machines to start... ")

    ## Tag EBS volumes AFTER instances are running
    sys.stdout.write("Tagging EBS volumes... ")
    sys.stdout.flush()

    if launch_master:
        conn.create_tags([v.id for mid in master_instance_ids
                          for v in conn.get_all_volumes(filters={'attachment.instance-id': mid})],
                         master_tag)

    conn.create_tags([v.id for sid in slave_instance_ids
                      for v in conn.get_all_volumes(filters={'attachment.instance-id': sid})],
                     slave_tag)
    print("Done.")

    ## Persist master's EBS volume if needed
    if launch_master and args.persist_master_vol:
        # really bizarre way of setting delete_on_termination to false
        conn.modify_instance_attribute(master_instance_ids[0], 'BlockDeviceMapping', ['/dev/sda1=false'])

    return (master_instance_ids, slave_instance_ids)


def get_cluster(conn, cluster_name):
    '''Get all non-terminating/non-terminated EC2 instances for a tagged cluster.

    Although the clusters, if created with this script, should always have exactly
    one master, we cannot guarantee the user won't do something manually. So the
    number of returned master instances can be > 1.

    Arguments:
    conn -- EC2 connection instance (boto.ec2.connection.EC2Connection)
    cluster_name -- Name of the cluster (string)

    Returns:
    Tuple of master and slave instance ids: ([master-id, master-id, ...], [slave-id, slave-id, ...]).
    One or both lists may be empty if machines are missing (e.g., ([], [])).
    '''

    # If instances were launched together, they belong to a single reservation.
    #
    # get_all_instances() returns a list of reservations, and each reservation contains a list of instances
    # get_only_instances() just returns list of instances
    master_instances = conn.get_only_instances(filters={'tag:cluster': cluster_name, 'tag:master': 'True'})
    slave_instances = conn.get_only_instances(filters={'tag:cluster': cluster_name, 'tag:master': 'False'})

    # (example for using res: [i.id for res in slave_res for i in res.instances])

    # match only non-terminating/non-terminated instances
    # (no additional error handling---the caller deals with that)
    master_instance_ids = [i.id for i in master_instances if exists(i)]
    slave_instance_ids = [i.id for i in slave_instances if exists(i)]

    return (master_instance_ids, slave_instance_ids)


####################
# Action Functions
####################
def create_kp(conn, args):
    '''Create a key pair and save it to the local machine.

    The pem key is saved to where this script is located.

    Arguments:
    conn -- EC2 connection instance (boto.ec2.connection.EC2Connection)
    args -- Command-line arguments (argparse.Namespace)
    '''

    try:
        key = conn.create_key_pair(args.key_pair)
        # key is saved as <args.key_pair>.pem
        key.save(SCRIPT_DIR)
        print("Key created and saved to %s%s.pem" % (SCRIPT_DIR, args.key_pair))

    except boto.exception.EC2ResponseError as e:
        if "already exists" in e.body:
            print("Key pair %s already exists!" % args.key_pair)
            return
        else:
            raise


def create_sg(conn, args):
    '''Creates a security group.

    Arguments:
    conn -- EC2 connection instance (boto.ec2.connection.EC2Connection)
    args -- Command-line arguments (argparse.Namespace)
    '''

    try:
        sg = conn.create_security_group(args.security_group,
                                        'SG for Hadoop, Giraph, GPS, GraphLab, Mizan')

        # external rules
        sg.authorize('tcp', 22, 22, '0.0.0.0/0')        # SSH
        sg.authorize('tcp', 50030, 50030, '0.0.0.0/0')  # Hadoop monitoring
        sg.authorize('tcp', 50060, 50060, '0.0.0.0/0')  # Hadoop
        sg.authorize('tcp', 50070, 50070, '0.0.0.0/0')  # Hadoop
        sg.authorize('tcp', 8888, 8888, '0.0.0.0/0')    # GPS monitoring
        sg.authorize('tcp', 4444, 4444, '0.0.0.0/0')    # GPS debug monitoring

        # internal rules
        sg.authorize('tcp', 0, 65535, '172.31.0.0/16')
        sg.authorize('udp', 0, 65535, '172.31.0.0/16')

        print("Security group %s successfully created!" % args.security_group)

    except boto.exception.EC2ResponseError as e:
        if "already exists" in e.body:
            print("Security group %s already exists!" % args.security_group)
            return
        else:
            raise


def start_cluster(conn, args):
    '''Start a cluster of tagged instances.

    Arguments:
    conn -- EC2 connection instance (boto.ec2.connection.EC2Connection)
    args -- Command-line arguments (argparse.Namespace)
    '''

    (master_instance_ids, slave_instance_ids) = get_cluster(conn, args.cluster_name)

    if len(master_instance_ids) == 0 and len(slave_instance_ids) == 0:
        print("ERROR: No machines to start!")
        return

    if len(master_instance_ids) == 0:
        print("ERROR: No master machine found!")
        return
    if len(master_instance_ids) > 1:
        print("ERROR: Multiple master machines found!")
        return

    # go ahead anyway, the user probably knows what he/she is doing...
    if len(slave_instance_ids) != args.num_slaves:
        print("WARNING: Only %i of %i slave machines found!" % (len(slave_instance_ids), args.num_slaves))

    sys.stdout.write("Starting cluster %s... " % args.cluster_name)
    sys.stdout.flush()
    try:
        conn.start_instances(master_instance_ids + slave_instance_ids)
    except boto.exception.EC2ResponseError as e:
        if "not in a state" in e.body:
            print("\nCannot start instances! Ensure they are all stopped.")
            return
        else:
            raise

    wait_for_status_exit(conn, master_instance_ids + slave_instance_ids,
                         'pending', "Starting cluster " + args.cluster_name + "... ")


def stop_cluster(conn, args):
    '''Stop a cluster of tagged instances.

    Arguments:
    conn -- EC2 connection instance (boto.ec2.connection.EC2Connection)
    args -- Command-line arguments (argparse.Namespace)
    '''

    (master_instance_ids, slave_instance_ids) = get_cluster(conn, args.cluster_name)

    if len(master_instance_ids) == 0 and len(slave_instance_ids) == 0:
        print("ERROR: No machines to stop!")
        return

    if len(master_instance_ids) > 1:
        print("ERROR: Multiple master machines found!")
        return

    if len(master_instance_ids) == 0:
        print("WARNING: No master machine found!")
    if len(slave_instance_ids) != args.num_slaves:
        print("WARNING: Only %i of %i slaves machines found!" % (len(slave_instance_ids), args.num_slaves))

    sys.stdout.write("Stopping cluster %s... " % args.cluster_name)
    sys.stdout.flush()

    try:
        conn.stop_instances(master_instance_ids + slave_instance_ids)
    except boto.exception.EC2ResponseError as e:
        if "cannot be stopped" in e.body:
            print("\Cannot stop instances! Ensure they are all running.")
            return
        elif "is a spot instance" in e.body:
            print("\nCannot stop spot instances! Use terminate instead.")
            return
        else:
            raise

    wait_for_status_exit(conn, master_instance_ids + slave_instance_ids,
                         'stopping', "Stopping cluster " + args.cluster_name + "... ")


def terminate_cluster(conn, args):
    '''Terminate a cluster of tagged instances.

    Arguments:
    conn -- EC2 connection instance (boto.ec2.connection.EC2Connection)
    args -- Command-line arguments (argparse.Namespace)
    '''

    (master_instance_ids, slave_instance_ids) = get_cluster(conn, args.cluster_name)

    if len(master_instance_ids) == 0 and len(slave_instance_ids) == 0:
        print("ERROR: No machines to terminate!")
        return

    # just in case the user forgot about a renamed master...
    if len(master_instance_ids) > 1:
        print("ERROR: Multiple master machines found!")
        return

    if len(master_instance_ids) == 0:
        print("WARNING: No master machine found!")
    if len(slave_instance_ids) != args.num_slaves:
        print("WARNING: Only %i of %i slave machines found!" % (len(slave_instance_ids), args.num_slaves))

    # find this info out before terminating the instances
    if len(master_instance_ids) != 0:
        master_vol_deleted = conn.get_instance_attribute(
            master_instance_ids[0],
            'blockDeviceMapping')['blockDeviceMapping']['/dev/sda1'].delete_on_termination
    else:
        master_vol_deleted = True

    sys.stdout.write("Terminating cluster %s... " % args.cluster_name)
    sys.stdout.flush()
    conn.terminate_instances(master_instance_ids + slave_instance_ids)
    print("Done.")

    if not master_vol_deleted:
        print("WARNING: The master's volume has NOT been deleted. Please delete it manually.")


def launch_cluster(conn, args):
    '''Create/launch a cluster of properly tagged instances.

    This also handles launching replacement slave instances,
    in case they are intentionally or accidentally terminated.

    This does NOT replace the master instance!

    Arguments:
    conn -- EC2 connection instance (boto.ec2.connection.EC2Connection)
    args -- Command-line arguments (argparse.Namespace)

    Returns:
    Tuple of master and slave instance ids: ([master-id], [slave-id, slave-id, ...]),
    or ([], []) if the launch fails.

    Also fails if a cluster already exists and there are no missing slaves.
    '''

    print("Creating cluster %s with %i slaves..." % (args.cluster_name, args.num_slaves))

    ## Check if instances already exist for a cluster (and if replacements are needed)
    (master_instance_ids, slave_instance_ids) = get_cluster(conn, args.cluster_name)

    if len(master_instance_ids) > 0 or len(slave_instance_ids) > 0:
        print("WARNING: There are existing instances for %s!" % args.cluster_name)

        num_launch_slaves = args.num_slaves - len(slave_instance_ids)

        if num_launch_slaves > 0:
            print("\nThere are %i missing slaves for %s! Launching replacements..."
                  % (num_launch_slaves, args.cluster_name))
            ret = launch_instances(conn, args, num_launch_slaves, False)

            # start up existing instances
            if ret != ([], []):
                conn.start_instances(master_instance_ids + slave_instance_ids)
                wait_for_status_exit(conn, master_instance_ids + slave_instance_ids,
                                     'pending', "Starting existing instances... ")
            return ret

        else:
            return ([], [])

    ## Otherwise, launch like normal
    return launch_instances(conn, args, args.num_slaves, True)


def init_cluster(conn, args):
    '''Initialize a tagged cluster.

    This creates a tag "name" for all instances and EBS volumes where,
    for a cluster name "cw" and 16 slaves, the master is "cw0" and the
    slaves are "cw1", "cw2", ..., "cw16".

    Then it updates hostnames, /etc/hostname, and /etc/hosts of all
    intances in the cluster (using the above "name" tag).

    Arguments:
    conn -- EC2 connection instance (boto.ec2.connection.EC2Connection)
    args -- Command-line arguments (argparse.Namespace)
    '''

    (master_instance_ids, slave_instance_ids) = get_cluster(conn, args.cluster_name)

    if len(master_instance_ids) == 0:
        print("ERROR: No master machine found!")
        return
    if len(master_instance_ids) > 1:
        print("ERROR: Multiple master machines found!")
        return

    if len(slave_instance_ids) != args.num_slaves:
        print("ERROR: Only %i of %i slave machines found!" % (len(slave_instance_ids), args.num_slaves))
        return

    ## Assign proper 'name' tags to instances and EBS volumes
    sys.stdout.write("Assigning 'name' tags... ")
    sys.stdout.flush()
    conn.create_tags(master_instance_ids, {'name': '%s0' % args.cluster_name})
    conn.create_tags([v.id for mid in master_instance_ids
                      for v in conn.get_all_volumes(filters={'attachment.instance-id': mid})],
                     {'name': '%s0' % args.cluster_name})

    for i,slave in enumerate(conn.get_only_instances(slave_instance_ids)):
        slave.add_tag('name', '%s%i' % (args.cluster_name, i+1))
        conn.create_tags([v.id for v in conn.get_all_volumes(filters={'attachment.instance-id': slave.id})],
                         {'name': '%s%i' % (args.cluster_name, i+1)})
    print("Done.")

    ## Check that all instances are running
    for i in conn.get_only_instances(master_instance_ids + slave_instance_ids):
        if i.state != 'running':
            print("\nInstance %s not running! Try again once it's running." % i.tags['name'])
            return

    ## Update hostnames and /etc/hosts
    hosts = ("127.0.0.1 localhost\n\n"
             "# The following lines are desirable for IPv6 capable hosts\n"
             "::1 ip6-localhost ip6-loopback\n"
             "fe00::0 ip6-localnet\n"
             "ff00::0 ip6-mcastprefix\n"
             "ff02::1 ip6-allnodes\n"
             "ff02::2 ip6-allrouters\n"
             "ff02::3 ip6-allhosts\n\n")

    master_instance = conn.get_only_instances(master_instance_ids)[0]
    hosts += "%s %s\n" % (master_instance.private_ip_address,
                          master_instance.tags['name'])
    hosts += ''.join(["%s %s\n" % (i.private_ip_address, i.tags['name'])
                      for i in conn.get_only_instances(slave_instance_ids)])

    # perform multiple SSH commands in the background
    sys.stdout.write("Updating hostname and /etc/hosts... (0 of %i done)" % (args.num_slaves+1))
    sys.stdout.flush()

    cmd = ""
    for i,instance in enumerate(conn.get_only_instances(master_instance_ids + slave_instance_ids)):
        # build up command (to be ran in bg)
        # NOTE: subprocess.call(...,shell=True) uses /bin/sh, so escapes in echo are always interpreted
        cmd += ("ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i \"%s\" %s@%s \""
                % (args.identity_file, EC2_USER, instance.ip_address))
        cmd += ("sudo hostname " + instance.tags['name'] + "; "           # update hostname
                "sudo chown " + EC2_USER + " /etc/hostname /etc/hosts; "  # chown so we can write
                "echo '" + instance.tags['name'] + "' > /etc/hostname; "  # update /etc/hostname
                "echo '" + hosts + "' > /etc/hosts; "                     # update /etc/hosts
                "sudo chown root /etc/hostname /etc/hosts")               # restore to root for security

        cmd += "\" 2>&1 | grep -v 'Warning: Permanently added'"           # suppress specific warnings
        cmd += " | grep -v 'sudo: unable to resolve host' & "             # suppress hostname-changed warnings

        # Execute command once in a while, so it doesn't become too large.
        # Also execute remaining commands if this is the last iteration.
        if (i+1) % 32 == 0 or i == args.num_slaves:
            cmd += "wait"
            output = subprocess.check_output(cmd, shell=True)
            cmd = ""

            if len(output) != 0:
                print "\n" + output
                print "Initialization failed!"
                return

            sys.stdout.write("\rUpdating hostname and /etc/hosts... (%i of %i done)"
                             % (i+1, args.num_slaves+1))
            sys.stdout.flush()

    print("\nDone.")

    ## Generate ~/benchmark/common/get-hosts.sh on master
    sys.stdout.write("Generating get-hosts.sh... ")
    sys.stdout.flush()

    get_hosts = ("#!/bin/bash\n\n"
                 "# Set the prefix name and number of slaves/worker machines.\n#\n"
                 "# NOTE: This file is automatically generated by uw-ec2.py init!\n\n"
                 "HOSTNAME=\$(hostname)\n"
                 "CLUSTER_NAME=%s\n"
                 "NUM_MACHINES=%d") % (args.cluster_name, args.num_slaves)

    master_instance = conn.get_only_instances(master_instance_ids)[0]

    cmd = ("ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i \"%s\" %s@%s \""
            % (args.identity_file, EC2_USER, master_instance.ip_address))
    cmd += ("echo '" + get_hosts + "' > ~/benchmark/common/get-hosts.sh; "
            "chmod +x ~/benchmark/common/get-hosts.sh")
    cmd += "\" 2>&1 | grep -v 'Warning: Permanently added' || true"   # "|| true" is hack to get exit status 0
    output = subprocess.check_output(cmd, shell=True)

    if len(output) != 0:
        print "\n" + output
        print "Initialization failed!"
        return

    print("Done.")

    # example of using paramiko via boto's cmdshell
    # to see results from remote cmds, use: print(''.join(map(str,ssh.run('some-cmd')[1:])))
    #ssh = boto.manage.cmdshell.sshclient_from_instance(master_instance, args.identity_file,
    #                                                   user_name=EC2_USER,
    #                                                   host_key_file='/dev/null')
    #ssh.run('echo \"%s\" > ~/benchmark/common/get-hosts.sh' % get_hosts)

    print("Initialization complete!")


def ssh_master(conn, args):
    '''Connect/ssh to the master of a cluster.

    Arguments:
    conn -- EC2 connection instance (boto.ec2.connection.EC2Connection)
    args -- Command-line arguments (argparse.Namespace)
    '''

    (master_instance_ids, slave_instance_ids) = get_cluster(conn, args.cluster_name)

    if len(master_instance_ids) == 0:
        print("ERROR: No master machine found!")
        return
    if len(master_instance_ids) > 1:
        print("ERROR: Multiple master machines found!")
        return

    master_instance = conn.get_only_instances(master_instance_ids)[0]

    if master_instance.state == 'pending':
        wait_for_status_exit(conn, master_instance_ids,
                             'pending', "Waiting for master machine to start... ")
        master_instance.update()

    if master_instance.state != 'running':
        print("ERROR: Master machine is not running!")
        return

    pub_ip = master_instance.ip_address
    subprocess.call("ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i \"%s\" %s@%s" %
                    (args.identity_file, EC2_USER, pub_ip), shell=True)


def get_logs(conn, args):
    '''Grab tarballs from each system's log folder (~/benchmark/<system>/logs/*.tar.gz).

    Specifically, remote files from ~/benchmark/<system>/logs/*.tar.gz are scp'd
    to ../results/<system>/<num-slaves>/, relative to the location of this script.
    Here, <num-slaves> is the number of slaves in the cluster.

    Arguments:
    conn -- EC2 connection instance (boto.ec2.connection.EC2Connection)
    args -- Command-line arguments (argparse.Namespace)
    '''

    (master_instance_ids, slave_instance_ids) = get_cluster(conn, args.cluster_name)

    if len(master_instance_ids) == 0:
        print("ERROR: No master machine found!")
        return
    if len(master_instance_ids) > 1:
        print("ERROR: Multiple master machines found!")
        return

    master_instance = conn.get_only_instances(master_instance_ids)[0]

    if master_instance.state == 'pending':
        wait_for_status_exit(conn, master_instance_ids,
                             'pending', "Waiting for master machine to start... ")
        master_instance.update()

    if master_instance.state != 'running':
        print("ERROR: Master machine is not running!")
        return

    pub_ip = master_instance.ip_address

    # build SCP command and create result directories (if they don't exist)
    scp_cmd = ""
    for system in ['giraph', 'gps', 'graphlab', 'mizan']:
        scp_cmd += ("scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i \"%s\" "
                    "%s@%s:~/benchmark/%s/logs/*.tar.gz %s/../results/%s/%i/ & "
                    % (args.identity_file, EC2_USER, pub_ip, system, SCRIPT_DIR, system, args.num_slaves))

        target_dir = '%s/../results/%s/%i/' % (SCRIPT_DIR, system, args.num_slaves)
        if not os.path.exists(target_dir):
            os.makedirs(target_dir)

    # basically a hacky way to spawn shell processes & wait on them
    scp_cmd += "wait"

    print("Grabbing tarballs from all systems in parallel...")
    subprocess.call(scp_cmd, shell=True)
    print("Complete!")


####################
# main()
####################
ACTION_FUNCS = (launch_cluster, terminate_cluster, start_cluster, stop_cluster,
                ssh_master, init_cluster, create_sg, create_kp, get_logs)

def main():
    args = get_args()

    # credentials are in ~/.boto
    conn = boto.ec2.connect_to_region(args.region)

    # safety checks
    if args.action == 'terminate':
        response = raw_input("\n"
                             "***************************************************\n"
                             "* WARNING: ALL DATA ON ALL MACHINES WILL BE LOST! *\n"
                             "***************************************************\n"
                             "Terminate cluster %s? (y/N): " % args.cluster_name)
        print("")
        if response != "y":
            return

    elif args.action == 'stop':
        response = raw_input("\n"
                             "************************************************************\n"
                             "* WARNING: ALL DATA ON EPHEMERAL DISKS WILL BE LOST!       *\n"
                             "*          THE CLUSTER WILL CONTINUE TO INCUR EBS CHARGES! *\n"
                             "************************************************************\n"
                             "Stop cluster %s? (y/N): " % args.cluster_name)
        print("")
        if response != "y":
            return

    ACTION_FUNCS[ACTIONS.index(args.action)](conn, args)

if __name__ == "__main__":
    main()

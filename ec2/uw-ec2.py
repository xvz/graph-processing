#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

####################
# Notes
####################
# Authors: Young Han, Khaled Ammar
#          {young.han, kammar} @ uwaterloo . ca
#
# For any bugs or comments, please contact the authors
#
# This is loosely based off of Graphlab's gl_ec2.py file, so some functions may be similar.


####################
# Misc Dev Notes
####################
# For valid filters, see e.g.:
# http://docs.aws.amazon.com/AWSEC2/latest/CommandLineReference/ApiReference-cmd-DescribeInstances.html

import os, sys
import argparse
import time
import boto.ec2, boto.manage.cmdshell
import subprocess
#import logging


####################
# Constants
####################
SCRIPT_DIR = sys.path[0] + '/'

ACTIONS = ('launch', 'terminate', 'start', 'stop',
           'connect', 'init', 'create-sg', 'create-kp')
# ACTION_FUNCS is defined below

# special cluster names used in our experiments
EXP_NAMES = ('cloud', 'cld', 'cw', 'cx', 'cy', 'cz')
EXP_NUMS = (4, 8, 16, 32, 64, 128)

# Default master/slave AMI images
AMI_MASTER = 'ami-40dca970'
AMI_SLAVE = 'ami-42dca972'

# default key pair, security group, instance type
DEFAULT_KEY = 'uwbench'
DEFAULT_PEM = SCRIPT_DIR + DEFAULT_KEY + '.pem'
DEFAULT_INSTANCE = 'm1.xlarge'
DEFAULT_SG = 'uwbench'

# default region & availability zone
DEFAULT_REGION = 'us-west-2'
DEFAULT_AZ = 'us-west-2c'


####################
# Utility functions
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
                             "start     - start a stopped cluster (on-demand only)\n"
                             "stop      - stop a running cluster (on-demand only)\n"
                             "init      - initialize a cluster\n"
                             "create-sg - create new security group\n"
                             "create-kp - create new EC2 key pair (saved in %s)" % SCRIPT_DIR)

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
                        help="If specified, launch as spot instances with the given maximum price (in dollars)")
    parser.add_argument('--persist-master-vol', action='store_true', default=False,
                        help="Do not delete the master's EBS volume on termination")

    parser.add_argument('-s', '--ssh-key', default=DEFAULT_PEM,
                        help="Local pem key file for SSHing (default: %s)" % DEFAULT_PEM)
    parser.add_argument('-k', '--key-pair', default=DEFAULT_KEY,
                        help="Name of key file on AWS (default: %s)" % DEFAULT_KEY)

    parser.add_argument('-t', '--instance-type', metavar="INSTANCE_TYPE", default=DEFAULT_INSTANCE,
                        help="Instance type (default: %s)" % DEFAULT_INSTANCE)
    parser.add_argument('-g', '--security-group', metavar="SECURITY_GROUP", default=DEFAULT_SG,
                        help="Name of security group (default: %s)" % DEFAULT_SG)
    parser.add_argument('-r', '--region', metavar="REGION", default=DEFAULT_REGION,
                        help="EC2 region to use (default: %s)" % DEFAULT_REGION)
    parser.add_argument('-a', '--availability-zone', metavar="AZ", default=DEFAULT_AZ,
                        help="Availability zone to use (default: %s)" % DEFAULT_AZ)


    parser.add_argument('--ami-master', metavar="AMI_ID", default=AMI_MASTER,
                        help="Master AMI image (default: %s)" % AMI_MASTER)
    parser.add_argument('--ami-slave', metavar="AMI_ID", default=AMI_SLAVE,
                        help="Slave AMI image (default: %s)" % AMI_SLAVE)

    args = parser.parse_args()

    # add cluster index as an extra key/value pair
    setattr(args, 'cluster_name', get_cluster_name(args.num_slaves))
    return args

def get_cluster_name(num_slaves):
    '''Generates a cluster name based on the number of slaves.

    If num_slaves is 4, 8, 16, 32, 64, or 128, it will return
    the machine names we used in our experiments.

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


def get_cluster(conn, cluster_name):
    '''Get all running or stopped EC2 instances for a particular cluster.

    Arguments:
    conn -- EC2 connection instance (boto.ec2.connection.EC2Connection)
    cluster_name -- Name of the cluster (string)

    Returns:
    Tuple of master and slave instance ids: ([master-id], [slave-id, slave-id, ...]).
    One or both lists may be empty if machines are missing (e.g., ([], [])).
    '''

    # If instances were launched together, they belong to a single reservation.
    #
    # get_all_instances() returns a list of reservations, and each reservation contains a list of instances
    # get_only_instances() just returns list of instances
    master_instances = conn.get_only_instances(filters={'tag:Name': '%s0' % cluster_name})
    slave_instances = conn.get_only_instances(filters={'tag:Name': cluster_name})

    # (example for using res: [i.id for res in slave_res for i in res.instances])

    # match only non-terminating/non-terminated instances
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
        print("Key created and saved to %s/%s.pem" % (SCRIPT_DIR, args.key_pair))

    except boto.exception.EC2ResponseError as e:
        if "already exists" in e.body:
            print("Key pair %s already exists!" % args.key_pair)
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
        print("No machines to start!")
        return

    if len(master_instance_ids) != 1:
        print("WARNING: no master machine found!")
    if len(slave_instance_ids) != args.num_slaves:
        print("WARNING: only %i of %i slave machines found!" % (len(slave_instance_ids), args.num_slaves))

    sys.stdout.write("Starting cluster [%s]... " % args.cluster_name)
    sys.stdout.flush()
    try:
        conn.start_instances(master_instance_ids + slave_instance_ids)
    except boto.exception.EC2ResponseError as e:
        if "not in a state" in e.body:
            print("\nCannot start instances! Ensure they are all stopped.")
            return
        else:
            raise

    sec = 0
    while True:
        sys.stdout.write("\rStarting cluster [%s]... (waited %is)" % (args.cluster_name, sec))
        sys.stdout.flush()
        pending_instances = conn.get_only_instances(master_instance_ids + slave_instance_ids,
                                                    filters={'instance-state-name': 'pending'})
        if len(pending_instances) == 0:
            break
        time.sleep(5)
        sec += 5

    print("\nDone.")


def stop_cluster(conn, args):
    '''Stop a cluster of tagged instances.

    Arguments:
    conn -- EC2 connection instance (boto.ec2.connection.EC2Connection)
    args -- Command-line arguments (argparse.Namespace)
    '''

    (master_instance_ids, slave_instance_ids) = get_cluster(conn, args.cluster_name)

    if len(master_instance_ids) == 0 and len(slave_instance_ids) == 0:
        print("No machines to stop!")
        return

    if len(master_instance_ids) != 1:
        print("WARNING: no master machine found!")
    if len(slave_instance_ids) != args.num_slaves:
        print("WARNING: only %i of %i slaves machines found!" % (len(slave_instance_ids), args.num_slaves))

    sys.stdout.write("Stopping cluster [%s]... " % args.cluster_name)
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

    sec = 0
    while True:
        sys.stdout.write("\rStopping cluster [%s]... (waited %is)" % (args.cluster_name, sec))
        sys.stdout.flush()
        stopping_instances = conn.get_only_instances(master_instance_ids + slave_instance_ids,
                                                     filters={'instance-state-name': 'stopping'})
        if len(stopping_instances) == 0:
            break
        time.sleep(5)
        sec += 5

    print("\nDone.")


def terminate_cluster(conn, args):
    '''Terminate a cluster of tagged instances.

    Arguments:
    conn -- EC2 connection instance (boto.ec2.connection.EC2Connection)
    args -- Command-line arguments (argparse.Namespace)
    '''
    (master_instance_ids, slave_instance_ids) = get_cluster(conn, args.cluster_name)

    if len(master_instance_ids) == 0 and len(slave_instance_ids) == 0:
        print("No machines to terminate!")
        return

    if len(master_instance_ids) != 1:
        print("WARNING: no master machine found!")
    if len(slave_instance_ids) != args.num_slaves:
        print("WARNING: only %i of %i machines found!" % (len(slave_instance_ids), args.num_slaves))

    sys.stdout.write("Terminating cluster [%s]... " % args.cluster_name)
    sys.stdout.flush()
    conn.terminate_instances(master_instance_ids + slave_instance_ids)
    print("Done.")

    master_vol_deleted = conn.get_instance_attribute(
        master_instance_ids[0],
        'blockDeviceMapping')['blockDeviceMapping']['/dev/sda1'].delete_on_termination

    if not master_vol_deleted:
        print("WARNING: The master's volume has NOT been deleted. Please delete it manually.")


def launch_cluster(conn, args):
    '''Create/launch a cluster of properly tagged instances.

    Master instance, spot request, and EBS volume are tagged with
    the cluster name and 0: e.g., "cw0". Slave instances and spot
    requests are tagged with the cluster name, e.g. "cw".

    Arguments:
    conn -- EC2 connection instance (boto.ec2.connection.EC2Connection)
    args -- Command-line arguments (argparse.Namespace)

    Returns:
    Tuple of master and slave instance ids: ([master-id], [slave-id, slave-id, ...]).
    Fails (exits) if a cluster already exists.
    '''

    print("Creating cluster [%s] with %i slaves..." % (args.cluster_name, args.num_slaves))

    ## Check if instances already exist for a cluster
    (masters, slaves) = get_cluster(conn, args.cluster_name)
    if len(masters) > 0 or len(slaves) > 0:
        print("ERROR: There are existing instances for %s!" + args.cluster_name)
        sys.exit(1)

    ## Check if images actually exist
    try:
        conn.get_all_images(image_ids=[args.ami_master])
        conn.get_all_images(image_ids=[args.ami_slave])
    except:
        print("ERROR: Could not find AMIs!")
        sys.exit(1)

    # common launch settings
    launch_config = dict(key_name = args.key_pair,
                         instance_type = args.instance_type,
                         security_groups = [args.security_group],
                         placement = args.availability_zone)


    ## Launch instances
    if args.spot_price == None:
        # if no spot price specified, launch things on-demand
        print("Requesting master and %d slaves as on-demand instances." % args.num_slaves)

        master_res = conn.run_instances(args.ami_master, **launch_config)

        slave_res = conn.run_instances(args.ami_slave,
                                       min_count = args.num_slaves,
                                       max_count = args.num_slaves,
                                       **launch_config)

        master_instance_ids = [i.id for i in master_res.instances]
        slave_instance_ids = [i.id for i in slave_res.instances]

    else:
        print("Requesting master and %d slaves as spot instances with price $%.3f."
              % (args.num_slaves, args.spot_price))

        master_reqs = conn.request_spot_instances(args.spot_price,
                                                  args.ami_master,
                                                  launch_group = args.cluster_name,
                                                  **launch_config)

        slave_reqs = conn.request_spot_instances(args.spot_price,
                                                 args.ami_slave,
                                                 count = args.num_slaves,
                                                 launch_group = args.cluster_name,
                                                 **launch_config)

        # get request ids
        master_req_ids = [req.id for req in master_reqs]
        slave_req_ids = [req.id for req in slave_reqs]

        # tag spot requests
        time.sleep(5)         # wait for requests to actually exist
        sys.stdout.write("  Tagging spot requests... ")
        sys.stdout.flush()
        conn.create_tags(master_req_ids, {'Name': '%s0' % args.cluster_name})
        conn.create_tags(slave_req_ids, {'Name': args.cluster_name})
        print("Done.")

        print("  Waiting for spot instances to be granted...")

        # wait for all requests to become active/fulfilled
        sec = 0
        while True:
            # get remaining open requests (this is needed to get updated info)
            pending_master_reqs = conn.get_all_spot_instance_requests(master_req_ids, filters={'state': 'open'})
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
                    return

            # check if all requests have been fulfilled
            if len(pending_master_reqs) == 0 and len(pending_slave_reqs) == 0:
                print("\nMaster and all %i slaves granted." % args.num_slaves)
                break

            elif len(pending_slave_reqs) == 0:
                sys.stdout.write("\r  Master not granted yet... (waited %is)" % sec)
                sys.stdout.flush()
            else:
                sys.stdout.write("\r  %i of %i slaves granted... (waited %is)" %
                                 (args.num_slaves - len(pending_slave_reqs), args.num_slaves, sec))
                sys.stdout.flush()

            time.sleep(5)
            sec += 5

        # get instance ids from requests
        # NOTE: must retreive them again to get instance ids
        master_reqs = conn.get_all_spot_instance_requests(master_req_ids)
        slave_reqs = conn.get_all_spot_instance_requests(slave_req_ids)
        master_instance_ids = [r.instance_id for r in master_reqs]
        slave_instance_ids = [r.instance_id for r in slave_reqs]


    ## Tag instances (this is easier than getting each resource and using r.add_tags(...))
    sys.stdout.write("Tagging instances... ")
    sys.stdout.flush()
    conn.create_tags(master_instance_ids, {'Name': '%s0' % args.cluster_name})
    conn.create_tags(slave_instance_ids, {'Name': args.cluster_name})
    print("Done.")

    ## Wait for instances to become 'running'
    sec = 0
    while True:
        sys.stdout.write("\rWaiting for machines to start... (waited %is)" % sec)
        sys.stdout.flush()

        pending_instances = conn.get_only_instances(master_instance_ids + slave_instance_ids,
                                                    filters={'instance-state-name': 'pending'})
        if len(pending_instances) == 0:
            break

        time.sleep(5)
        sec += 5

    print("\nDone.")

    ## Tag EBS volumes AFTER instances are running
    sys.stdout.write("Tagging EBS volumes... ")
    sys.stdout.flush()
    conn.create_tags([v.id for mid in master_instance_ids
                      for v in conn.get_all_volumes(filters={'attachment.instance-id': mid})],
                     {'Name': '%s0' % args.cluster_name})

    conn.create_tags([v.id for sid in slave_instance_ids
                      for v in conn.get_all_volumes(filters={'attachment.instance-id': sid})],
                     {'Name': args.cluster_name})
    print("Done.")

    ## Persist master's EBS vol if needed
    if args.persist_master_vol:
        # really bizarre way of setting delete_on_termination to false
        conn.modify_instance_attribute(master_instance_ids[0], 'BlockDeviceMapping', ['/dev/sda1=false'])

    return (master_instance_ids, slave_instance_ids)


def init_cluster(conn, args):
    '''Initialize a tagged cluster.

    Arguments:
    conn -- EC2 connection instance (boto.ec2.connection.EC2Connection)
    args -- Command-line arguments (argparse.Namespace)
    '''

    (master_instance_ids, slave_instance_ids) = get_cluster(conn, args.cluster_name)

    if len(master_instance_ids) != 1:
        print("No master machine found!")
        return

    master_instance = conn.get_only_instances(master_instance_ids)[0]

    ssh = boto.manage.cmdshell.sshclient_from_instance(master_instance,
                                                       args.ssh_key,
                                                       user_name='ubuntu')

    # TODO: pem key permission/mode check

    hosts = ("127.0.0.1 localhost\n\n"
             "# The following lines are desirable for IPv6 capable hosts\n"
             "::1 ip6-localhost ip6-loopback\n"
             "fe00::0 ip6-localnet\n"
             "ff00::0 ip6-mcastprefix\n"
             "ff02::1 ip6-allnodes\n"
             "ff02::2 ip6-allrouters\n"
             "ff02::3 ip6-allhosts\n\n")

    machine_id = 0
    hosts += "%s %s%i\n" % (master_instance.private_ip_address, args.cluster_name, machine_id)

    private_ips = [i.private_ip_address for i in conn.get_only_instances(slave_instance_ids)]
    for ip in private_ips:
        machine_id += 1
        hosts += "%s %s%i\n" % (ip, args.cluster_name, machine_id)

    # change master's hostname
    ssh.run('sudo hostname %s0' % args.cluster_name)
    print ssh.run('sudo echo \"%s0\" > /etc/hostname' % args.cluster_name)

    # update master's /etc/hosts
    print ssh.run('sudo echo \"%s\" > /etc/hosts' % hosts)

    # execute ~/benchmark/init-all.sh
    #print(' '.join(map(str,ssh.run('~/benchmark/init-all.sh')[1:])))

    print("Initialization complete!")


def connect_cluster(conn, args):
    '''Connect to the master of a cluster.

    Arguments:
    conn -- EC2 connection instance (boto.ec2.connection.EC2Connection)
    args -- Command-line arguments (argparse.Namespace)
    '''

    (master_instance_ids, slave_instance_ids) = get_cluster(conn, args.cluster_name)

    if len(master_instance_ids) != 1:
        print("No master machine found!")
        return

    pub_ip = conn.get_only_instances(master_instance_ids)[0].ip_address

    subprocess.check_call("ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i \"%s\" ubuntu@%s" %
                          (args.ssh_key, pub_ip), shell=True)


####################
# main()
####################
ACTION_FUNCS = (launch_cluster, terminate_cluster, start_cluster, stop_cluster,
                connect_cluster, init_cluster, create_sg, create_kp)

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
                             "Terminate cluster [" + args.cluster_name + "]? (y/N): ")
        if response != "y":
            sys.exit(1)

    elif args.action == 'stop':
        response = raw_input("\n"
                             "************************************************************\n"
                             "* WARNING: ALL DATA ON EPHEMERAL DISKS WILL BE LOST!       *\n"
                             "*          THE CLUSTER WILL CONTINUE TO INCUR EBS CHARGES! *\n"
                             "************************************************************\n"
                             "Stop cluster [" + args.cluster_name + "]? (y/N): ")
        if response != "y":
            sys.exit(1)

    ACTION_FUNCS[ACTIONS.index(args.action)](conn, args)

    # TODO: get results

if __name__ == "__main__":
#    logging.basicConfig()
    main()

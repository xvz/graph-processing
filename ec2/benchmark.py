#ls!/usr/bin/env python
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

#########################################
#           NOTE
#########################################
#
# Author: Khaled Ammar (kammar @ uwaterloo . ca)
# For any bugs or comments, please contact the author
#
#
# Disclaimer: This python file was inspired by Graphlab benchmark python file. Some utility functions might be identical.

import boto
import logging
import os
import random
import shutil
import subprocess
import datetime
import sys
import tempfile
import time
import urllib2
import stat
from optparse import OptionParser
from sys import stderr
from boto.ec2.blockdevicemapping import BlockDeviceMapping, EBSBlockDeviceType


# Configure and parse our command-line arguments
def parse_args():
  parser = OptionParser(usage="run-benchmark [options] <action> <cluster_name>"
      + "\n\n<action> can be: launch, destroy, login, stop, start, start-hadoop, stop-hadoop, check-hadoop, get-master, update",
      add_help_option=False)
  parser.add_option("-h", "--help", action="help",
                    help="Show this help message and exit")
  parser.add_option("-s", "--slaves", type="int", default=1,
      help="Number of slaves to launch (default: 1)")
  parser.add_option("-k", "--key-pair",
      help="The name of the ssh identitiy key")
  parser.add_option("-i", "--identity-file", 
      help="SSH private key file to use for logging into instances")
  parser.add_option("-r", "--region", default="us-west-2",
      help="EC2 region zone to launch instances in")
  parser.add_option("-z", "--zone", default="",
      help="Availability zone to launch instances in")
  parser.add_option("-a", "--ami", default="std",
      help="Amazon Machine Image ID to use, or 'hpc' to use ami for high performance instances" +
           "(default: std)")
  parser.add_option("--spot-price", metavar="PRICE", type="float",
      help="If specified, launch slaves as spot instances with the given " +
            "maximum price (in dollars)")
  parser.add_option("--ami_master", metavar="ami_master", default="",
                      help="ami image for master")
  parser.add_option("--ami_slave", metavar="ami_slave", default="",
                        help="ami image for slave workers")
  parser.add_option("--instance_type", metavar="instance_type", default="m1.xlarge",
                      help="instance type, default is m1.xlarge")
    
    
  (opts, args) = parser.parse_args()
  if len(args) != 2:
    parser.print_help()
    sys.exit(1)
    
  (action, cluster_name) = args
  if opts.identity_file == None :
    print >> stderr, ("ERROR: The -i or --identity-file argument is " +
                      "required for " + action)
    sys.exit(1)
  private_key_mode = str(oct(os.stat(opts.identity_file)[stat.ST_MODE])[-3:])
  if private_key_mode != "400" :
    print >> stderr, ("ERROR: permissions of private key file " +opts.identity_file+
                      " should be 400")
    sys.exit(1)
      
  if os.getenv('AWS_ACCESS_KEY_ID') == None:
    print >> stderr, ("ERROR: The environment variable AWS_ACCESS_KEY_ID " +
                      "must be set")
    sys.exit(1)

  if os.getenv('AWS_SECRET_ACCESS_KEY') == None:
    print >> stderr, ("ERROR: The environment variable AWS_SECRET_ACCESS_KEY " +
                      "must be set")
    sys.exit(1)

  if opts.instance_type == "m1.xlarge":
    compilation_threads = 4

  opts.ami_master = "ami-40dca970"	# master image
  opts.ami_slave =  "ami-42dca972" # slave image

  return (opts, action, cluster_name)


# Get the EC2 security group of the given name, creating it if it doesn't exist
def get_or_make_group(conn, name):
  groups = conn.get_all_security_groups()
  group = [g for g in groups if g.name == name]
  if len(group) > 0:
    return group[0]
  else:
    print "Creating security group " + name
    return conn.create_security_group(name, "default group")


# Wait for a set of launched instances to exit the "pending" state
# (i.e. either to start running or to fail and be terminated)
def wait_for_instances(conn, instances):
  while True:
    for i in instances:
      i.update()
    if len([i for i in instances if i.state == 'pending']) > 0:
      time.sleep(5)
    else:
      return


# Wait for a set of instances to stop 
# (i.e. either to start running or to fail and be terminated)
def wait_for_stopping(conn, instance):
   while True:
     instance.update()
     if instance.state == 'stopping':
       time.sleep(5)
     else:
       return



# Check whether a given EC2 instance object is in a state we consider active,
# i.e. not terminating or terminated. We count both stopping and stopped as
# active since we can restart stopped clusters.
# TODO: We probably should not consider pending, stopping, or stopped !
def is_active(instance):
  return (instance.state in ['pending', 'running', 'stopping', 'stopped'])


# Launch a cluster of the given name, by setting up its security groups,
# and then starting new instances in them.
# Returns a tuple of EC2 reservation objects for the master, slave
# and zookeeper instances (in that order).
# Fails if there already instances running in the cluster's groups.
def launch_cluster(conn, opts, cluster_name):
  print "create benchmarking by AMIs: " + opts.ami_master + " and " + opts.ami_slave
  print "Setting up security groups..."
  master_group = get_or_make_group(conn, cluster_name + "-master")
  slave_group = get_or_make_group(conn, cluster_name + "-slaves")
  zoo_group = get_or_make_group(conn, cluster_name + "-zoo")
  # master_group = get_or_make_group(conn, cluster_name)
  # slave_group = get_or_make_group(conn, cluster_name)
  # zoo_group = get_or_make_group(conn, cluster_name)


  if master_group.rules == []: # Group was just now created
    master_group.authorize(src_group=master_group)
    master_group.authorize(src_group=slave_group)
    master_group.authorize(src_group=zoo_group)
    master_group.authorize('tcp', 22, 22, '0.0.0.0/0')
    master_group.authorize('tcp', 0, 65535, '0.0.0.0/0')
    master_group.authorize('udp', 0, 65535, '0.0.0.0/0')
    master_group.authorize('tcp', 8080, 8081, '0.0.0.0/0')
    master_group.authorize('tcp', 50030, 50030, '0.0.0.0/0')
    master_group.authorize('tcp', 50070, 50070, '0.0.0.0/0')
    master_group.authorize('tcp', 60070, 60070, '0.0.0.0/0')
    master_group.authorize('tcp', 38090, 38090, '0.0.0.0/0')
  if slave_group.rules == []: # Group was just now created
    slave_group.authorize(src_group=master_group)
    slave_group.authorize(src_group=slave_group)
    slave_group.authorize(src_group=zoo_group)
    slave_group.authorize('tcp', 0, 65535, '0.0.0.0/0')
    slave_group.authorize('udp', 0, 65535, '0.0.0.0/0')
    slave_group.authorize('tcp', 22, 22, '0.0.0.0/0')
    slave_group.authorize('tcp', 8080, 8081, '0.0.0.0/0')
    slave_group.authorize('tcp', 50060, 50060, '0.0.0.0/0')
    slave_group.authorize('tcp', 50075, 50075, '0.0.0.0/0')
    slave_group.authorize('tcp', 60060, 60060, '0.0.0.0/0')
    slave_group.authorize('tcp', 60075, 60075, '0.0.0.0/0')
  if zoo_group.rules == []: # Group was just now created
    zoo_group.authorize(src_group=master_group)
    zoo_group.authorize(src_group=slave_group)
    zoo_group.authorize(src_group=zoo_group)
    zoo_group.authorize('tcp', 22, 22, '0.0.0.0/0')
    zoo_group.authorize('tcp', 2181, 2181, '0.0.0.0/0')
    zoo_group.authorize('tcp', 2888, 2888, '0.0.0.0/0')
    zoo_group.authorize('tcp', 3888, 3888, '0.0.0.0/0')

  # Check if instances are already running in our groups
  print "Checking for running cluster..."
  reservations = conn.get_all_instances()
  for res in reservations:
    group_names = [g.id for g in res.groups]
    if master_group.name in group_names or slave_group.name in group_names or zoo_group.name in group_names:
      active = [i for i in res.instances if is_active(i)]
      if len(active) > 0:
        print >> stderr, ("ERROR: There are already instances running in " +
            "group %s, %s or %s" % (master_group.name, slave_group.name, zoo_group.name))
        sys.exit(1)


  print "Launching instances..."
  try:
    image_master = conn.get_all_images(image_ids=[opts.ami_master])[0]
    image_slave = conn.get_all_images(image_ids=[opts.ami_slave])[0]
  except:
    print >> stderr, "Could not find AMI " + opts.ami
    sys.exit(1)

  # Launch slaves
  if opts.spot_price != None:
    # Launch spot instances with the requested price
    print ("Requesting %d slaves as spot instances with price $%.3f" %
           (opts.slaves, opts.spot_price))
    slave_reqs = conn.request_spot_instances(
        price = opts.spot_price,
        image_id = opts.ami_slave,
        launch_group = "launch-group-%s" % cluster_name,
        placement = opts.zone,
        count = opts.slaves,
        key_name = opts.key_pair,
        security_groups = [slave_group],
        instance_type = opts.instance_type)
    my_req_ids = [req.id for req in slave_reqs]
    print "Waiting for spot instances to be granted..."
    while True:
      time.sleep(10)
      reqs = conn.get_all_spot_instance_requests()
      id_to_req = {}
      for r in reqs:
        id_to_req[r.id] = r
      active = 0
      instance_ids = []
      for i in my_req_ids:
        if id_to_req[i].state == "active":
          active += 1
          instance_ids.append(id_to_req[i].instance_id)
      if active == opts.slaves:
        print "All %d slaves granted" % opts.slaves
        reservations = conn.get_all_instances(instance_ids)
        slave_nodes = []
        for r in reservations:
          slave_nodes += r.instances
        break
      else:
        print "%d of %d slaves granted, waiting longer" % (active, opts.slaves)
  else:
    # Launch non-spot instances
    slave_res = image_slave.run(key_name = opts.key_pair,
                          security_groups = [slave_group],
                          instance_type = opts.instance_type,
                          placement = opts.zone,
                          min_count = opts.slaves,
                          max_count = opts.slaves)
    slave_nodes = slave_res.instances
    print "Launched slaves, regid = " + slave_res.id

  # # Launch masters
  master_type = opts.master_instance_type
  if master_type == "":
    master_type = opts.instance_type
  master_res = image_master.run(key_name = opts.key_pair,
                         security_groups = [master_group],
                         instance_type = master_type,
                         placement = opts.zone,
                         min_count = 1,
                         max_count = 1)
  master_nodes = master_res.instances
  print "Launched master, regid = " + master_res.id

  zoo_nodes = []

  # Return all the instances
  return (master_nodes, slave_nodes, zoo_nodes)


# Get the EC2 instances in an existing cluster if available.
# Returns a tuple of lists of EC2 instance objects for the masters,
# slaves and zookeeper nodes (in that order).
def get_existing_cluster(conn, opts, cluster_name):
  print "Searching for existing cluster " + cluster_name + "..."
  reservations = conn.get_all_instances()
  master_nodes = []
  slave_nodes = []
  zoo_nodes = []
  for res in reservations:
    active = [i for i in res.instances if is_active(i)]
    if len(active) > 0:
      print "Acitve: ", active
      group_names = list(set(g.name for g in i.groups for i in res.instances)) #DB: bug fix as explained here: https://spark-project.atlassian.net/browse/SPARK-749
      print "Group names: ", group_names 
      if group_names == [cluster_name + "-master"]:
        master_nodes += res.instances
      elif group_names == [cluster_name + "-slaves"]:
        slave_nodes += res.instances
      elif group_names == [cluster_name + "-zoo"]:
        zoo_nodes += res.instances
  if master_nodes != [] and slave_nodes != []:
    print ("Found %d master(s), %d slaves, %d ZooKeeper nodes" %
           (len(master_nodes), len(slave_nodes), len(zoo_nodes)))
    return (master_nodes, slave_nodes, zoo_nodes)
  else:
    if master_nodes == [] and slave_nodes != []:
      print "ERROR: Could not find master in group " + cluster_name + "-master"
    elif master_nodes != [] and slave_nodes == []:
      print "ERROR: Could not find slaves in group " + cluster_name + "-slaves"
    else:
      print "ERROR: Could not find any existing cluster"
    sys.exit(1)


# Get the EC2 instances in an existing cluster if available for destory purpose.
# This function returns whatever found instances
# Returns a tuple of lists of EC2 instance objects for the masters,
# slaves and zookeeper nodes (in that order).
def get_existing_cluster_destroy(conn, opts, cluster_name):
    print "Searching for existing cluster " + cluster_name + "..."
    reservations = conn.get_all_instances()
    master_nodes = []
    slave_nodes = []
    zoo_nodes = []
    for res in reservations:
        active = [i for i in res.instances if is_active(i)]
        if len(active) > 0:
            print "Acitve: ", active
            group_names = list(set(g.name for g in i.groups for i in res.instances)) #DB: bug fix as explained here: https://spark-project.atlassian.net/browse/SPARK-749
            print "Group names: ", group_names
            if group_names == [cluster_name + "-master"]:
                master_nodes += res.instances
            elif group_names == [cluster_name + "-slaves"]:
                slave_nodes += res.instances
            elif group_names == [cluster_name + "-zoo"]:
                zoo_nodes += res.instances
    if master_nodes != [] and slave_nodes != []:
        print ("Found %d master(s), %d slaves, %d ZooKeeper nodes" %
               (len(master_nodes), len(slave_nodes), len(zoo_nodes)))
        return (master_nodes, slave_nodes, zoo_nodes)
    else:
        if master_nodes == [] and slave_nodes != []:
            print "ERROR: Could not find master in group " + cluster_name + "-master"
        elif master_nodes != [] and slave_nodes == []:
            print "ERROR: Could not find slaves in group " + cluster_name + "-slaves"
        else:
            print "ERROR: Could not find any existing cluster"
        return (master_nodes, slave_nodes, zoo_nodes)


def get_private_dns(conn, opts, cluster_name):
    (master_nodes, slave_nodes, zoo_nodes) = get_existing_cluster(conn, opts, cluster_name)
    hosts = [master_nodes[0].private_dns_name]
    for slave in slave_nodes:
      hosts.append(slave.private_dns_name)
    return hosts

def get_internal_ips(conn, opts, cluster_name):
    (master_nodes, slave_nodes, zoo_nodes) = get_existing_cluster(conn, opts, cluster_name)
    hosts = [master_nodes[0].private_ip_address]
    for slave in slave_nodes:
        hosts.append(slave.private_ip_address)
    return hosts


def get_master_ip(conn, opts, cluster_name):
     (master_nodes, slave_nodes, zoo_nodes) = get_existing_cluster(conn, opts, cluster_name)
     ip = master_nodes[0].private_ip_address
     return ip



# Prepare the cluster to run the benchmark
# This step is mandatory
def setup_cluster(conn, master_nodes, slave_nodes, zoo_nodes, opts, cluster_name, deploy_ssh_key):
  masterIP = master_nodes[0].private_ip_address
  master = master_nodes[0].public_dns_name
  if deploy_ssh_key:
    print "Copying SSH key %s to master node %s..." % (opts.identity_file,master)
    ssh(master, opts, 'sudo mkdir -p /root/.ssh; rm -rf tmp; mkdir tmp')
    scp(master, opts, opts.identity_file, 'tmp/id_rsa')
      #The following step is useful if we want to send log files to S3
      #scp(master, opts, '.s3cfg', 'tmp/.s3cfg')
      #ssh(master, opts, 'sudo mv tmp/id_rsa ~/.ssh/; sudo mv tmp/.s3cfg ~/.s3cfg')
    ssh(master, opts, 'sudo mv tmp/id_rsa ~/.ssh/key.pem')
    ssh(master, opts, 'sudo chown ubuntu /mnt; sudo chgrp ubuntu /mnt')
    config = open("config", "w")
    config.write("StrictHostKeyChecking no\nBatchMode yes\n")
    config.close()
    #print("4")
    scp(master, opts, "config", ".ssh/config")
    for i in slave_nodes:
       ip = i.public_dns_name
       print "Copying SSH key %s to slave node %s..." % (opts.identity_file,ip)
       ssh(ip, opts, 'sudo mkdir -p /root/.ssh; rm -rf tmp; mkdir tmp')
       scp(ip, opts, opts.identity_file, 'tmp/id_rsa')
       #The following step is useful if we want to send log files to S3
       #scp(ip, opts, '.s3cfg', 'tmp/.s3cfg')
       #ssh(ip, opts, 'sudo mv tmp/id_rsa ~/.ssh/; sudo mv tmp/.s3cfg ~/.s3cfg')
       ssh(ip, opts, 'sudo mv tmp/id_rsa ~/.ssh/key.pem')
       scp(ip, opts, "config", ".ssh/config")
       ssh(ip, opts, 'sudo chown ubuntu /mnt; sudo chgrp ubuntu /mnt')
  print "Copy machines hostfile to master..."
  hosts = get_internal_ips(conn, opts, cluster_name)
           # Create a file machines_<No slaves> at local directory
           # This file includes local-ip and hostname for all machines in the cluster starting by the master
           # Then we move this file to one in the master
           # Finally, the file is distributed to all slaves
  hostfile = open("machines_%s"%cluster_name, "w")
  ipIndex = 0
  for ip in hosts:
    hostfile.write("%s %s%i\n" % (ip,cluster_name,ipIndex))
    ipIndex = ipIndex +1
  hostfile.close()
  scp(master, opts, "default_hosts", '~/default_hosts')
  ssh(master, opts, "sudo -- sh -c \"cat ~/default_hosts > /etc/hosts\" ")
  scp(master, opts, "machines_%s"%cluster_name, '~/hosts_%i'%opts.slaves)
  ssh(master, opts, "sudo -- sh -c \"cat ~/hosts_%i >> /etc/hosts\" "%opts.slaves)
  ssh(master, opts, "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ~/.ssh/key.pem -t ubuntu@%s \
    \" echo '%s0' > /tmp/hostname && sudo mv /tmp/hostname /etc/hostname; sudo hostname %s0 \" "%(masterIP, cluster_name, cluster_name) )

  print "Finished preparing clluster !"
  print "The master ip is : %s"%  master


# Wait for a whole cluster (masters, slaves and ZooKeeper) to start up
def wait_for_cluster(conn, wait_secs, master_nodes, slave_nodes, zoo_nodes):
  print "Waiting for instances to start up..."
  time.sleep(5)
  wait_for_instances(conn, master_nodes)
  wait_for_instances(conn, slave_nodes)
  if zoo_nodes != []:
    wait_for_instances(conn, zoo_nodes)
  print "Waiting %d more seconds..." % wait_secs
  time.sleep(wait_secs)


# Copy a file to a given host through scp, throwing an exception if scp fails
def scp(host, opts, local_file, dest_file):
  subprocess.check_call(
      "scp -r -q -o StrictHostKeyChecking=no -i %s '%s' 'ubuntu@%s:%s'" %
      (opts.identity_file, local_file, host, dest_file), shell=True)


# Run a command on a host through ssh, throwing an exception if ssh fails
def ssh(host, opts, command):
    #print("ssh -t -o StrictHostKeyChecking=no -i %s ubuntu@%s '%s'" %
    #      (opts.identity_file, host, command))
        
    subprocess.check_call(
      "ssh -t -o StrictHostKeyChecking=no -i %s ubuntu@%s '%s'" %
      (opts.identity_file, host, command), shell=True)
 
# Run a command on a host through ssh, throwing an exception if ssh fails (run command in background)
def ssh_bkg(host, opts, command):
    #print("ssh -f -t -o StrictHostKeyChecking=no -i %s ubuntu@%s '%s'" %
    #      (opts.identity_file, host, command))
    
    subprocess.check_call(
                          "ssh -f -t -o StrictHostKeyChecking=no -i %s ubuntu@%s '%s'" %
                          (opts.identity_file, host, command), shell=True)

def tagging(conn, opts, cluster_name):
    print "Cluster tagging"
    (master_nodes, slave_nodes, zoo_nodes) = get_existing_cluster(conn, opts, cluster_name)
    master_nodes[0].add_tag("Name","%s0"%(cluster_name))
    tag_id=1
    for inst in slave_nodes:
        inst.add_tag("Name","%s%i"%(cluster_name,tag_id))
        tag_id = tag_id + 1
    print "done tagging."




def main():
    (opts, action, cluster_name) = parse_args()
    conn = boto.ec2.connect_to_region(opts.region)
    
    # Select an AZ at random if it was not specified.
    if opts.zone == "":
        opts.zone = random.choice(conn.get_all_zones()).name
    
    if action == "launch":
        (master_nodes, slave_nodes, zoo_nodes) = launch_cluster(conn, opts, cluster_name)
        wait_for_cluster(conn, opts.wait, master_nodes, slave_nodes, zoo_nodes)
        setup_cluster(conn, master_nodes, slave_nodes, zoo_nodes, opts, cluster_name, True)
    
    elif action == "destroy":
        response = raw_input("Are you sure you want to destroy the cluster " +
                             cluster_name + "?\nALL DATA ON ALL NODES WILL BE LOST!!\n" +
                             "Destroy cluster " + cluster_name + " (y/N): ")
        if response == "y":
            (master_nodes, slave_nodes, zoo_nodes) = get_existing_cluster_destroy(conn, opts, cluster_name)
            print "Terminating master..."
            for inst in master_nodes:
                inst.terminate()
            print "Terminating slaves..."
            for inst in slave_nodes:
                inst.terminate()
            if zoo_nodes != []:
                print "Terminating zoo..."
                for inst in zoo_nodes:
                    inst.terminate()
    
    elif action == "login":
        (master_nodes, slave_nodes, zoo_nodes) = get_existing_cluster(
                                                                      conn, opts, cluster_name)
        master = master_nodes[0].public_dns_name
        print "Logging into master " + master + "..."
        proxy_opt = ""
        if opts.proxy_port != None:
            proxy_opt = "-D " + opts.proxy_port
        subprocess.check_call("ssh -o StrictHostKeyChecking=no -i %s %s ubuntu@%s" %
                              (opts.identity_file, proxy_opt, master), shell=True)
    

    elif action == "get-master":
        (master_nodes, slave_nodes, zoo_nodes) = get_existing_cluster(conn, opts, cluster_name)
        print master_nodes[0].public_dns_name
    
    
    elif action == "stop":
        response = raw_input("Are you sure you want to stop the cluster " +
                             cluster_name + "?\nDATA ON EPHEMERAL DISKS WILL BE LOST, " +
                             "BUT THE CLUSTER WILL KEEP USING SPACE ON\n" + 
                             "AMAZON EBS IF IT IS EBS-BACKED!!\n" +
                             "Stop cluster " + cluster_name + " (y/N): ")
        if response == "y":
            (master_nodes, slave_nodes, zoo_nodes) = get_existing_cluster(
                                                                          conn, opts, cluster_name)
            print "Stopping master..."
            for inst in master_nodes:
                if inst.state not in ["shutting-down", "terminated"]:
                    inst.stop()
            print "Stopping slaves..."
            for inst in slave_nodes:
                if inst.state not in ["shutting-down", "terminated"]:
                    inst.stop()
            if zoo_nodes != []:
                print "Stopping zoo..."
                for inst in zoo_nodes:
                    if inst.state not in ["shutting-down", "terminated"]:
                        inst.stop()
    
    elif action == "start":
        (master_nodes, slave_nodes, zoo_nodes) = get_existing_cluster(
                                                                      conn, opts, cluster_name)
        print "Starting slaves..."
        for inst in slave_nodes:
            if inst.state not in ["shutting-down", "terminated"]:
                inst.start()
        print "Starting master..."
        for inst in master_nodes:
            if inst.state not in ["shutting-down", "terminated"]:
                inst.start()
        if zoo_nodes != []:
            print "Starting zoo..."
            for inst in zoo_nodes:
                if inst.state not in ["shutting-down", "terminated"]:
                    inst.start()
        wait_for_cluster(conn, opts.wait, master_nodes, slave_nodes, zoo_nodes)
        setup_cluster(conn, master_nodes, slave_nodes, zoo_nodes, opts, cluster_name, False)

    elif action == "tag-machines":
        tagging(conn, opts, cluster_name)

    elif action == "setup":
        (master_nodes, slave_nodes, zoo_nodes) = get_existing_cluster(conn, opts, cluster_name)
        setup_cluster(conn, master_nodes, slave_nodes, zoo_nodes, opts, cluster_name, True)
        print "setup is done"

    elif action == "initialize":
        (master_nodes, slave_nodes, zoo_nodes) = get_existing_cluster(conn, opts, cluster_name)
        ssh(master_nodes[0].public_dns_name, opts, '. ~/benchmark/init-all.sh')
        print "initialization is done"

    elif action == "benchmark":
        (master_nodes, slave_nodes, zoo_nodes) = get_existing_cluster(conn, opts, cluster_name)
        print "\n\n[1] Load data files by executing ~/benchmark/datasets/load-files.sh on the master.\n[2] Run all benchmarks by executing ~/benchmark/bench-all.sh on the master.\n\n"
        ssh(master_nodes[0].public_dns_name, opts, '. ~/benchmark/datasets/load-files.sh;. ~/benchmark/bench-all.sh')
        print "running benchmark is done"

## TODO: commands to get results
    elif action == "results":
        (master_nodes, slave_nodes, zoo_nodes) = get_existing_cluster(conn, opts, cluster_name)
        ssh(master_nodes[0].public_dns_name, opts, '')
        print "retrieving results is done"


    elif action == "run-all":
        print "###############################################################\n###############################################################\n"
        print "      Running a Graph Processing benchmark\n"
        print "###############################################################\n"
        print " [1] launch cluster instances\n"
        (master_nodes, slave_nodes, zoo_nodes) = launch_cluster(conn, opts, cluster_name)
        wait_for_cluster(conn, opts.wait, master_nodes, slave_nodes, zoo_nodes)
        print "###############################################################\n"
        print " [2] setup cluster\n"
        setup_cluster(conn, master_nodes, slave_nodes, zoo_nodes, opts, cluster_name, True)
        print "###############################################################\n"
        print " [3] Tag cluster machines\n"
        tagging(conn, opts, cluster_name)
        print "###############################################################\n"
        print " [4] Benchmark initialization by executing ~/benchmark/init-all.sh on the master\n"
        ssh(master_nodes[0].public_dns_name, opts, '. ~/benchmark/init-all.sh')
        print "###############################################################\n"
        print " [5] Load data files by executing ~/benchmark/datasets/load-files.sh on the master.\n"
        ssh(master_nodes[0].public_dns_name, opts, '. ~/benchmark/datasets/load-files.sh')
        print "###############################################################\n"
        print " [6] Run all benchmarks by executing ~/benchmark/bench-all.sh on the master.\n"
        ssh(master_nodes[0].public_dns_name, opts, '. ~/benchmark/bench-all.sh')
        print "###############################################################\n"
        print " [6] Run all benchmarks by executing ~/benchmark/bench-all.sh on the master.\n"
        print "Start Collecting results"
        ssh(master_nodes[0].public_dns_name, opts, '')
        print "###############################################################\n###############################################################\n"
        print "      Congratulations Benchmark is done!\n"
        print "###############################################################\n"




    else:
        print >> stderr, "Invalid action: %s" % action
        sys.exit(1)


if __name__ == "__main__":
    logging.basicConfig()
    main()

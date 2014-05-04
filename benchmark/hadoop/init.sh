#!/bin/bash -e

# Initiate Hadoop by preparing the necessary config files
# and copying them to all worker machines.
#
# To change the max JVM heap size for Hadoop mappers
# (which will only affect Giraph), see ./get-configs.sh.
#
# NOTE: if testing on a single machine (i.e., pseudo-distributed),
# slaves will have to be edited manually.

commondir=$(dirname "${BASH_SOURCE[0]}")/../common
source "$commondir"/get-hosts.sh
source "$commondir"/get-dirs.sh
source "$commondir"/get-configs.sh

cd "$HADOOP_DIR/conf/"


# masters and slaves
echo "${HOSTNAME}" > masters

rm -f slaves
for ((i = 1; i <= ${NUM_MACHINES}; i++)); do
    echo "${CLUSTER_NAME}${i}" >> slaves
done


# core-site.xml
echo "<?xml version=\"1.0\"?>
<?xml-stylesheet type=\"text/xsl\" href=\"configuration.xsl\"?>

<!-- Put site-specific property overrides in this file. -->

<configuration>
  <property>
    <name>hadoop.tmp.dir</name>
    <value>${HADOOP_DATA_DIR}/hadoop_tmp-\${user.name}</value>
  </property>
  <property>
    <name>fs.default.name</name>
    <value>hdfs://${HOSTNAME}:54310</value>
  </property>
  <property>
    <name>fs.checkpoint.edits.dir</name>
    <value>${HADOOP_DATA_DIR}/hadoop_checkpoint-\${user.name}</value>
  </property>
</configuration>" > core-site.xml


# hdfs-site.xml (not really needed, but here it is)
echo '<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<!-- Put site-specific property overrides in this file. -->
<configuration>
  <property>
    <name>dfs.replication</name>
    <value>1</value>
  </property>
  <property>
    <name>dfs.permissions</name>
    <value>false</value>
  </property>
</configuration>' > hdfs-site.xml


# mapred-site.xml
echo "<?xml version=\"1.0\"?>
<?xml-stylesheet type=\"text/xsl\" href=\"configuration.xsl\"?>

<!-- Put site-specific property overrides in this file. -->

<configuration>
  <property>
    <name>mapred.job.tracker</name>
    <value>${HOSTNAME}:54311</value>
  </property>
  <property>
    <name>mapred.local.dir</name>
    <value>${HADOOP_DATA_DIR}/hadoop_local-\${user.name}</value>
  </property>
  <property>
    <name>mapred.child.tmp</name>
    <value>${HADOOP_DATA_DIR}/hadoop_child-\${user.name}</value>
  </property>
  <property>
    <name>mapred.job.tracker.persist.jobstatus.dir</name>
    <value>/home/${USER}/hadoop_jobstatus-\${user.name}</value>
  </property>
  <property>
    <name>mapred.tasktracker.map.tasks.maximum</name>
    <value>5</value>
  </property>
  <property>
    <name>mapred.tasktracker.reduce.tasks.maximum</name>
    <value>5</value>
  </property>
  <property>
    <name>mapred.map.tasks</name>
    <value>5</value>
  </property>
  <property>
    <name>mapred.reduce.tasks</name>
    <value>10</value>    <!-- determines # of reduce tasks for premizan (modhash + 5a/5b) -->
  </property>
  <property>
    <name>mapreduce.job.counters.max</name>
    <value>1000000</value>
  </property>
  <property>
    <name>mapreduce.job.counters.limit</name>
    <value>1000000</value>
  </property>
  <property>
    <name>mapred.child.java.opts</name>
    <value>-Xmx${GIRAPH_XMX}</value>
  </property>
</configuration>" > mapred-site.xml


# copy configs to worker machines
for ((i = 1; i <= ${NUM_MACHINES}; i++)); do
    rsync -avz ./* ${CLUSTER_NAME}${i}:"$HADOOP_DIR"/conf/ &
done
wait
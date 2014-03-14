#!/bin/bash -e

echo "This will replace core-site.xml and mapred-site.xml!!"
read -p "Enter to continue..." none

hostname=$(hostname)

case ${hostname} in
    "cloud0") name=cloud; nodes=4;;
    "cld0") name=cld; nodes=8;;
    "c0") name=c; nodes=16;;
    "cx0") name=cx; nodes=32;;
    "cy0") name=cy; nodes=64;;
    "cz0") name=cz; nodes=128;;
    *) echo "Invalid hostname"; exit -1;;
esac

cd ~/hadoop-1.0.4/conf/

# masters and slaves
rm -f masters
rm -f slaves

echo "$hostname" > masters

for ((i = 1; i <= ${nodes}; i++)); do
    echo "${name}${i}" >> slaves
done

# core-site.xml
echo '<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<!-- Put site-specific property overrides in this file. -->

<configuration>
  <property>
    <name>hadoop.tmp.dir</name>
    <value>/home/ubuntu/hadoop_data/hadoop_tmp-${user.name}</value>
  </property>
  <property>
    <name>fs.default.name</name>' > core-site.xml
# hack to expand ${hostname} but not ${user.name}
echo "    <value>hdfs://${hostname}:54310</value>" >> core-site.xml
echo '  </property>
  <property>
    <name>fs.checkpoint.edits.dir</name>
    <value>/home/ubuntu/hadoop_data/hadoop_checkpoint-${user.name}</value>
  </property>
</configuration>' >> core-site.xml

# mapred-site.xml
echo '<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<!-- Put site-specific property overrides in this file. -->

<configuration>
  <property>
    <name>mapred.job.tracker</name>' > mapred-site.xml
echo "    <value>${hostname}:54311</value>" >> mapred-site.xml
echo '  </property>
  <property>
    <name>mapred.local.dir</name>
    <value>/home/ubuntu/hadoop_data/hadoop_local-${user.name}</value>
  </property>
  <property>
    <name>mapred.child.tmp</name>
    <value>/home/ubuntu/hadoop_data/hadoop_child-${user.name}</value>
  </property>
  <property>
    <name>mapred.job.tracker.persist.jobstatus.dir</name>
    <value>/home/ubuntu/hadoop_jobstatus-${user.name}</value>
  </property>
  <property>
    <name>mapred.tasktracker.map.tasks.maximum</name>
    <value>10</value>
  </property>
  <property>
    <name>mapred.tasktracker.reduce.tasks.maximum</name>
    <value>10</value>
  </property>
  <property>
    <name>mapred.map.tasks</name>
    <value>5</value>
  </property>
  <property>
    <name>mapred.reduce.tasks</name>
    <value>5</value>
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
    <value>-Xmx7300m</value>
  </property>
</configuration>' >> mapred-site.xml
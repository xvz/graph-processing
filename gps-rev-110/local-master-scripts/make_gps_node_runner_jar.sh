cd .. 
GPS_DIR="`pwd`"
GPS_SRC_DIR=${GPS_DIR}/src
GPS_CLASSES_DIR=${GPS_DIR}/classes
LIBS_DIR=${GPS_DIR}/libs

echo "removing ${GPS_DIR}/gps_node_runner.jar"
rm ${GPS_DIR}/gps_node_runner.jar

echo "removing ${GPS_CLASSES_DIR}"
rm -rf ${GPS_CLASSES_DIR}

echo "making ${GPS_CLASSES_DIR}"
mkdir ${GPS_CLASSES_DIR}

echo "cding into ${GPS_SRC_DIR}"
cd ${GPS_SRC_DIR}

find java/gps/examples -name \*.java -print > file.list
$GPS_SRC_DIR/java/gps/node/GPSNodeRunner.java >> file.list
echo "compiling GPSNodeRunner to classes directory"
#javac -verbose \
javac \
-cp $LIBS_DIR/asm-3.3.1.jar:$LIBS_DIR/guava-r08.jar:$LIBS_DIR/objenesis-1.2.jar:$LIBS_DIR/cglib-2.2.jar:$LIBS_DIR/commons-cli-1.2.jar:$LIBS_DIR/jline-0.9.94.jar:$LIBS_DIR/log4j-1.2.15.jar:$LIBS_DIR/commons-logging-1.1.1.jar:$LIBS_DIR/hadoop-core-1.0.4.jar:$LIBS_DIR/commons-collections-3.2.1.jar:$LIBS_DIR/commons-lang-2.4.jar:$LIBS_DIR/commons-configuration-1.6.jar:$LIBS_DIR/tools.jar:$LIBS_DIR/mina-core-2.0.3.jar:$LIBS_DIR/mina-example-2.0.3.jar:$LIBS_DIR/slf4j-api-1.6.1.jar:$LIBS_DIR/colt.jar:$LIBS_DIR/concurrent.jar:$GPS_SRC_DIR/java \
-d ${GPS_CLASSES_DIR} \
@file.list

echo "cding into ${GPS_CLASSES_DIR}"
cd ${GPS_CLASSES_DIR}
pwd
echo "making gps_node_runner.jar..."
#jar -cmvf $GPS_DIR/local-master-scripts/manifest.txt ../gps_node_runner.jar gps/
jar -cmf $GPS_DIR/local-master-scripts/manifest.txt ../gps_node_runner.jar gps/
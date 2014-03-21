//============================================================================
// Name        : Mizan.cpp
// Author      : Zuhair Khayyat
// Version     :
// Copyright   : Your copyright notice
// Description : Hello World in C++, Ansi-style
//============================================================================

#define Verbose 1

#include "Mizan.h"
#include "Mizan.cpp"
#include "dataManager/dataManager.h"

#include "unistd.h"
#include <stdio.h>
#include <stdlib.h>
#include "unitTest.h"
#include "algorithms/dimEst.h"
#include "algorithms/pageRank.h"
#include "algorithms/pageRankTopK.h"
#include "algorithms/AdSim.h"
#include "algorithms/SSSP.h"
#include "algorithms/WCC.h"
#include "algorithms/MST.h"
#include "tools/argParser.h"
#include "algorithms/maxAggregator.h"
#include "general.h"

using namespace std;

int main(int argc, char** argv) {

  argParser argp;
  MizanArgs myArgs = argp.parse(argc, argv);

  char ** inputBaseFile = argp.setInputPaths(myArgs.fs, myArgs.clusterSize,
                                             myArgs.graphName, myArgs.hdfsUserName, myArgs.partition);

#ifdef Verbose
  time_t begin_time = time(NULL);
#endif

  bool groupVoteToHalt;
  edgeStorage storageType;
  distType partType;

  int myWorkerID;

  if (myArgs.algorithm == 1) {
    groupVoteToHalt = false;      // vertices should wake from incoming messages
    storageType = OutNbrStore;
    pageRank us(myArgs.superSteps);
    pageRankCombiner prc;

    Mizan<mLong, mDouble, mDouble, mLong> * mmk =
      new Mizan<mLong, mDouble, mDouble, mLong>(myArgs.communication, &us, storageType,
                                                inputBaseFile, myArgs.clusterSize,
                                                myArgs.fs, myArgs.migration);

    mmk->registerMessageCombiner(&prc);

    mmk->setVoteToHalt(groupVoteToHalt);

    string output;
    output.append("/user/");
    output.append(myArgs.hdfsUserName.c_str());
    output.append("/mizan-output/");
    //output.append(myArgs.graphName.c_str());
    mmk->setOutputPath(output.c_str());

    //User Defined aggregator
    //char * maxAgg = "maxAggregator";
    //maxAggregator maxi;
    //mmk->registerAggregator(maxAgg, &maxi);

    mmk->run(argc, argv);
    myWorkerID = mmk->getPEID();
    delete mmk;

  } else if (myArgs.algorithm == 2) {
    groupVoteToHalt = false;
    storageType = OutNbrStore;
    pageRankTopK prt(5, 10, myArgs.superSteps);

    Mizan<mLong, mDoubleArray, mDouble, mLong> * mmk =
      new Mizan<mLong, mDoubleArray, mDouble, mLong>(myArgs.communication, &prt, storageType,
                                                     inputBaseFile, myArgs.clusterSize,
                                                     myArgs.fs, myArgs.migration);
    mmk->setVoteToHalt(groupVoteToHalt);

    mmk->run(argc, argv);
    myWorkerID = mmk->getPEID();
    delete mmk;

  } else if (myArgs.algorithm == 3) {
    groupVoteToHalt = false;     // vertices need to wake up on incoming messages
    storageType = OutNbrStore;   // to match Giraph and GPS
    dimEst dE(myArgs.superSteps);

    Mizan<mLong, mLongArray, mLongArray, mLong> * mmk =
      new Mizan<mLong, mLongArray, mLongArray, mLong>(myArgs.communication, &dE, storageType,
                                                      inputBaseFile, myArgs.clusterSize,
                                                      myArgs.fs, myArgs.migration);

    string output;
    output.append("/user/");
    output.append(myArgs.hdfsUserName.c_str());
    output.append("/mizan-output/");
    //output.append(myArgs.graphName.c_str());
    mmk->setOutputPath(output.c_str());

    mmk->setVoteToHalt(groupVoteToHalt);

    mmk->run(argc, argv);
    myWorkerID = mmk->getPEID();
    delete mmk;

  } else if (myArgs.algorithm == 4) {
    groupVoteToHalt = false;
    storageType = InOutNbrStore;
    AdSim alg(myArgs.superSteps);

    Mizan<mLong, mLong, mLongArray, mLong> * mmk =
      new Mizan<mLong, mLong, mLongArray, mLong>(myArgs.communication, &alg, storageType,
                                                 inputBaseFile, myArgs.clusterSize,
                                                 myArgs.fs, myArgs.migration);
    mmk->setVoteToHalt(groupVoteToHalt);

    mmk->run(argc, argv);
    myWorkerID = mmk->getPEID();
    delete mmk;

  } else if (myArgs.algorithm == 5) {
    // NOTE: this should be FALSE so halted vertices wake on incoming message
    groupVoteToHalt = false;
    storageType = OutNbrStore;       // only store outgoing edge values

    SSSP sssp(mLong(myArgs.srcID), myArgs.superSteps);

    Mizan<mLong, mLong, mLong, mLong> * mmk =
      new Mizan<mLong, mLong, mLong, mLong>(myArgs.communication, &sssp, storageType,
                                            inputBaseFile, myArgs.clusterSize,
                                            myArgs.fs, myArgs.migration);

    // use combiner for better network efficiency
    SSSPCombiner ssspc;
    mmk->registerMessageCombiner(&ssspc);

    string output;
    output.append("/user/");
    output.append(myArgs.hdfsUserName.c_str());
    output.append("/mizan-output/");
    //output.append(myArgs.graphName.c_str());
    mmk->setOutputPath(output.c_str());

    mmk->setVoteToHalt(groupVoteToHalt);

    mmk->run(argc, argv);
    myWorkerID = mmk->getPEID();
    delete mmk;

  } else if (myArgs.algorithm == 6) {
    // NOTE: this should be FALSE so halted vertices wake on incoming message
    groupVoteToHalt = false;
    storageType = OutNbrStore;       // only store outgoing edge values

    WCC wcc(myArgs.superSteps);

    Mizan<mLong, mLong, mLong, mLong> * mmk =
      new Mizan<mLong, mLong, mLong, mLong>(myArgs.communication, &wcc, storageType,
                                            inputBaseFile, myArgs.clusterSize,
                                            myArgs.fs, myArgs.migration);

    // use combiner for better network efficiency
    WCCCombiner wccc;
    mmk->registerMessageCombiner(&wccc);

    string output;
    output.append("/user/");
    output.append(myArgs.hdfsUserName.c_str());
    output.append("/mizan-output/");
    //output.append(myArgs.graphName.c_str());
    mmk->setOutputPath(output.c_str());

    mmk->setVoteToHalt(groupVoteToHalt);

    mmk->run(argc, argv);
    myWorkerID = mmk->getPEID();
    delete mmk;

  } else if (myArgs.algorithm == 7) {
    groupVoteToHalt = false;
    storageType = OutNbrStore;

    MST mst(myArgs.superSteps);

    Mizan<mLong, mMSTVertexValue, mLongArray, mLong> * mmk =
      new Mizan<mLong, mMSTVertexValue, mLongArray, mLong>(myArgs.communication, &mst, storageType,
                                                           inputBaseFile, myArgs.clusterSize,
                                                           myArgs.fs, myArgs.migration);

    // aggregator needed for superbarriers
    // included from MST header
    char* counterAgg_name = "counter";
    sumAggregator counterAgg;
    mmk->registerAggregator(counterAgg_name, &counterAgg);

    char* supervertexAgg_name = "supervertex";
    sumAggregator supervertexAgg;
    mmk->registerAggregator(supervertexAgg_name, &supervertexAgg);

    string output;
    output.append("/user/");
    output.append(myArgs.hdfsUserName.c_str());
    output.append("/mizan-output/");
    //output.append(myArgs.graphName.c_str());
    mmk->setOutputPath(output.c_str());

    mmk->setVoteToHalt(groupVoteToHalt);

    mmk->run(argc, argv);
    myWorkerID = mmk->getPEID();
    delete mmk;
  }

#ifdef Verbose
  if (myWorkerID == 0) {
    std::cout << "-----TIME: Total Running Time = "
              << float(time(NULL) - begin_time) << std::endl;
  }
#endif

  if (myWorkerID == 0) {
    cout << "!!!bye bye -- terminating Mizan, see you later!!!" << endl;
  }

  return 0;
}

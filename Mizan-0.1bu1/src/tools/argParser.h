/*
 * argParser.h
 *
 *  Created on: Mar 9, 2013
 *      Author: refops
 */

#ifndef ARGPARSER_H_
#define ARGPARSER_H_

#include <boost/program_options.hpp>
#include "../general.h"

#include <iostream>
#include <string>

class argParser {
public:
  argParser() {
  }

  virtual ~argParser() {
  }

  MizanArgs parse(int argc, char** argv) {
    const size_t ERROR_IN_COMMAND_LINE = 1;
    const size_t SUCCESS = 0;
    const size_t ERROR_UNHANDLED_EXCEPTION = 2;
    const size_t EXIT = 3;

    MizanArgs args;
    //default args
    args.algorithm = 1;
    args.fs = HDFS;
    args.partition = hashed;
    args.migration = NONE;
    args.communication = _pt2ptb;
    args.superSteps = 20;
    //args.errTol = 0.01;
    args.srcID = 0;

    int partition = -1;
    int fileSystem = -1;
    int migration = -1;
    char * graphName;
    char * hdfsUserName;


    boost::program_options::options_description desc("Options");

    desc.add_options()
      ("help,h", "Print help messages")
      ("algorithm,a", boost::program_options::value<int>(&args.algorithm),
       "Algorithm ID:\n"
       "  1) PageRank (default)\n"
       "  2) TopK PageRank\n"
       "  3) Diameter Estimation\n"
       "  4) Ad Simulation\n"
       "  5) Single Source Shortest Path"
       "  6) Weakly Connected Components"
       "  7) Minimum Spanning Tree")
      ("supersteps,s", boost::program_options::value<int>(&args.superSteps),
       "Max number of supersteps")
      //("tol", boost::program_options::value<double>(&args.errTol),
      // "Error tolerance threshold, for PageRank")
      ("src", boost::program_options::value<long>(&args.srcID),
       "Source vertex ID, for SSSP")
      ("workers,w", boost::program_options::value<int>(&args.clusterSize)->required(),
       "Number of Workers/Partitions")
      ("graph,g",boost::program_options::value<string>()->required(),
       "Input Graph Name")
      ("fs",boost::program_options::value<int>(&fileSystem),
       "Input File system:\n"
       "  1) HDFS (default)\n"
       "  2) Local disk")
      ("partition,p", boost::program_options::value<int>(&partition),
       "Partitioning Type:\n"
       "  1) Hash (default)\n"
       "  2) range")
      ("user,u", boost::program_options::value<string>(),
       "Linux user name, required in case of\n using option (-fs 1)")
      ("migration,m", boost::program_options::value<int>(&migration),
       "(Advanced Option) Dynamic load balancing type:\n"
       "  1) none (default)\n"
       "  2) Delayed Migration\n"
       "  3) Mix Migration Mode\n"
       "  4) Pregel Work Stealing");

    boost::program_options::variables_map vm;
    try {
      boost::program_options::store(boost::program_options::parse_command_line(argc, argv, desc), vm); // can throw

      //cout << "args.hdfsUserName = " << args.hdfsUserName << std::endl;
      //cout << "args.graphName = " << args.graphName << std::endl;

      if (vm.count("help")) {
        std::cout << "Basic Command Line Parameter App" << std::endl
                  << desc << std::endl;
        exit(-1);
      }
      if (vm.count("user")) {
        args.hdfsUserName.append(vm["user"].as<std::string>());
      }
      if (vm.count("graph")) {
        args.graphName.append(vm["graph"].as<std::string>());
      }
      if (vm.count("partition")) {
        if (partition == 1) {
          args.partition = hashed;
        } else if (partition == 2) {
          args.partition = range;
        }
      }
      if (vm.count("fs")) {
        if (fileSystem == 1) {
          args.fs = HDFS;
        } else if (fileSystem == 2) {
          args.fs = OS_DISK_ALL;
        }
      }
      if (vm.count("migration")) {
        migration = (vm["migration"].as<int>());
        if (migration == 1) {
          args.migration = NONE;
        } else if (migration == 2) {
          args.migration = DelayMigrationOnly;
        } else if (migration == 3) {
          args.migration = MixMigration;
        } else if (migration == 4) {
          args.migration = PregelWorkStealing;
        }
      }
      if (args.fs == HDFS && args.hdfsUserName.length() == 0) {
        std::cerr
          << "ERROR: You have to specify the linux current user by using (-u username)."
          << std::endl;
        exit(-1);
      }

      boost::program_options::notify(vm);
    } catch (boost::program_options::error& e) {
      std::cerr << "ERROR: " << e.what() << std::endl << std::endl;
      std::cerr << desc << std::endl;
      exit(-1);
    }
    return args;
  }

  char ** setInputPaths(fileSystem diskType, int pCount, string fileName,
                        string userName, distType partition) {
    char ** inputBaseFile = (char **) calloc(pCount, sizeof(char *));

    if (diskType == HDFS) {
      char head[] = "/user/";
      char mid[] = "/m_output/mizan_";
      char tail[] = "/part-r-";

      char buffer[10];
      sprintf(buffer, "%d", pCount);

      int size = strlen(head) + strlen(mid) + strlen(tail) + 100;
      for (int i = 0; i < pCount; i++) {

        inputBaseFile[i] = (char *) calloc(size, sizeof(char));
        strcat(inputBaseFile[i], head);
        strcat(inputBaseFile[i], userName.c_str());
        strcat(inputBaseFile[i], mid);
        strcat(inputBaseFile[i], fileName.c_str());
        if (partition == hashed) {
          strcat(inputBaseFile[i], "_mhash_");
        } else if (partition == minCuts) {
          strcat(inputBaseFile[i], "_minc_");
        } else if (partition == range) {
          strcat(inputBaseFile[i], "_mrange_");
        }
        strcat(inputBaseFile[i], buffer);
        strcat(inputBaseFile[i], tail);
        char buffer2[10];
        if (i < 10) {
          sprintf(buffer2, "0000%d", i);
        } else if (i < 100) {
          sprintf(buffer2, "000%d", i);
        } else if (i < 1000) {
          sprintf(buffer2, "00%d", i);
        } else if (i < 10000) {
          sprintf(buffer2, "0%d", i);
        } else {
          sprintf(buffer2, "%d", i);
        }
        strcat(inputBaseFile[i], buffer2);
      }
    } else if (diskType == OS_DISK_ALL) {
      char mid[] = "mizan_";
      char tail[] = "/part-r-";

      char buffer[10];
      sprintf(buffer, "%d", pCount);

      int size = strlen(mid) + strlen(tail) + 100;
      for (int i = 0; i < pCount; i++) {

        inputBaseFile[i] = (char *) calloc(size, sizeof(char));
        strcat(inputBaseFile[i], mid);
        strcat(inputBaseFile[i], fileName.c_str());
        if (partition == hashed) {
          strcat(inputBaseFile[i], "_mhash_");
        } else if (partition == minCuts) {
          strcat(inputBaseFile[i], "_minc_");
        } else if (partition == range) {
          strcat(inputBaseFile[i], "_mrange_");
        }
        strcat(inputBaseFile[i], buffer);
        strcat(inputBaseFile[i], tail);
        char buffer2[10];
        if (i < 10) {
          sprintf(buffer2, "0000%d", i);
        } else if (i < 100) {
          sprintf(buffer2, "000%d", i);
        } else if (i < 1000) {
          sprintf(buffer2, "00%d", i);
        } else if (i < 10000) {
          sprintf(buffer2, "0%d", i);
        } else {
          sprintf(buffer2, "%d", i);
        }
        strcat(inputBaseFile[i], buffer2);
      }
    }
    return inputBaseFile;
  }
};

#endif /* ARGPARSER_H_ */

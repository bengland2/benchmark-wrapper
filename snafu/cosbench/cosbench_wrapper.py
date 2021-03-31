#!/usr/bin/env python
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
import os
import logging

from . import trigger_cosbench

logger = logging.getLogger("snafu")


class cosbench_wrapper():

    def __init__(self, parser):
        # collect arguments

        # it is assumed that the parser was created using argparse and already knows
        # about the --tool option
        parser.add_argument(
            '-s', '--samples',
            type=int,
            help='number of times to run benchmark, defaults to 1',
            default=1)
        # this directory is used both to pass input XML files and to 
        # hold output files
        # XML files determine which operation types are done
        parser.add_argument(
            '-d', '--dir',
            help='parent directory',
            default=os.path.dirname(os.getcwd()))

        self.server = ""

        self.cluster_name = "mycluster"
        if "clustername" in os.environ:
            self.cluster_name = os.environ["clustername"]

        self.uuid = ""
        if "uuid" in os.environ:
            self.uuid = os.environ["uuid"]

        self.user = ""
        if "test_user" in os.environ:
            self.user = os.environ["test_user"]

        self.redis_host = os.environ["redis_host"] if "redis_host" in os.environ else None
        self.redis_timeout = os.environ["redis_timeout"] if "redis_timeout" in os.environ else 60
        self.redis_timeout_th = os.environ["redis_timeout_th"] if "redis_timeout_th" in os.environ else 25
        self.clients = os.environ["clients"] if "clients" in os.environ else 1
        self.samples = self.args.samples
        self.result_dir = os.path.join(self.args.dir, 'results')

    def run(self):
        if not os.path.exists(self.result_dir):
            os.mkdir(self.result_dir)
        for s in range(1, self.samples + 1):
            sample_dir = self.result_dir + '/' + str(s)
            if not os.path.exists(sample_dir):
                os.mkdir(sample_dir)
            xml_list = os.path.listdir(os.path.join(self.result_dir, 'xmls'):
            for xml in xml_list:
                trigger_generator = trigger_cosbench._trigger_cosbench(logger, 
                                                                         self.cluster_name,
                                                                         sample_dir,
                                                                         self.user,
                                                                         self.uuid,
                                                                         self.clients,
                                                                         xml,
                                                                         s)
                yield trigger_generator

import time
from datetime import datetime
import os
import json
import subprocess
import socket


class COSBenchWrapperException(Exception):
    pass


class _trigger_cosbench:
    """
        Will execute with the provided arguments and return normalized results for indexing
    """

    def __init__(self, logger, cluster_name, result_dir, user, uuid, clients, xmlfile, sample):
        self.logger = logger
        self.xmlfile = xmlfile
        self.result_dir = result_dir
        self.user = user
        self.uuid = uuid
        self.sample = sample
        self.cluster_name = cluster_name
        self.clients = int(clients)
        self.host = socket.gethostname()

    def ensure_dir_exists(self, directory):
        if not os.path.exists(directory):
            os.mkdir(directory)

    def emit_actions(self):
        """
        Executes test and calls document parsers, if index_data is true will yield normalized data
        """

        rsptime_dir = os.path.join(self.result_dir, 'rsptime')

        # clear out any unconsumed response time files in this directory
        if os.path.exists(rsptime_dir):
            contents = os.listdir(rsptime_dir)
            for c in contents:
                if c.endswith('.csv'):
                    os.unlink(os.path.join(rsptime_dir, c))

        # only do 1 operation at a time in emit_actions
        # so that cache dropping works right

        before = datetime.now()
        cmd = ["run_cosbench.sh",
               "--xml", self.xml,
               "--output_dir", self.result_dir]
        self.logger.info('running:' + ' '.join(cmd))
        self.logger.info('from current directory %s' % os.getcwd())
        try:
            process = subprocess.check_call(cmd, stderr=subprocess.STDOUT)
        except subprocess.CalledProcessError as e:
            self.logger.exception(e)
            raise COSBenchWrapperException(
                'run_cosbench.sh non-zero process return code %d' % e.returncode)
        self.logger.info("completed sample {} for operation {} , results in {}".format(
            self.sample, self.xmlfile, self.result_dir ))

        # FIXME: what format will output data be?
        # see github.com/jharriga/CBTools for example

        thrd = {}
        thrd['cluster_name'] = self.cluster_name
        thrd['uuid'] = self.uuid
        thrd['user'] = self.user
        thrd['sample'] = self.sample
        thrd['xml'] = self.xmlfile
        thrd['host'] = self.host
        thrd['date'] = time.time()
        yield thrd, 'results'


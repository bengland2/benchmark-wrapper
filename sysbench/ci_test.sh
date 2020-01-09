#!/bin/bash

set -x

source ci/common.sh

update_benchmark_image sysbench sysbench

cd ripsaw

# Build new ripsaw image
update_operator_image sysbench roles/sysbench/templates/workload.yml

# sysbench does not utilize a wrapper from snafu, only the Dockerfile
# We will confirm that the test_sysbench passes only
bash tests/test_sysbench.sh 

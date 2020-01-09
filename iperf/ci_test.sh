#!/bin/bash

set -x

source ci/common.sh

update_benchmark_image iperf iperf3

cd ripsaw

# Build new ripsaw image
update_operator_image iperf3 "`echo roles/iperf3-bench/templates/*.yml.j2`"

# iperf does not utilize a wrapper from snafu, only the Dockerfile
# We will confirm that the test_iperf passes only
bash tests/test_iperf3.sh 

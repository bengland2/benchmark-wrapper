#!/bin/bash

set -x

source ci/common.sh

update_benchmark_image ycsb-wrapper ycsb-server

cd ripsaw

# Build new ripsaw image
update_operator_image ycsb-server roles/load-ycsb/tasks/main.yml

get_uuid test_ycsb.sh
uuid=`cat uuid`

cd ..

index="ripsaw-ycsb-summary"

check_es $uuid $index
exit $?

#!/bin/bash

set -x

source ci/common.sh

update_benchmark_image pgbench-wrapper pgbench

cd ripsaw

# Build new ripsaw image
update_operator_image pgbench roles/pgbench/defaults/main.yml

get_uuid test_pgbench.sh
uuid=`cat uuid`

cd ..

index="ripsaw-pgbench-summary"

check_es $uuid $index
exit $?

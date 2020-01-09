#!/bin/bash

set -x

source ci/common.sh

# Build image for ci

update_benchmark_image fs_drift_wrapper fs-drift

cd ripsaw

# Build new ripsaw image
update_operator_image fs-drift "`echo roles/fs-drift/{tasks/main.yml,templates/workload_job.yml.j2}`"

get_uuid test_fs_drift.sh
uuid=`cat uuid`

cd ..

index="ripsaw-fs-drift-results"

check_es $uuid $index
exit $?

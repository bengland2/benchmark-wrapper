#!/bin/bash

set -x

source ci/common.sh

update_benchmark_image smallfile_wrapper smallfile

cd ripsaw

# Build new ripsaw image
update_operator_image smallfile \
  "`echo roles/smallfile-bench/{tasks/main.yml,templates/workload_job.yml.j2}`"

get_uuid test_smallfile.sh
uuid=`cat uuid`

cd ..

index="ripsaw-smallfile-results ripsaw-smallfile-rsptimes"

check_es $uuid $index
exit $?

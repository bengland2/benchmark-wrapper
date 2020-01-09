#!/bin/bash

set -x

source ci/common.sh

update_benchmark_image hammerdb hammerdb

cd ripsaw

update_operator_image hammerdb "`echo roles/hammerdb/templates/{db_creation.yml,db_workload.yml.j2}`"

get_uuid test_hammerdb.sh
uuid=`cat uuid`

cd ..

index="ripsaw-hammerdb-results"

check_es $uuid $index
exit $?

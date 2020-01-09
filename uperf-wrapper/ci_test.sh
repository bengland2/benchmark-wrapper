#!/bin/bash

set -x

source ci/common.sh

update_benchmark_image uperf-wrapper uperf

cd ripsaw

# Build new ripsaw image
update_operator_image uperf "`echo roles/uperf-bench/templates/*.yml.j2`"

get_uuid test_uperf.sh
uuid=`cat uuid`

cd ..

index="ripsaw-uperf-results"

check_es $uuid $index
exit $?

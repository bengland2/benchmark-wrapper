#!/bin/bash

set -x

source ci/common.sh

# Build image for ci
update_benchmark_image fio_wrapper fio

cd ripsaw

# Build new ripsaw image
update_operator_image fio "`echo roles/fio-distributed/templates/*.yaml`"

get_uuid test_fiod.sh
uuid=`cat uuid`

cd ..

# Define index
index="ripsaw-fio-results ripsaw-fio-log ripsaw-fio-analyzed-result"

check_es $uuid $index
exit $?

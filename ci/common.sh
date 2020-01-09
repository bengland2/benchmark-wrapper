#!/bin/bash

es_server="marquez.perf.lab.eng.rdu2.redhat.com"
es_port=9200
image_account=${RIPSAW_CI_IMAGE_ACCOUNT:-rht_perf_ci}
if [ "$USER" != "root" ] ; then
  SUDO=sudo
fi
# we'll try podman push more than once in case of 
# intermittent network or server problem
img_try_limit=2

# process exit statuses
OK=0
NOTOK=1

# this function rebuilds the benchmark image, it takes 3 parameters:
# wrapper_dir - sub-directory where wrapper lives
# tool - image name
# tag name: defaults to "snafu_ci"

function update_benchmark_image() {
  wrapper_dir=$1
  tool=$2
  tag_name=${3:-snafu_ci}

  image_spec=quay.io/$image_account/$tool:$tag_name

  # don't trust that the CI installed the tools

  $SUDO yum install -y skopeo podman buildah

  # rebuild the image, tag it, 
  # return failure status if any of these don't work
  ($SUDO buildah build-using-dockerfile -f $wrapper_dir . 2>&1 \
         | tee /tmp/buildah-bud.$$.log && \
   image_id=`tail -n 1 /tmp/buildah-bud.$$.log` && \
   $SUDO podman tag $image_id $image_spec) \
     || exit $NOTOK
  try_count=0
  while [ $try_count -le $img_try_limit ] 
  do
    $SUDO podman push $image_spec
    s=$?
    if [ $s = $OK ] ; then
        break
    fi
    ((try_count++))
  done
  if [ $s != $OK ] ; then
    # ensure that the test fails unless push succeeds
    skopeo delete docker://$image_spec || exit $NOTOK
    echo "ERROR: Could not upload image $image_spec to repository. Exiting"
    exit $NOTOK
  fi
  skopeo inspect docker://$image_spec
}

function update_operator_image() {
  tool_name=$1
  ripsaw_files=$2
  tag_name=${3:-snafu_ci}
  image_spec="quay.io/$image_account/benchmark-operator:$tag_name"
  sed -i "s|          image: quay.io/benchmark-operator/benchmark-operator:master*|          image: quay.io/$image_account/benchmark-operator:$tag_name # |" resources/operator.yaml
  grep $image_account resources/operator.yaml || exit $NOTOK

  for f in $ripsaw_files ; do
    sed -i "s#cloud-bulldozer/${tool_name}:master#$image_account/${tool_name}:$tag_name#" $f
    sed -i "s#cloud-bulldozer/${tool_name}:latest#$image_account/${tool_name}:$tag_name#" $f
    echo "checking update to image spec in ripsaw file $f"
    grep $image_account/${tool_name}:$tag_name $f || exit $NOTOK
  done

  # ensure that test doesn't run unless container image is up to date

  $SUDO yum install -y skopeo podman buildah

  $SUDO operator-sdk build $image_spec --image-builder podman || exit $NOTOK

  # In case we have issues uploading to quay.io we will retry
  try_count=0
  while [ $try_count -lt $img_try_limit ]
  do
    $SUDO podman push $image_spec
    s=$?
    if [ $s = $OK ] ; then
        break
    fi
    ((try_count++))
  done
  if [ $s != $OK ]
  then
    skopeo delete docker://$image_spec || exit $NOTOK
    echo "ERROR Could not upload image $image_spec to repository. Exiting"
    exit $NOTOK
  fi
  skopeo inspect docker://$image_spec
}

function wait_clean {
  kubectl delete all --all -n my-ripsaw
  for i in {1..30}; do
    if [ `kubectl get pods --namespace my-ripsaw | wc -l` -ge 1 ]; then
      sleep 5
    else
      break
    fi
  done
}

# Takes 2 arguements. $1 is the uuid and $2 is a space seperated list of indexs to check
# Returns 0 if ALL indexes are found
function check_es() {
  uuid=$1
  index=${@:2}

  rc=0
  for my_index in $index
  do
    python3 ci/check_es.py -s $es_server -p $es_port -u $uuid -i $my_index || return $NOTOK
  done
}

# Takes test script as parameter and returns the uuid
function get_uuid() {
  my_test=$1
  
  sed -i '/trap finish EXIT/d' tests/$my_test

  rm -f uuid
  (
  source tests/$my_test || :

  # Get UUID
  uuid=`kubectl -n my-ripsaw get benchmarks -o jsonpath='{.items[0].status.uuid}'`

  finish
  echo $uuid > uuid
  )
}

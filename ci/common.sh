#!/bin/bash

es_server="marquez.perf.lab.eng.rdu2.redhat.com"
es_port=9200
image_account=${RIPSAW_CI_IMAGE_ACCOUNT:-rht_perf_ci}
if [ "$USER" != "root" ] ; then
  SUDO=sudo
fi

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

  # make sure the pre-existing image is removed.  That way,
  # if the image update fails and somehow isn't reflected in status code,
  # CI test will still fail

  skopeo inspect docker://$image_spec
  if [ $? = $OK ] ; then 
    skopeo delete docker://$image_spec || exit $NOTOK
  fi

  # rebuild the image, tag it and push it, 
  # return failure status if any of these don't work
  ($SUDO buildah build-using-dockerfile -f $wrapper_dir . 2>&1 | tee /tmp/buildah-bud.$$.log && \
   image_id=`tail -n 1 /tmp/buildah-bud.$$.log` && \
   $SUDO podman tag $image_id $image_spec && \
   $SUDO podman push $image_spec) \
       || exit $NOTOK
}

function update_operator_image() {
  tag_name=$1
  sed -i "s|          image: quay.io/benchmark-operator/benchmark-operator:master*|          image:
  quay.io/$image_account/benchmark-operator:$tag_name # |" resources/operator.yaml
  $SUDO operator-sdk build quay.io/$image_account/benchmark-operator:$tag_name --image-builder podman || \
    exit $NOTOK

  # In case we have issues uploading to quay we will retry a few times
  try_count=0
  while [ $try_count -le 2 ]
  do
    $SUDO podman push quay.io/$image_account/benchmark-operator:$tag_name
    s=$?
    if [ $s = $OK ] ; then
        break
    fi
    ((try_count++))
  done
  if [ $try_count -gt 2 -a $s != $OK ]
  then
    echo "Could not upload image to repository. Exiting"
    exit $NOTOK
  fi
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

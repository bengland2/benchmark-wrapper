
# COSBench
[COSBench](https://github.com/intel-cloud/cosbench) is a distributed object-storage workload generator that uses either S3 or Swift
object storage REST APIs.

## workload overview

This page discusses specifics of running COSBench inside benchmark-wrapper (and benchmark-operator).   

The Dockerfile builds the container image, and the rest of the wrapper invokes COSBench tests and parses the resulting data
into a form that can be ingested into Elastic Search. 

Since COSBench has a "controller" that orchestrates each test, we don't use redis to synchronize the start of the drivers.


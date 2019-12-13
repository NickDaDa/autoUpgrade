#!/bin/bash

# import config file
. ./config.bash

# add create configmap script here
kubectl create configmap $CONFIGMAP --from-file=../yaml/conf/
#echo "this is a init configmap script"

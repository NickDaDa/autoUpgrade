#!/bin/bash
OBJA="nginx-a"
OBJB="nginx-b"
TYPE="sts"

# value is equivalent to configmap.bash's name  & *.yaml mounted name
CONFIGMAP="cm-test"

# check pod if is ready timeout
TIMEOUT="60s"

readonly OBJA OBJB TYPE CONFIGMAP TIMEOUT

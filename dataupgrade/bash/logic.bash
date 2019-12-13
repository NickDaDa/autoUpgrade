#!/bin/bash

# import config file
. ./config.bash

# mounted yaml base path
YAML_BASE_PATH="/home/yaml/"

# store to create and delete pods name
TODELETE=""
TOCREATE=""

# if A is existed
EXISTED=$(kubectl get "$TYPE" | grep "$OBJA")
if [ -n "$EXISTED" ]
then 
  echo "$TYPE/$OBJA is existed, create $OBJB, delete $OBJA"
  TODELETE="$OBJA"
  TOCREATE="$OBJB"
else
  echo "$TYPE/$OBJA is not existed, create $OBJA, delete $OBJB"
  TODELETE="$OBJB"
  TOCREATE="$OBJA"
fi

#echo "TODELETE : $TODELETE , TOCREATE : $TOCREATE"

# create
# create configmap
if [ -z "$(kubectl get configmap | grep $CONFIGMAP)" ]
  then
    ./configmap.bash
  else
    echo "configmap is existed, no need to recreate."  
  fi

# create main object
kubectl create -f "$YAML_BASE_PATH$TOCREATE/$TOCREATE.yaml"
#echo "$YAML_BASE_PATH$TOCREATE/$TOCREATE.yaml is created"

# create success flag, 1 is success; 0 is failed
CREATEREADY=1

# get max pod count
MAXPODNUM=`kubectl get sts | grep $TOCREATE | awk {'print $2'} | cut -d '/' -f 2`
if [ -z "$MAXPODNUM" ]
then
  MAXPODNUM="0"
fi

PODNUMINDEX="0"
echo MAXPODNUM=${MAXPODNUM}  PODNUMINDEX=${PODNUMINDEX}
while [ "${PODNUMINDEX}" -lt "${MAXPODNUM}" ]; do
  READYSTR=$(kubectl wait --for=condition=ready pod/$TOCREATE-$PODNUMINDEX --timeout=$TIMEOUT | grep 'condition met')
  PODNUMINDEX=`expr $PODNUMINDEX + 1`
  if [ -z "$READYSTR" ]
  then 
    CREATEREADY=0
    break
  fi  
done

echo create ready status is ${CREATEREADY}

# if create is succeed, reclaim resource, otherwise output error info
if [ "${CREATEREADY}" = "1" ]
then
    # TODELETE is exist?
    NEEDRECLAIM=$(kubectl get "${TYPE}" | grep "${TODELETE}")
    if [ -n "${NEEDRECLAIM}" ]
    then
      echo "need reclaim, $TYPE/$TODELETE is exist."
      # find binded pvc&pv
      PVARR=()
      PVCARR=()
      PVI=0
      PVCS=$(kubectl get pvc | grep Bound | awk {'print $1'})
      for pvc in $PVCS; do 
        MOUNTEDBY=$(kubectl describe pvc $pvc | grep "Mounted By" | awk {'print $3'} |sed 's/^\([^0-9]*\).*/\1/g')
        #echo $MOUNTEDBY
        if [ "$TODELETE-" = "$MOUNTEDBY" ]
        then
          #echo "matched."
          PVNAME=$(kubectl describe pvc $pvc | grep "Volume:" | awk {'print $2'})
          # push into array
          PVARR[${PVI}]=$PVNAME
          PVCARR[${PVI}]=$pvc
          PVI=`expr $PVI+1`
        fi   
      done
      #echo ${PVARR[*]}
      
      # delete main object
      kubectl delete -f "$YAML_BASE_PATH$TODELETE/$TODELETE.yaml"
      #echo "main object $TODELETE is deleted."
      
      # delete configmap if is exist
      # if [ -n "$CONFIGMAP" ]
      # then
        # kubectl delete configmap $CONFIGMAP
      # else
        # echo "no configmap configured in config.bash."  
      # fi
      
      # reclaim: delete binded pvc&pv
      for pvc in $PVCARR; do
        kubectl delete pvc $pvc
        #echo "$TOCREATE dependent pvc $pvc is deleted."
      done
      for pv in $PVARR; do
        kubectl delete pv $pv
        #echo "$TOCREATE dependent pv $pv is deleted."
      done
    else
      echo "$TYPE/$TODELETE is not exist. skip reclaim."
    fi
else
    echo "$YAML_BASE_PATH$TOCREATE/$TOCREATE.yaml create failed."
fi 

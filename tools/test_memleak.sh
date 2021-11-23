#!/bin/bash
let counter=0
oc apply -f config/minimal-keyretrieve
while true;
do
  echo "======================  $counter =================="
  oc -n nbde describe tangservers.daemons.redhat.com
  ./tools/api_tools/key_rotate.sh -n nbde
  sleep 10
  oc -n nbde describe tangservers.daemons.redhat.com
  oc apply -f config/minimal-keyretrieve-deletehiddenkeys
  sleep 5
  oc -n nbde describe tangservers.daemons.redhat.com
  echo "====================== /$counter =================="
  sleep 5
  let counter=$counter+1
done
echo

#!/bin/bash -e

namespace=""

usage() {
  echo
  echo "Usage:"
  echo
  echo "$1 -n namespace [-c k8s_client]"
  echo
  exit "$2"
}

while getopts "n:c:h" arg
do
case "${arg}" in
  n) namespace=${OPTARG}
  ;;
  c) oc_client=${OPTARG}
  ;;
  h) usage "$0" 0
  ;;
  *) usage "$0" 1
  ;;
esac
done

test -z "${namespace}" && namespace="default"
test -z "${oc_client}" && oc_client="oc"

sha1_1=$("${oc_client}" -n nbde get tangservers.daemons.redhat.com  -o json | jq '.items[0].status.activeKeys[0].sha1')
sha1_2=$("${oc_client}" -n nbde get tangservers.daemons.redhat.com  -o json | jq '.items[0].status.activeKeys[1].sha1')
replicas=$("${oc_client}" -n nbde get tangservers.daemons.redhat.com  -o json | jq '.items[0].spec.replicas')

ftemp=$(mktemp)
cat<<EOF>"${ftemp}"
apiVersion: daemons.redhat.com/v1alpha1
kind: TangServer
metadata:
  name: tangserver-mini
  namespace: nbde
  finalizers:
  - finalizer.daemons.tangserver.redhat.com
spec:
  replicas: ${replicas}
  hiddenKeys:
  - sha1: ${sha1_1}
  - sha1: ${sha1_2}
EOF

"${oc_client}" apply -f "${ftemp}" -n "${namespace}"
rm "${ftemp}"

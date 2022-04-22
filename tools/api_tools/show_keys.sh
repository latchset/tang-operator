#!/bin/bash -e

namespace=""
using_minikube=""

usage() {
  echo
  echo "Usage:"
  echo
  echo "$1 -n namespace [-c k8s_client] [-m (using minikube)] [-v (verbose)]"
  echo
  exit "$2"
}

while getopts "n:c:hmv" arg
do
case "${arg}" in
  n) namespace=${OPTARG}
  ;;
  c) oc_client=${OPTARG}
  ;;
  m) using_minikube="yes"
  ;;
  v) set -x
  ;;
  h) usage "$0" 0
  ;;
  *) usage "$0" 1
  ;;
esac
done

test -z "${namespace}" && namespace="default"
test -z "${oc_client}" && oc_client="oc"

getAdvUrl() {
  if [ "${using_minikube}" != "yes" ];
  then
      "${oc_client}" -n "${namespace}" get tangservers.daemons.redhat.com  -o json | jq '.items[0].status.serviceExternalUrl' | tr -d '"'
  else
      port=$("${oc_client}" -n "${namespace}" get service -o json | jq '.items[0].spec.ports[0].nodePort')
      echo "http://$(minikube ip):${port}/adv"
  fi
}

adv_url=$(getAdvUrl)
adv=$(wget -O - ${adv_url} -o /dev/null)

dumpFromAdvWithHash() {
    local adv="$1"
    local hash="$2"
    jose fmt --json "${adv}" -g payload -y -o- | jose jwk use -i- -r -u verify -o- \
        | jose jwk thp -i- -a "${hash}"    
}

echo "===ADV (URL:${adv_url})==="
echo "${adv}"
echo "===/ADV (URL:${adv_url})==="
echo "===FORMATTED ADV (URL:${adv_url})==="
echo "${adv}" | jq
echo "===/FORMATTED ADV (URL:${adv_url})==="
echo
echo "===JOSE PAYLOAD==="
payload=$(jose fmt --json "${adv}" -g payload -y -o-)
echo "${payload}"
echo "===/JOSE PAYLOAD==="
echo "===FORMATTED JOSE PAYLOAD==="
echo "${payload}" | jq
echo "===/FORMATTED JOSE PAYLOAD==="
echo
echo "===JOSE VERIFY==="
verify=$(echo "${payload}" | jose jwk use -i- -r -u verify -o-)
echo "${payload}"
echo "===/JOSE VERIFY==="
echo "===FORMATTED JOSE VERIFY==="
echo "${verify}" | jq
echo "===/FORMATTED JOSE VERIFY==="
echo
echo "===SIGNING KEY==="
echo "SHA1:$(dumpFromAdvWithHash "${adv}" "S1")"
echo "SHA256:$(dumpFromAdvWithHash "${adv}" "S256")"
echo "===/SIGNING KEY==="

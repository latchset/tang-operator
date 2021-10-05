#!/bin/bash
#
OPTIND=1
CONFIG_FILE=""
CONTEXT=""
NAMESPACE=""
alias cp='cp -rfv'

function usage() {
  echo "$1 -f config-file [-c context] [-n namespace]"
  #exit $2
  return $2
}

while getopts "f:c:n:h" arg
do
  case "${arg}" in
    f) CONFIG_FILE=${OPTARG}
       echo "CONFIG_FILE=${CONFIG_FILE}"
       ;;
    c) CONTEXT=${OPTARG}
       echo "CONTEXT=${CONTEXT}"
       ;;
    n) NAMESPACE=${OPTARG}
       echo "NAMESPACE=${NAMESPACE}"
       ;;
    h) usage $0 0
       ;;
  esac
done

if [ -z "${CONFIG_FILE}" ];
then
  usage "$0" 1
fi

CONFIG_FILE_PATH=$(readlink -f "${CONFIG_FILE}")
if [ -f ${HOME}/.kube/config.onlyMinikube ];
then
  echo "cp ${HOME}/.kube/config.onlyMinikube ${HOME}/.kube/config"
  cp ${HOME}/.kube/config.onlyMinikube ${HOME}/.kube/config
fi

export KUBECONFIG=${HOME}/.kube/config:${CONFIG_FILE_PATH}
echo "export KUBECONFIG=${HOME}/.kube/config:${CONFIG_FILE_PATH}"
export KUBECONFIG=${HOME}/.kube/config:${CONFIG_FILE_PATH}
echo "kubectl config view --raw > /tmp/kubeconfig"
kubectl config view --raw > /tmp/kubeconfig
echo "cp /tmp/kubeconfig ~/.kube/config"
cp /tmp/kubeconfig ~/.kube/config

if [ ! -z "${CONTEXT}" ];
then
  if [ ! -z "${NAMESPACE}" ];
  then
    echo "kubectl config set-context ${CONTEXT} --namespace=${NAMESPACE}"
  fi
  echo "kubectl config use-context ${CONTEXT}"
  kubectl config use-context "${CONTEXT}"
fi

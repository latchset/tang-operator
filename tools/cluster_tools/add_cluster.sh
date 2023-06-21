#!/bin/bash
#
# Copyright 2023 sarroutb@redhat.com
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom
# the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
# OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
OPTIND=1
CONFIG_FILE=""
CONTEXT=""
NAMESPACE=""
alias cp='cp -rfv'

function usage() {
  echo "$1 -f config-file [-c context] [-n namespace]"
  return "$2"
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
    h) usage "$0" 0
       ;;
    *) usage "$0" 1
       ;;
  esac
done

if [ -z "${CONFIG_FILE}" ];
then
  usage "$0" 1
fi

CONFIG_FILE_PATH=$(readlink -f "${CONFIG_FILE}")
if [ -f "${HOME}"/.kube/config.onlyMinikube ];
then
  cp "${HOME}"/.kube/config.onlyMinikube "${HOME}"/.kube/config -v
fi

export KUBECONFIG=${HOME}/.kube/config:${CONFIG_FILE_PATH}
echo "export KUBECONFIG=${HOME}/.kube/config:${CONFIG_FILE_PATH}"
export KUBECONFIG=${HOME}/.kube/config:${CONFIG_FILE_PATH}
echo "kubectl config view --raw > /tmp/kubeconfig"
kubectl config view --raw > /tmp/kubeconfig
echo "cp /tmp/kubeconfig ~/.kube/config"
cp /tmp/kubeconfig ~/.kube/config

if [ -n "${CONTEXT}" ];
then
  if [ -n "${NAMESPACE}" ];
  then
    echo "kubectl config set-context ${CONTEXT} --namespace=${NAMESPACE}"
  fi
  echo "kubectl config use-context ${CONTEXT}"
  kubectl config use-context "${CONTEXT}"
fi

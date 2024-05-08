#!/bin/bash
#
#   Copyright [2023] [sarroutb (at) redhat.com]
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
OPTIND=1
CONFIG_FILE=""
CONTEXT=""
NAMESPACE=""
alias cp='cp -rfv'

function usage() {
  local sourced=1
  echo ""
  {
    [[ -n $ZSH_VERSION && $ZSH_EVAL_CONTEXT =~ :file$ ]] ||
    [[ -n $BASH_VERSION ]] && [[ $0 != "${BASH_SOURCE[0]}" ]]
  } && sourced=1 || sourced=0
  if [ "${sourced}" -eq 0 ];
  then
    echo "$1 -f config-file [-c context] [-n namespace]"
    echo ""
    exit "$2"
  else
    echo "${BASH_ARGV[0]} -f config-file [-c context] [-n namespace]"
    echo ""
    return "$2"
  fi
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
    h) usage "$0" 0 || return 0
       ;;
    *) usage "$0" 1 || return 1
       ;;
  esac
done

if [ -z "${CONFIG_FILE}" ];
then
  usage "$0" 1 || return 1
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

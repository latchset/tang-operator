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
list_only=""

function usage() {
    echo
    echo "Usage:"
    echo
    echo "$1 [-h] [-l]"
    echo
    exit "$2"
}

while getopts "hl" arg
do
  case "${arg}" in
    l) list_only="true"
       ;;
    h) usage "$0" 0
       ;;
    *) usage "$0" 1
       ;;
  esac
done

echo "-------------------------------------"
echo "oc status"
oc status
if [ -z "${list_only}" ];
then
    sleep 1
    echo "-------------------------------------"
    echo "oc create -f tang_catalog_source.yaml"
    oc create -f tang_catalog_source.yaml
fi
echo "-------------------------------------"
sleep 1
echo "oc get catsrc -nopenshift-marketplace"
oc get catsrc -nopenshift-marketplace
echo "-------------------------------------"
sleep 1
echo "oc get pods -nopenshift-marketplace"
oc get pods -nopenshift-marketplace
if [ -z "${list_only}" ];
then
    echo "-------------------------------------"
    sleep 1
    echo "oc create -f tang_subscription.yaml -n openshift-operators"
    oc create -f tang_subscription.yaml -n openshift-operators
fi
echo "-------------------------------------"
sleep 1
echo "oc get sub -n openshift-operators"
oc get sub -n openshift-operators
echo "-------------------------------------"
sleep 1
echo "oc get ip -n openshift-operators"
oc get ip -n openshift-operators
echo "-------------------------------------"
sleep 1
echo "oc get jobs -nopenshift-marketplace"
oc get jobs -nopenshift-marketplace
echo "-------------------------------------"
sleep 1
echo "oc get pods -nopenshift-marketplace"
oc get pods -nopenshift-marketplace
echo "-------------------------------------"
sleep 1
if [ -z "${list_only}" ];
then
    sleep 9
fi
echo "oc get csv -n openshift-operators"
oc get csv -n openshift-operators
echo "-------------------------------------"
sleep 1
echo "oc get pods -n openshift-operators"
oc get pods -n openshift-operators
echo "-------------------------------------"
sleep 1

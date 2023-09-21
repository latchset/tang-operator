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
echo "oc project openshift-operators"
oc project openshift-operators
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
    echo "oc create -f tang_subscription.yaml"
    oc create -f tang_subscription.yaml
fi
echo "-------------------------------------"
echo "oc project"
oc project
echo "-------------------------------------"
sleep 1
echo "oc get sub"
oc get sub
echo "-------------------------------------"
sleep 1
echo "oc get ip"
oc get ip
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
echo "oc get csv"
oc get csv
echo "-------------------------------------"
sleep 1
echo "oc get pods"
oc get pods
echo "-------------------------------------"
sleep 1

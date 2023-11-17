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

test -f tang_subscription.yaml && oc delete -f tang_subscription.yaml 
test -f tang_catalog_source.yaml && oc delete -f tang_catalog_source.yaml 
oc get csv -nopenshift-operators
csv=$(oc get csv -n openshift-operators | grep -v NAME | head | awk '{print $1}')
test -z "${csv}" || oc delete csv "${csv}" -n openshift-operators

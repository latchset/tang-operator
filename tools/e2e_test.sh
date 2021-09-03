#!/bin/bash -x
# Copyright 2021.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
SM="subscription-manager"
OC_PATH=http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/openshift-clients/4.9.0/202109020218.p0.git.96e95ce.assembly.stream.el8/x86_64
OC_FILE=openshift-clients-4.9.0-202109020218.p0.git.96e95ce.assembly.stream.el8.x86_64.rpm
OC_OUTPUT_FILE=openshift-clients-4.9.0.rpm
TMPDIR=$(mktemp -d)
OC_INSTALL_FILE="${TMPDIR}/${OC_OUTPUT_FILE}"
#### OC Installation
get_oc_rpm_adding_repo() {
  "${SM}" register
  "${SM}" refresh
  POOL_ID=$("${SM}" list --available --matches 'Red Hat OpenShift Container Platform' | grep -i 'Pool ID' | awk -F ':' '{print $2}' | tr -d ' ' | head -1)
  for pool_id in $("${SM}" list --available --matches 'Red Hat OpenShift Container Platform' | grep -i 'Pool ID' | awk -F ':' '{print $2}' | tr -d ' ')
  do
    "${SM}" attach --pool="${POOL_ID}"
    echo "POOL_ID=${POOL_ID}"
    for repo in $(subscription-manager repos --list | grep 'Repo ID:' | awk -F ':' '{print $2}');
    do
      "${SM}" repos --enable="${repo}"
      #"${SM}" repos --enable="rhocp-4.7-for-rhel-8-x86_64-rpms"
      yum update
      yum install openshift-clients
      #yum search openshift-clients
    done
  done
  #
  "${SM}" attach --pool="${POOL_ID}"
  #"${SM}" repos --enable="rhocp-4.7-for-rhel-8-x86_64-rpms"
  "${SM}" repos --enable="rhocp-4.8-for-rhel-8-x86_64-rpms"
  yum install openshift-clients
}


get_oc_rpm_with_wget() {
  wget "${OC_PATH}/${OC_FILE}" -O "${OC_INSTALL_FILE}"
}

install_oc() {
  dnf install -y "${OC_INSTALL_FILE}"
}

get_oc_rpm_with_wget
install_oc

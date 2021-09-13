#!/bin/bash
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

# Uncomment next line to dump verbose information in script execution:
# set -x

SM="subscription-manager"
OC_PATH=http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/openshift-clients/4.9.0/202109020218.p0.git.96e95ce.assembly.stream.el8/x86_64
OC_FILE=openshift-clients-4.9.0-202109020218.p0.git.96e95ce.assembly.stream.el8.x86_64.rpm
OC_OUTPUT_FILE=openshift-clients-4.9.0.rpm
TMPDIR=$(mktemp -d)
TMPDIR_NON_TMPFS=$(echo "${TMPDIR}" | sed -e 's@/tmp/@@g')
OC_INSTALL_FILE="${TMPDIR}/${OC_OUTPUT_FILE}"
CRC_PATH=https://developers.redhat.com/content-gateway/rest/mirror/pub/openshift-v4/clients/crc/latest
CRC_FILE=crc-linux-amd64.tar.xz
CRC_OUTPUT_FILE=crc-linux-amd64.tar.xz
CRC_INSTALL_FILE="${TMPDIR_NON_TMPFS}/${CRC_OUTPUT_FILE}"
CRC_PREFIX="crc-linux-[0-9]"
CRC_EXEC="crc"
CRC_VIRSH_DOMAIN="crc"
HOME_BIN="${HOME}/bin"
HOME_BASHRC="${HOME}/.bashrc"
CRC_USER="crc"
CRC_PASSWORD="crc1234crc5678"
CRC_HOME="/home/${CRC_USER}"
CRC_HOME_BIN="${CRC_HOME}/bin"
CRC_HOME_BASHRC="${CRC_HOME}/.bashrc"
CRC_EXEC_PATH="${CRC_HOME_BIN}/${CRC_EXEC}"
CRC_SECRET=""

usage() {
  echo ""
  echo "$1"
  echo ""
  echo "NOTE: secret is mandatory for CRC install, as it requires it for its installation"
  echo "      It will be prompted after crc installation, in \"crc start\" step"
  echo "      Secret can be retrieved in next URL: https://console.redhat.com/openshift/create/local"
  echo ""
  exit $2
}

#### OC Installation
get_oc_rpm_adding_repo() {
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
  "${SM}" repos --enable="rhocp-4.8-for-rhel-8-x86_64-rpms"
  yum install openshift-clients
}

get_oc_rpm_with_wget() {
  type oc && return 0
  wget "${OC_PATH}/${OC_FILE}" -O "${OC_INSTALL_FILE}"
}

get_crc_tgz_with_wget() {
  mkdir "${TMPDIR_NON_TMPFS}"
  wget "${CRC_PATH}/${CRC_FILE}" -O "${CRC_INSTALL_FILE}"
}

install_podman() {
  type podman && return 0
  yum install -y podman
}

install_network_manager() {
  yum install -y NetworkManager
  systemctl enable --now NetworkManager
}

install_libvirtd() {
  yum install -y libvirt-daemon
#  yum install -y dbus-x11
  systemctl enable --now libvirt-daemon
}

install_oc() {
  type oc && return 0
  yum install -y "${OC_INSTALL_FILE}"
}

install_crc() {
  type crc && return 0
  test -d "${CRC_HOME_BIN}/${CRC_EXEC}" && return 0
  get_crc_tgz_with_wget
  pushd "${TMPDIR_NON_TMPFS}"
  tar Jxvf "${CRC_OUTPUT_FILE}"
  CRC_DIR=$(ls -d ${CRC_PREFIX}*)
  pushd "${CRC_DIR}"
  test -d "${CRC_HOME_BIN}" || mkdir -p "${CRC_HOME_BIN}"
  rm -fr "${CRC_USER}"/.crc "${CRC_USER}"/.kube
  virsh shutdown "${CRC_VIRSH_DOMAIN}"
  virsh undefine "${CRC_VIRSH_DOMAIN}"
  virsh delete   "${CRC_VIRSH_DOMAIN}"
  cp "${CRC_EXEC}" "${CRC_HOME_BIN}"
#  export PATH="${PATH}:${HOME_BIN}"
  cp "${HOME_BASHRC}" "${CRC_HOME_BASHRC}"
  cat<<EOF>>"${CRC_HOME_BASHRC}"

# CRC installation PATH update
EOF
  printf 'export PATH="${PATH}:' >> "${CRC_HOME_BASHRC}"
  printf "${CRC_HOME_BIN}\"\n" >> "${CRC_HOME_BASHRC}"
  popd
  popd
  useradd "${CRC_USER}"
  passwd "${CRC_USER}"<<EOF
"${CRC_PASSWORD}"
"${CRC_PASSWORD}"
EOF
  chown -R "${CRC_USER}.${CRC_USER}" "${CRC_HOME}"
  cat<<EOF>>/etc/sudoers

### Add crc user to sudoers
"${CRC_USER}" ALL=(ALL) NOPASSWD:ALL
EOF

  # AVOID issues with systemctl and network manager
  sudo loginctl enable-linger
  sudo -u "${CRC_USER}" "${CRC_EXEC_PATH}" config set skip-check-daemon-systemd-unit true
  sudo -u "${CRC_USER}" "${CRC_EXEC_PATH}" config set skip-check-daemon-systemd-sockets true
  sudo -u "${CRC_USER}" "${CRC_EXEC_PATH}" config set skip-check-network-manager-running true
  sudo -u "${CRC_USER}" "${CRC_EXEC_PATH}" config set skip-check-network-manager-installed true
  sudo -u "${CRC_USER}" "${CRC_EXEC_PATH}" config set skip-check-network-manager-config true


  ###   34  2021-09-07 12:41:44 sudo -u crc XDG_RUNTIME_DIR=/run/user/$(id -u $otherUser) systemctl --user
  sudo -u "${CRC_USER}" XDG_RUNTIME_DIR=/run/user/$(id -u "${CRC_USER}") "${CRC_EXEC_PATH}" setup<<EOF
no
EOF
  sudo -u "${CRC_USER}" XDG_RUNTIME_DIR=/run/user/$(id -u "${CRC_USER}") "${CRC_EXEC_PATH}" start
}

sm_register() {
  "${SM}" register
  "${SM}" refresh
}

clean() {
  test -d "${TMPDIR}" && rm -fr "${TMPDIR}"
  test -d "${TMPDIR_NON_TMPFS}" && rm -fr "${TMPDIR_NON_TMPFS}"
}

install_operator_sdk() {
  export ARCH=$(case $(uname -m) in x86_64) echo -n amd64 ;; aarch64) echo -n arm64 ;; *) echo -n $(uname -m) ;; esac)
  export OS=$(uname | awk '{print tolower($0)}')
  export OPERATOR_SDK_DL_URL=https://github.com/operator-framework/operator-sdk/releases/download/v1.12.0
  curl -LO ${OPERATOR_SDK_DL_URL}/operator-sdk_${OS}_${ARCH}
  chmod +x operator-sdk_${OS}_${ARCH} && sudo mv operator-sdk_${OS}_${ARCH} "${CRC_HOME_BIN}/operator-sdk"
}

# TODO: A parse pararams function could be added for this
while getopts "s:h" arg
do
  case "${arg}" in
    s) CRC_SECRET=${OPTARG}
      ;;
    h) usage $0 0
      ;;
    *) usage $0 0
      ;;
  esac
done

sm_register
install_podman
install_libvirtd
install_network_manager
get_oc_rpm_with_wget
install_oc
install_crc
install_operator_sdk
clean

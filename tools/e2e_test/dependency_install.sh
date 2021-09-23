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
TMPDIR_NON_TMPFS="${TMPDIR//\/tmp/}"
OC_INSTALL_FILE="${TMPDIR}/${OC_OUTPUT_FILE}"
CRC_PATH=https://developers.redhat.com/content-gateway/rest/mirror/pub/openshift-v4/clients/crc/latest
CRC_FILE=crc-linux-amd64.tar.xz
CRC_OUTPUT_FILE=crc-linux-amd64.tar.xz
CRC_INSTALL_FILE="${TMPDIR_NON_TMPFS}/${CRC_OUTPUT_FILE}"
CRC_PREFIX="crc-linux-[0-9]"
CRC_EXEC="crc"
CRC_VIRSH_DOMAIN="crc"
HOME_BASHRC="${HOME}/.bashrc"
CRC_USER="crc"
CRC_PASSWORD="crc1234crc5678"
CRC_HOME="/home/${CRC_USER}"
CRC_HOME_BIN="${CRC_HOME}/bin"
CRC_HOME_BASHRC="${CRC_HOME}/.bashrc"
CRC_EXEC_PATH="${CRC_HOME_BIN}/${CRC_EXEC}"
PULL_SECRET_PATH="$(dirname $(readlink -f $0))"
PULL_SECRET_FILENAME="public_pull_secret.txt"
PULL_SECRET_FILE="${PULL_SECRET_PATH}/${PULL_SECRET_FILENAME}"
PULL_SECRET_INSTALL_FILE="${TMPDIR}/${PULL_SECRET_FILENAME}"
MINIKUBE_URL="https://storage.googleapis.com/minikube/releases/latest"
MINIKUBE_FILE="minikube-latest.x86_64.rpm"
MINIKUBE_URL_FILE="${MINIKUBE_URL}/${MINIKUBE_FILE}"
RH_INSTALL=0
RELEASE_K8S_URL="https://dl.k8s.io/release/"
STABLE_K8S_URL_FILE="https://dl.k8s.io/release/stable.txt"
BIN_LINUX_PATH="bin/linux/amd64"
MINIKUBE_USER="minikube"
MINIKUBE_HOME="/home/${MINIKUBE_USER}"
MINIKUBE_HOME_BIN="${MINIKUBE_HOME}/bin"
MINIKUBE_HOME_BASHRC="${MINIKUBE_HOME}/.bashrc"
MINIKUBE_CLIENT="kubectl"
OLM_INSTALL_TIMEOUT="5m"

usage() {
  echo ""
  echo "Usage: $1 [-r redhat_installation (oc, crc)]"
  echo ""
  echo "      -r: install RedHat tools (CRC, oc) instead of Minikube and kubectl"
  echo ""
  exit "$2"
}

#### OC Installation
get_oc_rpm_adding_repo() {
  POOL_ID=$("${SM}" list --available --matches 'Red Hat OpenShift Container Platform' | grep -i 'Pool ID' | awk -F ':' '{print $2}' | tr -d ' ' | head -1)
  for pool_id in $("${SM}" list --available --matches 'Red Hat OpenShift Container Platform' | grep -i 'Pool ID' | awk -F ':' '{print $2}' | tr -d ' ')
  do
    "${SM}" attach --pool="${pool_id}"
    echo "POOL_ID=${pool_id}"
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

install_jq() {
  type jq && return 0
  yum install -y jq
}

install_network_manager() {
  yum install -y NetworkManager
  systemctl enable --now NetworkManager
}

install_libvirtd() {
  yum install -y libvirt-daemon
  yum install -y libvirt-client
#  yum install -y dbus-x11
  systemctl enable --now libvirt-daemon
}

install_oc() {
  type oc && return 0
  yum install -y "${OC_INSTALL_FILE}"
}

install_crc() {
  sudo -u "${CRC_USER}" /home/crc/bin/crc status && return 0
  test -f "${CRC_HOME_BIN}/${CRC_EXEC}" && return 0
  get_crc_tgz_with_wget
  pushd "${TMPDIR_NON_TMPFS}" || exit
  tar Jxvf "${CRC_OUTPUT_FILE}"
  CRC_DIR=$(ls -d ${CRC_PREFIX}*)
  pushd "${CRC_DIR}" || exit
  test -d "${CRC_HOME_BIN}" || mkdir -p "${CRC_HOME_BIN}"
  rm -fr "${CRC_USER}"/.crc "${CRC_USER}"/.kube
  virsh destroy "${CRC_VIRSH_DOMAIN}"
  virsh undefine "${CRC_VIRSH_DOMAIN}"
  cp "${CRC_EXEC}" "${CRC_HOME_BIN}"
  cp "${HOME_BASHRC}" "${CRC_HOME_BASHRC}"
  cat<<EOF>>"${CRC_HOME_BASHRC}"

# CRC installation PATH update
EOF
  printf 'export PATH="${PATH}:' >> "${CRC_HOME_BASHRC}"
  printf "%s\"\n" "${CRC_HOME_BIN}" >> "${CRC_HOME_BASHRC}"
  popd || exit
  popd || exit
  sudo -u "${CRC_USER}" true 2>/dev/null || useradd "${CRC_USER}"
  passwd "${CRC_USER}"<<EOF
"${CRC_PASSWORD}"
"${CRC_PASSWORD}"
EOF
  chown -R "${CRC_USER}.${CRC_USER}" "${CRC_HOME}"
  grep -R "Add crc user to sudoers" /etc/sudoers
  if [ $? -ne 0 ];
  then
    cat<<EOF>>/etc/sudoers

### Add crc user to sudoers
"${CRC_USER}" ALL=(ALL) NOPASSWD:ALL
EOF
  fi
  # AVOID issues with systemctl and network manager
  sudo loginctl enable-linger
  sudo -u "${CRC_USER}" "${CRC_EXEC_PATH}" config set skip-check-daemon-systemd-unit true
  sudo -u "${CRC_USER}" "${CRC_EXEC_PATH}" config set skip-check-daemon-systemd-sockets true
  sudo -u "${CRC_USER}" "${CRC_EXEC_PATH}" config set skip-check-network-manager-running true
  sudo -u "${CRC_USER}" "${CRC_EXEC_PATH}" config set skip-check-network-manager-installed true
  sudo -u "${CRC_USER}" "${CRC_EXEC_PATH}" config set skip-check-network-manager-config true


  ###   34  2021-09-07 12:41:44 sudo -u crc XDG_RUNTIME_DIR=/run/user/$(id -u $otherUser) systemctl --user
  sudo -u "${CRC_USER}" XDG_RUNTIME_DIR="/run/user/$(id -u ${CRC_USER})" "${CRC_EXEC_PATH}" setup<<EOF
no
EOF
  check_pull_secret
  test -f "${PULL_SECRET_INSTALL_FILE}" &&
    sudo -u "${CRC_USER}" XDG_RUNTIME_DIR="/run/user/$(id -u ${CRC_USER})" "${CRC_EXEC_PATH}" start -p "${PULL_SECRET_INSTALL_FILE}" ||
    sudo -u "${CRC_USER}" XDG_RUNTIME_DIR="/run/user/$(id -u ${CRC_USER})" "${CRC_EXEC_PATH}" start
}

sm_register() {
  "${SM}" register
  "${SM}" refresh
}

clean() {
  test -d "${TMPDIR}" && rm -fr "${TMPDIR}"
  test -d "${TMPDIR_NON_TMPFS}" && rm -fr "${TMPDIR_NON_TMPFS}"
  test -f "${MINIKUBE_CLIENT}.sha256" && rm "${MINIKUBE_CLIENT}.sha256"
}

create_minikube_user() {
  sudo -u "${MINIKUBE_USER}" true 2>/dev/null || useradd "${MINIKUBE_USER}"
  mkdir -p "${MINIKUBE_HOME_BIN}"
  chown -R "${MINIKUBE_USER}.${MINIKUBE_USER}" "${MINIKUBE_HOME}"
  cp "${HOME_BASHRC}" "${MINIKUBE_HOME_BASHRC}"
  printf 'export XDG_RUNTIME_DIR="' >> "${MINIKUBE_HOME_BASHRC}"
  printf "%s\"\n\n" "/run/user/$(id -u ${MINIKUBE_USER})" >> "${MINIKUBE_HOME_BASHRC}"
  grep -R "Add minikube user to sudoers" /etc/sudoers
  if [ $? -ne 0 ];
  then
    cat<<EOF>>/etc/sudoers

### Add minikube user to sudoers
"${MINIKUBE_USER}" ALL=(ALL) NOPASSWD:ALL
EOF
  fi
}

install_operator_sdk() {
  ARCH=$(case $(uname -m) in x86_64) echo -n amd64 ;; aarch64) echo -n arm64 ;; *) echo -n "$(uname -m)" ;; esac)
  OS=$(uname | awk '{print tolower($0)}')
  OPERATOR_SDK_DL_URL=https://github.com/operator-framework/operator-sdk/releases/download/v1.12.0
  curl -LO "${OPERATOR_SDK_DL_URL}/operator-sdk_${OS}_${ARCH}"
  if [ ${RH_INSTALL} -eq 1 ];
  then
    chmod +x "operator-sdk_${OS}_${ARCH}" && sudo mv "operator-sdk_${OS}_${ARCH}" "${CRC_HOME_BIN}/operator-sdk"
  else
    chmod +x "operator-sdk_${OS}_${ARCH}" && sudo mv "operator-sdk_${OS}_${ARCH}" "${MINIKUBE_HOME_BIN}/operator-sdk"
  fi
}

setup_crc() {
  sudo -u "${CRC_USER}" oc adm policy add-scc-to-group anyuid system:authenticated
}

install_minikube() {
  curl -LO "${MINIKUBE_URL_FILE}"
  rpm -Uvh "${MINIKUBE_FILE}"
  rm "${MINIKUBE_FILE}"
}

setup_minikube() {
  minikube_user_id=$(id "${MINIKUBE_USER}" | awk {'print $1'} | egrep -E "[0-9]{1,}" -o)
  loginctl enable-linger ${minikube_user_id}
  pushd /tmp
  sudo -u "${MINIKUBE_USER}" XDG_RUNTIME_DIR="/run/user/$(id -u ${MINIKUBE_USER})" podman ps
  sudo -u "${MINIKUBE_USER}" XDG_RUNTIME_DIR="/run/user/$(id -u ${MINIKUBE_USER})" minikube start
  sudo -u "${MINIKUBE_USER}" XDG_RUNTIME_DIR="/run/user/$(id -u ${MINIKUBE_USER})" podman ps
  sudo -u "${MINIKUBE_USER}" XDG_RUNTIME_DIR="/run/user/$(id -u ${MINIKUBE_USER})" "${MINIKUBE_HOME_BIN}"/operator-sdk --timeout ${OLM_INSTALL_TIMEOUT} olm install
  popd
}

install_kubectl() {
  ARCH=$(uname -m)
  if [ "${ARCH}" != "x86_64" ];
  then
      echo "WARNING: ARCHITECTURE NOT SUPPORTED:${ARCH}"
      return 1
  fi
  curl -LO "${RELEASE_K8S_URL}/$(curl -L -s ${STABLE_K8S_URL_FILE})/${BIN_LINUX_PATH}/${MINIKUBE_CLIENT}"
  curl -LO "${RELEASE_K8S_URL}/$(curl -L -s ${STABLE_K8S_URL_FILE})/${BIN_LINUX_PATH}/${MINIKUBE_CLIENT}.sha256"
  echo "$(<kubectl.sha256) ${MINIKUBE_CLIENT}" | sha256sum --check
  mv ${MINIKUBE_CLIENT} ${MINIKUBE_HOME_BIN}
  cat<<EOF>>"${MINIKUBE_HOME_BASHRC}"

# Minikube installation PATH update
EOF
  printf 'export PATH="${PATH}:' >> "${MINIKUBE_HOME_BASHRC}"
  printf "%s\"\n" "${MINIKUBE_HOME_BIN}" >> "${MINIKUBE_HOME_BASHRC}"
}

check_pull_secret() {
  test -f "${PULL_SECRET_FILE}"
  if [ $? -eq 0 ];
  then
    echo "FILE SECRET:${PULL_SECRET_FILE} FOUND"
    chmod 777 "${TMPDIR}"
    cp "${PULL_SECRET_FILE}" "${PULL_SECRET_INSTALL_FILE}"
    chmod 777 "${PULL_SECRET_INSTALL_FILE}"
  else
    echo "FILE SECRET:${PULL_SECRET_FILE} NOT FOUND"
  fi
}

set_minikube_permission() {
  chown "${MINIKUBE_USER}.${MINIKUBE_USER}" ${MINIKUBE_HOME}/*
  chmod 755 ${MINIKUBE_HOME_BIN}/*
}

# TODO: A parse pararams function could be added for this
while getopts "s:ph" arg
do
  case "${arg}" in
    p) RH_INSTALL=1
      ;;
    h) usage "$0" 0
      ;;
    *) usage "$0" 0
      ;;
  esac
done

if [ ${RH_INSTALL} -eq 0 ];
then
  create_minikube_user
fi
install_operator_sdk
install_podman
install_jq
if [ ${RH_INSTALL} -eq 1 ];
then
  sm_register
  install_libvirtd
  install_network_manager
  get_oc_rpm_with_wget
  install_oc
  install_crc
  setup_crc
else
  install_minikube
  setup_minikube
  install_kubectl
  set_minikube_permission
fi
clean

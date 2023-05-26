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
set -x -e

OPERATOR_SDK_DEFAULT_RELEASE_VERSION="v1.28.0"
DEFAULT_BUNDLE_IMG="quay.io/sec-eng-special/tang-operator-bundle"
DEFAULT_TIMEOUT="5m"
DEFAULT_GITHUB_BRANCH="main"

OPERATOR_SDK_RELEASE_VERSION="${1}"
TIMEOUT="${2}"
BUNDLE_IMG="${3}"
GITHUB_REF="${4}"
GITHUB_BRANCH="${4##*/}"
BUNDLE_VERSION="${5}"

test -z "${GITHUB_BRANCH}" && GITHUB_BRANCH="main"
ARCH=$(case $(uname -m) in x86_64) echo -n amd64 ;; aarch64) echo -n arm64 ;; *) echo -n "$(uname -m)" ;; esac)
OS=$(uname | awk '{print tolower($0)}')

MAKEFILE_BASE_PATH="https://raw.githubusercontent.com/latchset/tang-operator/${GITHUB_BRANCH}/Makefile"
MAKEFILE_BASE_PATH_FROM_SHA="https://raw.githubusercontent.com/latchset/tang-operator/${GITHUB_SHA}/Makefile"

# Guess version from Makefile
guess_version() {
  MAKE_BUNDLE_VERSION="$(wget -o /dev/null -O - "${MAKEFILE_BASE_PATH}" | grep "^VERSION " | awk -F "=" '{print $2}' | sed -e 's@ @@g' 2>/dev/null)"
  if [ -z "${MAKE_BUNDLE_VERSION}" ]; then
    MAKE_BUNDLE_VERSION="$(wget -o /dev/null -O - "${MAKEFILE_BASE_PATH_FROM_SHA}" | grep "^VERSION " | awk -F "=" '{print $2}' | sed -e 's@ @@g' 2>/dev/null)"
  fi
}

dump_info() {
  cat << EOF
==================$0 INFO ===================
OPERATOR_SDK_RELEASE_VERSION="${OPERATOR_SDK_RELEASE_VERSION}"
TIMEOUT="${TIMEOUT}"
GITHUB_SHA="${GITHUB_SHA}"
GITHUB_REF="${GITHUB_REF}"
GITHUB_BRANCH="${GITHUB_BRANCH}"
BUNDLE_IMG="${BUNDLE_IMG}"
BUNDLE_VERSION="${BUNDLE_VERSION}"
BUNDLE_IMG_VERSION="${BUNDLE_IMG_VERSION}"
ARCH=${ARCH}
OS=${OS}
==================$0 INFO ===================
EOF
}

if [ -z "${OPERATOR_SDK_RELEASE_VERSION}" ]; then
  echo "INFO: operator-sdk release version is not set. Setting default version:${OPERATOR_SDK_DEFAULT_RELEASE_VERSION}"
  OPERATOR_SDK_RELEASE_VERSION="${OPERATOR_SDK_DEFAULT_RELEASE_VERSION}"
fi

OPERATOR_SDK_DL_URL=https://github.com/operator-framework/operator-sdk/releases/download/${OPERATOR_SDK_RELEASE_VERSION}

if [ -z "${TIMEOUT}" ]; then
  echo "INFO: using default timeout: ${DEFAULT_TIMEOUT}"
  TIMEOUT="${DEFAULT_TIMEOUT}"
fi

if [ -z "${BUNDLE_IMG}" ]; then
  echo "INFO: using default bundle image: ${DEFAULT_BUNDLE_IMG}"
  BUNDLE_IMG="${DEFAULT_BUNDLE_IMG}"
fi

if [ -z "${GITHUB_BRANCH}" ]; then
  echo "INFO: using default github branch: ${DEFAULT_GITHUB_BRANCH}"
  GITHUB_BRANCH=${DEFAULT_GITHUB_BRANCH}
fi

if [ -z "${BUNDLE_VERSION}" ]; then
  guess_version
  echo "INFO: using Makefile bundle image: ${MAKE_BUNDLE_VERSION}"
  BUNDLE_VERSION="${MAKE_BUNDLE_VERSION}"
fi

BUNDLE_IMG_VERSION="${BUNDLE_IMG}:v${BUNDLE_VERSION}"
dump_info

curl -L -o "operator-sdk_${OS}_${ARCH}" -L "${OPERATOR_SDK_DL_URL}/operator-sdk_${OS}_${ARCH}"
gpg --keyserver keyserver.ubuntu.com --recv-keys 052996E2A20B5C7E
curl -LO "${OPERATOR_SDK_DL_URL}"/checksums.txt
curl -LO "${OPERATOR_SDK_DL_URL}"/checksums.txt.asc
gpg -u "Operator SDK (release) <cncf-operator-sdk@cncf.io>" --verify checksums.txt.asc
grep "operator-sdk_${OS}_${ARCH}" checksums.txt | sha256sum -c -

mv "operator-sdk_${OS}_${ARCH}" "$(pwd)/operator-sdk"
chmod +x "$(pwd)/operator-sdk"
"$(pwd)"/operator-sdk olm install --timeout "${TIMEOUT}"
"$(pwd)"/operator-sdk olm status
"$(pwd)"/operator-sdk run bundle --timeout "${TIMEOUT}" "${BUNDLE_IMG_VERSION}"
"$(pwd)"/operator-sdk olm status
"$(pwd)"/operator-sdk scorecard --wait-time="${TIMEOUT}" "${BUNDLE_IMG_VERSION}"

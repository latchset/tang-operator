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
set -x

OPERATOR_SDK_DEFAULT_RELEASE_VERSION="v1.10.1"
DEFAULT_BUNDLE_IMG="quay.io/sarroutb/tang-operator-bundle"
DEFAULT_TIMEOUT="5m"
MAKEFILE_BASE_PATH="https://raw.githubusercontent.com/sarroutbi/tang-operator/main/Makefile"

OPERATOR_SDK_RELEASE_VERSION="${1}"
TIMEOUT="${2}"
BUNDLE_IMG="${3}"
BUNDLE_VERSION="${4}"

# Guess version from Makefile
guess_version() {
  MAKE_BUNDLE_VERSION="$(wget -O - "${MAKEFILE_BASE_PATH}" | grep "^VERSION " | awk -F "=" '{print $2}' | sed -e 's@ @@g' 2>/dev/null)"
}

if [ -z "${OPERATOR_SDK_RELEASE_VERSION}" ]; then
  echo "INFO: operator-sdk release version is not set. Defaulting to ${OPERATOR_SDK_DEFAULT_RELEASE_VERSION}"
  OPERATOR_SDK_RELEASE_VERSION="${OPERATOR_SDK_DEFAULT_RELEASE_VERSION}"
fi

if [ -z "${TIMEOUT}" ]; then
  echo "INFO: using default timeout: ${DEFAULT_TIMEOUT}"
  TIMEOUT="${DEFAULT_TIMEOUT}"
fi

if [ -z "${BUNDLE_IMG}" ]; then
  echo "INFO: using default bundle image: ${DEFAULT_BUNDLE_IMG}"
  BUNDLE_IMG="${DEFAULT_BUNDLE_IMG}"
fi

if [ -z "${BUNDLE_VERSION}" ]; then
  guess_version
  echo "INFO: using Makefile bundle image: ${BUNDLE_VERSION}"
  BUNDLE_VERSION="${MAKE_BUNDLE_VERSION}"
fi

BUNDLE_IMG_VERSION="${BUNDLE_IMG}:v${BUNDLE_VERSION}"

curl -L -o "$(pwd)/operator-sdk" "https://github.com/operator-framework/operator-sdk/releases/download/${OPERATOR_SDK_RELEASE_VERSION}/operator-sdk_linux_amd64"
chmod +x "$(pwd)/operator-sdk"
"$(pwd)"/operator-sdk olm install --timeout "${TIMEOUT}"
"$(pwd)"/operator-sdk run bundle --timeout "${TIMEOUT}" "${BUNDLE_IMG_VERSION}"
"$(pwd)"/operator-sdk scorecard "${BUNDLE_IMG_VERSION}"

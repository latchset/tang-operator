#!/bin/bash
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

curl -L -o "$(pwd)/operator-sdk" "https://github.com/operator-framework/operator-sdk/releases/download/${OPERATOR_SDK_RELEASE_VERSION}/operator-sdk_linux_amd64"
chmod +x "$(pwd)/operator-sdk"
"$(pwd)"/operator-sdk olm install --timeout "${TIMEOUT}"
"$(pwd)"/operator-sdk run bundle --timeout "${TIMEOUT}" "${BUNDLE_IMG}:v${BUNDLE_VERSION}"
"$(pwd)"/operator-sdk scorecard "${BUNDLE_IMG}"

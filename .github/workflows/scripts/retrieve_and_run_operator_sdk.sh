#!/bin/bash
set -x

OPERATOR_SDK_DEFAULT_RELEASE_VERSION="v1.10.1"
DEFAULT_BUNDLE_IMG="quay.io/sarroutb/tang-operator-bundle:latest"
DEFAULT_TIMEOUT="5m"

OPERATOR_SDK_RELEASE_VERSION="${1}"
BUNDLE_IMG="${2}"
TIMEOUT="${3}"

if [ -z "${OPERATOR_SDK_RELEASE_VERSION}" ]; then
  echo "INFO: operator-sdk release version is not set. Defaulting to ${OPERATOR_SDK_DEFAULT_RELEASE_VERSION}"
  OPERATOR_SDK_RELEASE_VERSION="${OPERATOR_SDK_DEFAULT_RELEASE_VERSION}"
fi

if [ -z "${BUNDLE_IMG}" ]; then
  echo "INFO: using default bundle image: ${DEFAULT_BUNDLE_IMG}"
  BUNDLE_IMG="${DEFAULT_BUNDLE_IMAGE}"
fi

if [ -z "${TIMEOUNT}" ]; then
  echo "INFO: using default timeout: ${DEFAULT_TIMEOUT}"
  TIMEOUT="${DEFAULT_TIMEOUT}"
fi

echo "PWD:$(pwd)"

curl -L -o "$(pwd)/operator-sdk" "https://github.com/operator-framework/operator-sdk/releases/download/${OPERATOR_SDK_RELEASE_VERSION}/operator-sdk_linux_amd64"
chmod +x "$(pwd)/operator-sdk"
echo "PWD:$(pwd)"
echo "LS:$(ls $(pwd))"
$(pwd)/operator-sdk olm install --timeout "${TIMEOUT}"
$(pwd)/operator-sdk run bundle --timeout "${TIMEOUT}" "${BUNDLE_IMG}"

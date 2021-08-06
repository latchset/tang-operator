#!/bin/bash
set -x

OPERATOR_SDK_DEFAULT_RELEASE_VERSION="v1.8.2"

OPERATOR_SDK_RELEASE_VERSION="${1}"

if [ -z "$OPERATOR_SDK_RELEASE_VERSION" ]; then
  echo "INFO: operator-sdk release version is not set. Defaulting to ${OPERATOR_SDK_DEFAULT_RELEASE_VERSION}"
  OPERATOR_SDK_RELEASE_VERSION="${OPERATOR_SDK_DEFAULT_RELEASE_VERSION}"
fi

curl -L -o /operator-sdk "https://github.com/operator-framework/operator-sdk/releases/download/${OPERATOR_SDK_RELEASE_VERSION}/operator-sdk_linux_amd64"

chmod +x /operator-sdk

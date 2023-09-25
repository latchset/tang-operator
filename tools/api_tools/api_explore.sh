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
# Uncomment next line to dump verbose information in script execution:
# set -x

DEFAULT_K8SC="oc"
test -z "${K8SC}" && K8SC=${DEFAULT_K8SC}

DEFAULT_SA="api-explorer"
test -z "${SA}" && SA=${DEFAULT_SA}

DEFAULT_NAMESPACE="nbde"
test -z "${NAMESPACE}" && NAMESPACE=${DEFAULT_NAMESPACE}

DEFAULT_POD_COMMAND="hostname"
test -z "${POD_COMMAND}" && POD_COMMAND=${DEFAULT_POD_COMMAND}

CLUSTERROLE_FILE=$(mktemp)
CART_FILE=$(mktemp)
CLUSTERROLE_NAME=key-reader

dumpInfo() {
    echo "K8SC:${K8SC}"
    echo "POD_COMMAND:${POD_COMMAND}"
    echo "SA:${SA}"
    echo "PODNAME:${PODNAME}"
    echo "SERVICENAME:${SERVICENAME}"
    echo "NAMESPACE:${NAMESPACE}"
    echo "CLUSTERROLE_FILE:${CLUSTERROLE_FILE}"
    echo "CLUSTERROLE_NAME:${CLUSTERROLE_NAME}"
    echo "CART_FILE=${CART_FILE}"
}

installDeps() {
    type jq || yum install -y jq
}

guessPodName() {
    ${K8SC} -n "${NAMESPACE}" get pods | tail -1 | awk '{print $1}'
}

guessServiceName() {
    ${K8SC} -n "${NAMESPACE}" get service | tail -1 | awk '{print $1}'
}

auth_curl() {
    curl --verbose --include \
         --no-buffer \
         --header "Connection: Upgrade" \
         --header "Upgrade: websocket" \
         --header "Host: example.com:80" \
         --header "Origin: http://example.com:80" \
         --header "Sec-WebSocket-Key: SGVsbG8sIHdvcmxkIQ==" \
         --header "Sec-WebSocket-Version: 13" \
         --header "Authorization: Bearer ${TOKEN}" \
         -s --cacert "${CART_FILE}" "${1}"
}

test -z "${PODNAME}" && PODNAME=$(guessPodName)
test -z "${SERVICENAME}" && SERVICENAME=$(guessServiceName)

dumpInfo
installDeps

### Delete previous executions
${K8SC} -n "${NAMESPACE}" delete serviceaccount "${SA}"
### Create specific service account
${K8SC} -n "${NAMESPACE}" create serviceaccount "${SA}"
### Dump appropriate info to clusterrole
cat <<EOF >>"${CLUSTERROLE_FILE}"
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: ${CLUSTERROLE_NAME}
  namespace: ${NAMESPACE}
rules:
- apiGroups: [""] # "" indicates the core API group
  resources: ["pods", "pods/log", "pods/exec", "pods/status", "services", "services/status"]
  verbs: ["get", "watch", "list"]
EOF

### Delete existing clusterrole
${K8SC} -n "${NAMESPACE}" delete -f "${CLUSTERROLE_FILE}"

### Create clusterrole
${K8SC} -n "${NAMESPACE}" apply -f "${CLUSTERROLE_FILE}"

### Delete previous rolebinding
${K8SC} -n "${NAMESPACE}" delete rolebinding "${SA}:${CLUSTERROLE_NAME}"

### Bind clusterrole to service account
${K8SC} -n "${NAMESPACE}" create rolebinding "${SA}:${CLUSTERROLE_NAME}" --clusterrole "${CLUSTERROLE_NAME}" --serviceaccount "${NAMESPACE}:${SA}"

### Get the ServiceAccount's token Secret's name
SECRET=$(${K8SC} -n "${NAMESPACE}" get serviceaccount "${SA}" -o json | jq -Mr '.secrets[].name')

### Extract the Bearer token from the Secret and decode
TOKEN=$(${K8SC} -n "${NAMESPACE}" get secret "${SECRET}" -o json | jq -Mr '.data.token' | base64 -d)

### Extract, decode and write the ca.crt to a temporary location
${K8SC} -n "${NAMESPACE}" get secret "${SECRET}" -o json | jq -Mr '.data["ca.crt"]' | base64 -d > "${CART_FILE}"

### Get the API Server location
APISERVER=https://$("${K8SC}" -n default get endpoints kubernetes --no-headers | awk '{ print $2 }')

### Test API
echo "---Test API---"
${K8SC} "/openapi/v2"
echo "---Test API---"

### Extract logs from pod
echo "---Extract logs from pod---"
${K8SC} get --raw "/api/v1/namespaces/${NAMESPACE}/pods/${PODNAME}/log"
echo "---Extract logs from pod---"

### Extract status of pod
echo "---Extract status of pod---"
${K8SC} get --raw "${APISERVER}/api/v1/namespaces/${NAMESPACE}/pods/${PODNAME}/status"
echo "---Extract status of pod---"

### Command execution
echo "---Command execution---"
${K8SC} get --raw "/api/v1/namespaces/${NAMESPACE}/pods/${PODNAME}/exec?command=/bin/bash&command=-c&command=${POD_COMMAND}&stdin=true&stderr=true&stdout=true&tty=true"
echo "---Command execution---"

### Extract status of service
echo "---Extract status of service---"
${K8SC} get --raw "/api/v1/namespaces/${NAMESPACE}/services/${SERVICENAME}/status"
echo "---Extract status of service---"

rm "${CLUSTERROLE_FILE}"
rm "${CART_FILE}"

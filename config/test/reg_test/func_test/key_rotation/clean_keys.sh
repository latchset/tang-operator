#!/bin/bash
OSH_CLIENT="oc"
KR_NAMESPACE="nbde"

function get_pod() {
  "${OSH_CLIENT}" -n "${KR_NAMESPACE}" get pods | tail -1 | awk '{print $1}'
}

KR_POD=$(get_pod)
echo "KR_POD=${KR_POD}"

"${OSH_CLIENT}" -n ${KR_NAMESPACE} exec -it "${KR_POD}" -- /bin/bash -c 'cd /var/db/tang; rm ./*'

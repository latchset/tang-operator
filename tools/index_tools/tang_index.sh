#!/bin/bash
# Parameters:
# 1 - sync image to quay.io/<repository>/ or registry-proxy.engineering.redhat.com/rh-osbs/tang-operator-bundle@sha256:fceb6d82cea8fd14be1b0ebc0333d314ec5bd2c88199c0aa63377d12c6f4db6e
# 2 - two parameters, $1 is for bundle; $2 is for release, format like 0.0.25-1
# Example:
# $0 "registry-proxy.engineering.redhat.com/rh-osbs/tang-operator-bundle:0.2.0-6"
# ./tang_index.sh registry-proxy.engineering.redhat.com/rh-osbs/tang-operator-bundle@sha256:a69a44c15bb0ca40a382dcd551f2e7ed06fe8ae8007df55feeeb8a1c33de6e7d 0.2.0-6
#
#
CONTAINER_MGR='docker'

usage() {
###    echo './tang_index.sh registry-proxy.engineering.redhat.com/rh-osbs/tang-operator-bundle@sha256:a69a44c15bb0ca40a382dcd551f2e7ed06fe8ae8007df55feeeb8a1c33de6e7d 0.2.0-6'
    echo './tang_index.sh quay.io/sec-eng-special/tang-operator-bundle:v0.2.0-6 0.2.0-6'
    exit "$2"
}

while getopts "h" arg
do
  case "${arg}" in
    h) usage "$0" 0
       ;;
    *) usage "$0" 1
       ;;
  esac
done

CO_image_with_digest=$1
version=$2
  
digest=$(echo "${CO_image_with_digest}" | awk -F: '{print $2}')
sub_digest="${digest:0:12}"
     
"${CONTAINER_MGR}" login quay.io -u sarroutb
echo "sub_digest:${sub_digest}"

#1. Mirror bundle container image
echo -e "step 1 \n\n"

oc image mirror --filter-by-os=".*" --keep-manifest-list "${CO_image_with_digest}" quay.io/sec-eng-special/tang-operator-bundle-container:"${sub_digest}"
oc image mirror --filter-by-os=".*" --keep-manifest-list "${CO_image_with_digest}" quay.io/sec-eng-special/tang-operator-bundle-container:latest

#2.  Build index image
echo -e "step 2 \n\n"
opm index add --bundles "${CO_image_with_digest}" --tag quay.io/sec-eng-special/tang-operator-index:v"${version}" -c ${CONTAINER_MGR}

#3. Push image index to quay.io/sec-eng-special/
echo -e "step 3 \n\n"
echo -e "${CONTAINER_MGR} push quay.io/sec-eng-special/tang-operator-index:v$version \n"
${CONTAINER_MGR} push quay.io/sec-eng-special/tang-operator-index:v"${version}"

#4. Substitute version in catalog source
sed -e "s@VERSION_HERE@v${version}@g" < tang_catalog_source_template.yaml > tang_catalog_source.yaml

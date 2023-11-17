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
OPTIND=1
OLD_VERSION=""
NEW_VERSION=""
NOV_OLD_VERSION=""
NOV_NEW_VERSION=""
README_PATH="../README.md"
VERBOSE=""

function usage() {
  echo ""
  echo "$1 -o old_version -n new_version [-f README.md]"
  echo ""
  echo "Example: $1 -o v0.0.25 -n v0.0.26"
  echo ""
  exit "$2"
}

while getopts "o:n:f:hv" arg
do
  case "${arg}" in
    o) OLD_VERSION=${OPTARG}
       ;;
    n) NEW_VERSION=${OPTARG}
       ;;
    f) README_PATH=${OPTARG}
       ;;
    v) VERBOSE="YES"
       ;;
    h) usage "$0" 0
       ;;
    *) usage "$0" 1
       ;;
  esac
done

if [ -z "${OLD_VERSION}" ] || [ -z "${NEW_VERSION}" ];
then
  usage "$0" 1
fi

if [ "${VERBOSE}" = "YES" ];
then
  echo "OLD_VERSION=${OLD_VERSION}"
  echo "NEW_VERSION=${NEW_VERSION}"
  echo "README_PATH=${README_PATH}"
  echo "VERBOSE=${VERBOSE}"
fi

# Substitution
sed -i "s/${OLD_VERSION}/${NEW_VERSION}/g" "${README_PATH}"

# Remove also references to "non-v" versions
NOV_OLD_VERSION=$(echo "${OLD_VERSION}" | tr -d 'v')
NOV_NEW_VERSION=$(echo "${NEW_VERSION}" | tr -d 'v')
sed -i "s/${NOV_OLD_VERSION}/${NOV_NEW_VERSION}/g" "${README_PATH}"

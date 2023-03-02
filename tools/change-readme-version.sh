#!/bin/bash
#
# Copyright 2022 sarroutb@redhat.com
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom
# the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
# OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
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

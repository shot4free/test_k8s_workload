#!/bin/bash

set -o pipefail

echo 'Running kubeval validations...'

if ! [[ -x "$(command -v kubeval)" ]]; then
  echo 'Error: kubeval is not installed.' >&2
  exit 1
fi

# Inspect code using kubeval
# Skip CRD's because they are custom
# https://github.com/instrumenta/kubeval/pull/127
find ./output \( -name '*.yaml' -not -name '*-crd.yaml' \) -print0  | xargs --null kubeval

status_code=$?

if [[ $status_code != 0 ]]; then
  echo
  echo 1>&2 'Static analysis found violations that need to be fixed.'
  exit 1
else
  echo
  echo 'Static analysis found no problems.'
fi

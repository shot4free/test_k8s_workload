#!/bin/bash

set -euo pipefail

prog_name=${0}

usage() {
  echo -e "\\nUsage:\\n${prog_name} [environment]\\n"
}

tmp_dir=$(mktemp -d "${TEMPDIR:-./tmp}.XXXXXXXXX")
chart_version=$(cat GITLAB_CHARTS_VERSION)
environment=${1-nil}

if [[ ${environment} == "nil" ]]; then
  echo "You must supply an Environment"
  usage
  exit 1
fi

set -x

git clone https://gitlab.com/charts/gitlab.git "${tmp_dir}"
pushd "${tmp_dir}"
git checkout "${chart_version}"

helm dependency update

helm template . \
  --namespace gitlab \
  --name gitlab \
  --values ../values.yaml \
  --values "../${environment}.yaml" \
  --output-dir "../output/${environment}"

popd
rm -rf "${tmp_dir}"

set +x

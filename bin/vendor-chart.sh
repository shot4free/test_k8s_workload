#!/bin/bash

set -euo pipefail

function vendor_chart() {
  SHA=$(yq eval "explode(...) | .environments.${ENVIRONMENT}.values[0] * .environments.${ENVIRONMENT}.values[1] | .$(echo "${CHART}" | tr '-' '_')_chart_version" bases/environments.yaml)
  if [ -d charts/"${CHART}"/"${ENVIRONMENT}" ]; then
    rm -rf charts/"${CHART}"/"${ENVIRONMENT}"
  fi
  git clone git@dev.gitlab.org:gitlab/charts/"${CHART}".git charts/"${CHART}"/"${ENVIRONMENT}"
  pushd charts/"${CHART}"/"${ENVIRONMENT}"
  git -c advice.detachedHead=false checkout "${SHA}"
  helm dep update
  rm -rf .git requirements.lock spec
  if [[ -d charts ]]; then
    git add -f charts/*.tgz
  fi
  # This will go away once https://github.com/helm/helm/pull/8499 is merged
  popd
}

usage() {
  cat <<EOF
$0: Vendor a chart in a specific environment to a specific version. You must give
this tool the chart to vendor, and the environment to vendor for. The SHA is taken
from the 'helmfile' 'bases/environments.yaml' with the variable '<env>_chart_version'
for the environment in question.

USAGE:
$0 chart environment

e.g. $0 gitlab gstg
EOF
}

main() {

  if [[ $# -ne 2 ]]; then
    usage
    exit 1
  else
    CHART=${1}
    ENVIRONMENT=${2}
    vendor_chart
  fi

}

main "$@"

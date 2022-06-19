#!/bin/bash

set -euo pipefail

bump_chart() {
  # Get current chart ver for environment
  ENV_CHART_VER=$(yq e ".directories[0].contents[] | select(.path == \"gitlab/${ENVIRONMENT}\").git.ref" vendir.yml)

  # Get chart version from dev.gitlab.org
  UPSTREAM_VER=$(git ls-remote git@dev.gitlab.org:gitlab/charts/gitlab.git HEAD | awk '{ print $1}')

  if [[ ${ENV_CHART_VER} != "${UPSTREAM_VER}" ]]; then
    yq -i e ".directories[0].contents |= map(select(.path == \"gitlab/${ENVIRONMENT}\").git.ref = \"${UPSTREAM_VER}\")" vendir.yml
    vendir sync
    git checkout -b "${ENVIRONMENT}-chart-bump-${UPSTREAM_VER}"
    git add vendir.yml vendir.lock.yml
    git add "vendor/charts/gitlab/${ENVIRONMENT}"
    git commit -m "Bump to Gitlab chart ${UPSTREAM_VER} in ${ENVIRONMENT}

Changes can be viewed at

https://gitlab.com/gitlab-org/charts/gitlab/-/compare/${ENV_CHART_VER}...${UPSTREAM_VER}"
    glab mr create -f -y --squash-before-merge --remove-source-branch --push -a ggillies -a skarbek -a ahyield -l "automation:bot-authored"
  fi
}

usage() {
  cat <<EOF
$0: Automatically looks for the latest version of the Gitlab chart in git and
opens a merge request for the specified environment to bump the chart to
that version.

USAGE:
$0 environment

e.g. $0 gstg
EOF
}

main() {

  if [[ $# -ne 1 ]]; then
    usage
    exit 1
  else
    ENVIRONMENT=${1}
    bump_chart
  fi

}

main "$@"

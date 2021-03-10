#!/bin/bash

set -euo pipefail

FILENAME="archive.zip"

function build() {
  CLONE_DIR=$(mktemp -d -p "$(pwd)")
  git clone --no-checkout "git@dev.gitlab.org:gitlab/charts/gitlab.git" "$CLONE_DIR"
  cd "$CLONE_DIR"
  git -c advice.detachedHead=false checkout "$CHART_VERSION"
  git rev-parse --verify HEAD
  helm package ./ --dependency-update --version "0.0.0+${CHART_VERSION}" --destination ../
}

function verify_download() {
  unzip "$FILENAME"

  if [[ -e "gitlab-0.0.0+${CHART_VERSION}.tgz" ]]; then
    echo "The appropriate chart build exists, no need to build"
    exit 0
  else
    echo "Expected Chart Version: $CHART_VERSION, but did not find it, will trigger a build..."
    ls -lah -- *.tgz
    build
  fi
}

result=$(curl \
  --location \
  --silent \
  --write-out '%{http_code}' \
  --output "$FILENAME" \
  --header "JOB-TOKEN: $CI_JOB_TOKEN" \
  "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/jobs/artifacts/${CI_DEFAULT_BRANCH}/download?job=build-chart")

if [[ "$result" != "200" ]]; then
  echo "We failed to download the archive, we'll need to build it."
  echo "HTTP Status: ${result}"
  build
else
  echo "Sucessfully downloaded an archive."
  verify_download
fi

#!/bin/bash

set -euo pipefail

tmpdir=$(mktemp -d)
cp -ar . "${tmpdir}"
pushd "${tmpdir}"
for i in gitlab gitlab-runner; do
  for j in charts/"${i}"/*; do
    ./bin/vendor-chart.sh "${i}" "$(basename -- "${j}")"
    if [[ $(diff -r "${j}" "${tmpdir}"/"${j}") ]]; then
      echo "Chart ${i} for environment ${j} is not the same as upstream"
      exit 1
    fi
  done
done
popd
rm -rf "${tmpdir}"

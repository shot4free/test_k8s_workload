#!/bin/bash

set -uo pipefail

tmpdir=$(mktemp -d)
cp -ar . "${tmpdir}"
for i in gitlab gitlab-runner; do
  for j in charts/"${i}"/*; do
    pushd "${tmpdir}" || exit 4
    ./bin/vendor-chart.sh "${i}" "$(basename -- "${j}")"
    popd || exit 4
    diff -r "${j}" "${tmpdir}"/"${j}"
    DIFFCODE=$?
    if [[ ${DIFFCODE} -ne 0 ]]; then
      echo "Chart ${i} for environment ${j} is not the same as upstream"
      rm -rf "${tmpdir}"
      exit 1
    fi
  done
done
rm -rf "${tmpdir}"

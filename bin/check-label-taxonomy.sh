#!/bin/bash

missingLabelManifests=""

while IFS= read -r -d '' file; do
  if [[ "$(yq <"$file" '.metadata.labels.type, .metadata.labels.tier, .metadata.labels.stage, .metadata.labels.shard')" == *"null"* ]]; then
    missingLabelManifests="$missingLabelManifests $file"
  fi
done < <(find manifests -name "*.yaml" -type f -print0)

if [ -n "${missingLabelManifests}" ]; then
  echo "There are resources without proper labels (labels.type|tier|stage|shard) and the following are the manifests that got generated without them."
  for manifest in $missingLabelManifests; do
    echo "${manifest}"
  done
  exit 1
fi

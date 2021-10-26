#!/bin/bash

NAMESPACE=${1}
KCTL_PID=$PPID

while [[ $(helm -n gitlab status -o json gitlab | jq -r .info.status) == "deployed" ]]; do
  if ! ps -p "${KCTL_PID}" >/dev/null; then
    exit
  fi
  sleep 1
done
sleep 60
kubectl -n "${NAMESPACE}" get deployment -o name | xargs -P0 -L1 kubectl -n "${NAMESPACE}" rollout status

#!/usr/bin/env bash

HELM_OPTS_VALUES+=(
    "-f" "values.yaml"
    "-f" "pre.yaml"
)

if [[ -z ${CI_JOB_ID:-} ]]; then
    if ! pre_checks; then
        usage
        exit 1
    fi

    # If running locally, use kubectx to switch to the correct
    # kubectl context
    switch_kubectx
fi

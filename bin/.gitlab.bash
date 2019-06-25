#!/usr/bin/env bash


update_gitlab_chart() {
    set -e
    local charts_dir
    charts_dir=$1
    pushd "${charts_dir}"
    set -x
    git clone -b "${GITLAB_CHART_BRANCH:-master}" https://gitlab.com/charts/gitlab.git "$charts_dir" >/dev/null
    helm dependency update >/dev/null
    popd
}



if [[ -z ${CI_JOB_ID:-} ]]; then
    if ! pre_checks; then
        usage
        exit 1
    fi

    # If running locally, use kubectx to switch to the correct
    # kubectl context
    switch_kubectx
fi

CHART="${CHART:-gitlab}"
NAME="${NAME:-gitlab}"
NAMESPACE="${NAMESPACE:-gitlab}"
HELM_OPTS_VALUES+=(
    "-f" "$dir/../values.yaml"
    "-f" "$dir/../$ENV.yaml"
    "--namespace" "$NAMESPACE"
)
KUBECTL_OPTS+=(
    "-n" "$NAMESPACE"
)

echo "Validating secrets.."
for secret in registry-certificate registry-httpsecret; do
    if ! kubectl get secrets -n "$NAMESPACE" $secret >/dev/null; then
        echo "Secret \"$secret\" is not yet set, are secrets configured properly?"
        exit 1
    fi
done

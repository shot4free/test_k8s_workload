#!/usr/bin/env bash
##############################
# Common checks and variables needed by the
# install/remove/upgrade scripts

usage() {
    cat <<-EOF
    Usage $0 [-e <environment>] [-D] -- [extra opts]

        Examples:
                $0 -e pre
                $0 -e gstg
                $0 -e pre -D # dry-run mode

        extra opts: additional options that you want
                    to pass to the helm command
	EOF
}

while getopts ":e:D" o; do
    case "${o}" in
        e)
            environment=${OPTARG}
            ;;
        D)
            dry_run="true"
            ;;
        *)
            ;;
    esac
done
shift $((OPTIND-1))

ENV="${environment:-${CI_ENVIRONMENT_NAME:-}}"
if [[ -z $ENV ]]; then
    usage
    exit 1
fi

if [[ -z ${CI_JOB_ID:-} ]]; then
    url="https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/common/raw/master/bin/common.bash"
    echo "Fetching and sourcing common functions from $url"
    tmpfile=$(mktemp)
    curl -s "$url" > "$tmpfile"
    source "$tmpfile"
    rm -f "$tmpfile"
else
    source "/k8s-workloads/common.bash"
fi


PROJECT=${PROJECT:-$(get_project "$ENV")}
DRY_RUN="${dry_run:-}"
CLUSTER="${CLUSTER:-$ENV-gitlab-gke}"
REGION="${REGION:-us-east1}"

## Setup options for helm tiller and kubectl

HELM_OPTS=()
KUBECTL_OPTS=()

if [[ -n $DRY_RUN ]]; then
    HELM_OPTS+=('--dry-run')
HELM_OPTS=()

if [[ -n $DRY_RUN ]]; then
    HELM_OPTS+=('--dry-run')
fi



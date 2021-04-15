#!/bin/bash -x
# vim: ai:ts=2:sw=2:et

set -ef -o pipefail

ACTION="${1}"

enable() {
  echo "Enabling Gitlab.com access"
  cp /etc/hosts ~/hosts.new
  sed -i '/gitlab/d' ~/hosts.new
  cp -f ~/hosts.new /etc/hosts
}

disable() {
  echo "Disabling Gitlab.com access"
  echo -e "127.0.0.1  gitlab.com\\n127.0.0.1  registry.gitlab.com\\n127.0.0.1  charts.gitlab.io" >>/etc/hosts
}

usage() {
  echo "Usage:"
  echo "${0} [enable|disable]"
  echo "This tool is used in CI jobs for enabling/disabling access"
  echo "to specific Gitlab.com domains in order to test pipeline"
  echo "dependance on Gitlab.com"
}

ping_gitlab() {
  ping -c4 gitlab.com
  ping -c4 registry.gitlab.com
  ping -c4 charts.gitlab.io
}

if [[ -z ${GITLAB_ACCESS_DISABLE} || -z ${ARTIFACT_AVAILABLE} ]]; then
  echo "env var GITLAB_ACCESS_DISABLE not set or artifact not available (ARTIFACT_AVAILABLE is unset), Gitlab.com access is OPEN"
else
  case "${ACTION}" in
    enable)
      enable
      ping_gitlab
      ;;
    disable)
      disable
      ping_gitlab
      ;;
    *)
      usage
      ;;
  esac
fi

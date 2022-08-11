{
  'check-vendored-charts': {
    image: '${CI_REGISTRY}/gitlab-com/gl-infra/k8s-workloads/common/k8-helm-ci:${CI_IMAGE_VERSION}',
    stage: 'check',
    script: |||
      chmod 400 "$SSH_PRIVATE_KEY"
      export GIT_SSH_COMMAND="ssh -i $SSH_PRIVATE_KEY -o IdentitiesOnly=yes -o GlobalKnownHostsFile=$SSH_KNOWN_HOSTS"
      vendir sync
      for i in pre gstg gprd;do pushd vendor/charts/gitlab/$i;helm dep update;popd;done
      git diff --exit-code vendor || (echo "Charts in this commit are not the same as upstream" >&2 && exit 1)
    |||,
    rules: [
      {
        'if': '$AUTO_DEPLOY == "true"',
        when: 'never',
      },
      {
        'if': '$CI_COMMIT_REF_NAME == "master"',
        when: 'never',
      },
      {
        'if': '$CI_PIPELINE_SOURCE == "schedule"',
        when: 'never',
      },
      {
        'if': '$CI_API_V4_URL == "https://ops.gitlab.net/api/v4"',
        when: 'never',
      },
      {
        when: 'always',
      },
    ],
  },
}

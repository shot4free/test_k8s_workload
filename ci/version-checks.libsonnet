{
  assert_consistent_tool_versions: {
    stage: 'check',
    image: '${CI_REGISTRY}/gitlab-com/gl-infra/k8s-workloads/common/k8-helm-ci:${CI_IMAGE_VERSION}',
    script: '/k8s-workloads/assert-tool-versions.sh',
    allow_failure: true,
    rules: [
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
        when: 'on_success',
      },
    ],
  },
}

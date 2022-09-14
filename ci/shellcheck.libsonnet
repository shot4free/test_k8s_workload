{
  shellcheck: {
    image: {
      name: 'koalaman/shellcheck-alpine:v0.8.0',
      entrypoint: [
        '/bin/sh',
        '-c',
      ],
    },
    stage: 'check',
    script: [
      'find bin/ -maxdepth 1 -type f | xargs -r shellcheck -e SC1090,SC1091',
    ],
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
        when: 'on_success',
      },
    ],
  },
  shfmt: {
    image: {
      name: 'mvdan/shfmt:v3.5.1-alpine',
      entrypoint: [
        '/bin/sh',
        '-c',
      ],
    },
    stage: 'check',
    script: [
      'find bin/ -maxdepth 1 -type f | xargs -r shfmt -i 2 -ci -l -d',
    ],
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
        when: 'on_success',
      },
    ],
  },
  tooling: {
    image: '${CI_REGISTRY}/gitlab-com/gl-infra/k8s-workloads/common/k8-helm-ci:${CI_IMAGE_VERSION}',
    stage: 'check',
    script: [
      'bin/k-ctl -t',
    ],
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
        when: 'on_success',
      },
    ],
  },
}

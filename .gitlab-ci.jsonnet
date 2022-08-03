local stages = {
  stages: [
    'check',
    'dryrun-check',
    'dryrun',
    'non-prod-cny:deploy',
    'non-prod:deploy',
    'non-prod:QA',
    'gprd-cny:deploy',
    'gprd:deploy:alpha',
    'gprd:deploy:beta',
    'cleanup',
    'scheduled',
  ],
};

local includes = {
  include: [
    '/ci/except-ops.yml',
    '/ci/cluster-init-before-script.yml',
    '/ci/shellcheck.yml',
    '/ci/version-checks.yml',
    '/ci/check-vendored-charts.yml',
    // Dependency scanning
    // https://docs.gitlab.com/ee/user/application_security/dependency_scanning/
    { template: 'Security/Dependency-Scanning.gitlab-ci.yml' },
  ],
};

local exceptCom = {
  except+: {
    variables+: [
      '$CI_API_V4_URL == "https://gitlab.com/api/v4"',
    ],
  },
};

local exceptOps = {
  except+: {
    variables+: [
      '$CI_API_V4_URL == "https://ops.gitlab.net/api/v4"',
    ],
  },
};

local variables = {
  variables: {
    CI_IMAGE_VERSION: 'v15.4.0',
    AUTO_DEPLOY: 'false',
  },
};

local mainRegion = 'us-east1';

local clusterAttrs = {
  pre: {
    GOOGLE_PROJECT: 'gitlab-pre',
    GKE_CLUSTER: 'pre-gitlab-gke',
    GOOGLE_REGION: mainRegion,
  },
  gstg: {
    GOOGLE_PROJECT: 'gitlab-staging-1',
    GKE_CLUSTER: 'gstg-gitlab-gke',
    GOOGLE_REGION: mainRegion,
  },
  'gstg-us-east1-b': {
    ENVIRONMENT: 'gstg',
    GOOGLE_PROJECT: 'gitlab-staging-1',
    GKE_CLUSTER: 'gstg-us-east1-b',
    GOOGLE_ZONE: 'us-east1-b',
  },
  'gstg-us-east1-c': {
    ENVIRONMENT: 'gstg',
    GOOGLE_PROJECT: 'gitlab-staging-1',
    GKE_CLUSTER: 'gstg-us-east1-c',
    GOOGLE_ZONE: 'us-east1-c',
  },
  'gstg-us-east1-d': {
    ENVIRONMENT: 'gstg',
    GOOGLE_PROJECT: 'gitlab-staging-1',
    GKE_CLUSTER: 'gstg-us-east1-d',
    GOOGLE_ZONE: 'us-east1-d',
  },
  gprd: {
    GOOGLE_PROJECT: 'gitlab-production',
    GKE_CLUSTER: 'gprd-gitlab-gke',
    GOOGLE_REGION: mainRegion,
  },
  'gprd-us-east1-b': {
    ENVIRONMENT: 'gprd',
    GOOGLE_PROJECT: 'gitlab-production',
    GKE_CLUSTER: 'gprd-us-east1-b',
    GOOGLE_ZONE: 'us-east1-b',
  },
  'gprd-us-east1-c': {
    ENVIRONMENT: 'gprd',
    GOOGLE_PROJECT: 'gitlab-production',
    GKE_CLUSTER: 'gprd-us-east1-c',
    GOOGLE_ZONE: 'us-east1-c',
  },
  'gprd-us-east1-d': {
    ENVIRONMENT: 'gprd',
    GOOGLE_PROJECT: 'gitlab-production',
    GKE_CLUSTER: 'gprd-us-east1-d',
    GOOGLE_ZONE: 'us-east1-d',
  },
};

local baseCiConfigs = {
  '.pre-base': {
    variables: {
      PROJECT: clusterAttrs.pre.GOOGLE_PROJECT,
      REGION: clusterAttrs.pre.GOOGLE_REGION,
    },
    environment: {
      name: 'pre',
      url: 'https://pre.gitlab.com',
    },
  },
  '.pre': {
    extends: [
      '.pre-base',
    ],
    variables: {
      CLUSTER: clusterAttrs.pre.GKE_CLUSTER,
    },
    environment: {
      name: 'pre',
    },
    resource_group: 'pre',
  },
  '.gstg-base': {
    variables: {
      PROJECT: clusterAttrs.gstg.GOOGLE_PROJECT,
    },
    environment: {
      url: 'https://staging.gitlab.com',
    },
  },
  '.gstg': {
    extends: [
      '.gstg-base',
    ],
    variables: {
      CLUSTER: clusterAttrs.gstg.GKE_CLUSTER,
      REGION: clusterAttrs.gstg.GOOGLE_REGION,
    },
    environment: {
      name: 'gstg',
    },
    resource_group: 'gstg',
  },
  '.gstg-us-east1-b': {
    extends: [
      '.gstg-base',
    ],
    variables: {
      CLUSTER: clusterAttrs['gstg-us-east1-b'].GKE_CLUSTER,
      REGION: clusterAttrs['gstg-us-east1-b'].GOOGLE_ZONE,
    },
    environment: {
      name: 'gstg-us-east1-b',
    },
    resource_group: 'gstg-us-east1-b',
  },
  '.gstg-us-east1-c': {
    extends: [
      '.gstg-base',
    ],
    variables: {
      CLUSTER: clusterAttrs['gstg-us-east1-c'].GKE_CLUSTER,
      REGION: clusterAttrs['gstg-us-east1-c'].GOOGLE_ZONE,
    },
    environment: {
      name: 'gstg-us-east1-c',
    },
    resource_group: 'gstg-us-east1-c',
  },
  '.gstg-us-east1-d': {
    extends: [
      '.gstg-base',
    ],
    variables: {
      CLUSTER: clusterAttrs['gstg-us-east1-d'].GKE_CLUSTER,
      REGION: clusterAttrs['gstg-us-east1-d'].GOOGLE_ZONE,
    },
    environment: {
      name: 'gstg-us-east1-d',
    },
    resource_group: 'gstg-us-east1-d',
  },
  '.gprd-base': {
    variables: {
      PROJECT: clusterAttrs.gprd.GOOGLE_PROJECT,
    },
    environment: {
      url: 'https://gitlab.com',
    },
  },
  '.gprd': {
    extends: [
      '.gprd-base',
    ],
    variables: {
      CLUSTER: clusterAttrs.gprd.GKE_CLUSTER,
      REGION: clusterAttrs.gprd.GOOGLE_REGION,
    },
    environment: {
      name: 'gprd',
    },
    resource_group: 'gprd',
  },
  '.gprd-us-east1-b': {
    extends: [
      '.gprd-base',
    ],
    variables: {
      CLUSTER: clusterAttrs['gprd-us-east1-b'].GKE_CLUSTER,
      REGION: clusterAttrs['gprd-us-east1-b'].GOOGLE_ZONE,
    },
    environment: {
      name: 'gprd-us-east1-b',
    },
    resource_group: 'gprd-us-east1-b',
  },
  '.gprd-us-east1-c': {
    extends: [
      '.gprd-base',
    ],
    variables: {
      CLUSTER: clusterAttrs['gprd-us-east1-c'].GKE_CLUSTER,
      REGION: clusterAttrs['gprd-us-east1-c'].GOOGLE_ZONE,
    },
    environment: {
      name: 'gprd-us-east1-c',
    },
    resource_group: 'gprd-us-east1-c',
  },
  '.gprd-us-east1-d': {
    extends: [
      '.gprd-base',
    ],
    variables: {
      CLUSTER: clusterAttrs['gprd-us-east1-d'].GKE_CLUSTER,
      REGION: clusterAttrs['gprd-us-east1-d'].GOOGLE_ZONE,
    },
    environment: {
      name: 'gprd-us-east1-d',
    },
    resource_group: 'gprd-us-east1-d',
  },
  '.only-auto-deploy-false': {
    only: {
      variables: [
        '$AUTO_DEPLOY == "false" && $CI_PIPELINE_SOURCE != "schedule"',
      ],
    },
  },
  '.only-auto-deploy-false-and-config-changes': {
    only: {
      variables: [
        '$AUTO_DEPLOY == "false" && $CI_PIPELINE_SOURCE != "schedule"',
      ],
      changes: [
        'vendor/charts/gitlab/**/*',
        'bases/**/*',
        'bin/**/*',
        'releases/**/*',
        '*.yaml',
        '*.yml',
        '.gitlab-ci.yml',
      ],
    },
  },
};

local assertFormatting = {
  assert_formatting: {
    stage: 'check',
    image: '${CI_REGISTRY}/gitlab-com/gl-infra/k8s-workloads/common/k8-helm-ci:${CI_IMAGE_VERSION}',
    script: |||
      find . -name '*.*sonnet' | xargs -n1 jsonnetfmt -i
      git diff --exit-code
    |||,
  } + exceptOps,
};

local ciConfigGenerated = {
  ci_config_generated: {
    stage: 'check',
    image: '${CI_REGISTRY}/gitlab-com/gl-infra/k8s-workloads/common/k8-helm-ci:${CI_IMAGE_VERSION}',
    script: |||
      make generate-ci-config
      git diff --exit-code || (echo "Please run 'make generate-ci-config'" >&2 && exit 1)
    |||,
  },
};

local notifyComMR = {
  notify_com_mr: {
    stage: 'check',
    image: '${CI_REGISTRY}/gitlab-com/gl-infra/k8s-workloads/common/notify-mr:${CI_IMAGE_VERSION}',
    script: |||
      notify-mr -s
    |||,
    allow_failure: true,
    except: {
      variables: [
        '$EXPEDITE_DEPLOYMENT',
      ],
    },
    only: {
      variables: [
        '$AUTO_DEPLOY == "false" && $CI_PIPELINE_SOURCE != "schedule"',
      ],
    },
  } + exceptCom,
};

local dependencyScanning = {
  dependency_scanning: {
    stage: 'check',
  },
};

local bundlerAuditDependencyScanning = {
  'bundler-audit-dependency_scanning': {
    stage: 'check',
  },
};

local retireJsDependencyScanning = {
  'retire-js-dependency_scanning': {
    stage: 'check',
  },
};

local deploy(environment, stage, cluster, ciStage) = {
  local isCanary = stage == 'cny',
  ['%s:dryrun:auto-deploy' % cluster]: {
    stage: 'dryrun',
    extends: [
      '.cluster-init-before-script',
      '.%s' % (if isCanary then std.strReplace(environment, '-cny', '') else cluster),
    ],
    image: '${CI_REGISTRY}/gitlab-com/gl-infra/k8s-workloads/common/k8-helm-ci:${CI_IMAGE_VERSION}',
    script: |||
      bin/k-ctl -D %s upgrade
    ||| % if isCanary then '-s cny' else '',
    only: {
      variables: [
        '$ENVIRONMENT == "%s" && $AUTO_DEPLOY == "true" && $CI_PIPELINE_SOURCE != "schedule"' % environment,
      ],
    },
    tags: [
      'k8s-workloads',
    ],
    [if isCanary then 'resource_group']: environment,
  } + exceptCom,
  ['%s:auto-deploy' % cluster]: {
    stage: ciStage,
    extends: [
      '.cluster-init-before-script',
      '.%s' % (if isCanary then std.strReplace(environment, '-cny', '') else cluster),
    ],
    image: '${CI_REGISTRY}/gitlab-com/gl-infra/k8s-workloads/common/k8-helm-ci:${CI_IMAGE_VERSION}',
    script: |||
      sendEvent "Starting k8s deployment for $CLUSTER" "%s" "deployment" %s
      bin/k-ctl %s upgrade
      sendEvent "Finished k8s deployment for $CLUSTER" "%s" "deployment" %s
    ||| % if isCanary then
      [std.strReplace(environment, '-cny', ''), '"cny"', '-s cny', std.strReplace(environment, '-cny', ''), '"cny"']
    else
      [environment, '', '', environment, ''],
    only: {
      variables: [
        '$ENVIRONMENT == "%s" && $DRY_RUN == "false" && $AUTO_DEPLOY == "true" && $CI_PIPELINE_SOURCE != "schedule"' % environment,
      ],
    },
    tags: [
      'k8s-workloads',
    ],
    [if isCanary then 'resource_group']: environment,
  } + exceptCom,
  ['%s:dryrun' % cluster]: {
    stage: 'dryrun',
    extends: [
      '.cluster-init-before-script',
      '.%s' % (if isCanary then std.strReplace(environment, '-cny', '') else cluster),
      '.only-auto-deploy-false-and-config-changes',
    ],
    image: '${CI_REGISTRY}/gitlab-com/gl-infra/k8s-workloads/common/k8-helm-ci:${CI_IMAGE_VERSION}',
    script: |||
      bin/k-ctl -D %s upgrade
    ||| % if isCanary then '-s cny' else '',
    tags: [
      'k8s-workloads',
    ],
    [if isCanary then 'resource_group']: environment,
  } + exceptCom,
  ['%s:upgrade' % cluster]: {
    stage: ciStage,
    extends: [
      '.cluster-init-before-script',
      '.%s' % (if isCanary then std.strReplace(environment, '-cny', '') else cluster),
      '.only-auto-deploy-false-and-config-changes',
    ],
    image: '${CI_REGISTRY}/gitlab-com/gl-infra/k8s-workloads/common/k8-helm-ci:${CI_IMAGE_VERSION}',
    script: |||
      bin/grafana-annotate -e $CI_ENVIRONMENT_NAME
      sendEvent "Starting k8s configuration for $CLUSTER" "%s" "configuration" %s
      bin/k-ctl %s upgrade
      sendEvent "Finished k8s configuration for $CLUSTER" "%s" "configuration" %s
    ||| % if isCanary then
      [std.strReplace(environment, '-cny', ''), '"cny"', '-s cny', std.strReplace(environment, '-cny', ''), '"cny"']
    else
      [environment, '', '', environment, ''],
    only: {
      refs: [
        'master',
      ],
    },
    tags: [
      'k8s-workloads',
    ],
    variables: {
      DRY_RUN: 'false',
    },
    [if isCanary then 'resource_group']: environment,
  } + exceptCom,
};

local triggerQaSmoke = {
  '.trigger-qa-smoke': {
    extends: [
      // Skip QA smoke tests for auto-deploy because
      // QA is run in the context of the deployer
      // pipeline
      '.only-auto-deploy-false-and-config-changes',
    ],
    image: 'alpine:3.12.0',
    // This script can be replaced with the `trigger:` keyword
    // when the product supports retries for triggers
    // https://gitlab.com/gitlab-org/gitlab/-/issues/32559
    except: {
      variables: [
        "$CI_COMMIT_REF_NAME != 'master'",
      ],
      refs: [
        'tags',
      ],
    },
    script: |||
      if [[ $SKIP_QA == "true" ]]; then
        echo "Skipping QA because SKIP_QA is set to true"
        exit 0
      fi
      apk add curl jq
      # project=full/path/to/project
      echo "Sending trigger to $project"
      # URL encode the project
      project=$(echo -n "$project" | jq -sRr @uri)
      trigger_url="$CI_API_V4_URL/projects/$project/trigger/pipeline"
      resp=$(curl -s --request POST --form "variables[SMOKE_ONLY]=true" --form "token=$CI_JOB_TOKEN" --form ref=master $trigger_url)
      id=$(echo "$resp" | jq -r ".id")
      web_url=$(echo "$resp" | jq -r ".web_url")
      echo "Waiting for pipeline $web_url ..."
      status_url="$CI_API_V4_URL/projects/$project/pipelines/$id"
      for retry in $(seq 1 120); do
        resp=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_OPS_API_TOKEN" "$status_url")
        status=$(echo "$resp" | jq -r '.status')
        echo "Got pipeline status $status, retry $retry/10"
        [[ $status == "success" || $status == "failed" || $status == "canceled" ]] && break
        sleep 30
      done
      if [[ $status != "success" ]]; then
        echo "$web_url has status $status, failing"
        exit 1
      fi
    |||,
  } + exceptCom,
};

local qaJob(name, project, allow_failure=false) = {
  ['%s:qa' % name]: {
    extends: [
      '.trigger-qa-smoke',
    ],
    stage: 'non-prod:QA',
    [if allow_failure then 'allow_failure']: allow_failure,
    variables: {
      project: project,
    },
    except: {
      variables: [
        "$CI_COMMIT_REF_NAME != 'master'",
        '$EXPEDITE_DEPLOYMENT',
      ],
    },
    only: {
      changes: [
        'vendor/charts/gitlab/%s/**/*' % name,
        'vendor/charts/gitlab-runner/%s/**/*' % name,
        '.gitlab-ci.yml',
        '*.yaml',
        'releases/gitlab/helmfile.yaml',
        'releases/gitlab/values/values*',
        'releases/gitlab/values/%s*' % name,
      ],
    },
  } + exceptCom,
};

local openChartBumpMR(name) = {
  ['open-chart-bump-mr-%s' % name]: {
    stage: 'scheduled',
    image: '${CI_REGISTRY}/gitlab-com/gl-infra/k8s-workloads/common/k8-helm-ci:${CI_IMAGE_VERSION}',
    script: |||
      chmod 400 "$SSH_PRIVATE_KEY"
      export GIT_SSH_COMMAND="ssh -i $SSH_PRIVATE_KEY -o IdentitiesOnly=yes -o GlobalKnownHostsFile=$SSH_KNOWN_HOSTS"
      git config --global user.email "ops@ops.gitlab.net"
      git config --global user.name "ops-gitlab-net"
      git remote set-url origin https://ops-gitlab-net:${GITLAB_API_TOKEN}@gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com.git
      echo $GITLAB_API_TOKEN | glab auth login --hostname gitlab.com --stdin
      glab config set git_protocol https
      glab auth status
      ./bin/autobump-gitlab-chart.sh %s
    ||| % name,
    rules: [
      {
        'if': '$CI_PIPELINE_SOURCE == "schedule"',
      },
      {
        when: 'never',
      },
    ],
  },
};

local removeExpediteVariable = {
  'remove-expedite-variable': {
    stage: 'cleanup',
    image: '${CI_REGISTRY}/gitlab-com/gl-infra/k8s-workloads/common/k8-helm-ci:${CI_IMAGE_VERSION}',
    script: |||
      curl --fail --header "PRIVATE-TOKEN: ${OPS_API_TOKEN}" -X DELETE "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/variables/EXPEDITE_DEPLOYMENT"
    |||,
    rules: [
      {
        'if': '$CI_API_V4_URL == "https://gitlab.com/api/v4"',
        when: 'never',
      },
      {
        'if': '$AUTO_DEPLOY == "true"',
        when: 'never',
      },
      {
        'if': '$CI_PIPELINE_SOURCE == "schedule"',
        when: 'never',
      },
      {
        'if': '($CI_COMMIT_REF_NAME == $CI_DEFAULT_BRANCH) && $EXPEDITE_DEPLOYMENT',
      },
    ],
  },
};

local gitlabCIConf =
  stages
  + variables
  + includes
  + notifyComMR
  + triggerQaSmoke
  + baseCiConfigs
  + dependencyScanning
  + bundlerAuditDependencyScanning
  + retireJsDependencyScanning
  + assertFormatting
  + ciConfigGenerated
  + deploy('pre', 'main', 'pre', 'non-prod:deploy')
  + deploy('gstg-cny', 'cny', 'gstg-cny', 'non-prod-cny:deploy')
  + deploy('gstg', 'main', 'gstg', 'non-prod:deploy')
  + deploy('gstg', 'main', 'gstg-us-east1-b', 'non-prod:deploy')
  + deploy('gstg', 'main', 'gstg-us-east1-c', 'non-prod:deploy')
  + deploy('gstg', 'main', 'gstg-us-east1-d', 'non-prod:deploy')
  + deploy('gprd-cny', 'cny', 'gprd-cny', 'gprd-cny:deploy')
  + deploy('gprd', 'main', 'gprd', 'gprd:deploy:alpha')
  + deploy('gprd', 'main', 'gprd-us-east1-b', 'gprd:deploy:alpha')
  + deploy('gprd', 'main', 'gprd-us-east1-c', 'gprd:deploy:beta')
  + deploy('gprd', 'main', 'gprd-us-east1-d', 'gprd:deploy:beta')
  + qaJob('pre', 'gitlab-org/quality/preprod', allow_failure=true)
  + qaJob('gstg', 'gitlab-org/quality/staging')
  + openChartBumpMR('pre')
  + openChartBumpMR('gstg')
  + openChartBumpMR('gprd')
  + removeExpediteVariable;

std.manifestYamlDoc(gitlabCIConf)

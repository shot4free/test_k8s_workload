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
    // Dependency scanning
    // https://docs.gitlab.com/ee/user/application_security/dependency_scanning/
    { template: 'Security/Dependency-Scanning.gitlab-ci.yml' },
    // Make sure we do branch pipelines only (no duplicate pipelines)
    // https://docs.gitlab.com/ee/ci/yaml/workflow.html#workflowrules-templates
    { template: 'Workflows/Branch-Pipelines.gitlab-ci.yml' },
  ],
};

local exceptCom = {
  'if': '$CI_API_V4_URL == "https://gitlab.com/api/v4"',
  when: 'never',
};

local exceptOps = {
  'if': '$CI_API_V4_URL == "https://ops.gitlab.net/api/v4"',
  when: 'never',
};

local variables = {
  variables: {
    // renovate: datasource=docker depName=registry.gitlab.com/gitlab-com/gl-infra/k8s-workloads/common/k8-helm-ci versioning=docker
    CI_IMAGE_VERSION: 'v17.3.0',
    AUTO_DEPLOY: 'false',
  },
};

local mainRegion = 'us-east1';

local clusterAttrs = {
  pre: {
    ENVIRONMENT_WITHOUT_STAGE: 'pre',
    GOOGLE_PROJECT: 'gitlab-pre',
    GKE_CLUSTER: 'pre-gitlab-gke',
    GOOGLE_REGION: mainRegion,
  },
  gstg: {
    ENVIRONMENT_WITHOUT_STAGE: 'gstg',
    GOOGLE_PROJECT: 'gitlab-staging-1',
    GKE_CLUSTER: 'gstg-gitlab-gke',
    GOOGLE_REGION: mainRegion,
  },
  'gstg-us-east1-b': {
    GOOGLE_PROJECT: 'gitlab-staging-1',
    GKE_CLUSTER: 'gstg-us-east1-b',
    GOOGLE_ZONE: 'us-east1-b',
  },
  'gstg-us-east1-c': {
    GOOGLE_PROJECT: 'gitlab-staging-1',
    GKE_CLUSTER: 'gstg-us-east1-c',
    GOOGLE_ZONE: 'us-east1-c',
  },
  'gstg-us-east1-d': {
    GOOGLE_PROJECT: 'gitlab-staging-1',
    GKE_CLUSTER: 'gstg-us-east1-d',
    GOOGLE_ZONE: 'us-east1-d',
  },
  gprd: {
    ENVIRONMENT_WITHOUT_STAGE: 'gprd',
    GOOGLE_PROJECT: 'gitlab-production',
    GKE_CLUSTER: 'gprd-gitlab-gke',
    GOOGLE_REGION: mainRegion,
  },
  'gprd-us-east1-b': {
    GOOGLE_PROJECT: 'gitlab-production',
    GKE_CLUSTER: 'gprd-us-east1-b',
    GOOGLE_ZONE: 'us-east1-b',
  },
  'gprd-us-east1-c': {
    GOOGLE_PROJECT: 'gitlab-production',
    GKE_CLUSTER: 'gprd-us-east1-c',
    GOOGLE_ZONE: 'us-east1-c',
  },
  'gprd-us-east1-d': {
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
      ENVIRONMENT_WITHOUT_STAGE: clusterAttrs.pre.ENVIRONMENT_WITHOUT_STAGE,
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
      ENVIRONMENT_WITHOUT_STAGE: clusterAttrs.gstg.ENVIRONMENT_WITHOUT_STAGE,
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
      ENVIRONMENT_WITHOUT_STAGE: clusterAttrs.gprd.ENVIRONMENT_WITHOUT_STAGE,
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
};

local onlyAutoDeployFalseAndConfigChanges = {
  rules+: [
    {
      'if': '$AUTO_DEPLOY == "true"',
      when: 'never',
    },
    {
      'if': '$CI_PIPELINE_SOURCE == "schedule"',
      when: 'never',
    },
    {
      when: 'always',
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
  ],
};

local checkVendoredCharts = import 'ci/check-vendored-charts.libsonnet';
local shellcheck = import 'ci/shellcheck.libsonnet';
local versionChecks = import 'ci/version-checks.libsonnet';

local assertFormatting = {
  assert_formatting: {
    stage: 'check',
    image: '${CI_REGISTRY}/gitlab-com/gl-infra/k8s-workloads/common/k8-helm-ci:${CI_IMAGE_VERSION}',
    script: |||
      find . -name '*.*sonnet' | xargs -n1 jsonnetfmt -i
      git diff --exit-code
    |||,
    rules: [
      exceptOps,
      { when: 'always' },
    ],
  },
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
    rules: [
      {
        'if': '$EXPEDITE_DEPLOYMENT',
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
      exceptCom,
      {
        when: 'always',
      },
    ],
  },
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

local clusterInitBeforeScript = {
  before_script: |||
    if [[ $LOG_LEVEL == "debug" ]]; then
      echo "A high debug level may expose secrets, this job will now exit..."
      exit 1
    fi
    eval $(./bin/k-ctl config 2>/dev/null)
    if [[ $DRY_RUN == "false" ]]; then
      echo 'Using SERVICE_KEY'
      gcloud auth activate-service-account --key-file $SERVICE_KEY
    else
      echo 'Using SERVICE_KEY_RO'
      gcloud auth activate-service-account --key-file $SERVICE_KEY_RO
    fi
    gcloud config set project $PROJECT
    gcloud container clusters get-credentials ${CLUSTER} --region ${REGION}
  |||,
};

local deploy(environment, stage, cluster, ciStage) = {
  local isCanary = stage == 'cny',
  ['%s:dryrun:auto-deploy' % cluster]: {
    stage: 'dryrun',
    extends: [
      '.%s' % (if isCanary then std.strReplace(environment, '-cny', '') else cluster),
    ],
    image: '${CI_REGISTRY}/gitlab-com/gl-infra/k8s-workloads/common/k8-helm-ci:${CI_IMAGE_VERSION}',
    script: |||
      bin/k-ctl -D %s upgrade
    ||| % if isCanary then '-s cny' else '',
    rules: [
      exceptCom,
      {
        'if': '$ENVIRONMENT == "%s" && $AUTO_DEPLOY == "true" && $CI_PIPELINE_SOURCE != "schedule"' % environment,
        when: 'always',
      },
    ],
    tags: [
      'k8s-workloads',
    ],
    [if isCanary then 'resource_group']: environment,
  } + clusterInitBeforeScript,
  ['%s:auto-deploy' % cluster]: {
    stage: ciStage,
    extends: [
      '.%s' % (if isCanary then std.strReplace(environment, '-cny', '') else cluster),
    ],
    image: '${CI_REGISTRY}/gitlab-com/gl-infra/k8s-workloads/common/k8-helm-ci:${CI_IMAGE_VERSION}',
    script: |||
      bin/k-ctl %s upgrade
    ||| % if isCanary then '-s cny' else '',
    rules: [
      exceptCom,
      {
        'if': '$ENVIRONMENT == "%s" && $DRY_RUN == "false" && $AUTO_DEPLOY == "true" && $CI_PIPELINE_SOURCE != "schedule"' % environment,
        when: 'always',
      },
    ],
    tags: [
      'k8s-workloads',
    ],
    [if isCanary then 'resource_group']: environment,
  } + clusterInitBeforeScript,
  ['%s:dryrun' % cluster]: {
    stage: 'dryrun',
    extends: [
      '.%s' % (if isCanary then std.strReplace(environment, '-cny', '') else cluster),
    ],
    image: '${CI_REGISTRY}/gitlab-com/gl-infra/k8s-workloads/common/k8-helm-ci:${CI_IMAGE_VERSION}',
    script: |||
      bin/k-ctl -D %s upgrade
    ||| % if isCanary then '-s cny' else '',
    tags: [
      'k8s-workloads',
    ],
    rules: [
      exceptCom,
    ],
    [if isCanary then 'resource_group']: environment,
  } + clusterInitBeforeScript + onlyAutoDeployFalseAndConfigChanges,
  ['%s:upgrade' % cluster]: {
    stage: ciStage,
    extends: [
      '.%s' % (if isCanary then std.strReplace(environment, '-cny', '') else cluster),
    ],
    image: '${CI_REGISTRY}/gitlab-com/gl-infra/k8s-workloads/common/k8-helm-ci:${CI_IMAGE_VERSION}',
    script: |||
      bin/grafana-annotate -e $CI_ENVIRONMENT_NAME
      bin/k-ctl %s upgrade
    ||| % if isCanary then '-s cny' else '',
    rules: [
      {
        'if': '$CI_DEFAULT_BRANCH != $CI_COMMIT_REF_NAME',
        when: 'never',
      },
      exceptCom,
    ],
    tags: [
      'k8s-workloads',
    ],
    variables: {
      DRY_RUN: 'false',
    },
    [if isCanary then 'resource_group']: environment,
  } + clusterInitBeforeScript + onlyAutoDeployFalseAndConfigChanges,
};

local triggerQaSmoke = {
  '.trigger-qa-smoke': {
    image: 'alpine:3.16',
    // This script can be replaced with the `trigger:` keyword
    // when the product supports retries for triggers
    // https://gitlab.com/gitlab-org/gitlab/-/issues/32559
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
    rules: [
      exceptCom,
    ],
  } + onlyAutoDeployFalseAndConfigChanges,
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
    rules: [
      exceptCom,
      {
        'if': '$CI_DEFAULT_BRANCH != $CI_COMMIT_REF_NAME',
        when: 'never',
      },
      {
        'if': '$EXPEDITE_DEPLOYMENT',
        when: 'never',
      },
      {
        when: 'always',
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
    ],
  },
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
  + shellcheck
  + versionChecks
  + checkVendoredCharts
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

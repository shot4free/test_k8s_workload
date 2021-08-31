[[_TOC_]]

# gitlab-com

Kubernetes Workload configurations for GitLab.com

## Documentation

[CONTRIBUTING.md](CONTRIBUTING.md)
[DEPLOYMENT.md](DEPLOYMENT.md)

:warning: **WARNING** :warning:

The following are _NOT_ allowed this repository:
* Files that contain secrets in plain text

## Services

The following services are managed by this Chart:

| Service | Upgrades |
| --- | --- |
| [API](https://gitlab.com/gitlab-org/gitlab)([readiness](https://gitlab.com/gitlab-com/gl-infra/readiness/-/tree/master/api-k8s-migration) | Auto-deploy pipeline created from a pipeline trigger from the deployer pipeline |
| [Web](https://gitlab.com/gitlab-org/gitlab)(readiness TBD, in pre env only) | Auto-deploy pipeline created from a pipeline trigger from the deployer pipeline |
| [Git](https://gitlab.com/gitlab-org/gitlab) ([readiness](https://gitlab.com/gitlab-com/gl-infra/readiness/-/blob/master/git-https-websockets/index.md)) | Auto-deploy pipeline created from a pipeline trigger from the deployer pipeline |
| [Mailroom](https://gitlab.com/gitlab-org/gitlab-mail_room) ([readiness](https://gitlab.com/gitlab-com/gl-infra/readiness/-/blob/master/mailroom/overview.md)) | Upgrades are done manually be setting a version in [values.yaml](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/7bd15324144a2c85699bf685fb606b6dd7c92975/releases/gitlab/values/values.yaml.gotmpl#L1076-1080) ([release template](https://gitlab.com/gitlab-org/gitlab-mail_room/-/blob/master/.gitlab/issue_templates/Release.md)). |
| [Registry](https://gitlab.com/gitlab-org/container-registry) ([readiness](https://gitlab.com/gitlab-com/gl-infra/readiness/-/blob/master/registry-gke/overview.md)) | Done by manually setting a version in [init-values.yaml](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/7bd15324144a2c85699bf685fb606b6dd7c92975/releases/gitlab/values/init-values.yaml.gotmpl#L75) ([release template](https://gitlab.com/gitlab-org/container-registry/-/blob/master/.gitlab/issue_templates/Release%20Plan.md)). |
| [Sidekiq](https://gitlab.com/gitlab-org/gitlab) ([readiness](https://gitlab.com/gitlab-com/gl-infra/readiness/-/blob/master/sidekiq/index.md)) | Auto-deploy pipeline created from a pipeline trigger from the deployer pipeline |

## GitLab Environments Configuration

While `gstg` and `gprd` are single environments on their own, we are leveraging
helmfile environments to segregate configuration changes to each cluster that
participates in each environment.  As such `gprd` and `gstg` expand their
environment configurations into 1 per cluster.

On merge, configuration changes will be deployed to the following environments:

| Environment | URL | Cluster |
| ----------- | --- | ------- |
| `pre`       | `https://pre.gitlab.com`     | pre-gitlab-gke |
| `gstg`      | `https://staging.gitlab.com` | gstg-gitlab-gke |
| `gstg`      | `https://staging.gitlab.com` | gstg-us-east1-b |
| `gstg`      | `https://staging.gitlab.com` | gstg-us-east1-c |
| `gstg`      | `https://staging.gitlab.com` | gstg-us-east1-d |
| `gprd`      | `https://gitlab.com`         | gprd-gitlab-gke |
| `gprd`      | `https://gitlab.com`         | gprd-us-east1-b |
| `gprd`      | `https://gitlab.com`         | gprd-us-east1-c |
| `gprd`      | `https://gitlab.com`         | gprd-us-east1-d |

## GitLab CI/CD Variables Configuration

On the Ops instance, a special variable is used [in cases of
emergency](./DEPLOYMENT.md#in-case-of-emergency)

| Variable | Description |
| -------- | ----------- |
| `OPS_API_TOKEN`       | Token utilized by the ops.gitlab.com instance to make
API calls on behalf of the CI jobs. |
| `EXPEDITE_DEPLOYMENT` | Skips select processes and CI Jobs to push a configuration change out to production faster than normal. |

Each of the below variables is applied to the environment defined above

| Variable        | Description
| --------        | --------
| `CLUSTER`       | Name of the GKE cluster, ex: `gstg-gitlab-gke` or `gstg-us-east1-b`
| `REGION `       | Name of the region or zone of the cluster, ex: `us-east1` or `us-east1-b`
| `PROJECT`       | Name of the project, ex: `gitlab-staging-1`
| `SERVICE_KEY`   | Service Account key used for CI for write operations to the cluster
| `SERVICE_KEY_RO`| Service Account key used for CI for read operations, used on branches

### Access to GitLab production website blocked in CI

Please note that the tooling in this repository specificly sometimes blocks access to the following URLs when running CI Jobs, only during the execution of helm/helmfile

* gitlab.com
* registy.gitlab.com
* charts.gitlab.io

The rationale behind this is to avoid a situation where our deployment tooling to deploy GitLab.com on Kubernetes is dependant on GitLab.com being available. During
an outage where we might might need to use this repository to deploy an upgrade/fix to GitLab.com, we don't want this to fail because some part of GitLab.com is unavailable.

The CI job will disable access to these urls if the following conditions are met

* We have the CI environment variable 'GITLAB_ACCESS_DISABLE' set. This is typically set as a Global CI variable in the projects configuration, and allows us to globally enable/disable this functionality at will.

* The environment variable 'ARTIFACT_AVAILABLE' is set. This means the GitLab chart and dependencies have been cached locally using the GitLab CI cache. While the GitLab chart is pulled from dev.gitlab.org, due
to the way helm chart dependencies work, attempting to fetch the chart dependencies makes helm call gitlab.com, so whenever we do a CI job with a chart bump, that job will fetch the new chart and dependencies to
cache it locally for all new CI jobs.

## GitLab Secrets

In order to work with the existing omnibus installation of GitLab.com, we will need to bring in a few already configured items that exist in that environment.  These items will ensure that when the Deployment is spun up inside of Kubernetes we interact appropriately with our existing infrastructure.

:warning: This guide assumes you are connected to the appropriate Kubernetes cluster :warning:

There is an upstream helm chart wrapped into a helm release called `gitlab-secrets` which is installed in order to populate all the secrets needed to run the GitLab helm chart. [Helmfile](https://github.com/roboll/helmfile) is used to obtain the values for these secrets from our existing infrastructure that is used for chef, and populate the values for the helm chart in the appropriate locations. In order to install this chart, you need to have a working `gcloud` setup. These secrets will be deployed along with our gitlab helm chart at the same time using the `k-ctl` wrapper script.

When creating a secret, attempt to follow the documentation as close as possible and utilize the default values where possible.  Except when naming the secret.  When naming the secret, attempt to provide some form of version control that way if we need to rotate a secret we can do so and still have a fall back in the case where a new secret prevents the start-up of a Pod.  Example, if we utilize the name `some-secret` in our own documentation, utilize `some-secret-v1`, where `-v1` will be utilize for future usage in secret rotations.

### Secret Rotation

1. Duplicate the secret that already exists
1. Change the name of the secret by incrementing it's version control portion of the name
    * Example `some-secret-v1` is then named `some-secret-v2`
1. Find the location in our `gitlab` release and modify the secret object to be used by changing the name appropriately
1. Create a Merge Request
1. Proceed to follow our [CONTRIBUTING.md](CONTRIBUTING.md) document to complete the roll-out of said secret

## Create/Apply Configurations

### Chef Managed Secrets/Configurations

For any changes to configurations that are stored in Chef:

* https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/master/releases/gitlab-secrets/helmfile.yaml
* https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/master/releases/gitlab/values/values-from-external-sources.yaml.gotmpl

We must ensure that our Chef infrastructure and Kubernetes infrastructure match.
To apply a change that is stored inside of chef perform the following tasks:

1. Add a line to the file `CHEF_CONFIG_UPDATE` in the root of this directory (see file for example)
1. Create a Merge Request with this file that links to the change contained in Chef for auditing purposes.
    * When the pipelines execute, we should see the configuration change as desired.
1. Proceed to have a member of Delivery merge/review the MR
1. After the change has been applied, proceed to verification of the change as
   necessary.

The above steps are not our desired state.  We have issue
https://gitlab.com/gitlab-com/gl-infra/delivery/-/issues/1128 to make this
procedure friendlier.

## Decisions

Read about how we've come to decide how this repository is setup by viewing our [design document](https://about.gitlab.com/handbook/engineering/infrastructure/library/kubernetes/configuration/).

## Working locally

Local development is not something that currently works very well.  An issue
exists to address this:
https://gitlab.com/gitlab-com/gl-infra/delivery/-/issues/381

### Prerequisites

Complete the [Workstation setup](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/kube/k8s-oncall-setup.md#workstation-setup-for-k-ctl) steps described in the [k8s-operations runbook](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/kube/k8s-operations.md).

## Bootstrapping new clusters

### Creating a new environment

Every cluster must have a unique environment for Helm, there should be a new environment defined in https://ops.gitlab.net/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/master/bases/environments.yaml that inherits the right values depending on whether it is staging or production.

After the environment is defined, CI jobs will need to be created in the [gitlab-ci.yml](https://ops.gitlab.net/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/master/.gitlab-ci.yml) for gitlab-helmfiles.

See [Example MR for the production zonal clusters](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/merge_requests/448)

### Apply configuration locally to the cluster

It's useful to apply configuration locally using `k-ctl` for the first time, to work out any issues that may arise.
Before applying you will need to set the following environment variables:

```
CLUSTER=<cluster name>
REGION=<region or zone name>
```

Then apply using `k-ctl`

```
./bin/k-ctl -e <env name> apply
```

## Setting Chart Version

This is in a global variable called `CHART_VERSION` in the `.gitlab-ci.yml` file

We build our own chart versus using the official version.  This allows us to
incrementally update the chart as we make improvements we require.  The built
chart is then stored as an artifact and will be attempted to be reused for
future pipelines.  Should the `CHART_VERSION` be updated, the next chart build
that occurs on our default branch will contain the updated artifact.  Should
`CHART_VERSION` be overridden for an environment, we will be unable to use the
cached version of the chart.  This has a consequence of unexpected changes to
various versions that are stored inside of Kubernetes objects , but should be
considered a safe operation.

## Helm Charts and this Repository

In order to minimise the amount of external dependencies this repo has (as it's
part of our critical deployment pipeline), and to make it easier to read and
understand this repository, we vendor the charts that we use into this repo
under the directory `charts`.

Currently the following charts are vendored in this repo

| Chart | Vendored | How to correctly do modifications |
| -- | -- | -- |
| `raw` | yes | This was forked from an abandoned upstream chart, so local modifications as necessary are fine |
| `gitlab` | no | Work in upstream chart repo and then see instructions above |
| `gitlab-runner` | no | Work in upstream chart repo and then see instructions above |

## Node Selectors

Due to an unknown issue with GKE's cluster-autoscaler, we are currently using
the names of node pools to manage where our workloads reside.  Keep in mind that
node pool names are not consistent between any environment!  If new node pools
are created, the use of the label will need to be modified in this repo prior to
removing the old node pool.  Details of how we landed here can be found in
Incident: https://gitlab.com/gitlab-com/gl-infra/production/-/issues/4940

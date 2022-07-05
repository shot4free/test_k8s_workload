[[_TOC_]]

# gitlab-com

Kubernetes Workload configurations for GitLab.com

## Documentation

* [CONTRIBUTING.md](CONTRIBUTING.md)
* [DEPLOYMENT.md](DEPLOYMENT.md)

:warning: **WARNING** :warning:

The following are _NOT_ allowed this repository:
* Files that contain secrets in plain text

## Services

The following services are managed by this Chart:

| Service | Upgrades |
| --- | --- |
| [API](https://gitlab.com/gitlab-org/gitlab) ([readiness](https://gitlab.com/gitlab-com/gl-infra/readiness/-/tree/master/api-k8s-migration)) | Auto-deploy pipeline created from a pipeline trigger from the deployer pipeline |
| [Web](https://gitlab.com/gitlab-org/gitlab) ([readiness](https://gitlab.com/gitlab-com/gl-infra/readiness/-/blob/master/web-k8s-migration/index.md)) | Auto-deploy pipeline created from a pipeline trigger from the deployer pipeline |
| [Git](https://gitlab.com/gitlab-org/gitlab) ([readiness](https://gitlab.com/gitlab-com/gl-infra/readiness/-/blob/master/git-https-websockets/index.md)) | Auto-deploy pipeline created from a pipeline trigger from the deployer pipeline |
| [Mailroom](https://gitlab.com/gitlab-org/gitlab-mail_room) ([readiness](https://gitlab.com/gitlab-com/gl-infra/readiness/-/blob/master/mailroom/overview.md)) | Upgrades are done manually be setting a version in [values.yaml](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/7bd15324144a2c85699bf685fb606b6dd7c92975/releases/gitlab/values/values.yaml.gotmpl#L1076-1080) ([release template](https://gitlab.com/gitlab-org/gitlab-mail_room/-/blob/master/.gitlab/issue_templates/Release.md)). |
| [Container Registry](https://gitlab.com/gitlab-org/container-registry) ([readiness](https://gitlab.com/gitlab-com/gl-infra/readiness/-/blob/master/registry-gke/overview.md)) | Done by manually setting a version in [init-values.yaml](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/7bd15324144a2c85699bf685fb606b6dd7c92975/releases/gitlab/values/init-values.yaml.gotmpl#L75) ([release template](https://gitlab.com/gitlab-org/container-registry/-/blob/master/.gitlab/issue_templates/Release%20Plan.md)). |
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

## GitLab Secrets

:warning: Please note that from the work done in https://gitlab.com/gitlab-com/gl-infra/delivery/-/issues/2384 all Kubernetes secrets we use for this repository are now stored in a separate Git repo called [gitlab-secrets](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-secrets). Please see that repository for details on how to sync secrets from chef into Kubernetes.

Note that if you wish to update a secret, you will need to make a new version of the secret object in that repository, merge it, then do a merge request against this repository to change what Kubernetes secret object is being used.

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

We vendor the `gitlab` and `gitlab-runner` charts into this repo. This allows
us to minimise the amount of external dependencies invoked at runtime, and allow
easier understanding of this repo by including all "code" needed inside it.

We use a tool called [vendir](https://carvel.dev/vendir) to handle the process
of "vendoring" the charts into this repo (and checking they are the same as
their upstream versions during merge requests). In order to bump the version
of the GitLab chart used in an environment, you will need to edit `vendir.yml`
file, and look for the `ref` field under the chart directory you are interested
(these are in the format `gitlab/${environment name}`. Change the ref to the
new git ref (from the charts repository) you wish to use, then run the command
`vendir sync` which will vendor the new copy locally. Then feel free to do an MR
with these changes to actually get the change applied.

An example to commit the new chart for in `gstg` for the `gitlab` chart

```
git checkout -b username/bump-chart-gitlab-in-gstg
# edit vendir.yml changing `ref` for the `gitlab/gstg` path to the new SHA
vendir sync
# manually sync helm deps
cd vendor/charts/gitlab/gstg
helm dep update
cd ../../../..
git add vendor/charts/gitlab/gstg vendir.yml vendir.lock.yml
git commit -m "Bump chart in gstg"
# You are now ready to push and open an MR
```

It is expected that if you are bumping the version in one environment you will
take responsibility for bumping all other environments in due course.  If your
focus/requirement is only `gstg` and `gprd`, you should probably do `pre` when
you do `gstg` (same MR) unless there are extenuating circumstances (e.g.
other work ongoing on pre that shouldn't be interrupted, etc.)

## Helm Charts and this Repository

In order to minimise the amount of external dependencies this repo has (as it's
part of our critical deployment pipeline), and to make it easier to read and
understand this repository, we vendor the charts that we use into this repo
under the directory `vendor/charts`.

Currently the following charts are vendored in this repo

| Chart | Vendored | How to correctly do modifications |
| -- | -- | -- |
| `gitlab` | yes | Work in upstream chart repo and then see instructions above |
| `gitlab-runner` | yes | Work in upstream chart repo and then see instructions above |

## Node Selectors

Due to an unknown issue with GKE's cluster-autoscaler, we are currently using
the names of node pools to manage where our workloads reside.  Keep in mind that
node pool names are not consistent between any environment!  If new node pools
are created, the use of the label will need to be modified in this repo prior to
removing the old node pool.  Details of how we landed here can be found in
Incident: https://gitlab.com/gitlab-com/gl-infra/production/-/issues/4940

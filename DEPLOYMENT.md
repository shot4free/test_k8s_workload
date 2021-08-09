# Deployment

This document contains details as to how this repository performs deployment for
either configuration changes to the components this repo maintains, or
auto-deploys to components directly attributed to the GitLab.com product that
have been migrated to this repository.

Follow our [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to get started
with working on this repository.

## Common Configuration

This repository that resides on the SaaS GitLab.com instance is the canonical
location of this repository.  No actions made to the canonical repository make
changes to any infrastructure.  Instead, we mirror this repo to our ops instance
which has the necessary permissions to reach out to any and all clusters to
complete the configurations.

When a Merge Request is opened, the ops instance will run the suite of tests and
report with links to the MR pointing to the pipeline that has been run, and
output very basic information per environment if changes are detected.  Team
members whom have access to the ops instance will use the links provided to
assist them in completing the review, per our [CONTRIBUTING] document.

### Chart Management

In CI, we've reduced the need to constantly ask for our dependencies by building
the chart once at the start of all CI jobs, and carrying that build as an
artifact for all CI jobs following.  Doing so is defined in our .gitlab-ci.yml
file.  With this, we intentionally set the version of the chart used to
`0.0.0+<SHA>`.  `SHA` representing the version of the Helm Chart defined.  If
the build is successful, we set the variable `ARTIFACT_AVIALABLE` for all jobs
in the pipeline.  Should a build fail for any reason, we attempt to not block
ourselves by falling back to using helmfiles method and the `git` plugin for
helm to pull down and use this version of the chart.  The downside to this is
that we'll see more changes in our diff jobs, and this may fail auto-deployments
due to changes to the version of the helm chart.  There does not exist a
workaround for this.

Testing this locally involves the following steps:

1. Check out the appropriate version of our helm chart
1. Package the chart: `helm package ./ --dependency-update --version
   "0.0.0+$(git rev-parse --verify HEAD)" --destination
   /path/to/k8s-workloads/gitlab-com`
1. Change to: `/path/to/k8s-workloads/gitlab-com`
1. Untar the package: `tar xf gitlab-0.0.0+<SHA>.tgz`
1. Now you can prefix any `k-ctl` commands with `ARTIFACT_AVILABLE=true`

## Configuration Changes

Configuration change constitute any change that is created manually via an MR
into the canonical location of this repository.  Follow our [CONTRIBUTING]
document for help getting started.

After an MR is merged, and after repository mirroring has occurred, ops will
create a new pipeline that targets all environments.  QA jobs run for select
changes that target our Preprod and Staging environments.  See the [resolving QA failures](https://gitlab.com/gitlab-org/release/docs/-/blob/master/runbooks/resolving-qa-failures.md) runbook for help with failing tests. The jobs which target
our production main stage are automatically promoted following successful QA smoke tests. Separate MRs should be used to target changes on the different environments to avoid accidental promotion. 

### Auto-Deploy with Configuration Changes

[Auto-Deploy](https://gitlab.com/gitlab-org/release/docs/-/blob/master/general/deploy/auto-deploy.md) runs a pipeline in this project that will update application images for the [GitLab Helm Chart](https://docs.gitlab.com/charts/#gitlab-cloud-native-helm-chart).  This pipeline runs on ops and is limited to a single environment.  There are two stages, Diff and Deploy that perform the following:

1. Validate that no change other than an application upgrade is occurring
1. If all is well, proceed with deploying, synchronously to all clusters

Auto-deploy will use the master branch at all times for these jobs.  Should a change have been merged into master not be fully rolled out, *this will block auto-deploys*.  It is advised if a change will take a long time to rollout, to ask permission from the `@release-managers` to ensure that Auto-Deploys will not be blocked.  Otherwise a revert of the change will be required.

We plan to make this better in the future.  Tracking issue: https://gitlab.com/gitlab-com/gl-infra/delivery/-/issues/1326

## Auto Deploy

This project receives a pipeline trigger for auto-deploy, that runs special auto-deploy CI jobs for GitLab image updates to the cluster.
The trigger is initiated from [deployer](https://ops.gitlab.net/gitlab-com/gl-infra/deployer) in the fleet stage of the deployment pipeline.
4 variables are passed in the trigger for auto-deploy trigger ([set in deploy-tooling](https://ops.gitlab.net/gitlab-com/gl-infra/deploy-tooling/-/blob/cc07cb8705e12dcf520615080a6926c2342dd4d6/common_tasks/k8s_trigger.yml#L27-30)):
* `AUTO_DEPLOY`: When set to `true` only auto-deploy jobs will be created in the pipeline
* `GITLAB_IMAGE_TAG`: The auto-deploy image tag, which must be a valid tag for the CNG image being deployed. It is read in [init-values.yaml](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/master/releases/gitlab/values/init-values.yaml.gotmpl)
* `DRY_RUN`: When set to `true`, only dry-run jobs are executed.
* `ENVIRONMENT`: Environment for deployment, this should be the prefixed environment name. ex: `gprd` for the helmfile environment`gprd-us-east1-b`

To ensure that only image updates occur during an auto-deploy, only the [gitlab](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/tree/master/releases/gitlab) release is applied when `AUTO_DEPLOY=true` is set, which means that secrets are not updated.
There is also a safety mechanism in the [`bin/k-ctl`](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/master/bin/k-ctl) wrapper that ensures that changes listed in the helm diff are limited to the changes we expect to see for an image update. To do this, we match the json diff output to `auto-deploy-image-check/<env>.json`.  This mechanism MUST be updated if a new component is added that is subject to auto-deploy.

## Upgrades and Rollbacks

When deployments to environments fail, helm will automatically attempt to rollback the application and mark the deployment job as failed.
When this happens, the application will not be upgraded, but the master branch of the repo will contain the desired state that failed.

This must be addressed immediately, if there's a failure to deploy, perform a revert of the commit immediately to ensure the master branch represents what is in production.
Once the revert commit is in place, proceed to perform the investigation to continue towards the desired state.

## In Case of Emergency

During outages, it may be difficult to get things deployed quickly.  Perform the
following steps in the case of a full blown outage of .com:

1. Add an environment variable to the Ops instance for this repository: `EXPEDITE_DEPLOYMENT` with a value set to `true`
1. Open a Merge Request on the ops instance for proper review
1. Complete the review as normal and merge the MR when ready
1. Ensure the change rolls out as desired, repeat the above as necessary
   * Note that the variable `EXPEDITE_DEPLOYMENT` will be removed with each
     merge into the default branch.  If further configurations require the use
     of this variable, it will need to be set into place.
1. When the .com instance is back online, we must re-sync the repos as mirroring
   will now be broken.
1. On .com, unprotect the default branch - note the settings as we'll restore
   this later
1. Push the latest change on Ops default branch to .com's default branch
1. Protect the default branch using the settings that you noted prior

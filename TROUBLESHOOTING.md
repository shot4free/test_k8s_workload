[[_TOC_]]

# Troubleshooting

## Auto-Deploy

### Diff Job Failure

Diff jobs may fail when there are changes detected that are not part of an
Auto-Deploy, such as when a configuration change sneaks in.  Example error:

`Check https://ops.gitlab.net/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/pipelines to see if there are any outstanding configuration changes, to override this failure set IMAGE_CHECK_OVERRIDE=true as a CI variable`

Earlier in the job log we may see the following message:

`❌ Unexpected number of changes for an image-only update`

Look at the job log output to determine if there are any change indicated in the
diff that do not appear as desired.  If this is true, this is a sign that a
configuration change was detected, most likely a pipeline containing said
configuration should be identified to determine if it failed to roll out, should
be reverted, or maybe the pipeline of said change did not get a chance to
complete.

Another possibility is that a new component was added, but it was forgotten to
add this component to the auto-deploy checker.  See
[DEPLOYMENT.md#auto-deploy](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/master/DEPLOYMENT.md#auto-deploy)

Reference the Auto Deploy Checker:

* Configurations: https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/tree/master/auto-deploy-image-check
* Function: https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/027a4ae0eb15c83cae9fcb4eaaad7f833ee76971/bin/k-ctl#L101-139

### Deployment Job Failure

Error: `Error: UPGRADE FAILED: another operation (install/upgrade/rollback) is
in progress`

This is a sign that helm is in a bad state.  Investigation must be done to
determine what version of the application is currently running and how to set
helm back into a safe state.

One option would be to perform a rollback.  This can be accomplished via: `helm
-n gitlab rollback gitlab <REVISION>` specifying the current revision - 1.

---

Error: `Error: UPGRADE FAILED: release gitlab failed, and has been rolled back
due to atomic being set: <SOME ERROR>`

If able, troubleshoot the provided `SOME ERROR`.  If it's a generic timeout,
take a look at the time it took the CI job to fail.  If we are well w/i the
timeout settings, we may have a sporadic failure that may be safe to retry.  If
we are at the time limit imposed by either Helm or our CI job, begin
investigating the Pods that would've come online for the upgrade.  This may be a
sign that Pods were unable to start for X reason which may point to a problem
with either our build of the application, or the application failing to start.

## Skipping Cluster Deployments

Sometimes it may be necessary to skip deploying to clusters entirely, whether it
be for maintenance or outages of some kind.  To run a configuration or
auto-deploy though while skipping a target cluster, utilize the following steps

1. Identify the cluster to be skipped.  Keep in mind that this repository uses
   the name of the environment to determine which cluster to be skipped.  For
   example, to skip the `pre` cluster, we'd specify `pre`.  Where-as for one of
   our many production clusters, we'd need to specify the full name of the
   cluster in GKE, example `gprd-us-east1-b`
1. Add the environment variable `SKIP_CLUSTER` set to the value identified
   above.  This needs to be placed on our ops instance where the pipelines run: https://ops.gitlab.net/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/settings/ci_cd
1. Run a pipeline, or retry a job as desired
1. Remove this variable when maintenance or an outage is complete

Note that both diff jobs as well as deployments will be skipped for the target
cluster.  This works for both auto-deploys as well as configuration changes
initiated by the pipelines on this repository.

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

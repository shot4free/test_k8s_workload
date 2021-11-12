# Auto-deploy image checks

These files contain `helm diff --output json ...` files for the different helm environments. These are compared during auto-deploy pipeline runs as a safety check to ensure that we are only updating images and not other configuration.

The purpose of this check is to ensure that an auto-deploy is only ever deploying a new version of Gitlab container images, and not
also deploying a configuration change either committed to this repository but not applied, or a change that has been synced over
by chef automatically.

These files will need to be updated as more services are migrated to the Kubernetes cluster.

To update the image-check output locally:

* Use `sshuttle` to connect to a cluster
* Update your environment for corresponding cluster / region

```
# Example
export REGION=us-east1-b
export CLUSTER=gstg-us-east1-b
export AUTO_DEPLOY=true
export GITLAB_IMAGE_TAG=some-new-image
```

* Run `k-ctl` in dry-run mode

```
# Example
./bin/k-ctl -e gstg-us-east1-b -D upgrade
```

* After ensuring that the diff only contains an image update, copy the expected value into the corresponding json file

## What to do if an auto-deploy reports an outstanding number of changes
Auto deploys should only ever change the image tag on the Kubernetes deployment objects (as they are only changing the
version of Gitlab code that is running).

If an auto-deploy job fails because

"Check https://ops.gitlab.net/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/pipelines to see if there are any outstanding configuration changes"

then the best thing to do is look at the `helmfile diff` output in the job itself and see if you can isolate what the
extra change is that is not just a change in image version. It could be a configuration change from a previously merged
change that had a broken apply pipeline (so is still outstanding), or it could be something new because certain settings
synced from chef.

In either case the safest option if you believe the change is safe to apply, is to create a new pipeline on `master`
at https://ops.gitlab.net/gitlab-com/gl-infra/k8s-workloads/gitlab-com and wait for it to apply, before retrying
the auto-deploy job.

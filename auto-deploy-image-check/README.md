# Auto-deploy image checks

These files contain `helm diff --output json ...` files for the different helm environments. These are compared during auto-deploy pipeline runs as a safety check to ensure that we are only updating images and not other configuration.

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

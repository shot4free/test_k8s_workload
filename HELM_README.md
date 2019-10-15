## Overview

Helm is currently used to generate our current set of configurations.  For each
environment we want to deploy, we'll override `values.yaml` file with an
environment file for it, such as `pre.yaml`.  The generation script will merge
these together and create the templated files in the environments output
directory.

Despite having some configurations generated, some will still be manually
created, namely secrets. The guide below will assist us with inputting the
manual generated configuration into our cluster as well as generating the
configurations to be handled via CI.

## Container Registry

In order to work with the existing omnibus installation of GitLab.com, we will
need to bring in a few already configured items that exist in that environment.
These items will ensure that when the Container Registry is spun up inside of
Kubernetes we interact appropriately with our existing infrastructure.  These
include the following:
  * The JWT Authentication mechanism, which includes the auth token itself, as
    well as the certificate
  * The default helm chart configures the JWT issuer differently than our
    omnibus installation.  The values.yml file contains a change to make them
    the same.
      * In this case the `registry.tokenIssuer` must be set to match our omnibus
        installation.
  * The other difference is that it is necessary to disable the other services
    The configuration in `values.yml` will have this configured.
  * And then we simply need to ensure that the registry is configured to utilize
    our existing object storage configuration.

The instructions below cover these details.

### Secret for GCS Configuration

:warning: This guide assumes you are connected to the appropriate Kubernetes
cluster :warning:

The following secrets are needed for the Registry service:

* `registry-storage`: For accessing object storage, local to the registry service and contains the json credential for the service account
* `registry-httpsecret`: Random data used to sign state, local to the registry service
* `registry-certificate`: Used for signing tokens
* `dev-registry-access`: Deploy token used for pulling down the GitLab fork of the Registry image

Follow these steps to bootstrap secrets, it is assumed that secrets are copied from one of the existing environments.

For example, to copy secrets from the preprod environment for minikube:

```
## Example
export REMOTE_ENV="pre"
export CHEF_REPO="$HOME/workspace/chef-repo"
```

1. The service account json for GCS is configured in secrets
   and can be copied from one of the existing GitLab environments.
   From the [chef-repo](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/)
   project, using the gkms helper script. Run the following to extract
   the secrets:

```
$CHEF_REPO/bin/gkms-vault-show gitlab-omnibus-secrets $REMOTE_ENV \
  | jq -r '."gitlab-server"."google-creds".json_base64_registry' \
  | base64 -D > service-account-key.json


HTTP_SECRET=$($CHEF_REPO/bin/gkms-vault-show gitlab-omnibus-secrets $REMOTE_ENV| \
  jq -r '."omnibus-gitlab".gitlab_rb.registry.http_secret')


$CHEF_REPO/bin/gkms-vault-show gitlab-omnibus-secrets $REMOTE_ENV | \
  jq -r '."omnibus-gitlab".ssl.internal_certificate' > registry-auth.crt
```

2. Use the `$REMOTE_ENV` version of `registry.gcs.yaml` or create a new one with the
   [example gcs config](https://gitlab.com/charts/gitlab/blob/master/examples/objectstorage/registry.gcs.yaml)

```
cd input/$REMOTE_ENV
```

3. Create the secrets

```
kubectl create secret generic registry-storage \
  --namespace=gitlab \
  --from-file=config=registry-storage.yaml \
  --from-file=gcs.json=service-account-key.json

kubectl create secret generic registry-httpsecret \
  --namespace=gitlab \
  --from-literal=secret=$HTTP_SECRET

kubectl create secret generic registry-certificate \
  --namespace=gitlab \
  --from-file=registry-auth.crt=registry-auth.crt
```

The deploy token for pulling the registry image can be found in the 1password production vault:

```
kubectl create secret docker-registry dev-registry-access \
  --namespace=gitlab \
  --docker-server=dev.gitlab.org:5005 \
  --docker-username=k8s-workloads-deploy-token \
  --docker-password=<token value from 1password>
```

## Deploy

1. This is handled via CI/CD when changes are merged into master
    * See the [`.gitlab-ci.yml` file](../.gitlab-ci.yml)

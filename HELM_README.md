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

## GitLab Secrets

In order to work with the existing omnibus installation of GitLab.com, we will
need to bring in a few already configured items that exist in that environment.
These items will ensure that when the Deployment is spun up inside of Kubernetes
we interact appropriately with our existing infrastructure.

:warning: This guide assumes you are connected to the appropriate Kubernetes
cluster :warning:

For example, to copy secrets from the preprod environment for minikube:

```
## Example
export REMOTE_ENV="pre"
export CHEF_REPO="$HOME/workspace/chef-repo"
```

### Dev Registry Access

In order to ensure that we can always pull our images, we override the location
where our clusters pull images.  If GitLab.com were down, so would the ability
to pull images.  Therefore, we must ensure the following secret is available to
all clusters.

* `dev-registry-access`: Deploy token used for pulling down the GitLab fork of
  the Registry image

The deploy token for pulling the registry image can be found in the 1password
production vault:

```
kubectl create secret docker-registry dev-registry-access \
  --namespace=gitlab \
  --docker-server=dev.gitlab.org:5005 \
  --docker-username=k8s-workloads-deploy-token \
  --docker-password=<token value from 1password>
```

### Object Storage

We utilize object storage in a variety of ways, one of them is for `lfs`,
`artifacts`, and `uploads`.  For this we need a differently formatted
configuration file compared to the Container Registry.

1. Create a file called `gitlab-object-storage.yml` with the following content:

```yaml
provider: Google
google_json_key_string: |
  {
  }
```

1. The `google_json_key_string` can be found via:

```
$CHEF_REPO/bin/gkms-vault-show gitlab-omnibus-secrets $REMOTE_ENV \
  | jq -r '."gitlab-server"."google-creds".json_base64' | base64 -d
```

1. Apply this handcraft file to the cluster:

```
kubectl create secret generic gitlab-object-storage \
  --from-file gitlab-object-storage.yml
```

### Postgresql

```
pg=$($CHEF_REPO/bin/gkms-vault-show gitlab-omnibus-secrets $REMOTE_ENV \
  | jq -r '."omnibus-gitlab".gitlab_rb."gitlab-rails".db_password')

kubectl create secret generic gitlab-postgres-credential \
  --namespace gitlab \
  --from-literal=secret=$pg
```

### Redis

_Note that the PreProd environment uses cloud memorystore which does
[not support redis auth](https://stackoverflow.com/questions/52122294/how-to-add-password-to-google-cloud-memorystore),
access is granted by network_

```
redis_pass=$($CHEF_REPO/bin/gkms-vault-show gitlab-omnibus-secrets $REMOTE_ENV \
  | jq -r '."omnibus-gitlab".gitlab_rb."gitlab-rails".redis_password')

> **Note:** this is not needed for the PreProd environment
kubectl create secret generic gitlab-redis-credential --namespace=gitlab  \
  --from-literal=secret=$redis_pass
```

### Gitaly

```
gitaly=$($CHEF_REPO/bin/gkms-vault-show gitlab-omnibus-secrets $REMOTE_ENV \
  | jq -r '."omnibus-gitlab".gitlab_rb."gitlab-rails".gitaly_token')

kubectl create secret generic gitlab-gitaly-credential \
  --namespace gitlab \
  --from-literal=secret=$gitaly
```

### GitLab Rails

* Create a temporary file named `secrets.yml`, populate it with the following:

```yaml
production:
  secret_key_base: something
  otp_key_base: something
  db_key_base: something
  openid_connect_signing_key: |
    -----BEGIN RSA PRIVATE KEY-----
    something
    -----END RSA PRIVATE KEY-----
```

One can find the necessary values for the above in our chef vault.  Replace
`something` with the value noted when finding the same key using the following
command:

```
$CHEF_REPO/bin/gkms-vault-show gitlab-omnibus-secrets $REMOTE_ENV \
  | jq -r '."omnibus-gitlab".gitlab_rb."gitlab-rails"'
```

After the values are populated, simply run the following:

```
kubectl create secret generic gitlab-rails-secret --namespace gitlab --from-file secrets.yml
```

Delete this file from your workspace.


### Mailroom

The following secrets are needed for the Mailroom service:

* `gitlab-mailroom-imap`: Provides IMAP credentials
* `gitlab-redis-credential`: Provides credentials for redis
  * The Redis credential is provided above

```
incoming_pass=$($CHEF_REPO/bin/gkms-vault-show gitlab-omnibus-secrets $REMOTE_ENV \
  | jq -r '."omnibus-gitlab".gitlab_rb."gitlab-rails".incoming_email_password')

kubectl create secret generic gitlab-mailroom-imap --namespace=gitlab  \
  --from-literal=password=$incoming_pass
```

### Container Registry

The following secrets are needed for the Container Registry service:

* `registry-storage`: For accessing object storage, local to the registry service and contains the json credential for the service account
* `registry-httpsecret`: Random data used to sign state, local to the registry service
* `registry-certificate`: Used for signing tokens

```
$CHEF_REPO/bin/gkms-vault-show gitlab-omnibus-secrets $REMOTE_ENV \
  | jq -r '."gitlab-server"."google-creds".json_base64_registry' \
  | base64 -D > service-account-key.json


HTTP_SECRET=$($CHEF_REPO/bin/gkms-vault-show gitlab-omnibus-secrets $REMOTE_ENV| \
  jq -r '."omnibus-gitlab".gitlab_rb.registry.http_secret')


$CHEF_REPO/bin/gkms-vault-show gitlab-omnibus-secrets $REMOTE_ENV | \
  jq -r '."omnibus-gitlab".ssl.registry_certificate' > registry-auth.crt

$CHEF_REPO/bin/gkms-vault-show gitlab-omnibus-secrets $REMOTE_ENV | \
  jq -r '."omnibus-gitlab".ssl.registry_private_key' > registry-auth.key
```

Use the `$REMOTE_ENV` version of `registry.gcs.yaml` or create a new one with
the [example gcs_config](https://gitlab.com/charts/gitlab/blob/master/examples/objectstorage/registry.gcs.yaml)

```
cd input/$REMOTE_ENV
```

Create the secrets

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
  --from-file=registry-auth.crt=registry-auth.crt \
  --from-file=registry-auth.key=registry-auth.key
```

## Deploy

1. This is handled via CI/CD when changes are merged into master
    * See the [`.gitlab-ci.yml` file](../.gitlab-ci.yml)

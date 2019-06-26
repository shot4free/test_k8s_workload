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

1. Copy the service account json into the `input/<ENV>/` directory (found via chef)
1. Copy the [example gcs
   config](https://gitlab.com/charts/gitlab/blob/master/examples/objectstorage/registry.gcs.yaml)
   into the `input/<ENV>/` directory
1. Create our secret: 

```
kubectl create secret generic registry-storage
  --namespace=gitlab \
  --from-file=config=input/<ENV>/registry-storage.yaml \
  --from-file=gcs.json=input/<ENV>/<service-account-key>.json
```

### Secret for JWT Token

1. This token is already generated for us with our omnibus installation.  Pull
   it from chef and plop it here (found in our vaults at
   `omnibus-gitlab:gitlab_rb.registry.http_secret`):
1. `kubectl create secret generic registry-httpsecret \
  --namespace=gitlab \
  --from-literal=secret=GENERATED_HTTP_SECRET`

### Secret for Token Signing Certificate

1. Download the store the certificate into the `input/<ENV>/` directory.  Pull
   it from chef, in our vaults at
   `omnibus-gitlab:gitlab_rb:ssl:registry_certificate`
1. `kubectl create secret generic registry-certificate \
  --namespace=gitlab \
  --from-file=registry-auth.crt=input/<ENV>/<REGISTRY_CERTIFICATE_FILENAME>`

## Generate our Helm Configurations

1. `./bin/generate.sh`
1. Commit
1. Push for Review

## Deploy

1. This is handled via CI/CD when changes are merged into master
    * See the [`.gitlab-ci.yml` file](../.gitlab-ci.yml)

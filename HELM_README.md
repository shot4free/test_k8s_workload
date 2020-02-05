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

There is an upstream helm chart wrapped into a helm release 
called `gitlab-secrets` which we can install in order to populate all the secrets
needed to run the Gitlab helm chart. We use [helmfile](https://github.com/roboll/helmfile)
to obtain the values for these secrets from our existing infrastructure, and populate
the values for the helm chart in the appropriate locations. In order to install
this chart, you need to have a working `gcloud` setup. The following command
installs the helm chart (specifying the environment you wish to use secrets
from with the `-e` flag)

```
helmfile -e pre apply --suppress-secrets
```

If you wish to cleanup all the secrets out of your environment, simply run

```
helmfile -e pre destroy
```

## Deploy

1. This is handled via CI/CD when changes are merged into master
    * See the [`.gitlab-ci.yml` file](../.gitlab-ci.yml)

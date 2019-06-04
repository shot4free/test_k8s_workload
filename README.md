# gitlab-com

Kubernetes Workload configurations for GitLab.com

## Storage

:warning: **WARNING** :warning:

The following are _NOT_ allowed this repository:
* Files that create Kubernetes Objects of type `Secret`
* Files that contain secrets in plain text

## GitLab Environments Configuration

| Environment | URL |
| ----------- | --- |
| `pre`       | `https://pre.gitlab.com` |

## GitLab CI/CD Variables Configuration

Each variable is applied to the environment defined above

| Variable | What it is |
| -------- | ---------- |
| `CLUSTER` | Name of the cluster as configured in GKE |
| `PROJECT` | Name of the project associated for the desired target cluster |
| `CLOUD_SERVICE_KEY` | Key provided by the Service Account described below |
| `ZONE` | GCP Zone for which the cluster resides |

## GCP IAM Configuration

### Service Account
1. `k8s-workloads` - Deploy user for our k8s-workloads configurations
    * This is currently manually configured
1. Configured with Role `Kubernetes Engine Developer`
1. A `json` formatted key is then created
1. The downloaded file is then base64 encoded and placed into the above
   `CLOUD_SERVICE_KEY` variable targeting the environment for which it was
   created

### Cluster User Configuration

The bot user `k8s-workloads` will not have administrative access by default.  We
need to create a cluster role binding to ensure that our bot user will have the
ability to create RBAC permissions for our various components.  This only needs
to be done the first time a cluster is configured.  Run the following,
substituting `SERVICE_ACCOUNT_EMAIL_ADDRESS` with the name provided by the IAM
role above:

`kubectl create clusterrolebinding k8s-workloads --clusterrole=cluster-admin
--user=<SERVICE_ACCOUNT_EMAIL_ADDRESS>`

## Create/Apply Configurations

At this moment, we use our own helm charts to generate the Kubernetes
configuration for GitLab.com. This may change in the future as currently some
features of GitLab are [unsupported in our current Helm
charts](https://docs.gitlab.com/charts/#limitations).  Our infrastructure is
also [broken into multiple
fleets](https://about.gitlab.com/handbook/engineering/infrastructure/production-architecture/),
something our Helm chart also does not yet accomplish.  We'll address those
problems when we get to them. Until then, see [HELM_README.md](HELM_README.md)
to get started.

## Decisions

One can read about how we've come to decide how this repository is setup by
viewing our design document: https://about.gitlab.com/handbook/engineering/infrastructure/design/kubernetes-configuration/

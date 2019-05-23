# gitlab-com

Kubernetes Workload configurations for GitLab.com

## How To

This repo utilizes [GitLab Flow] method of deploying changes.  Please submit all
required changes to the appropriate branch:

| branch       | environment |
| ------       | ----------- |
| `master`     | `pre`       |

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

## Decisions

Follow along with how this repository is governed by reading through the
following epic: [Kubernetes Configuration Epic 64]

[GitLab Flow]: https://docs.gitlab.com/ee/workflow/gitlab_flow.html#environment-branches-with-gitlab-flow
[Kubernetes Configuration Epic 64]: https://gitlab.com/groups/gitlab-com/-/epics/64

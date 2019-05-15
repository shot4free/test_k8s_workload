# k8s-workloads

Kubernetes Workload configurations for GitLab.com

## How To

This repo utilizes [GitLab Flow] method of deploying changes.  Please submit all
required changes to the appropriate branch:

| branch       | environment |
| ------       | ----------- |
| `master`     | N/A         |

## Storage

:warning: **WARNING** :warning:

The following are _NOT_ allowed this repository:
* Files that create Kubernetes Objects of type `Secret`
* Files that contain secrets in plain text

## Decisions

Follow along with how this repository is governed by reading through the
following epic: [Kubernetes Configuration Epic 64]

[GitLab Flow]: https://docs.gitlab.com/ee/workflow/gitlab_flow.html#environment-branches-with-gitlab-flow
[Kubernetes Configuration Epic 64]: https://gitlab.com/groups/gitlab-com/-/epics/64

# gitlab-com

Kubernetes Workload configurations for GitLab.com

:warning: **WARNING** :warning:

The following are _NOT_ allowed this repository:
* Files that contain Kubernetes Objects of type `Secret`
* Files that contain secrets in plain text

## Services

The following services are managed by this Chart:

| Service | Upgrades |
| --- | --- |
| [Git HTTPs](https://gitlab.com/gitlab-org/gitlab) ([readiness](https://gitlab.com/gitlab-com/gl-infra/readiness/-/blob/master/git-https-websockets/index.md)) | Auto-deploy pipeline created from a pipeline trigger from the deployer pipeline |
| [Sidekiq](https://gitlab.com/gitlab-org/gitlab) ([readiness](https://gitlab.com/gitlab-com/gl-infra/readiness/-/blob/master/sidekiq/index.md)) | Auto-deploy pipeline created from a pipeline trigger from the deployer pipeline |
| [Registry](https://gitlab.com/gitlab-org/container-registry) ([readiness](https://gitlab.com/gitlab-com/gl-infra/readiness/-/blob/master/registry-gke/overview.md)) | Done by manually setting a version in [init-values.yaml](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/7bd15324144a2c85699bf685fb606b6dd7c92975/releases/gitlab/values/init-values.yaml.gotmpl#L75) ([release template](https://gitlab.com/gitlab-org/container-registry/-/blob/master/.gitlab/issue_templates/Release%20Plan.md)). |
| [Mailroom](https://gitlab.com/gitlab-org/gitlab-mail_room) ([readiness](https://gitlab.com/gitlab-com/gl-infra/readiness/-/blob/master/mailroom/overview.md)) | Upgrades are done manually be setting a version in [values.yaml](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/7bd15324144a2c85699bf685fb606b6dd7c92975/releases/gitlab/values/values.yaml.gotmpl#L1076-1080) ([release template](https://gitlab.com/gitlab-org/gitlab-mail_room/-/blob/master/.gitlab/issue_templates/Release.md)). |

## GitLab Environments Configuration

## Environments

On merge, configuration changes will be deployed to the following environments:

| Environment | URL |
| ----------- | --- |
| `pre`       | `https://pre.gitlab.com`     |
| `gstg`      | `https://staging.gitlab.com` |
| `gprd`      | `https://gitlab.com`         |

:warning: It is possible right for configuration changes to be applied to production before staging due to auto-deploy https://gitlab.com/gitlab-com/gl-infra/delivery/-/issues/1293 :warning:

## GitLab CI/CD Variables Configuration

Each variable is applied to the environment defined above

| Variable        | Description
| --------        | --------
| `CLUSTER`       | Name of the GKE cluster, ex: `gstg-gitlab-gke` or `gstg-us-east1-b`
| `REGION `       | Name of the region or zone of the cluster, ex: `us-east1` or `us-east1-b`
| `PROJECT`       | Name of the project, ex: `gitlab-staging-1`
| `SERVICE_KEY`   | Service Account key used for CI for write operations to the cluster
| `SERVICE_KEY_RO`| Service Account key used for CI for read operations, used on branches

## GitLab Secrets

In order to work with the existing omnibus installation of GitLab.com, we will need to bring in a few already configured items that exist in that environment.  These items will ensure that when the Deployment is spun up inside of Kubernetes we interact appropriately with our existing infrastructure.

:warning: This guide assumes you are connected to the appropriate Kubernetes cluster :warning:

There is an upstream helm chart wrapped into a helm release called `gitlab-secrets` which is installed in order to populate all the secrets needed to run the Gitlab helm chart. [Helmfile](https://github.com/roboll/helmfile) is used to obtain the values for these secrets from our existing infrastructure that is used for chef, and populate the values for the helm chart in the appropriate locations. In order to install this chart, you need to have a working `gcloud` setup. These secrets will be deployed along with our gitlab helm chart at the same time using the `k-ctl` wrapper script.

## Create/Apply Configurations

## Decisions

Read about how we've come to decide how this repository is setup by viewing our [design document](https://about.gitlab.com/handbook/engineering/infrastructure/library/kubernetes/configuration/).

## Working locally

The `./bin/k-ctl` script is used both locally and in CI to manage the chart for different environments.

### Prerequisites

Complete the [Workstation setup](https://gitlab.com/gitlab-com/runbooks/blob/master/docs/uncategorized/k8s-operations.md#workstation-setup) steps described in the [k8s-operations runbook](https://gitlab.com/gitlab-com/runbooks/blob/master/docs/uncategorized/k8s-operations.md).

### minikube

1. `minikube start`
1. `./bin/k-ctl -e pre -l minikube install`
1. Use helmfile to install the `gitlab-secrets` helm chart which will populate
all the secrets needed from the appropriate location
  * Use the `pre` as the environment to pull secrets from
  ```
  helmfile -e pre apply --suppress-secrets
  ```

Get the service, example:
```
% minikube service list
|-------------|------------------------------------|--------------------------------|
|  NAMESPACE  |                NAME                |              URL               |
|-------------|------------------------------------|--------------------------------|
| default     | kubernetes                         | No node port                   |
| gitlab      | gitlab-registry                    | http://192.168.99.103:30799    |
|             |                                    | http://192.168.99.103:30449    |
| kube-system | gitlab-monitoring-promethe-kubelet | No node port                   |
<snip>
```

### k3d

1. Install k3d https://github.com/rancher/k3d
1. `k3d create`
1. export KUBECONFIG=$(k3d get-kubeconfig)
1. Create the namespace `kubectl create namespace gitlab`
1. Configure secrets e.g. `helmfile -e pre apply --suppress-secrets`
1. Install the cluster `./bin/k-ctl -e pre -l k3d install`

### docker-desktop

1. Enable Kubernetes in the Docker preferences
1. Switch to the docker-desktop context
1. Create the namespace `kubectl create namespace gitlab`
1. Configure secrets e.g. `helmfile -e pre apply --suppress-secrets`
1. Install the cluster `./bin/k-ctl -e pre -l docker-desktop install`


### Using the local registry

Validate that the pods are running

```
% kubectl get pods -n gitlab
NAME                               READY   STATUS    RESTARTS   AGE
gitlab-registry-6995fbcf5b-jdw9h   1/1     Running   0          5m42s
gitlab-registry-6995fbcf5b-p9bgg   1/1     Running   0          5m38s
```
This is ordered in the same as the service port definition.  In the above we see
`gitlab-registry` has two entries, one for port 30799; this will map to port
5000.  The other port, 30449, will map to port 5001.  This can be validated by
       getting the service:
```
% kubectl get service -n gitlab
NAME              TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)                         AGE
gitlab-registry   NodePort   10.107.176.29   <none>        5000:30799/TCP,5001:30449/TCP   22m
```

Docker client forcibly allows connections via SSL, so we need to make a
configuration change locally.  This requires a configuration change to your
local docker configuration: https://docs.docker.com/registry/insecure/#deploy-a-plain-http-registry

Using the steps provided, and the example provided above, we'd utilize:
```
{
  "insecure-registries" : ["192.168.99.103:30799"]
}
```

Verify docker login:

```
% docker login http://192.168.99.103:30799
Username: jskarbek@gitlab.com
Password:
Login Succeeded
```

Verify docker push/pull:

```
% docker pull 192.168.99.103:30799/jskarbek/test0:1
1: Pulling from jskarbek/test0
Digest: sha256:1aa64ee3ef2c169c249cb64eae0a59adf9fd4df5de9712c140d2739d057c270d
Status: Downloaded newer image for 192.168.99.103:30799/jskarbek/test0:1
192.168.99.103:30799/jskarbek/test0:1
```

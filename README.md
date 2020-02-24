# gitlab-com

Kubernetes Workload configurations for GitLab.com

## Storage

:warning: **WARNING** :warning:

The following are _NOT_ allowed this repository:
* Files that contain Kubernetes Objects of type `Secret`
* Files that contain secrets in plain text

## GitLab Environments Configuration

| Environment | URL |
| ----------- | --- |
| `pre`       | `https://pre.gitlab.com`     |
| `gstg`      | `https://staging.gitlab.com` |
| `gprd`      | `https://gitlab.com`         |

## GitLab CI/CD Variables Configuration

Each variable is applied to the environment defined above

| Variable      | Default                     | What it is  |
| --------      | --------                    | ------------|
| `CLUSTER`     | Set in `.setup.bash`        | Name of the cluster as configured in GKE |
| `PROJECT`     | Set in `common/common.bash` | Name of the project
| `SERVICE_KEY` | None                        | Key provided by the Service Account |
| `SERVICE_KEY_RO`| None                      | Key provided by the Service Account |

View our common repo README for details on the above:
https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/common#gitlab-cicd-variables-configuration

## GitLab Secrets

In order to work with the existing omnibus installation of GitLab.com, we will
need to bring in a few already configured items that exist in that environment.
These items will ensure that when the Deployment is spun up inside of Kubernetes
we interact appropriately with our existing infrastructure.

:warning: This guide assumes you are connected to the appropriate Kubernetes
cluster :warning:

There is an upstream helm chart wrapped into a helm release called
`gitlab-secrets` which we install in order to populate all the secrets
needed to run the Gitlab helm chart. We use
[helmfile](https://github.com/roboll/helmfile) to obtain the values for these
secrets from our existing infrastructure that is used for chef, and populate the values for the helm
chart in the appropriate locations. In order to install this chart, you need to
have a working `gcloud` setup. These secrets will be deployed along with our
gitlab helm chart at the same time using the `k-ctl` wrapper script

## Create/Apply Configurations

At this moment, we use our own helm charts to generate the Kubernetes
configuration for GitLab.com. This may change in the future as currently some
features of GitLab are [unsupported in our current Helm
charts](https://docs.gitlab.com/charts/#limitations).  Our infrastructure is
also [broken into multiple
fleets](https://about.gitlab.com/handbook/engineering/infrastructure/production-architecture/),
something our Helm chart also does not yet accomplish.  We'll address those
problems when we get to them.

## Decisions

One can read about how we've come to decide how this repository is setup by
viewing our [design document](https://about.gitlab.com/handbook/engineering/infrastructure/library/kubernetes/configuration/).

## Working locally

The `./bin/k-ctl` script is used both locally and in CI to manage the chart for
different environments.

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

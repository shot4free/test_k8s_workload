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
| `pre`       | `https://pre.gitlab.com`     |
| `gstg`      | `https://staging.gitlab.com` |

## GitLab CI/CD Variables Configuration

Each variable is applied to the environment defined above

| Variable      | Default                     | What it is  |
| --------      | --------                    | ------------|
| `CLUSTER`     | Set in `.setup.bash`        | Name of the cluster as configured in GKE |
| `PROJECT`     | Set in `common/common.bash` | Name of the project
| `SERVICE_KEY` | None                        | Key provided by the Service Account described below |

## GCP IAM Configuration

### Service Account
1. `k8s-workloads` - Deploy user for our k8s-workloads configurations
    * This is currently created via Terraform
1. The user needs to be added to the correct IAM roles,
   `roles/container.developer` and `roles/compute.networkUser` you can use this example:
    * `gcloud projects add-iam-policy-binding gitlab-staging-1 --member 'serviceAccount:k8s-workloads@gitlab-staging-1.iam.gserviceaccount.com' --role 'roles/container.developer'`
    * `gcloud projects add-iam-policy-binding gitlab-staging-1 --member 'serviceAccount:k8s-workloads@gitlab-staging-1.iam.gserviceaccount.com' --role 'roles/compute.networkUser'`
    * To validate the above worked, run this, only the desired role should be
      printed: `gcloud projects get-iam-policy gitlab-staging-1 --flatten="bindings[].members" --format='table(bindings.role)' --filter="bindings.members:k8s-workloads@gitlab-staging-1.iam.gserviceaccount.com"`
1. A `json` formatted key needs to be created manually
1. The downloaded file is then copied into the `SERVICE_KEY` variable as type
   File

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

## Working locally

The `./bin/k-ctl` script is used both locally and in CI to manage the chart for
different environments.

### minikube

1. `minikube start`
1. `./bin/k-ctl -e minikube install`
1. Follow [HELM_README.md](HELM_README.md) to install the secrets
  * Use the `pre` as the environment to pull secrets from

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
1. Configure secrets (See `HELM_README.md`)
1. Install the cluster `./bin/k-ctl -e k3d install`

### docker-desktop

1. Enable Kubernetes in the Docker preferences
1. Switch to the docker-desktop context
1. Create the namespace `kubectl create namespace gitlab`
1. Configure secrets (See `HELM_README.md`)
1. Install the cluster `./bin/k-ctl -e docker-desktop install`


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

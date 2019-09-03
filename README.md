# PlantUML Helm Chart

PlantUML is a service that enabled UML diagrams. This Chart is maintained by
GitLab infrastructure for the deployment of PlantUML in GKE on GCP.

By default it configures the PlantUML in GKE with the following features:

* L7 load balancer w/ CDN
* Nginx sidecar for customizing headers

## Configuration

PlantUML requires one secret `plantuml-cert` which is the SSL certificate
for the service that will be added to the L7 GCP load balancer.

Before installing the chart you must create this secret:

```
kubectl create secret tls plantuml-cert --cert pre.plantuml.gitlab-static.net.chained.crt --key pre.plantuml.gitlab-static.net.key -n plantuml
```

The following table lists the configurable parameters of the cert-manager chart and their default values.

| Parameter | Description | Default |
| --------- | ----------- | ------- |
| `nginx_sidecar.server_name` | Endpoint of the PlantUML server | `example.com` |

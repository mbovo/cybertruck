# Kubernetes Cluster

## Requirements

The tool will perform a fast preflight check:

```bash
-------------------------
+ Preflight checks
  - Python3      OK
  - Terraform    OK
  - Helm         OK
  - kubectl      OK
  - gcloud       OK
  - Python3 env  OK
-------------------------
```
In order to use this automation you need to install:

- `python3` >= 3.7 (and python3-venv for virtual-env support)
- `terraform` >= v0.12.20
- `helm` >= v3.0.0
- `kubectl` (compatible with the chosen for the cluster version)
- `gcloud` (https://cloud.google.com/sdk/install)

## Usage

Startup a cluster with:

```bash
./cluster -s create
```

Installing tools and configuring the cluster

```bash
./cluster -s configure
```

Deleting when finished

```bash
./cluster -s delete
```

## Configuration

The configuration is a `yaml` file (default to `./config.yml`) with some information in it.
See [Configuration](docs/configuration.md) for more about syntax and examples

<details><summary>Kubernetes in Docker (KinD)</summary>
<p>
This example will create a cluster of 2 nodes, a master and a worker locally using docker. So the requirement is to have a working `Docker` installation

```yaml
---
cluster:
  type: kind
  name: "mycluster"
  config:
    kind: Cluster
    apiVersion: kind.x-k8s.io/v1alpha4
    nodes:
    - role: control-plane
    - role: worker
kubernetes:
 globals:
    domain_name: local.dev
  namespaces:
    - name: ingress
    - name: monitoring
    - name: cert-manager
  helm:
    - releaseName: ingress
      namespace: ingress
      repo: https://kubernetes-charts.storage.googleapis.com
      chart: nginx-ingress
      version: "1.34.2"
      customValues: # can be a string filename ora k/v map like this, if nothing to pass add it as empty map: {}
        controller:
          service:
            type: NodePort
    - releaseName: prometheus
      namespace: monitoring
      repo: https://kubernetes-charts.storage.googleapis.com
      chart: prometheus
      version: "11.0.3"
      customValues: {}
    - releaseName: grafana
      namespace: monitoring
      repo: https://kubernetes-charts.storage.googleapis.com
      chart: grafana
      version: "5.0.8"
      customValues: {}
    - releaseName: autoscaler
      namespace: monitoring
      repo: https://kubernetes-charts.storage.googleapis.com
      chart: prometheus-adapter
      version: "2.1.3"
      customValues:
        prometheus:
          url: "http://prometheus-server.monitoring"
          port: "80"
  kubectl_raw:
    - name: "Install cert-manager"
      cmds:
        - "apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.12.0/cert-manager.yaml"
        - "-n cert-manager rollout status deployment cert-manager"
  addons:
    - role: ingress-kind-proxy
      namespace: ingress
      vars:
        releaseName: ingress
    - role: certmanager
      namespace: cert-manager
      vars: {}
    - role: expose-monitoring
      namespace: monitoring
      vars: {}
```

</p></details>

<details><summary>GKE Example</summary>
<p>

```yaml
---
# if location is a region name the cluster will be multi-zone with that amount of nodes per zone
# otherwise will be a single-zone cluster with that amount of nodes as total
cluster:
  type: gke
  config:
    cluster_name: "cluster"
    project: "cybertruck"
    credential_file: "~/cybertruck-admin.json"
    location: "europe-north1"
    nodes: "1"
    machine_type: "n1-standard-1"
    cluster_version: "1.15.7-gke.23"
    network_policy: "true"
    network_policy_provider: "CALICO"

kubernetes:
 globals:
    domain_name: local.dev
  namespaces:
    - name: ingress
    - name: monitoring
    - name: cert-manager
  helm:
    - releaseName: ingress
      namespace: ingress
      repo: https://kubernetes-charts.storage.googleapis.com
      chart: nginx-ingress
      version: "1.34.2"
      customValues: # can be a string filename ora k/v map like this, if nothing to pass add it as empty map: {}
        controller:
          service:
            type: NodePort
    - releaseName: prometheus
      namespace: monitoring
      repo: https://kubernetes-charts.storage.googleapis.com
      chart: prometheus
      version: "11.0.3"
      customValues: {}
    - releaseName: grafana
      namespace: monitoring
      repo: https://kubernetes-charts.storage.googleapis.com
      chart: grafana
      version: "5.0.8"
      customValues: {}
    - releaseName: autoscaler
      namespace: monitoring
      repo: https://kubernetes-charts.storage.googleapis.com
      chart: prometheus-adapter
      version: "2.1.3"
      customValues:
        prometheus:
          url: "http://prometheus-server.monitoring"
          port: "80"
  kubectl_raw:
    - name: "Install cert-manager"
      cmds:
        - "apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.12.0/cert-manager.yaml"
        - "-n cert-manager rollout status deployment cert-manager"
  addons:
    - role: ingress-kind-proxy
      namespace: ingress
      vars:
        releaseName: ingress
    - role: certmanager
      namespace: cert-manager
      vars: {}
    - role: expose-monitoring
      namespace: monitoring
      vars: {}
```

This example will create a multi-zone cluster with 3 nodes on GKE.
As requirements you must have a google project pre-allocated and well configured and a credential file with correct IAM access rights.
</p></details>

The software installed will be:

- `Nginx` as ingress-controller
- `cert-manager` to handle TLS certificates and ACME-Verifier
- `Prometheus` exposed on https://prometheus.{{kubernetes.globals.domain_name}}
- `Grafana` exposed on https://grafana.{{kubernetes.globals.domain_name}} (Password will be accessible from a secret)
- `Prometheus-adapter` for autoscaling capabilities

### Expose custom Metrics

This configuration is by-hand for now

<details><summary>Example</summary>
<p>

```bash
kubectl -n monitoring edit cm autoscaler-prometheus-adapter -o yaml
kubectl apply -f autoscaler.yml
```

Add the following lines

```yaml
- seriesQuery: '{__name__="application_it_local_backend_MemeRequestService_createdMeme_total"}'
  seriesFilters: []
  resources:
    overrides:
      kubernetes_namespace:
        resource: namespace
      kubernetes_pod_name:
        resource: pod
  name:
    matches: "application_it_local_backend_MemeRequestService_createdMeme_total"
    as: ""
  metricsQuery: round(rate(<<.Series>>[2m]))
```
</p></details>

## Contribute

In order to contribue to this project please read carefully the following guidance.

- [Architecture](docs/architecture.md)
- [Configuration](docs/configuration.md)
- [Addons](docs/addons.md)

## License

This project is licensed under the [GNU AFFERO GENERAL PUBLIC LICENSE v3 + Commons Clause License v1.0](LICENSE.txt)

# Configuration

All the configuration is read from a yaml file.

_As of writing a little bug prevent to load realative path so you have to specify the full path to your configuration file unless is located in the same directory of `cluster` entrypoint script._

Please refer to [Architecture](architecture.md) for more information on how this project works.

The structure is very simple, the file is loaded as an [Ansible variables file](https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html#defining-variables-in-files) and used as python dict (k/v map)

Two global key must be present `cluster` and `kubernetes`, with the following *required* sub keys:

```yaml
cluster:
  type: string
  config: {}

kubernetes:
  globals: {}
  namespaces: []
  addons: []
```

_As of writing there are any validation check on this structure so please keep in mind when planning tests or dealing with it._

## Cluster object

The cluster object can be of two types right now: `gke` or `kind` and will load respectively setup action from same-name directories

### GKE clusters

Will use `terraform` to create a GKE cluster on google cloud infrastructure. You have to provide a valid google project name (previously created and setup by hand) and a valid credential file where your service account with IAM access rights is located.

The whole content of key `config` will be reflected to `terraform variables` and ingested as-is

```yaml
cluster:
  type: gke
  config:
    cluster_name: "cluster"
    project: "cybertruck"
    credential_file: "~/cybertruck-admin.json"
    location: "europe-north1"
    nodes: "1"
    machine_type:  "n1-standard-1"
    cluster_version: "1.15.7-gke.23"
    network_policy: "true"
    network_policy_provider: "CALICO"

```

### KinD clusters

When you have to test some [addon](addons.md) or you need to create a cluster locally you can leverage the cool [Kubernetes in Docker](https://github.com/kubernetes-sigs/kind).

Here the configuration is quite different, we have a new sub-key `name` used to identify the cluster (in case you want to create more than once)
Again the whole `config` key will be reflected as kind-config.yaml and ingested as-is so please refer to the official [kind configuration](https://kind.sigs.k8s.io/docs/user/configuration/) 

```yaml
## Otherwise use Kubernetes in Docker KinD
cluster:
  type: kind
  name: "mycluster"
  config:
    kind: Cluster
    apiVersion: kind.x-k8s.io/v1alpha4
    nodes:
    - role: control-plane
    - role: worker
  ## Enabling persistent storage outside of container (needed by each worker)
  #     extraMounts:
  #       - hostPath: /tmp
  #         containerPath: /var/local-path-provisioner

```

## Kubernetes object

The kubernetes object represent the configuration as code for all things related to the cluster after the creation of the infrastructure.
Here you fill find `namespaces` and their details; a series of [addon](addons.md) that will be installed (and configured) into the cluster and globals variables.

The latter is used to define variables used without a specified scope.
The `namespaces` key defines the list of namespaces that will be created in the kubernetes cluster. Each of them could have `annotations`, `labels`, `limits` and `quotas` exactly as described in the kubernetes official documentation:
- [Namespace](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.11/#namespace-v1-core)
- [LimitRange](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.11/#limitrange-v1-core)
- [ResourceQuota](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.11/#resourcequota-v1-core)

```yaml
kubernetes:
  globals:
    domain_name: local.dev
  namespaces:
    - name: ingress
    - name: test
      annotations:
        key: value
      labels:
        key: value
      limits:
        default:
          memory: 600Mi
        defaultRequest:
          memory: 200Mi
        type: container
        max:
          memory: 2Gi
        min:
          memory: 1Gi
      quotas:
        hard:
          requests.cpu: "1"
          requests.memory: "1Gi"
          limits.cpu: "2"
          limits.memory: "2Gi"
          pods: "20"
    - name: ingress
    - name: cert-manager
    - name: monitoring
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
        publishAddr: "10.10.10.50"
```

### Helm configuration

Helm is a first class citizen in cybertruck, so there is a dedicated sub-key in the configuration file.
This is a list of charts with specific fields and will trigger an `helm upgrade` command passing the specified options.
Custom values can be override using a map representation `customValues` like in the example below or a simpler string with the full path to a `values.yml` file.

```yaml
  helm:
    - releaseName: ingress  # the release name              REQUIRED
      namespace: ingress    # where to install this chart,  REQUIRED
      repo: https://kubernetes-charts.storage.googleapis.com      # chartrepo where to find the cart REQUIRED
      chart: nginx-ingress  # chart name                    REQUIRED
      version: "1.34.2"     # can not be empty (for now)    REQUIRED
      extraOptions: "-v5"   # extraOptions are passed as-is to helm upgrade comman  (optional)
      customValues:         # can be a string filename ora k/v map like this, if nothing to pass add it as empty map: {}  (optional)
        controller:
          service:
            type: NodePort
```

### Kubectl raw commands

If you have to issue raw kubectl commands to customize or apply settings you can do that simply using the following syntax:

```yaml
  kubectl_raw:
    - name: "Install cert-manager"
      cmds:
        - "apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.12.0/cert-manager.yaml"
        - "-n cert-manager rollout status deployment cert-manager"
```

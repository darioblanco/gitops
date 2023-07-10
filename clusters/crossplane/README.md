# Crossplane

## Folder structure

The folder contains the following top directories:

- **providers** dir contains Crossplane [providers](https://docs.crossplane.io/v1.12/concepts/providers/)
- **resources** dir contains Crossplane [managed resources](https://docs.crossplane.io/v1.12/concepts/managed-resources/) and [composite resources](https://docs.crossplane.io/v1.12/concepts/composition/).

```text
├── providers
└── resources
```

## Prerequisites

- A Kubernetes cluster with at least 6 GB of RAM permissions to create pods and secrets in the Kubernetes cluster
- [Helm](https://helm.sh/) version v3.2.0 or later
- A GCP account with permissions to create a storage bucket
- GCP [account keys](https://cloud.google.com/iam/docs/creating-managing-service-account-keys)
- GCP [Project ID](https://support.google.com/googleapi/answer/7014113?hl=en)

## Provision a GKE cluster

To provision a GKE cluster, first set your `kubectl` context to the cluster holding Crossplane.

### 1. Install the GCP provider

```sh
$ kubectl apply -f providers/gcp-provider.yaml
$ kubectl get providers
NAME                   INSTALLED   HEALTHY   PACKAGE                                        AGE
upbound-provider-gcp   True        True      xpkg.upbound.io/upbound/provider-gcp:v0.28.0   107s
```

A provider installs their own Kubernetes Custom Resource Definitions (CRDs). These CRDs allow you to create GCP resources directly inside Kubernetes.

You can view the new CRDs with kubectl get crds. Every CRD maps to a unique GCP service Crossplane can provision and manage.

### 2. Create the Kubernetes secret for GCP

The provider requires credentials to create and manage GCP resources.
Providers use a Kubernetes Secret to connect the credentials to the provider.

For basic user authentication, use a Google Cloud service account JSON file.
See the [GCP Docs](https://cloud.google.com/iam/docs/creating-managing-service-account-keys).

Save the JSON file as `gcp-credentials.json`, then:

```sh
kubectl create secret \
generic gcp-secret \
-n crossplane-system \
--from-file=creds=./gcp-credentials.json
```

### 3. Create a ProviderConfig

A `ProviderConfig` customizes the settings of the GCP Provider.

```sh
kubectl apply -f providers/gcp-provider-config.yaml
```

### 4. Create a Managed Resource (MR)

Now that the provider is configured we can create Kubernetes resources so Crossplane
defines the required state in our target cloud provider.

The `./resources/` folder has some managed resource examples.

```sh
kubectl apply -f resources/bucket/yaml
```

## Resources

[GCP Quickstart](https://docs.crossplane.io/v1.12/getting-started/provider-gcp/)

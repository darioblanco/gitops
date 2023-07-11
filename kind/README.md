# Kind

This folder contains configuration files for setting up local Kubernetes
clusters using [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/) (Kubernetes in Docker).

Kind allows you to create production-like Kubernetes cluster in your own computer.

See [creating a cluster](https://kind.sigs.k8s.io/docs/user/quick-start/#creating-a-cluster) in Kind's documentation.

## Requirements

- `podman`: make sure you have Podman installed. [Installation instructions](https://podman.io/docs/installation)
  - You can alternatively install `docker`, as `podman` has still experimental support with `kind`. You can download it [here](https://www.docker.com/get-started).
- `kind`: the main requirement. You can install it by following the instructions [here](https://kind.sigs.k8s.io/docs/user/quick-start/), or in MacOS with homebrew (`brew install kind`).
- `kubectl`: to connect to the clusters. You can install it by following the instructions [here](https://kubernetes.io/docs/tasks/tools/).
- `kubectx` (optional): very useful tool to make easier the switch between kubernetes contexts. Install it in MacOS with homebrew with `brew install kubectx`.

## Creating local Kubernetes clusters

For instance, to create two local clusters
(`production` and `staging` with the `kind-production` and `kind-staging` contexts respectively)

```sh
$ kind create cluster --name crossplane --config crossplane.yaml
$ kind create cluster --name production --config production.yaml
$ kind create cluster --name staging --config staging.yaml
$ kind get clusters
crossplane
production
staging
```

To switch between clusters:

```sh
# kubectl will connect to the crossplane cluster and create its context
kubectl cluster-info --context kind-crossplane
# kubectl will connect to the production cluster and create its context
kubectl cluster-info --context kind-production
# kubectl will connect to the staging cluster and create its context
kubectl cluster-info --context kind-staging
```

Alternatively, you can use a tool like `kubectx` (`brew install kubectx`):

```sh
$ kubectx
kind-crossplane
kind-production
kind-staging
$ kubectx kind-production
Switched to context "kind-production".
```

## Accessing a cluster

You can access the cluster using `kubectl`. Make sure you have selected the proper context.

For instance:

```sh
kubectx kind-staging
kubectl get namespaces
```

## Deleting the cluster

To delete a `kind` cluster:

```sh
kind delete cluster --name myname
```

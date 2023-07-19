# Infrastructure

Infrastructure components for Kubernetes clusters.
They provide essential functionality or services that are shared among multiple applications
or services running on the cluster, and they can be seen often in multiple clusters as they are
foundational services.

## Folder structure

The infrastructure addons is structured into:

- `infrastructure/controllers/` contains namespaces and Helm release definitions for Kubernetes controllers
- `infrastructure/configs/` contains Kubernetes custom resources such as cert issuers and networks policies

```text
└── infrastructure
    ├── configs
    │   ├── base
    │   ├── dev
    │   ├── prod
    │   └── staging
    └── controllers
        ├── base
        ├── dev
        ├── prod
        └── staging
```

In `infrastructure/controllers/` we have the Flux `HelmRepository` and `HelmRelease` definitions such as:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: cert-manager
  namespace: cert-manager
spec:
  interval: 30m
  chart:
    spec:
      chart: cert-manager
      version: "1.x"
      sourceRef:
        kind: HelmRepository
        name: cert-manager
        namespace: cert-manager
      interval: 12h
  values:
    installCRDs: true
```

Note that with `interval: 12h` we configure Flux to pull the Helm repository index every twelfth hours to check for updates.
If the new chart version that matches the `1.x` semver range is found, Flux will upgrade the release.

In `infrastructure/configs/` dir we have Kubernetes custom resources, such as the Let's Encrypt issuer:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt
spec:
  acme:
    # Replace the email address with your own contact email
    email: fluxcdbot@users.noreply.github.com
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-nginx
    solvers:
      - http01:
          ingress:
            class: nginx
```

In `clusters/apps-prod/infrastructure.yaml` we replace the Let's Encrypt server value to point to the production API:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: infra-configs
  namespace: flux-system
spec:
  # ...omitted for brevity
  dependsOn:
    - name: infra-controllers
  patches:
    - patch: |
        - op: replace
          path: /spec/acme/server
          value: https://acme-v02.api.letsencrypt.org/directory
      target:
        kind: ClusterIssuer
        name: letsencrypt
```

Note that with `dependsOn` we tell Flux to first install or upgrade the controllers and only then the configs.
This ensures that the Kubernetes CRDs are registered on the cluster, before Flux applies any custom resources.

## Monitoring

Monitoring is provisioned with the [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) chart (using the Prometheus Operator) and the [loki-stack](https://github.com/grafana/helm-charts/tree/main/charts/loki-stack).

See [Flux's monitoring guide](https://fluxcd.io/flux/guides/monitoring/)

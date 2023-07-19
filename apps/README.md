# Apps

## Folder structure

The apps configuration is structured into:

- **apps/base/** contains namespaces and Helm release definitions
- **apps/dev/** contains the production Helm release values
- **apps/prod/** contains the production Helm release values
- **apps/staging/** contains the staging values

```text
└── apps
    ├── base
    ├── dev
    ├── prod
    └── staging
```

## Helm releases

The podinfo example shows how a helm release is managed in different environments.

In `apps/base/podinfo/` we have a Flux `HelmRelease` with common values for both clusters:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: podinfo
  namespace: podinfo
spec:
  releaseName: podinfo
  chart:
    spec:
      chart: podinfo
      sourceRef:
        kind: HelmRepository
        name: podinfo
        namespace: flux-system
  interval: 50m
  values:
    ingress:
      enabled: true
      className: nginx
```

In `apps/staging/` dir we have a Kustomize patch with the staging specific values:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: podinfo
spec:
  chart:
    spec:
      version: ">=1.0.0-alpha"
  test:
    enable: true
  values:
    ingress:
      hosts:
        - host: podinfo.staging
```

Note that with `version: ">=1.0.0-alpha"` we configure Flux to automatically upgrade
the `HelmRelease` to the latest chart version including alpha, beta and pre-releases.

In `apps/production/` dir we have a Kustomize patch with the production specific values:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: podinfo
  namespace: podinfo
spec:
  chart:
    spec:
      version: ">=1.0.0"
  values:
    ingress:
      hosts:
        - host: podinfo.production
```

Note that with `version: ">=1.0.0"` we configure Flux to automatically upgrade
the `HelmRelease` to the latest stable chart version (alpha, beta and pre-releases will be ignored).

# gitops

[![e2e](https://github.com/darioblanco/gitops/actions/workflows/e2e.yaml/badge.svg)](https://github.com/darioblanco/gitops/actions/workflows/e2e.yaml)
[![json](https://github.com/darioblanco/gitops/actions/workflows/json.yaml/badge.svg)](https://github.com/darioblanco/gitops/actions/workflows/json.yaml)
[![test](https://github.com/darioblanco/gitops/actions/workflows/test.yaml/badge.svg)](https://github.com/darioblanco/gitops/actions/workflows/test.yaml)
[![yaml](https://github.com/darioblanco/gitops/actions/workflows/yaml.yaml/badge.svg)](https://github.com/darioblanco/gitops/actions/workflows/yaml.yaml)

Apply GitOps to everything with [Flux](https://fluxcd.io/) and [Crossplane](https://www.crossplane.io/).

Run `make help` for a list of commands.

## Repository structure

The Git repository contains the following top directories:

- **apps** dir contains Helm releases with a custom configuration per cluster.
- **clusters** dir contains the Flux configuration per cluster.
- **infrastructure** dir contains common infra tools such as ingress-nginx and cert-manager.
- **kind** dir contains kind configurations to create your local clusters for testing. See [kind/README](./kind/README.md).
- **crossplane** dir contains [Crossplane](https://www.crossplane.io/) definitions. See [crossplane/README](./kind/README.md)

```text
├── apps
│   ├── base
│   ├── production
│   └── staging
├── clusters
│   ├── crossplane
│   ├── production
│   └── staging
├── crossplane
│   ├── providers
│   └── resources
├── infrastructure
│   ├── configs
│   └── controllers
├── kind
└── scripts
```

### Applications

The apps configuration is structured into:

- **apps/base/** dir contains namespaces and Helm release definitions
- **apps/production/** dir contains the production Helm release values
- **apps/staging/** dir contains the staging values

```text
./apps/
├── base
│   └── podinfo
│       ├── kustomization.yaml
│       ├── namespace.yaml
│       ├── release.yaml
│       └── repository.yaml
├── production
│   ├── kustomization.yaml
│   └── podinfo-patch.yaml
└── staging
    ├── kustomization.yaml
    └── podinfo-patch.yaml
```

In **apps/base/podinfo/** dir we have a Flux `HelmRelease` with common values for both clusters:

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

In **apps/staging/** dir we have a Kustomize patch with the staging specific values:

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

In **apps/production/** dir we have a Kustomize patch with the production specific values:

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

### Infrastructure

The infrastructure is structured into:

- **infrastructure/controllers/** dir contains namespaces and Helm release definitions for Kubernetes controllers
- **infrastructure/configs/** dir contains Kubernetes custom resources such as cert issuers and networks policies

```text
./infrastructure/
├── configs
│   ├── cluster-issuers.yaml
│   ├── network-policies.yaml
│   └── kustomization.yaml
└── controllers
    ├── cert-manager.yaml
    ├── ingress-nginx.yaml
    ├── weave-gitops.yaml
    └── kustomization.yaml
```

In **infrastructure/controllers/** dir we have the Flux `HelmRepository` and `HelmRelease` definitions such as:

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

In **infrastructure/configs/** dir we have Kubernetes custom resources, such as the Let's Encrypt issuer:

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

In **clusters/production/infrastructure.yaml** we replace the Let's Encrypt server value to point to the production API:

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

## Bootstrap staging and production

The clusters dir contains the Flux configuration:

```text
./clusters/
├── production
│   ├── apps.yaml
│   └── infrastructure.yaml
└── staging
    ├── apps.yaml
    └── infrastructure.yaml
```

In **clusters/staging/** dir we have the Flux Kustomization definitions, for example:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: apps
  namespace: flux-system
spec:
  interval: 10m0s
  dependsOn:
    - name: infra-configs
  sourceRef:
    kind: GitRepository
    name: flux-system
  path: ./apps/staging
  prune: true
  wait: true
```

Note that with `path: ./apps/staging` we configure Flux to sync the staging Kustomize overlay and
with `dependsOn` we tell Flux to create the infrastructure items before deploying the apps.

Export your GitHub access token, username and repo name:

```sh
export GITHUB_TOKEN=<your-token>
export GITHUB_USER=<your-username>
export GITHUB_REPO=<repository-name>
```

Alternatively:

```sh
cp .envrc.example .envrc
# Fill the .envrc with your GITHUB_* variables
source .envrc
# Or if you have `direnv`
direnv allow
```

Verify that your staging cluster satisfies the prerequisites with:

```sh
flux check --pre
```

Set the kubectl context to your staging cluster and bootstrap Flux
(use `kind-staging` in the context flag if running a cluster locally with kind):

```sh
flux bootstrap github \
    --context=staging \
    --owner=${GITHUB_USER} \
    --repository=${GITHUB_REPO} \
    --branch=main \
    --personal \
    --path=clusters/staging
```

The bootstrap command commits the manifests for the Flux components in `clusters/staging/flux-system` dir
and creates a deploy key with read-only access on GitHub, so it can pull changes inside the cluster.

Watch for the Helm releases being installed on staging:

```console
$ watch flux get helmreleases --all-namespaces

NAMESPACE    	NAME         	REVISION	SUSPENDED	READY	MESSAGE
cert-manager 	cert-manager 	v1.11.0 	False    	True 	Release reconciliation succeeded
flux-system  	weave-gitops 	4.0.12   	False    	True 	Release reconciliation succeeded
ingress-nginx	ingress-nginx	4.4.2   	False    	True 	Release reconciliation succeeded
podinfo      	podinfo      	6.3.0   	False    	True 	Release reconciliation succeeded
```

Verify that the demo app can be accessed via ingress:

```console
$ kubectl -n ingress-nginx port-forward svc/ingress-nginx-controller 8080:80 &

$ curl -H "Host: podinfo.staging" http://localhost:8080
{
  "hostname": "podinfo-59489db7b5-lmwpn",
  "version": "6.2.3"
}
```

Bootstrap Flux on production by setting the context and path to your production cluster
(use `kind-production` in the context flag if running a cluster locally with kind):

```sh
flux bootstrap github \
    --context=production \
    --owner=${GITHUB_USER} \
    --repository=${GITHUB_REPO} \
    --branch=main \
    --personal \
    --path=clusters/production
```

Watch the production reconciliation:

```console
$ flux get kustomizations --watch

NAME             	REVISION     	SUSPENDED	READY	MESSAGE
apps             	main/696182e	False    	True 	Applied revision: main/696182e
flux-system      	main/696182e	False    	True 	Applied revision: main/696182e
infra-configs    	main/696182e	False    	True 	Applied revision: main/696182e
infra-controllers	main/696182e	False    	True 	Applied revision: main/696182e
```

### Access the Flux UI

To access the Flux UI on a cluster, first start port forwarding with:

```sh
kubectl -n flux-system port-forward svc/weave-gitops 9001:9001
```

Navigate to http://localhost:9001 and login using the username `admin` and the password `flux`.

[Weave GitOps](https://docs.gitops.weave.works/) provides insights into your application deployments,
and makes continuous delivery with Flux easier to adopt and scale across your teams.
The GUI provides a guided experience to build understanding and simplify getting started for new users;
they can easily discover the relationship between Flux objects and navigate to deeper levels of information as required.

![flux-ui-depends-on](.github/screens/flux-ui-depends-on.png)

You can change the admin password bcrypt hash in **infrastructure/controllers/weave-gitops.yaml**:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: weave-gitops
  namespace: flux-system
spec:
  # ...omitted for brevity
  values:
    adminUser:
      create: true
      username: admin
      # bcrypt hash for password "flux"
      passwordHash: "$2a$10$P/tHQ1DNFXdvX0zRGA8LPeSOyb0JXq9rP3fZ4W8HGTpLV7qHDlWhe"
```

To generate a bcrypt hash please see Weave GitOps
[documentation](https://docs.gitops.weave.works/docs/configuration/securing-access-to-the-dashboard/#login-via-a-cluster-user-account).

Note that on production systems it is recommended to expose Weave GitOps over TLS with an ingress controller and
to enable OIDC authentication for your organisation members.
To configure OIDC with Dex and GitHub please see this [guide](https://docs.gitops.weave.works/docs/guides/setting-up-dex/).

## Add clusters

If you want to add a cluster to your fleet, first clone your repo locally:

```sh
git clone https://github.com/${GITHUB_USER}/${GITHUB_REPO}.git
cd ${GITHUB_REPO}
```

Create a dir inside `clusters` with your cluster name:

```sh
mkdir -p clusters/dev
```

Copy the sync manifests from staging:

```sh
cp clusters/staging/infrastructure.yaml clusters/dev
cp clusters/staging/apps.yaml clusters/dev
```

You could create a dev overlay inside `apps`, make sure
to change the `spec.path` inside `clusters/dev/apps.yaml` to `path: ./apps/dev`.

Push the changes to the main branch:

```sh
git add -A && git commit -m "add dev cluster" && git push
```

Set the kubectl context and path to your dev cluster and bootstrap Flux
(use `kind-dev` in the context flag if running a cluster locally with kind):

```sh
flux bootstrap github \
    --context=dev \
    --owner=${GITHUB_USER} \
    --repository=${GITHUB_REPO} \
    --branch=main \
    --personal \
    --path=clusters/dev
```

## Identical environments

If you want to spin up an identical environment, you can bootstrap a cluster
e.g. `production-clone` and reuse the `production` definitions.

Bootstrap the `production-clone` cluster:

```sh
flux bootstrap github \
    --context=production-clone \
    --owner=${GITHUB_USER} \
    --repository=${GITHUB_REPO} \
    --branch=main \
    --personal \
    --path=clusters/production-clone
```

Pull the changes locally:

```sh
git pull origin main
```

Create a `kustomization.yaml` inside the `clusters/production-clone` dir:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - flux-system
  - ../production/infrastructure.yaml
  - ../production/apps.yaml
```

Note that besides the `flux-system` kustomize overlay, we also include
the `infrastructure` and `apps` manifests from the production dir.

Push the changes to the main branch:

```sh
git add -A && git commit -m "add production clone" && git push
```

Tell Flux to deploy the production workloads on the `production-clone` cluster:

```sh
flux reconcile kustomization flux-system \
    --context=production-clone \
    --with-source
```

## Testing

Any change to the Kubernetes manifests or to the repository structure should be validated in CI before
a pull requests is merged into the main branch and synced on the cluster.

This repository contains the following GitHub CI workflows:

- the [test](./.github/workflows/test.yaml) workflow validates the Kubernetes manifests and Kustomize overlays with [kubeconform](https://github.com/yannh/kubeconform)
- the [e2e](./.github/workflows/e2e.yaml) workflow starts a Kubernetes cluster in CI and tests the staging setup by running Flux in Kubernetes Kind.

## Secrets

Secrets encryption is done with `Mozilla SOPS` and `age` as its backend, at client level:

- [Using SOPS with age and git like a pro](https://devops.datenkollektiv.de/using-sops-with-age-and-git-like-a-pro.html)
- [Encrypted GitOps secrets with flux and age](https://major.io/p/encrypted-gitops-secrets-with-flux-and-age/)

To be able to decrypt secrets, you need to have a private file per cluster. The private file
has to be stored in `./cluster/{clusterName}/sops.agekey`.

### Generate a private key per cluster

Each cluster folder in `./clusters/` should have a git ignored `sops.agekey` file, whose public key
is listed in `./.sops.yaml` with a path_regex that involves files that only belong to that cluster.

You should have a file there with a format like this:

```sh
$ cat sops.agekey
# created: 2023-07-17T14:07:50+02:00
# public key: age1v6q8sylunaq9m08rwxq702enmmh9lama7sp47vkcw3z8wm74z39q846s3y
AGE-SECRET-KEY-THIS_IS_A_SECRET_THAT_SHOULD_NEVER_BE_PUSHED
```

Normally, you would need to put an `AGE-SECRET-*` value that is shared within your team. The
`sops.agekey` file will never be pushed to the repo as it is git ignored.

### Encrypt Kubernetes secrets

The encrypt command with `sops` is easy because the `.sops.yaml` configuration file already
points to the age public key based on the path of the target file. As the files to be encrypted
are always divided by cluster, `sops` know which public key to use thanks to that config.

In addition, the `sops` configuration defines an `encrypted_regex` so it will only encrypt the
`data` and `stringData` attributes, that are only found in Kubernetes secrets.

Therefore, to encrypt a secret so it can be pushed to the repo:

```sh
sops --in-place secret.yaml
```

Always make sure that the secrets you push to the repo are encrypted!

### Decrypt Kubernetes secrets

With the environment variables loaded (`source .envrc`), you can decrypt specific attributes from the YAML:

```sh
$ sops -d --extract '["data"]' secret.yaml
foo: ValueThatWasEncrypted
```

## References

- [Flux2 Example](https://github.com/fluxcd/flux2-kustomize-helm-example)
- [How to apply GitOps to everything with Crossplane and Flux](https://www.cncf.io/blog/2022/07/26/how-to-apply-gitops-to-everything-with-crossplane-and-flux/)

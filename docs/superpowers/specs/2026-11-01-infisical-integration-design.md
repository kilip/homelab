# Infisical Integration with Kubernetes & Flux GitOps Design

## Intent & Why
Integrate Infisical Cloud (`app.infisical.com`) into the Olympus K3s cluster using the official Infisical Kubernetes Secrets Operator via Flux CD GitOps. This allows Kubernetes workloads to dynamically sync application secrets and credentials from Infisical, while preserving SOPS for cluster-level settings and post-build substitutions (`settings.sops.yaml`).

## Goals & Non-Goals
- **Goals**:
  - Establish a clean, modular `k8s/security/` domain in the repository layout alongside existing top-level domains (`infra`, `network`, `storage`, `monitoring`, `apps`).
  - Deploy the official `secrets-operator` Helm chart from Infisical into the `security` namespace via Flux GitOps (`HelmRepository` and `HelmRelease`).
  - Configure authentication between the operator and Infisical Cloud via Universal Auth (Machine Identity: `clientId` and `clientSecret`).
  - Store Machine Identity credentials securely in a SOPS-encrypted secret (`universal-auth.sops.yaml`), maintaining zero plaintext secret commits.
  - Define clear conventions for how applications consume secrets using `InfisicalSecret` custom resources.
  - Keep `k8s/infra/settings.sops.yaml` intact as the single source of truth for cluster-wide post-build substitutions (e.g., `${SECRET_DOMAIN}`).
  - Ensure all manifests pass `just fl::validate`.
- **Non-Goals**:
  - Self-hosting the Infisical server or database inside the cluster (Infisical runs in Infisical Cloud).
  - Replacing `settings.sops.yaml` with Infisical (SOPS is intentionally retained for Flux settings).
  - Automatically migrating existing application `*.sops.yaml` secrets in one go (existing applications can adopt `InfisicalSecret` incrementally).

## Constraints
- **Zero Plaintext Secrets**: Machine identity credentials must be encrypted with SOPS using Age key rules defined in `.sops.yaml`.
- **Outbound Connectivity**: The operator pulls secrets from `https://app.infisical.com/api` over HTTPS; no inbound ports or internet-facing tunnels are required for the operator.
- **GitOps Validation**: All new manifests, Kustomizations, and Helm releases must pass `just fl::validate`.

## Approaches Considered
1. **Native Infisical Secrets Operator in Dedicated `k8s/security` Domain (Selected)**:
   - Introduce a new top-level domain `k8s/security/` with `infisical-operator/`.
   - Wire `k8s/infra/security.yaml` into `k8s/infra/kustomization.yaml` following the pattern of `network.yaml`, `storage.yaml`, `monitoring.yaml`, and `apps.yaml`.
   - Use Universal Auth with credentials managed via SOPS.
   - *Trade-off*: Adds one new top-level folder under `k8s/`, but mirrors the existing architectural pattern perfectly and keeps security/secret operators decoupled from general infra plumbing.
2. **External Secrets Operator (ESO) with Infisical Provider**:
   - Deploy ESO and use `ClusterSecretStore` pointing to Infisical.
   - *Trade-off*: Useful if multiple secret backends (AWS, HashiCorp Vault) are used simultaneously, but introduces extra abstraction layers and CRDs compared to Infisical's native operator.
3. **Deploy Operator Directly Under `k8s/infra/`**:
   - Place operator manifests directly in `k8s/infra/infisical-operator/`.
   - *Trade-off*: Avoids creating `k8s/security/`, but clutters the core `infra/` folder which is currently dedicated to Flux-system bootstrapping and root domain references.

## Architecture & Decisions

### 1. Directory Structure
```text
k8s/
├── infra/
│   ├── kustomization.yaml      # Adds security.yaml to resources
│   ├── security.yaml           # Flux Kustomization pointing to ./k8s/security
│   └── settings.sops.yaml      # Retained for cluster postBuild substitutions
└── security/
    ├── kustomization.yaml      # Aggregates security namespace and sub-components
    ├── namespace.yaml          # Creates 'security' namespace
    └── infisical-operator/
        ├── ks.yaml             # Flux Kustomization targeting app/
        └── app/
            ├── kustomization.yaml
            ├── repository.yaml # HelmRepository for Infisical charts
            ├── release.yaml    # HelmRelease for secrets-operator
            └── universal-auth.sops.yaml # Encrypted Machine Identity credentials
```

### 2. Root Flux Wiring
- **`k8s/infra/security.yaml`**:
  ```yaml
  apiVersion: kustomize.toolkit.fluxcd.io/v1
  kind: Kustomization
  metadata:
    name: security
    namespace: flux-system
  spec:
    interval: 10m0s
    retryInterval: 1m0s
    path: ./k8s/security
    prune: true
    wait: true
    timeout: 5m0s
    sourceRef:
      kind: GitRepository
      name: flux-system
  ```
- **`k8s/infra/kustomization.yaml`**: Add `security.yaml` to the resources list.
- **`k8s/security/kustomization.yaml`**:
  ```yaml
  apiVersion: kustomize.config.k8s.io/v1beta1
  kind: Kustomization
  resources:
    - ./namespace.yaml
    - ./infisical-operator/ks.yaml
  ```

### 3. Infisical Operator HelmRelease
- **`k8s/security/infisical-operator/ks.yaml`**:
  - Name: `infisical-operator`
  - Namespace: `flux-system`
  - TargetNamespace: `security`
  - Path: `./k8s/security/infisical-operator/app`
  - Prune: `true`, Wait: `true`
  - Decryption: SOPS with `sops-age` secret
- **`repository.yaml`**:
  - Name: `infisical-helm-charts`
  - Namespace: `security`
  - URL: `https://dl.cloudsmith.io/public/infisical/helm-charts/helm/charts/`
- **`release.yaml`**:
  - Chart: `secrets-operator`
  - Version: `~0.11` (or pinned latest stable `0.11.15`)
  - Target Namespace: `security`
  - Install/Upgrade CRDs: `CreateReplace`

### 4. Authentication (Universal Auth)
- A dedicated Machine Identity is created in Infisical Cloud (`app.infisical.com`) with Read access to project environments.
- Stored in `k8s/security/infisical-operator/app/universal-auth.sops.yaml`:
  ```yaml
  apiVersion: v1
  kind: Secret
  metadata:
    name: infisical-universal-auth
    namespace: security
  type: Opaque
  stringData:
    clientId: <INFISICAL_MACHINE_IDENTITY_CLIENT_ID>
    clientSecret: <INFISICAL_MACHINE_IDENTITY_CLIENT_SECRET>
  ```
- Cross-namespace or per-namespace usage:
  - The operator can be granted permission to read the credentials secret from the `security` namespace, or applications can reference secrets within their respective namespaces.

### 5. Application Consumption Pattern (`InfisicalSecret`)
When an application needs secrets from Infisical Cloud, it defines an `InfisicalSecret` resource:
```yaml
apiVersion: secrets.infisical.com/v1alpha1
kind: InfisicalSecret
metadata:
  name: app-secrets
  namespace: apps
spec:
  hostAPI: https://app.infisical.com/api
  resyncInterval: 60
  authentication:
    universalAuth:
      credentialsRef:
        secretName: infisical-universal-auth
        secretNamespace: security
      secretsScope:
        projectSlug: <project-slug>
        envSlug: prod
        secretsPath: /
  managedSecretReference:
    secretName: app-managed-secret
    secretNamespace: apps
```
The operator synchronizes secrets into the native Kubernetes Secret `app-managed-secret`, which the application mounts as environment variables or files.

### 6. Coexistence with SOPS
- **SOPS**: Retained for infrastructure-level configuration and post-build substitution (`settings.sops.yaml`), as well as bootstrapping the Infisical Machine Identity credentials (`universal-auth.sops.yaml`).
- **Infisical**: Used for runtime application secrets, tokens, and credentials, providing fine-grained access control, version history, audit logs, and automatic pod reload via Infisical Cloud dashboard.

## What's Left to the Builder
- Pin the exact stable patch version for `secrets-operator` in `release.yaml`.
- Set up boilerplate encrypted `universal-auth.sops.yaml` with placeholder keys matching `.sops.yaml` encryption rules.
- Document the step-by-step procedure for generating Machine Identity in Infisical Cloud and encrypting the real credentials via `sops`.

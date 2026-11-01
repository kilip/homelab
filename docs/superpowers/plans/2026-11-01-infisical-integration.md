# Infisical Integration with Kubernetes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Integrate Infisical Cloud into the K3s Kubernetes cluster using the official Infisical Secrets Operator via Flux CD GitOps in a new `k8s/security` domain, authenticating via Universal Auth while retaining SOPS for cluster settings.

**Architecture:** A new top-level `k8s/security/` domain is registered in `k8s/infra/kustomization.yaml` via `security.yaml`. Within it, the Infisical `secrets-operator` Helm chart is deployed to the `security` namespace with CRDs. A SOPS-encrypted Secret (`universal-auth.sops.yaml`) stores the Infisical Machine Identity credentials, enabling workloads to consume secrets dynamically via the `InfisicalSecret` CRD.

**Tech Stack:** Kubernetes (K3s), Flux CD v2 (Kustomize Controller & Helm Controller), Infisical Secrets Operator Helm Chart (`secrets-operator`), SOPS + Age encryption, `just` task runner, `kubeconform`.

**Spec:** `docs/superpowers/specs/2026-11-01-infisical-integration-design.md`

## Global Constraints

- **Zero Plaintext Secrets**: Machine identity credentials must be encrypted using SOPS with Age key conforming to `.sops.yaml` rules (`^k8s/.*\.sops\.ya?ml$`).
- **Convention & Tooling**: Run commands via `mise exec -- just ...` (or `just ...` if mise shims are active).
- **Validation**: All changes must pass `mise exec -- just fl::validate` without errors or unencrypted secret warnings.
- **Commit Style**: Use Conventional Commits with emoji (`type: <emoji> subject`), e.g., `feat: ✨ ...`, `docs: 📝 ...`.
- **SOPS Setting Coexistence**: `k8s/infra/settings.sops.yaml` remains the single source of truth for Flux post-build substitutions (`${SECRET_DOMAIN}`).

## Review Focus

- **SOPS unencrypted file prevention**: Ensure `universal-auth.sops.yaml` is fully encrypted with `sops` before any git commit and recognized by `just fl::validate`.
- **Validation coverage**: Ensure `.just/flux.just` includes `k8s/security` and `k8s/security/infisical-operator/app` so that all new manifests are evaluated during CI / `just fl::validate`.
- **CRD handling**: Ensure `release.yaml` specifies `install.crds: CreateReplace` and `upgrade.crds: CreateReplace` so the operator successfully installs `InfisicalSecret` CRDs.
- **Cross-namespace authentication**: Ensure documentation and secret structure accurately describe how `InfisicalSecret` in other namespaces (like `apps`) references `infisical-universal-auth` in `security`.
- **Flux dependency and pruning**: Ensure `k8s/security/namespace.yaml` sets `kustomize.toolkit.fluxcd.io/prune: disabled` to prevent the namespace from being accidentally deleted during reconciliation.

---

### Task 1: Establish `k8s/security` Domain & Root Flux Wiring

**Files:**
- Create: `k8s/security/namespace.yaml`
- Create: `k8s/security/kustomization.yaml`
- Create: `k8s/infra/security.yaml`
- Modify: `k8s/infra/kustomization.yaml:1-10`
- Modify: `.just/flux.just:125-135`

**Interfaces:**
- Consumes: `k8s/infra/kustomization.yaml`, GitRepository `flux-system`
- Produces: Flux Kustomization `security` pointing to `./k8s/security` and namespace `security`

- [ ] **Step 1: Create namespace manifest for `security`**

Create `k8s/security/namespace.yaml`:
```yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: security
  annotations:
    kustomize.toolkit.fluxcd.io/prune: disabled
```

- [ ] **Step 2: Create initial `k8s/security/kustomization.yaml`**

Create `k8s/security/kustomization.yaml`:
```yaml
---
# yaml-language-server: $schema=https://json.schemastore.org/kustomization
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ./namespace.yaml
```

- [ ] **Step 3: Create root Flux Kustomization in `k8s/infra/security.yaml`**

Create `k8s/infra/security.yaml`:
```yaml
---
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

- [ ] **Step 4: Add `security.yaml` to `k8s/infra/kustomization.yaml`**

Add `security.yaml` into resources of `k8s/infra/kustomization.yaml`:
```yaml
resources:
  - ./flux-system
  - settings.sops.yaml
  - network.yaml
  - storage.yaml
  - security.yaml
  - monitoring.yaml
  - apps.yaml
```

- [ ] **Step 5: Add `k8s/security` to `.just/flux.just` validation loop**

In `.just/flux.just`, add `k8s/security` in the directories list for the `validate` recipe right after `k8s/storage/...`.

- [ ] **Step 6: Run validation to verify setup**

Run: `mise exec -- just fl::validate`
Expected output: Includes `Validating k8s/security...` with 0 errors and all existing validations passing.

- [ ] **Step 7: Commit changes**

```bash
git add k8s/security/namespace.yaml k8s/security/kustomization.yaml k8s/infra/security.yaml k8s/infra/kustomization.yaml .just/flux.just
git commit -m "feat: ✨ establish security domain in flux and k8s"
```

---

### Task 2: Deploy Infisical Secrets Operator via Flux CD

**Files:**
- Create: `k8s/security/infisical-operator/ks.yaml`
- Create: `k8s/security/infisical-operator/app/repository.yaml`
- Create: `k8s/security/infisical-operator/app/release.yaml`
- Create: `k8s/security/infisical-operator/app/kustomization.yaml`
- Modify: `k8s/security/kustomization.yaml:5-10`
- Modify: `.just/flux.just:125-135`

**Interfaces:**
- Consumes: Namespace `security`, HelmRepository `infisical-helm-charts`
- Produces: HelmRelease `infisical-operator` deploying `secrets-operator` chart

- [ ] **Step 1: Create `k8s/security/infisical-operator/ks.yaml`**

Create `k8s/security/infisical-operator/ks.yaml`:
```yaml
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: infisical-operator
  namespace: flux-system
spec:
  interval: 10m0s
  retryInterval: 1m0s
  path: ./k8s/security/infisical-operator/app
  prune: true
  wait: true
  timeout: 5m0s
  sourceRef:
    kind: GitRepository
    name: flux-system
  targetNamespace: security
  decryption:
    provider: sops
    secretRef:
      name: sops-age
```

- [ ] **Step 2: Create `repository.yaml` for Infisical Helm charts**

Create `k8s/security/infisical-operator/app/repository.yaml`:
```yaml
---
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: infisical-helm-charts
  namespace: security
spec:
  interval: 24h
  url: https://dl.cloudsmith.io/public/infisical/helm-charts/helm/charts/
```

- [ ] **Step 3: Create `release.yaml` for secrets-operator**

Create `k8s/security/infisical-operator/app/release.yaml`:
```yaml
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: infisical-operator
  namespace: security
spec:
  interval: 30m
  chart:
    spec:
      chart: secrets-operator
      version: "0.11.15"
      sourceRef:
        kind: HelmRepository
        name: infisical-helm-charts
        namespace: security
      interval: 12h
  install:
    crds: CreateReplace
    remediation:
      retries: 3
  upgrade:
    crds: CreateReplace
    cleanupOnFail: true
    remediation:
      retries: 3
```

- [ ] **Step 4: Create `k8s/security/infisical-operator/app/kustomization.yaml`**

Create `k8s/security/infisical-operator/app/kustomization.yaml`:
```yaml
---
# yaml-language-server: $schema=https://json.schemastore.org/kustomization
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ./repository.yaml
  - ./release.yaml
```

- [ ] **Step 5: Register `./infisical-operator/ks.yaml` in `k8s/security/kustomization.yaml`**

Update `k8s/security/kustomization.yaml`:
```yaml
resources:
  - ./namespace.yaml
  - ./infisical-operator/ks.yaml
```

- [ ] **Step 6: Add `k8s/security/infisical-operator/app` to `.just/flux.just`**

Add `k8s/security/infisical-operator/app` into the `validate` recipe directory list.

- [ ] **Step 7: Run validation to verify operator manifests**

Run: `mise exec -- just fl::validate`
Expected output: Validates `k8s/security` and `k8s/security/infisical-operator/app` with 0 invalid resources and 0 errors.

- [ ] **Step 8: Commit changes**

```bash
git add k8s/security/infisical-operator/ k8s/security/kustomization.yaml .just/flux.just
git commit -m "feat: ✨ add infisical secrets operator helm release"
```

---

### Task 3: Configure Universal Auth Machine Identity SOPS Secret

**Files:**
- Create: `k8s/security/infisical-operator/app/universal-auth.sops.yaml`
- Modify: `k8s/security/infisical-operator/app/kustomization.yaml`

**Interfaces:**
- Consumes: SOPS encryption with Age key from `.sops.yaml`
- Produces: Kubernetes Secret `infisical-universal-auth` in namespace `security`

- [ ] **Step 1: Create and encrypt `universal-auth.sops.yaml` with placeholder credentials**

Generate the plaintext secret template temporarily:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: infisical-universal-auth
  namespace: security
type: Opaque
stringData:
  clientId: placeholder-client-id
  clientSecret: placeholder-client-secret
```
Encrypt it using SOPS into `k8s/security/infisical-operator/app/universal-auth.sops.yaml`:
```bash
mise exec -- sops --encrypt --encrypted-regex '^(data|stringData)$' \
  --age age1h6dhysy07e88zz7xt6vgfaag97enz0fl0q0290zx9m6z8w4kypmqzj49vf \
  /tmp/universal-auth-plain.yaml > k8s/security/infisical-operator/app/universal-auth.sops.yaml
rm -f /tmp/universal-auth-plain.yaml
```

- [ ] **Step 2: Add `universal-auth.sops.yaml` to `k8s/security/infisical-operator/app/kustomization.yaml`**

Update `k8s/security/infisical-operator/app/kustomization.yaml`:
```yaml
---
# yaml-language-server: $schema=https://json.schemastore.org/kustomization
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ./repository.yaml
  - ./release.yaml
  - ./universal-auth.sops.yaml
```

- [ ] **Step 3: Run validation to verify SOPS encryption and schema**

Run: `mise exec -- just fl::validate`
Expected output:
- `Validating k8s/security/infisical-operator/app...` passes.
- Under `Checking SOPS encryption on *.sops.yaml manifests...`:
  `✔ Encrypted: /home/toni/code/homelab/k8s/security/infisical-operator/app/universal-auth.sops.yaml`

- [ ] **Step 4: Commit changes**

```bash
git add k8s/security/infisical-operator/app/universal-auth.sops.yaml k8s/security/infisical-operator/app/kustomization.yaml
git commit -m "feat: ✨ configure infisical universal-auth sops secret"
```

---

### Task 4: Add Infisical Integration Guide & Usage Documentation

**Files:**
- Create: `k8s/security/README.md`
- Modify: `AGENTS.md:15-35` (update repository layout to include `k8s/security`)

**Interfaces:**
- Consumes: Infisical Cloud Machine Identity setup steps, `InfisicalSecret` CRD schema
- Produces: Comprehensive operator guide and documentation for developers/operators

- [ ] **Step 1: Create `k8s/security/README.md`**

Document:
1. **Overview**: Purpose of `k8s/security/` and Infisical integration.
2. **Setup Instructions in Infisical Cloud**:
   - Creating Machine Identity under **Access Control** > **Machine Identities**.
   - Assigning permissions (Read access to target project & environment).
   - Generating Universal Auth credentials (`Client ID` and `Client Secret`).
3. **Updating `universal-auth.sops.yaml`**:
   - Command: `sops k8s/security/infisical-operator/app/universal-auth.sops.yaml`
   - Setting real `clientId` and `clientSecret`.
4. **Application Usage Example (`InfisicalSecret`)**:
   - Complete manifest example showing how an application in `apps` namespace connects via `authentication.universalAuth.credentialsRef` to `infisical-universal-auth` in `security`.
   - Explanation of `secretsScope` (`projectSlug`, `envSlug`, `secretsPath`).
   - Explanation of `managedSecretReference` (auto-reconciled Kubernetes Secret).
5. **Coexistence with SOPS**:
   - Clear guidance that `settings.sops.yaml` handles cluster-wide post-build substitutions while Infisical handles dynamic runtime secrets.

- [ ] **Step 2: Update `AGENTS.md` repository layout**

In `AGENTS.md`, ensure the architecture overview or layout reflects `k8s/security`.

- [ ] **Step 3: Run full validation suite**

Run: `mise exec -- just fl::validate`
Expected output: All resources valid, 0 errors, all SOPS files encrypted.

- [ ] **Step 4: Commit documentation changes**

```bash
git add k8s/security/README.md AGENTS.md
git commit -m "docs: 📝 add infisical operator setup and usage documentation"
```

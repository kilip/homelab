# Omed Nightly Deployment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deploy a standalone `omed-nightly` service alongside `omed` in K3s with dedicated database, RustFS buckets, and nightly images (`kilip/omed-api:nightly`, `kilip/omed-web:nightly`).

**Architecture:** Create an isolated `k8s/apps/omed-nightly/` tree containing Flux Kustomizations for database provisioning and HelmRelease deployment, extend RustFS initialization for nightly buckets, generate SOPS-encrypted secrets using the repo Age key, and update Flux validation in `.just/flux.just`.

**Tech Stack:** Kubernetes, Flux CD (v2 Kustomize & Helm Controllers), SOPS + Age, CloudNative-PG, RustFS (S3), Traefik, Kustomize, Kubeconform, Just.

**Spec:** `docs/superpowers/specs/2026-04-19-omed-nightly-design.md`

## Global Constraints

- Secrets must be encrypted with SOPS and Age public key `age1h6dhysy07e88zz7xt6vgfaag97enz0fl0q0290zx9m6z8w4kypmqzj49vf`.
- Indentation: 2 spaces for YAML, 4 spaces for Justfiles (`.editorconfig`).
- All validation must pass: `just fl::validate`.
- Never commit or stage unencrypted secret files or plaintext secrets.

## Review Focus

- Secret encryption structure: SOPS file must have `data` or `stringData` encrypted and a top-level `sops:` metadata block.
- Service and deployment names: Must target `omed-nightly-api` instead of `omed-api` in postRenderer patches and `wait-for-db`.
- Database connection URL: Must point to database `omed_nightly` with user `omed_nightly` on host `paradedb-rw.storage.svc:5432`.
- Ingress hosts: Must be `omed-nightly.${SECRET_DOMAIN}` and `api-nightly.${SECRET_DOMAIN}`.
- Image pull policy: Must be `Always` for mutable `nightly` tags.

---

### Task 1: Add S3 Buckets for Omed Nightly

**Files:**
- Modify: `k8s/apps/rustfs/app/init-buckets-job.yaml`
- Modify: `k8s/apps/rustfs/ks.yaml`

**Interfaces:**
- Consumes: Existing `rustfs-init-buckets` Job spec and RustFS S3 endpoint `http://rustfs-svc.apps.svc.cluster.local:9000`.
- Produces: S3 buckets `omed-nightly` and `omed-nightly-ws-default`.

- [ ] **Step 1: Update `k8s/apps/rustfs/app/init-buckets-job.yaml` and `k8s/apps/rustfs/ks.yaml`**

In `k8s/apps/rustfs/app/init-buckets-job.yaml`, add `aws --endpoint-url http://rustfs-svc.apps.svc.cluster.local:9000 s3 mb s3://omed-nightly || true` and `aws --endpoint-url http://rustfs-svc.apps.svc.cluster.local:9000 s3 mb s3://omed-nightly-ws-default || true` before the bucket verification step.
In `k8s/apps/rustfs/ks.yaml`, set `spec.force: true` so Flux recreates the immutable `Job/rustfs-init-buckets` if an older instance still exists in cluster.

- [ ] **Step 2: Verify `k8s/apps/rustfs/app` kustomize build and manifest syntax**

Run: `kustomize build k8s/apps/rustfs/app | yq 'del(.sops)' | kubeconform -strict -ignore-missing-schemas -summary`
Expected: `Summary: 4 resources found parsing stdin - Valid: 2, Invalid: 0, Errors: 0, Skipped: 2`

- [ ] **Step 3: Commit**

```bash
git add k8s/apps/rustfs/app/init-buckets-job.yaml k8s/apps/rustfs/ks.yaml
git commit -m "feat: ✨ provision rustfs buckets for omed-nightly"
```

---

### Task 2: Create Database Manifests and Encrypted Credentials for Omed Nightly

**Files:**
- Create: `k8s/apps/omed-nightly/db/credentials.sops.yaml`
- Create: `k8s/apps/omed-nightly/db/db.yaml`
- Create: `k8s/apps/omed-nightly/db/wait-job.yaml`
- Create: `k8s/apps/omed-nightly/db/kustomization.yaml`

**Interfaces:**
- Consumes: CloudNative-PG cluster `paradedb` in namespace `storage`.
- Produces: `DatabaseRole/omed-nightly`, `Database/omed-nightly`, `Secret/omed-nightly-db-credentials`, and verification `Job/omed-nightly-db-check`.

- [ ] **Step 1: Generate SOPS-encrypted `credentials.sops.yaml` via in-memory pipeline**

Without writing plaintext secrets to disk or printing them to stdout, generate `k8s/apps/omed-nightly/db/credentials.sops.yaml` (`Secret/omed-nightly-db-credentials` in namespace `storage`, `type: kubernetes.io/basic-auth`, `stringData.username: omed_nightly`, `stringData.password`: 32-char random hex via `openssl rand -hex 16`) piped directly into:
`sops --encrypt --input-type yaml --output-type yaml --filename-override k8s/apps/omed-nightly/db/credentials.sops.yaml - > k8s/apps/omed-nightly/db/credentials.sops.yaml`

- [ ] **Step 2: Create `k8s/apps/omed-nightly/db/db.yaml`**

Mirror `k8s/apps/omed/db/db.yaml`:
- `DatabaseRole` (`postgresql.cnpg.io/v1`): metadata `name: omed-nightly`, `namespace: storage`; `spec`: `cluster: { name: paradedb }`, `name: omed_nightly`, `login: true`, `passwordSecret: { name: omed-nightly-db-credentials }`.
- `Database` (`postgresql.cnpg.io/v1`): metadata `name: omed-nightly`, `namespace: storage`; `spec`: `cluster: { name: paradedb }`, `name: omed_nightly`, `owner: omed_nightly`, `template: template0`.

- [ ] **Step 3: Create `k8s/apps/omed-nightly/db/wait-job.yaml`**

Mirror `k8s/apps/omed/db/wait-job.yaml` for `Job/omed-nightly-db-check` in namespace `storage` (`app.kubernetes.io/name: omed-nightly-db-check`), reading `PGUSER` and `PGPASSWORD` from `secretKeyRef.name: omed-nightly-db-credentials` and setting `PGDATABASE: omed_nightly`.

- [ ] **Step 4: Create `k8s/apps/omed-nightly/db/kustomization.yaml`**

Include `./credentials.sops.yaml`, `./db.yaml`, and `./wait-job.yaml`.

- [ ] **Step 5: Verify kustomize build and kubeconform on `k8s/apps/omed-nightly/db`**

Run: `kustomize build k8s/apps/omed-nightly/db | yq 'del(.sops)' | kubeconform -strict -ignore-missing-schemas -summary`
Expected: 4 resources, Valid: 2, Invalid: 0, Errors: 0, Skipped: 2.

- [ ] **Step 6: Commit**

```bash
git add k8s/apps/omed-nightly/db/
git commit -m "feat: ✨ add database manifests and credentials for omed-nightly"
```

---

### Task 3: Create Application Manifests, HelmRelease, and Encrypted Secret for Omed Nightly

**Files:**
- Create: `k8s/apps/omed-nightly/app/secret.sops.yaml`
- Create: `k8s/apps/omed-nightly/app/ocirepository.yaml`
- Create: `k8s/apps/omed-nightly/app/helmrelease.yaml`
- Create: `k8s/apps/omed-nightly/app/kustomization.yaml`

**Interfaces:**
- Consumes: OCI Chart `oci://ghcr.io/kilip/charts/omed` (`0.7.0`), `k8s/apps/omed-nightly/db/credentials.sops.yaml`, `paradedb-rw.storage.svc:5432`, `rustfs-svc.apps.svc.cluster.local:9000`.
- Produces: `OCIRepository/omed-nightly`, `HelmRelease/omed-nightly`, and `Secret/omed-nightly-secret` in namespace `apps`.

- [ ] **Step 1: Generate SOPS-encrypted `secret.sops.yaml` via in-memory pipeline**

Without writing plaintext files or printing secret values to stdout, pipe `sops -d k8s/apps/omed/app/secret.sops.yaml` through `yq` and `sops --encrypt --input-type yaml --output-type yaml --filename-override k8s/apps/omed-nightly/app/secret.sops.yaml - > k8s/apps/omed-nightly/app/secret.sops.yaml`:
- Read DB password in shell variable: `db_pass="$(sops -d k8s/apps/omed-nightly/db/credentials.sops.yaml | yq -r '.stringData.password')"`
- Generate auth secret in shell variable: `auth_secret="$(openssl rand -hex 32)"`
- Set `.metadata.name = "omed-nightly-secret"`
- Set `.stringData.OMED_AUTH_SECRET = strenv(auth_secret)`
- Set `.stringData.OMED_DB_MIGRATE_ON_START = "true"`
- Set `.stringData.OMED_DB_URL = "postgresql://omed_nightly:" + strenv(db_pass) + "@paradedb-rw.storage.svc:5432/omed_nightly?sslmode=disable"`
- Retain existing `OMED_S3_*`, `OMED_GITHUB_*`, `OMED_GOOGLE_*`, `OMED_MAILER_*` keys and remove `.sops` before re-encrypting.

- [ ] **Step 2: Create `k8s/apps/omed-nightly/app/ocirepository.yaml`**

Mirror `k8s/apps/omed/app/ocirepository.yaml` with `metadata.name: omed-nightly`, referencing `oci://ghcr.io/kilip/charts/omed` tag `0.7.0`.

- [ ] **Step 3: Create `k8s/apps/omed-nightly/app/helmrelease.yaml`**

Copy the full structure of `k8s/apps/omed/app/helmrelease.yaml` (preserving `replicaCount: 1`, `mailer.driver: memory`, `s3.driver: s3`, `s3.endpoint: "http://rustfs-svc.apps.svc.cluster.local:9000"`, `s3.region: "us-east-1"`, `s3.forcePathStyle: true`, `resources`, `migrations.enabled: true`, `ingress.className: traefik`, and `ingress.annotations`) and apply these changes for `omed-nightly`:
- `metadata.name: omed-nightly` and `spec.chartRef.name: omed-nightly`
- `postRenderers`: target and patch `Deployment/omed-nightly-api` (`initContainers[wait-for-db]` command `until pg_isready -h paradedb-rw.storage.svc -p 5432 -U omed_nightly -d omed_nightly; do ...`)
- `values.secrets.existingSecret: omed-nightly-secret`
- `values.api.image`: `tag: nightly`, `pullPolicy: Always`
- `values.api.config.sessionCookieName: omed_nightly_session`
- `values.api.config.s3.bucketPrefix: "omed-nightly-ws-"`
- `values.web.image`: `tag: nightly`, `pullPolicy: Always`
- `values.ingress.web.host: omed-nightly.${SECRET_DOMAIN}`
- `values.ingress.api.host: api-nightly.${SECRET_DOMAIN}`
- `values.ingress.tls[0].hosts`: `omed-nightly.${SECRET_DOMAIN}` and `api-nightly.${SECRET_DOMAIN}`

- [ ] **Step 4: Create `k8s/apps/omed-nightly/app/kustomization.yaml`**

Include `./secret.sops.yaml`, `./ocirepository.yaml`, and `./helmrelease.yaml`.

- [ ] **Step 5: Verify kustomize build and kubeconform on `k8s/apps/omed-nightly/app`**

Run: `kustomize build k8s/apps/omed-nightly/app | yq 'del(.sops)' | kubeconform -strict -ignore-missing-schemas -summary`
Expected: 3 resources, Valid: 1, Invalid: 0, Errors: 0, Skipped: 2.

- [ ] **Step 6: Commit**

```bash
git add k8s/apps/omed-nightly/app/
git commit -m "feat: ✨ add app manifests and helmrelease for omed-nightly"
```

---

### Task 4: Wire Flux Kustomizations and Update Validation

**Files:**
- Create: `k8s/apps/omed-nightly/ks.yaml`
- Modify: `k8s/apps/kustomization.yaml`
- Modify: `.just/flux.just`

**Interfaces:**
- Consumes: `k8s/apps/omed-nightly/db` and `k8s/apps/omed-nightly/app`.
- Produces: Flux `Kustomization/omed-nightly-db` and `Kustomization/omed-nightly` in `flux-system` namespace.

- [ ] **Step 1: Create `k8s/apps/omed-nightly/ks.yaml`**

Mirror `k8s/apps/omed/ks.yaml`:
- `Kustomization/omed-nightly-db`: `dependsOn: [{ name: paradedb }]`, `interval: 1h`, `path: ./k8s/apps/omed-nightly/db`, `prune: true`, `wait: true`, `timeout: 5m`, `sourceRef: { kind: GitRepository, name: flux-system }`, `targetNamespace: storage`, `decryption: { provider: sops, secretRef: { name: sops-age } }`.
- `Kustomization/omed-nightly`: `dependsOn: [{ name: omed-nightly-db }, { name: rustfs }, { name: traefik }]`, `interval: 1h`, `path: ./k8s/apps/omed-nightly/app`, `prune: true`, `sourceRef: { kind: GitRepository, name: flux-system }`, `targetNamespace: apps`, `decryption: { provider: sops, secretRef: { name: sops-age } }`, `postBuild: { substituteFrom: [{ kind: Secret, name: settings }] }`.

- [ ] **Step 2: Add `./omed-nightly/ks.yaml` to `k8s/apps/kustomization.yaml`**

Append `- ./omed-nightly/ks.yaml` under `resources`.

- [ ] **Step 3: Add `k8s/apps/omed-nightly/app` and `k8s/apps/omed-nightly/db` to `.just/flux.just`**

Include them in the `validate` recipe list of directories.

- [ ] **Step 4: Run full validation suite**

Run: `just fl::validate`
Expected: All directories validated cleanly, zero kubeconform errors, and all SOPS files encrypted.

- [ ] **Step 5: Commit**

```bash
git add k8s/apps/omed-nightly/ks.yaml k8s/apps/kustomization.yaml .just/flux.just
git commit -m "feat: ✨ register omed-nightly flux kustomizations and validation"
```

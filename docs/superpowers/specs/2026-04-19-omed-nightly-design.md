# Omed Nightly Deployment Design

## Intent & Why
Deploy a standalone `omed-nightly` instance in the K3s cluster tracking the `nightly` container images (`kilip/omed-api:nightly` and `kilip/omed-web:nightly`) so nightly builds can be tested continuously without affecting the production `omed` instance.

## Goals & Non-Goals
- **Goals**: Isolated database (`omed_nightly`), isolated S3 buckets (`omed-nightly-ws-*`), isolated ingress domains (`omed-nightly.${SECRET_DOMAIN}` and `api-nightly.${SECRET_DOMAIN}`), automatic pulling of `nightly` image tags (`pullPolicy: Always`).
- **Non-Goals**: Deploying a separate PostgreSQL cluster or separate RustFS instance (reuses existing `paradedb` and `rustfs` services with separate DB/buckets).

## Constraints
- All Kubernetes secrets (`credentials.sops.yaml`, `secret.sops.yaml`) must be encrypted with SOPS using rules in `.sops.yaml`.
- Must pass `just fl::validate` without errors.

## Approaches
1. **Subfolder inside `k8s/apps/omed/`**: Groups all `omed` manifests under one directory, sharing `ks.yaml`.
2. **Top-level `k8s/apps/omed-nightly/` directory (Selected)**: Full isolation of Flux Kustomizations (`omed-nightly-db`, `omed-nightly`), database manifests, and app manifests under `k8s/apps/omed-nightly/`, registered in `k8s/apps/kustomization.yaml`.

## Architecture & Decisions
- **Directory Layout**: `k8s/apps/omed-nightly/{ks.yaml,db/,app/}` registered in `k8s/apps/kustomization.yaml`.
- **Database (`k8s/apps/omed-nightly/db/`)**:
  - CNPG `DatabaseRole` and `Database` named `omed-nightly` (database/role name `omed_nightly` on cluster `paradedb` in `storage` namespace).
  - Secret `omed-nightly-db-credentials` (SOPS-encrypted) and readiness `Job` `omed-nightly-db-check`.
- **Storage S3 (`k8s/apps/rustfs/app/init-buckets-job.yaml`)**:
  - Update `rustfs-init-buckets` job to also ensure `s3://omed-nightly` and `s3://omed-nightly-ws-default` exist.
- **Application (`k8s/apps/omed-nightly/app/`)**:
  - `OCIRepository` `omed-nightly` pointing to `oci://ghcr.io/kilip/charts/omed` (`0.7.0`).
  - `HelmRelease` `omed-nightly` with:
    - `api.image.tag: nightly`, `api.image.pullPolicy: Always`
    - `web.image.tag: nightly`, `web.image.pullPolicy: Always`
    - `api.config.sessionCookieName: omed_nightly_session`
    - `api.config.s3.bucketPrefix: "omed-nightly-ws-"`
    - `postRenderers` patching `Deployment/omed-nightly-api` `wait-for-db` initContainer to check `-U omed_nightly -d omed_nightly`.
    - Ingress hosts `omed-nightly.${SECRET_DOMAIN}` and `api-nightly.${SECRET_DOMAIN}` with TLS.
  - Secret `omed-nightly-secret` (SOPS-encrypted, derived from `omed` secret with `OMED_DB_URL` pointing to `omed_nightly` database).

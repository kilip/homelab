# Termix Deployment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deploy Termix (self-hosted server and SSH management platform) into the K3s cluster via Flux GitOps on `ssh.${SECRET_DOMAIN}` with persistent storage and native GitHub & Google OAuth2 Single Sign-On.

**Architecture:** Use `bjw-s/app-template` Helm chart (v5.3.0) via Flux CD to run `ghcr.io/termix-ssh/termix:latest`. Mount `/app/data` to a `local-path` PVC (`termix-data`). Expose the web interface and WebSocket via Traefik Ingress on `ssh.${SECRET_DOMAIN}` with TLS and Cloudflare tunnel annotations. Manage credentials via a SOPS-encrypted `secret.sops.yaml` providing a cryptographically strong `OIDC_SYSTEM_SECRET` and `ADMIN_INITIAL_PASSWORD`. Configure dual OAuth2 (GitHub & Google) via Termix's native SSO plugin.

**Tech Stack:** Kubernetes (K3s), Flux CD (Kustomize & Helm Controller), bjw-s `app-template` v5.3.0, Traefik, SOPS + Age, Termix.

**Spec:** `docs/superpowers/specs/2026-10-31-termix-installation-design.md`

## Global Constraints

- **GitOps Layout**: All manifests live under `k8s/apps/termix/` and register in `k8s/apps/kustomization.yaml`.
- **Secrets Security**: NEVER print, log, or commit plaintext secrets. `secret.sops.yaml` must be encrypted using Age recipient `age1h6dhysy07e88zz7xt6vgfaag97enz0fl0q0290zx9m6z8w4kypmqzj49vf` matching `.sops.yaml`.
- **Validation**: All K8s manifests must strictly pass `just fl::validate` without errors.
- **WebSocket & Reverse Proxy Support**: Ingress service port must use `appProtocol: kubernetes.io/ws` and `EXTERNAL_FORCE_HTTPS: "true"` to ensure SSH terminal WebSockets and OAuth redirects function properly over HTTPS.

## Review Focus

- SOPS age encryption: Ensure `k8s/apps/termix/app/secret.sops.yaml` is properly encrypted and verified by `just fl::validate`.
- Storage permissions: Ensure `termix` container runs with `fsGroup: 1000`, `runAsUser: 1000`, `runAsGroup: 1000` so SQLite and plugin files in `/app/data` are writable.
- Flux Kustomization substitution: Ingress host `ssh.${SECRET_DOMAIN}` must use Flux variable substitution from `settings` secret.
- Ingress annotations: Ensure external-dns and Cloudflare tunnel target annotations match standard apps in this repo (`${CLOUDFLARE_TUNNEL_ID}.cfargotunnel.com`).
- OAuth2 callback URL: Callback format for both GitHub and Google must be `https://ssh.${SECRET_DOMAIN}/plugin-api/sso/callback`.

---

### Task 1: Generate secrets and create encrypted SOPS secret

**Files:**
- Create: `k8s/apps/termix/app/secret.sops.yaml`

**Interfaces:**
- Produces: `Secret/termix-secret` containing `OIDC_SYSTEM_SECRET` and `ADMIN_INITIAL_PASSWORD` for mounting in `HelmRelease/termix`.

- [ ] **Step 1: Generate cryptographically secure random values**
Generate:
- `OIDC_SYSTEM_SECRET`: 32-byte hex string (using `openssl rand -hex 32`).
- `ADMIN_INITIAL_PASSWORD`: 24-character random alphanumeric password (using `openssl rand -base64 24 | tr -dc 'a-zA-Z0-9!@#$%^&*' | head -c 24`).

- [ ] **Step 2: Create temporary plaintext secret and encrypt with SOPS**
Draft temporary secret payload:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: termix-secret
  namespace: apps
type: Opaque
stringData:
  OIDC_SYSTEM_SECRET: "<generated-hex>"
  ADMIN_INITIAL_PASSWORD: "<generated-password>"
```
Encrypt into `k8s/apps/termix/app/secret.sops.yaml` using:
`sops --encrypt --age age1h6dhysy07e88zz7xt6vgfaag97enz0fl0q0290zx9m6z8w4kypmqzj49vf --encrypted-regex '^(data|stringData)$' <temp-file> > k8s/apps/termix/app/secret.sops.yaml`
Immediately remove any temporary plaintext file.

- [ ] **Step 3: Verify SOPS encryption format**
Run: `grep -q "ENC\[AES256_GCM" k8s/apps/termix/app/secret.sops.yaml`
Expected: Return 0 (matches encrypted fields).

---

### Task 2: Create PVC, OCIRepository, HelmRelease, and app Kustomization

**Files:**
- Create: `k8s/apps/termix/app/pvc.yaml`
- Create: `k8s/apps/termix/app/ocirepository.yaml`
- Create: `k8s/apps/termix/app/helmrelease.yaml`
- Create: `k8s/apps/termix/app/kustomization.yaml`

**Interfaces:**
- Consumes: `Secret/termix-secret` from Task 1.
- Produces: Kustomization target for `k8s/apps/termix/app`.

- [ ] **Step 1: Create `k8s/apps/termix/app/pvc.yaml`**
Define `PersistentVolumeClaim/termix-data` with:
- `accessModes: [ReadWriteOnce]`
- `storageClassName: local-path`
- `resources.requests.storage: 5Gi`

- [ ] **Step 2: Create `k8s/apps/termix/app/ocirepository.yaml`**
Define `OCIRepository/termix` pointing to:
- `url: oci://ghcr.io/bjw-s-labs/helm/app-template`
- `ref.tag: 5.3.0`
- `interval: 15m`

- [ ] **Step 3: Create `k8s/apps/termix/app/helmrelease.yaml`**
Define `HelmRelease/termix` using `app-template`:
- Image: `ghcr.io/termix-ssh/termix:latest`
- Environment variables:
  - `PORT: &port 8080`
  - `EXTERNAL_FORCE_HTTPS: "true"`
  - `EXTERNAL_ALLOW_REGISTRATION: "true"`
  - `TZ: ${TIMEZONE}`
- `envFrom`:
  - `secretRef.name: termix-secret`
- Service:
  - `port: *port`, `appProtocol: kubernetes.io/ws`
- Ingress:
  - `className: traefik`
  - Annotations:
    - `external-dns.alpha.kubernetes.io/expose: "true"`
    - `external-dns.kubernetes.io/target: "${CLOUDFLARE_TUNNEL_ID}.cfargotunnel.com"`
  - Host: `ssh.${SECRET_DOMAIN}`
  - TLS: `ssh.${SECRET_DOMAIN}`
- Persistence:
  - `data`: `existingClaim: termix-data`, mounted at `/app/data`
  - `tmp`: `type: emptyDir`
- Security Context:
  - `defaultPodOptions`:
    - `runAsUser: 1000`
    - `runAsGroup: 1000`
    - `fsGroup: 1000`
    - `fsGroupChangePolicy: OnRootMismatch`

- [ ] **Step 4: Create `k8s/apps/termix/app/kustomization.yaml`**
Register resources:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ./pvc.yaml
  - ./ocirepository.yaml
  - ./secret.sops.yaml
  - ./helmrelease.yaml
```

---

### Task 3: Create Flux Kustomization and register in root apps

**Files:**
- Create: `k8s/apps/termix/ks.yaml`
- Modify: `k8s/apps/kustomization.yaml`

**Interfaces:**
- Consumes: `k8s/apps/termix/app` directory from Task 2.
- Produces: Flux CD management of Termix in `apps` namespace.

- [ ] **Step 1: Create `k8s/apps/termix/ks.yaml`**
Define `Kustomization/termix`:
```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/kustomize.toolkit.fluxcd.io/kustomization_v1.json
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: termix
  namespace: flux-system
spec:
  dependsOn:
    - name: local-path
    - name: traefik
  interval: 1h
  path: ./k8s/apps/termix/app
  prune: true
  sourceRef:
    kind: GitRepository
    name: flux-system
  targetNamespace: apps
  decryption:
    provider: sops
    secretRef:
      name: sops-age
  postBuild:
    substituteFrom:
      - kind: Secret
        name: settings
```

- [ ] **Step 2: Add `./termix/ks.yaml` to `k8s/apps/kustomization.yaml`**
Add `- ./termix/ks.yaml` to the `resources` list.

- [ ] **Step 3: Run validation**
Run: `just fl::validate`
Expected: All apps pass validation including `k8s/apps/termix/app` and all SOPS encryption checks return valid with 0 errors.

---

### Task 4: Post-deployment OAuth2 setup documentation & instructions

**Files:**
- Documentation output for the user with callback URL, GitHub OAuth app settings, Google OAuth app settings, and initial admin login steps.

- [ ] **Step 1: Document GitHub OAuth App setup parameters**
- Homepage URL: `https://ssh.<domain>`
- Authorization callback URL: `https://ssh.<domain>/plugin-api/sso/callback`

- [ ] **Step 2: Document Google Cloud OAuth Client setup parameters**
- Application Type: Web application
- Authorized JavaScript origins: `https://ssh.<domain>`
- Authorized redirect URIs: `https://ssh.<domain>/plugin-api/sso/callback`

- [ ] **Step 3: Provide admin onboarding steps**
Detail steps to register first admin user with generated `ADMIN_INITIAL_PASSWORD`, install the Single sign-on plugin, and configure the GitHub & Google providers.

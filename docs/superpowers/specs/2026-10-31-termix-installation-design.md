# Termix Installation with GitHub & Google OAuth2 Design

## Intent & Why
Deploy Termix (a self-hosted server and SSH management platform) into the K3s cluster via Flux GitOps to provide web-based SSH terminal access, host inventory management, SFTP file management, and server monitoring, authenticated via GitHub and Google OAuth2.

## Goals & Non-Goals
- **Goals**:
  - Deploy Termix using Flux GitOps in `k8s/apps/termix/`.
  - Expose Termix on `ssh.${SECRET_DOMAIN}` via Traefik ingress with TLS and Cloudflare tunnel DNS annotations.
  - Provide persistent storage for Termix data and SQLite DB (`/app/data`) using `local-path` StorageClass.
  - Support GitHub and Google OAuth2 Single Sign-On (SSO) using Termix's native SSO plugin.
  - Provide an encrypted SOPS secret (`k8s/apps/termix/app/secret.sops.yaml`) containing required secrets such as `OIDC_SYSTEM_SECRET` (used by Termix to encrypt stored user SSH keys/credentials) and `ADMIN_INITIAL_PASSWORD` (randomly generated password for initial admin registration).
  - Cleanly integrate into `k8s/apps/kustomization.yaml` and pass `just fl::validate`.
- **Non-Goals**:
  - Deploying an external relational database (Termix embeds SQLite on the persistent volume).
  - Deploying OAuth2-Proxy or external auth forwarders (Termix handles dual SSO natively).

## Constraints
- Secrets must be encrypted using SOPS with Age key conforming to `.sops.yaml`.
- All YAML files must pass `just fl::validate` without errors.
- Never commit plaintext secrets or unencrypted `.decrypted~*` files.

## Approaches Considered
1. **Native Termix SSO Plugin (Selected)**:
   - Termix runs using `bjw-s/app-template` Helm chart with persistent volume on `/app/data`.
   - Native SSO plugin enabled within Termix, allowing dual providers (GitHub and Google) with dedicated login buttons on the web interface.
   - User inputs GitHub and Google Client ID and Secret in Termix admin UI (stored in persistent SQLite), while cluster-level secrets like `OIDC_SYSTEM_SECRET` are managed via SOPS.
   - Callback URL for both providers: `https://ssh.${SECRET_DOMAIN}/plugin-api/sso/callback`.
   - *Trade-off*: Admin enters the OAuth app Client ID/Secret into Termix UI on initial setup, but gets native multi-user permission mapping and encryption.
2. **Reverse-Proxy OAuth Gateway (OAuth2-Proxy / ForwardAuth)**:
   - Deploy OAuth2-Proxy ahead of Traefik Ingress.
   - *Trade-off*: Substantial overhead, doesn't easily support dual identity providers (GitHub + Google) without deploying Keycloak/Authentik, and bypasses Termix's user-specific SSH credential encryption.
3. **Single Generic OIDC via Environment Variables**:
   - Provide `OIDC_*` environment variables in HelmRelease.
   - *Trade-off*: Termix environment variables only support a single OIDC provider, which cannot support both GitHub and Google simultaneously.

## Architecture & Decisions
- **Directory Layout**:
  ```text
  k8s/apps/termix/
  ├── ks.yaml
  └── app/
      ├── helmrelease.yaml
      ├── kustomization.yaml
      ├── ocirepository.yaml
      ├── pvc.yaml
      └── secret.sops.yaml
  ```
- **Flux Kustomization (`k8s/apps/termix/ks.yaml`)**:
  - Name: `termix`
  - Namespace: `flux-system`
  - DependsOn: `local-path`, `traefik`
  - TargetNamespace: `apps`
  - Decryption: SOPS with secret `sops-age`
  - PostBuild substituteFrom: `settings` secret
- **OCI Repository (`k8s/apps/termix/app/ocirepository.yaml`)**:
  - Chart: `oci://ghcr.io/bjw-s-labs/helm/app-template` tag `5.3.0`
- **Persistent Storage (`k8s/apps/termix/app/pvc.yaml`)**:
  - Name: `termix-data`
  - Storage: `5Gi`
  - StorageClass: `local-path`
- **Secret (`k8s/apps/termix/app/secret.sops.yaml`)**:
  - Contains:
    - `OIDC_SYSTEM_SECRET`: Derived encryption key for credential vault.
    - `ADMIN_INITIAL_PASSWORD`: Securely generated random password stored in encrypted SOPS secret for registering/securing the initial admin account.
  - Encrypted with SOPS (`age`).
- **HelmRelease (`k8s/apps/termix/app/helmrelease.yaml`)**:
  - Image: `ghcr.io/termix-ssh/termix:latest`
  - Environment:
    - `PORT: "8080"`
    - `EXTERNAL_FORCE_HTTPS: "true"`
    - `EXTERNAL_ALLOW_REGISTRATION: "true"`
  - EnvFrom: `secretRef: termix-secret`
  - Service: Port 8080 (http)
  - Ingress:
    - Host: `ssh.${SECRET_DOMAIN}`
    - Class: `traefik`
    - Annotations: Cloudflare tunnel target (`${CLOUDFLARE_TUNNEL_ID}.cfargotunnel.com`) and external DNS
    - TLS enabled
  - Persistence:
    - `data`: existingClaim `termix-data` mounted at `/app/data`
  - Security context: `runAsUser: 1000`, `runAsGroup: 1000`, `fsGroup: 1000`.
- **Root Apps Kustomization (`k8s/apps/kustomization.yaml`)**:
  - Add `./termix/ks.yaml` to resources.

## OAuth2 Callback & Configuration Guide
- **GitHub OAuth App**:
  - Application Name: `Termix Homelab`
  - Homepage URL: `https://ssh.<domain>`
  - Authorization callback URL: `https://ssh.<domain>/plugin-api/sso/callback`
- **Google Cloud OAuth 2.0 Client**:
  - Application Type: Web application
  - Authorized JavaScript origins: `https://ssh.<domain>`
  - Authorized redirect URIs: `https://ssh.<domain>/plugin-api/sso/callback`
- **Termix UI Setup**:
  1. Access `https://ssh.<domain>` and create the initial administrator account.
  2. Navigate to **Plugins** tab and ensure **Single sign-on** plugin is installed/enabled.
  3. Navigate to **Settings** > **Single sign-on** > **Add Provider**.
  4. Add **GitHub**: Enter GitHub Client ID & Secret, enable, and save.
  5. Add **Google**: Enter Google Client ID & Secret, enable, and save.

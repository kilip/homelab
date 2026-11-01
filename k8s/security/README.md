# Security Domain (`k8s/security`)

This directory contains security-related operators, secret synchronizers, and access control infrastructure for the Olympus cluster.

---

## Infisical Secrets Operator

The cluster integrates with [Infisical Cloud](https://app.infisical.com) via the official `secrets-operator` Helm chart deployed in the `security` namespace.

### Architecture & Coexistence with SOPS

- **SOPS (`k8s/infra/settings.sops.yaml`)**: Retained as the single source of truth for cluster-wide infrastructure variables and Flux post-build substitutions (such as `${SECRET_DOMAIN}`). It is also used to bootstrap the Infisical Machine Identity credentials (`universal-auth.sops.yaml`).
- **Infisical**: Manages runtime application secrets, database credentials, API keys, and service tokens, providing a centralized dashboard, audit logs, granular RBAC, and automatic pod reload upon secret changes.

---

## Setup & Credential Configuration

### 1. Create a Machine Identity in Infisical Cloud
1. Log in to [app.infisical.com](https://app.infisical.com) and navigate to your Project.
2. Go to **Access Control** > **Machine Identities** > **Add Machine Identity**.
3. Name it (e.g., `olympus-k3s-operator`) and assign the **Viewer / Reader** role to the required environments (`prod`, `staging`, etc.).
4. Under the newly created Machine Identity, configure **Universal Auth**:
   - Generate a new **Client ID** and **Client Secret**.

### 2. Update `universal-auth.sops.yaml`
Edit the encrypted credentials file using `sops`:

```bash
sops k8s/security/infisical-operator/app/universal-auth.sops.yaml
```

Set the real `clientId` and `clientSecret`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: infisical-universal-auth
  namespace: security
type: Opaque
stringData:
  clientId: "<YOUR_INFISICAL_CLIENT_ID>"
  clientSecret: "<YOUR_INFISICAL_CLIENT_SECRET>"
```

Save and exit. `sops` will automatically encrypt the file with Age before saving.

---

## Consuming Secrets in Workloads (`InfisicalSecret`)

To sync secrets from Infisical Cloud into a native Kubernetes Secret, deploy an `InfisicalSecret` Custom Resource alongside your application.

### Example Manifest

```yaml
apiVersion: secrets.infisical.com/v1alpha1
kind: InfisicalSecret
metadata:
  name: my-app-infisical-secret
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
        projectSlug: "my-project-slug"
        envSlug: "prod"
        secretsPath: "/"
  managedSecretReference:
    secretName: my-app-secret
    secretNamespace: apps
```

### Key Fields:
- **`hostAPI`**: `https://app.infisical.com/api` (points to Infisical Cloud).
- **`resyncInterval`**: Interval in seconds between secret sync checks (default: `60`).
- **`credentialsRef`**: Points to the `infisical-universal-auth` secret residing in the `security` namespace.
- **`secretsScope`**:
  - `projectSlug`: The slug of your Infisical project.
  - `envSlug`: Target environment slug (e.g., `prod`, `dev`).
  - `secretsPath`: Folder path within Infisical (e.g., `/` or `/database`).
- **`managedSecretReference`**: Name and namespace of the native Kubernetes Secret created and updated automatically by the operator.

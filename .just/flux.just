set shell := ["bash", "-euo", "pipefail", "-c"]

key_file := env("SOPS_AGE_KEY_FILE", justfile_directory() / "age.key")
kubeconfig := env("KUBECONFIG", justfile_directory() / "kubeconfig")

# Bootstrap Flux Operator and FluxInstance onto the cluster and provision secrets
bootstrap:
    #!/usr/bin/env bash
    set -euo pipefail
    just --justfile "{{ justfile_directory() }}/.justfile" sops::init-key
    export KUBECONFIG="{{ kubeconfig }}"
    if [ ! -f "$KUBECONFIG" ]; then
        echo "❌ kubeconfig not found at $KUBECONFIG (run 'just ans::kubeconfig' first)"
        exit 1
    fi
    key_path="{{ key_file }}"
    if [ ! -f "$key_path" ]; then
        echo "❌ age.key not found at $key_path"
        exit 1
    fi
    echo "Running Flux pre-flight checks..."
    flux check --pre
    echo "Applying flux-system namespace and sops-age secret..."
    kubectl create namespace flux-system --dry-run=client -o yaml | kubectl apply -f -
    kubectl create secret generic sops-age \
        --namespace=flux-system \
        --from-file=age.agekey="$key_path" \
        --dry-run=client -o yaml | kubectl apply -f -
    ssh_key="$(mktemp)"
    known_hosts="$(mktemp)"
    chmod 600 "$ssh_key"
    trap 'rm -f "$ssh_key" "$known_hosts"' EXIT
    echo "Fetching Flux SSH deploy key from pass hl/flux-ssh-key..."
    pass hl/flux-ssh-key > "$ssh_key"
    echo "Scanning GitHub SSH host keys..."
    ssh-keyscan -t rsa,ecdsa,ed25519 github.com 2>/dev/null > "$known_hosts"
    echo "Provisioning flux-system deploy key secret..."
    kubectl create secret generic flux-system \
        --namespace=flux-system \
        --from-file=identity="$ssh_key" \
        --from-file=known_hosts="$known_hosts" \
        --dry-run=client -o yaml | kubectl apply -f -
    echo "Installing flux-operator..."
    helm upgrade --install flux-operator \
        oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator \
        --version 0.62.1 \
        --namespace flux-system \
        --wait
    echo "Installing flux-instance..."
    helm upgrade --install flux-instance \
        oci://ghcr.io/controlplaneio-fluxcd/charts/flux-instance \
        --version 0.62.1 \
        --namespace flux-system \
        -f <(yq '.spec.values' "{{ justfile_directory() }}/k8s/infra/flux-system/instance/app/helmrelease.yaml") \
        --wait \
        --timeout 10m
    echo "✔ Flux bootstrap completed. GitOps reconciliation handed over to Flux Operator."

# Verify Flux CD installation, controllers, SOPS secret, and sync status
doctor:
    #!/usr/bin/env bash
    set -euo pipefail
    export KUBECONFIG="{{ kubeconfig }}"
    if [ ! -f "$KUBECONFIG" ]; then
        echo "❌ kubeconfig not found at $KUBECONFIG (run 'just ans::kubeconfig' first)"
        exit 1
    fi
    echo "Checking Flux Operator and Instance..."
    kubectl -n flux-system get helmreleases,pods -l app.kubernetes.io/part-of=flux || true
    echo
    echo "Checking Flux controllers and prerequisites..."
    flux check
    echo
    echo "Checking sops-age secret in flux-system..."
    if kubectl -n flux-system get secret sops-age >/dev/null 2>&1; then
        echo "✔ sops-age secret present in flux-system"
    else
        echo "✗ sops-age secret missing in flux-system"
        exit 1
    fi
    echo
    echo "Checking flux-system git credentials..."
    if kubectl -n flux-system get secret flux-system >/dev/null 2>&1; then
        echo "✔ flux-system deploy key present in flux-system"
    else
        echo "✗ flux-system deploy key missing in flux-system"
        exit 1
    fi
    echo
    echo "Checking Flux resources status..."
    flux get all -A

# Trigger immediate Flux GitRepository and Kustomization reconciliation
reconcile name="flux-system":
    #!/usr/bin/env bash
    set -euo pipefail
    export KUBECONFIG="{{ kubeconfig }}"
    if [ ! -f "$KUBECONFIG" ]; then
        echo "❌ kubeconfig not found at $KUBECONFIG (run 'just ans::kubeconfig' first)"
        exit 1
    fi
    flux reconcile kustomization "{{ name }}" --with-source
    flux get kustomizations

# Validate Kustomize overlays and Kubernetes manifests with kubeconform
validate:
    #!/usr/bin/env bash
    set -euo pipefail
    for dir in \
        k8s/infra \
        k8s/infra/flux-system/operator/app \
        k8s/infra/flux-system/instance/app \
        k8s/network \
        k8s/network/metallb/app \
        k8s/network/metallb/config \
        k8s/network/cert-manager/app \
        k8s/network/cert-manager/config \
        k8s/network/traefik/app \
        k8s/network/traefik/config \
        k8s/network/cloudflared/app \
        k8s/network/external-dns/app \
        k8s/network/flux-webhook/app \
        k8s/storage \
        k8s/storage/local-path/app \
        k8s/storage/cloudnative-pg/app \
        k8s/storage/paradedb/app \
        k8s/storage/redis/app \
        k8s/monitoring \
        k8s/monitoring/newrelic/app \
        k8s/apps \
        k8s/apps/echo/app \
        k8s/apps/home-assistant/app \
        k8s/apps/home-assistant/mcp \
        k8s/apps/omed/app \
        k8s/apps/omed/db \
        k8s/apps/omed-nightly/app \
        k8s/apps/omed-nightly/db \
        k8s/apps/rustfs/app \
        k8s/apps/termix/app; do
        echo "Validating $dir..."
        kustomize build "{{ justfile_directory() }}/$dir" \
            | yq 'del(.sops)' \
            | kubeconform -strict -ignore-missing-schemas -summary
    done
    echo "Checking SOPS encryption on *.sops.yaml manifests..."
    while IFS= read -r -d '' file; do
        if [[ "$(basename "$file")" == .decrypted~* ]]; then
            echo "⚠️  Warning: temporary decrypted file present in working tree: $file"
            continue
        fi
        if ! grep -q '^sops:' "$file"; then
            echo "❌ Unencrypted SOPS file detected: $file"
            exit 1
        fi
        echo "✔ Encrypted: $file"
    done < <(find "{{ justfile_directory() }}/k8s" -name "*.sops.y*ml" -print0)

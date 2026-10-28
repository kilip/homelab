set shell := ["bash", "-euo", "pipefail", "-c"]

key_file := env("SOPS_AGE_KEY_FILE", justfile_directory() / "age.key")
kubeconfig := env("KUBECONFIG", justfile_directory() / "kubeconfig")

# Bootstrap Flux CD onto the cluster and provision the SOPS Age secret
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
    chmod 600 "$ssh_key"
    trap 'rm -f "$ssh_key"' EXIT
    echo "Fetching Flux SSH deploy key from pass hl/flux-ssh-key..."
    pass hl/flux-ssh-key > "$ssh_key"
    echo "Bootstrapping Flux CD..."
    flux bootstrap git \
        --url=ssh://git@github.com/kilip/homelab.git \
        --branch=main \
        --path=k8s/infra \
        --private-key-file="$ssh_key" \
        --silent

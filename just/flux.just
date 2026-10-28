# FluxCD helpers. Most recipes are exercised for the first time in the Flux phase.
#
# Usage:  just flux <recipe>

set working-directory := '..'

owner := env('HOMELAB_GITHUB_OWNER', 'kilip')
repo := env('HOMELAB_GITHUB_REPO', 'homelab')
branch := 'main'
flux_path := 'k8s/flux-system'

# Kubeconfig of the homelab cluster. Override with HOMELAB_KUBECONFIG or KUBECONFIG.
export KUBECONFIG := env('HOMELAB_KUBECONFIG', env('KUBECONFIG', home_directory() / '.kube/config'))

key_file := env('SOPS_AGE_KEY_FILE', justfile_directory() / 'age.key')

# List the recipes of this module (also runs on a bare `just flux`)
[private]
default:
    @just --list flux

# Check cluster prerequisites for Flux
check:
    flux check --pre

# Bootstrap Flux into the cluster and push the manifests to GitHub (needs GITHUB_TOKEN)
# TODO (Flux phase): consider --components to drop controllers that are not needed (saves RAM).
[confirm('Bootstrap Flux into the current cluster and push to GitHub? Needs GITHUB_TOKEN. [y/N]')]
bootstrap:
    flux bootstrap github --owner={{owner}} --repository={{repo}} --branch={{branch}} --path={{flux_path}} --personal

# Create the sops-age secret that Flux uses to decrypt SOPS-encrypted manifests
sops-secret:
    kubectl create namespace flux-system --dry-run=client -o yaml | kubectl apply -f -
    kubectl -n flux-system create secret generic sops-age --from-file=age.agekey={{key_file}} --dry-run=client -o yaml | kubectl apply -f -

# Pull the latest Git state and reconcile the root Kustomization
reconcile:
    flux reconcile source git flux-system
    flux reconcile kustomization flux-system --with-source

# Show the state of sources, Kustomizations and HelmReleases
status:
    flux get sources git -A
    flux get kustomizations -A
    flux get helmreleases -A

# Show recent Flux controller logs
logs since='15m':
    flux logs --all-namespaces --since={{since}}

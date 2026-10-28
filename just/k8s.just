# kubectl helpers for the homelab cluster.
#
# Usage:  just k8s <recipe>

set working-directory := '..'

# Kubeconfig of the homelab cluster. Override with HOMELAB_KUBECONFIG or KUBECONFIG.
kubeconfig := env('HOMELAB_KUBECONFIG', env('KUBECONFIG', home_directory() / '.kube/config'))

export KUBECONFIG := kubeconfig

# List the recipes of this module (also runs on a bare `just k8s`)
[private]
default:
    @just --list k8s

# Print the kubeconfig path used by these recipes
config:
    @echo "{{kubeconfig}}"

# Verify that the cluster is reachable
check:
    kubectl cluster-info
    kubectl get nodes

# Show nodes with details
nodes:
    kubectl get nodes -o wide

# Show pods (all namespaces by default, or pass kubectl flags, e.g. -n flux-system)
pods *args='-A':
    kubectl get pods {{args}}

# Show node and pod resource usage (uses the metrics-server bundled with k3s)
top:
    kubectl top nodes
    kubectl top pods -A --sort-by=memory

# Show the 30 most recent cluster events
events:
    kubectl get events -A --sort-by=.lastTimestamp | tail -n 30

# Render a kustomization locally without applying it, e.g. just k8s build k8s/network
build path:
    kubectl kustomize "{{path}}"

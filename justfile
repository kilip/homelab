# homelab task runner. Run `just` to list every recipe, including modules.
# Developed and tested with just 1.59.0 (modules and `working-directory` need a recent release).
#
#   just ansible ...   node provisioning (Ansible)
#   just sops ...      secrets (SOPS + age)
#   just flux ...      GitOps (FluxCD)
#   just k8s ...       cluster inspection (kubectl)

set shell := ["bash", "-euo", "pipefail", "-c"]

mod ansible 'just/ansible.just'
mod sops 'just/sops.just'
mod flux 'just/flux.just'
mod k8s 'just/k8s.just'

# List all recipes, including those inside modules
[private]
default:
    @just --list --list-submodules

# Check that the tools used by this repository are installed on this machine
doctor:
    #!/usr/bin/env bash
    set -euo pipefail
    missing=0
    report() {
        local kind="$1" tool="$2"
        if command -v "$tool" >/dev/null 2>&1; then
            printf '  ok       %-17s %s\n' "$tool" "$(command -v "$tool")"
        else
            printf '  missing  %-17s (%s)\n' "$tool" "$kind"
            if [ "$kind" = "required" ]; then
                missing=1
            fi
        fi
    }
    echo "Required now (Ansible, SOPS):"
    for tool in git ssh ansible-playbook ansible-galaxy age-keygen sops; do
        report required "$tool"
    done
    echo
    echo "Needed in later phases (Flux, cluster access):"
    for tool in kubectl flux; do
        report later "$tool"
    done
    echo
    echo "Optional (linting, test VM snapshots):"
    for tool in ansible-lint VBoxManage; do
        report optional "$tool"
    done
    echo
    echo "just: $(just --version)"
    if command -v ansible >/dev/null 2>&1; then
        echo "ansible: $(ansible --version | head -n 1)"
    fi
    if [ "$missing" -ne 0 ]; then
        echo >&2
        echo "Install the missing required tools and run 'just doctor' again." >&2
        exit 1
    fi

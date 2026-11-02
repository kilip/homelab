set shell := ["bash", "-euo", "pipefail", "-c"]

mod deps '.just/deps.just'
mod sops '.just/sops.just'
mod ans '.just/ansible.just'
mod fl '.just/flux.just'

[private]
default:
    @just --list --list-submodules

# Verify local development toolchain and environment
doctor: sops::init-key
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Checking mise and environment..."
    if ! command -v mise >/dev/null 2>&1; then
        echo "❌ mise not found in PATH"
        exit 1
    fi
    echo "✅ mise: $(mise --version)"
    mise doctor
    echo
    echo "Checking core tools..."
    for tool in sops age-keygen kubectl flux helm uv python gitleaks lefthook; do
        if command -v "$tool" >/dev/null 2>&1; then
            printf "  %-12s %s\n" "$tool" "$(command -v "$tool")"
        else
            printf "  ❌ missing: %s\n" "$tool"
        fi
    done
    echo
    sops_key="$(mise exec -- printenv SOPS_AGE_KEY_FILE 2>/dev/null || echo "${SOPS_AGE_KEY_FILE:-}")"
    if [ -n "$sops_key" ]; then
        echo "✅ SOPS_AGE_KEY_FILE: $sops_key"
    else
        echo "⚠️  SOPS_AGE_KEY_FILE not exported"
    fi

# Run Ansible playbook (shortcut for ans::play)
[arg("host", long="host", short="h")]
[arg("tags", long="tags", short="t")]
[arg("check", long="check", short="c", value="true")]
play host="" tags="" check="":
    #!/usr/bin/env bash
    set -euo pipefail
    args=()
    if [ -n "{{ host }}" ]; then
        args+=(--host "{{ host }}")
    fi
    if [ -n "{{ tags }}" ]; then
        args+=(--tags "{{ tags }}")
    fi
    if [ "{{ check }}" = "true" ]; then
        args+=(--check)
    fi
    just ans::play "${args[@]}"

# Run Ansible playbook targeting Zeus workstation (shortcut for ans::play --host zeus --tags zeus)
[arg("tags", long="tags", short="t")]
[arg("check", long="check", short="c", value="true")]
zeus tags="zeus" check="":
    #!/usr/bin/env bash
    set -euo pipefail
    args=(--host zeus --tags "{{ tags }}")
    if [ "{{ check }}" = "true" ]; then
        args+=(--check)
    fi
    just ans::play "${args[@]}"

set shell := ["bash", "-euo", "pipefail", "-c"]

mod deps '.just/deps.just'
mod sops '.just/sops.just'

[private]
default:
    @just --list --list-submodules

# Verify local development toolchain and environment
doctor:
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
    for tool in sops age-keygen kubectl flux helm talosctl uv python; do
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

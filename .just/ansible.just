set shell := ["bash", "-euo", "pipefail", "-c"]

ansible_dir := justfile_directory() / "ansible"

# Run ansible-lint on the ansible directory
lint:
    cd "{{ ansible_dir }}" && ANSIBLE_VARS_SOPS_PLUGIN_STAGE=task ansible-lint

# Run full Molecule test lifecycle (optionally target a single platform: ubuntu, debian12, cachyos)
test platform="":
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{ ansible_dir }}"
    if [ -n "{{ platform }}" ]; then
        molecule test --platform-name "{{ platform }}"
    else
        molecule test
    fi

# Run Molecule converge (optionally target a single platform)
converge platform="":
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{ ansible_dir }}"
    if [ -n "{{ platform }}" ]; then
        molecule converge --platform-name "{{ platform }}"
    else
        molecule converge
    fi

# Run Molecule verify (optionally target a single platform)
verify platform="":
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{ ansible_dir }}"
    if [ -n "{{ platform }}" ]; then
        molecule verify
    else
        molecule verify
    fi

# Destroy Molecule test containers (optionally target a single platform)
destroy platform="":
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{ ansible_dir }}"
    if [ -n "{{ platform }}" ]; then
        molecule destroy --platform-name "{{ platform }}"
    else
        molecule destroy
    fi

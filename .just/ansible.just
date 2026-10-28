set shell := ["bash", "-euo", "pipefail", "-c"]

ansible_dir := justfile_directory() / "ansible"

# Run ansible-lint on the ansible directory
lint:
    cd "{{ ansible_dir }}" && ANSIBLE_VARS_SOPS_PLUGIN_STAGE=task ansible-lint

# Run Ansible playbook (optionally filter by --host/-h, --tags/-t, or dry-run with --check/-c)
[arg("host", long="host", short="h")]
[arg("tags", long="tags", short="t")]
[arg("check", long="check", short="c", value="true")]
play host="" tags="" check="":
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{ ansible_dir }}"
    args=()
    if [ -n "{{ host }}" ]; then
        args+=(--limit "{{ host }}")
    fi
    if [ -n "{{ tags }}" ]; then
        args+=(--tags "{{ tags }}")
    fi
    if [ "{{ check }}" = "true" ]; then
        args+=(--check --diff)
    fi
    ansible-playbook site.yml "${args[@]}"

# Run full Molecule test lifecycle (optionally target a single platform: ubuntu, debian, cachyos)
test platform="":
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "{{ justfile_directory() }}/.cache/molecule"/{ubuntu/{apt-cache,apt-lists,k3s},debian/{apt-cache,apt-lists},cachyos/{pacman-pkg,pacman-sync}}
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
    mkdir -p "{{ justfile_directory() }}/.cache/molecule"/{ubuntu/{apt-cache,apt-lists,k3s},debian/{apt-cache,apt-lists},cachyos/{pacman-pkg,pacman-sync}}
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

# Clean local Molecule package and binary caches
clean-cache:
    #!/usr/bin/env bash
    set -euo pipefail
    cache_dir="{{ justfile_directory() }}/.cache/molecule"
    if [ -d "$cache_dir" ]; then
        docker run --rm -v "{{ justfile_directory() }}/.cache:/cache" alpine:3.21 rm -rf /cache/molecule
        echo "Removed $cache_dir"
    else
        echo "No Molecule cache directory found at $cache_dir"
    fi

# Fetch K3s kubeconfig from cluster node to local kubeconfig
kubeconfig:
    cd "{{ ansible_dir }}" && ansible-playbook site.yml --tags kubeconfig

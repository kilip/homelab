# AGENTS.md

Project instructions and reference guide for AI coding agents working on **Olympus** (`homelab`).

## Project Overview

Olympus is an Infrastructure-as-Code (IaC) repository for homelab automation, cluster provisioning, GitOps delivery, and secrets management.

- **Configuration Management**: Ansible (`ansible/`) with `community.sops` integration
- **Container Orchestration**: K3s (Kubernetes) and Flux CD (`k8s/`)
- **Secrets Management**: SOPS + Age (`.sops.yaml`, `*.sops.yml`)
- **Toolchain & Environment**: `mise` (`.mise.toml`) + Python `.venv` managed via `uv`
- **Task Runner**: `just` (`.justfile` and modular recipes in `.just/`)

## Hardware & Node Inventory

Defined in `ansible/inventory/hosts.yml` and documented in `docs/nodes/`:

| Node | Role / Group | OS | Hardware |
| :--- | :--- | :--- | :--- |
| `zeus` | `workstations` | CachyOS Linux (`Archlinux` family) | Intel Core i5-12400, 32 GB RAM, GTX 1650 |
| `hera` | `servers`, `k3s` | Ubuntu Server 26.04 LTS (`Debian` family) | Intel NUC 6CAYH (Celeron J3455, 8 GB RAM) |
| `eros` | `servers` | Debian 13 arm64 (`Debian` family) | Raspberry Pi 3 Model B+ (1 GB RAM) |
| `ares` | Network Gateway / Router | MikroTik RouterOS v7 | RB2011iL |
| `gaia` | Access Point & Switch | MikroTik RouterOS v7 | RB951Ui-2HnD |
| `leto` | Access Point & Switch | MikroTik RouterOS v6 | RB941-2nD (hAP lite) |

## Repository Layout

```text
.
├── .github/workflows/       # CI pipelines (ansible-lint, Molecule matrix)
├── .just/                   # Modular justfile recipes
│   ├── ansible.just         # `ans` module: lint, Molecule lifecycle, kubeconfig fetch
│   ├── deps.just            # `deps` module: mise + uv virtualenv installation
│   ├── flux.just            # `fl` module: Flux CD bootstrap and SOPS secret setup
│   └── sops.just            # `sops` module: age key initialization from pass
├── ansible/                 # Ansible IaC
│   ├── ansible.cfg          # Ansible config (SOPS vars plugin enabled at inventory stage)
│   ├── inventory/           # `hosts.yml` and encrypted `host_vars/*.sops.yml`
│   ├── molecule/default/    # Docker-backed Molecule scenario (ubuntu, debian, cachyos)
│   ├── requirements.txt     # Python dependencies (ansible, ansible-lint, molecule, docker)
│   ├── roles/               # Ansible roles (`common`, `k3s`)
│   └── site.yml             # Main cluster & node playbook
├── docs/nodes/              # Hardware specification docs per node
├── k8s/                     # Kubernetes & Flux CD manifests
├── .editorconfig            # Formatting rules (2-space indent; 4-space for justfiles)
├── .justfile                # Root task entrypoint (`doctor`, submodules)
├── .mise.toml               # Pinned CLI tools and environment variables
└── .sops.yaml               # SOPS encryption creation rules and Age public key
```

## Common Commands

Run commands through `just` (or `mise exec -- just ...` if `mise` shims are not active in the shell):

- **Verify environment & toolchain**: `just doctor`
- **Install tools & Python dependencies**: `just deps::install`
- **Initialize Age key from `pass`**: `just sops::init-key`
- **Run Ansible playbook**: `just ans::play` (supports `--host/-h <host>`, `--tags/-t <tags>`, `--check/-c`)
- **Ping inventory hosts**: `just ans::ping [host]`
- **Run Ansible linter**: `just ans::lint`
- **Run full Molecule test suite (all platforms)**: `just ans::test`
- **Run Molecule tests for a single platform**: `just ans::test ubuntu` (or `debian`, `cachyos`)
- **Run Molecule converge / verify / destroy / clean-cache**:
  - `just ans::converge [platform]`
  - `just ans::verify [platform]`
  - `just ans::destroy [platform]`
  - `just ans::clean-cache`
- **Fetch K3s `kubeconfig` from server**: `just ans::kubeconfig`
- **Bootstrap Flux CD onto cluster**: `just fl::bootstrap`
- **Verify Flux CD installation & sync status**: `just fl::doctor`
- **Reconcile Flux CD state immediately**: `just fl::reconcile [name]`
- **Validate Kustomize overlays & K8s manifests**: `just fl::validate`

## Coding & Architecture Conventions

### Ansible (`ansible/`)
1. **FQCN Everywhere**: Always use Fully Qualified Collection Names (e.g., `ansible.builtin.package`, `community.general.pacman`, `community.general.ufw`).
2. **Role Structure**:
   - Validate required role variables upfront via `tasks/verify.yml` imported at the start of `tasks/main.yml` using `ansible.builtin.assert`.
   - Keep role defaults in `defaults/main.yml` and prefix role variables with the role name (e.g., `k3s_version`, `common_packages`).
   - Support multi-OS execution where applicable (`Debian` family via `apt` and `Archlinux` family via `pacman`).
3. **Container-Safe Testing Flags**:
   - Systemd/kernel operations that cannot run inside unprivileged or container test environments (such as `modprobe`, `sysctl --system`, `ufw`, or starting the `k3s` systemd service) must be guarded by boolean flags (e.g., `k3s_start_service`, `k3s_fetch_kubeconfig`) so Molecule can disable them in `molecule.yml` while still testing package installation, config rendering, and binary setup.
4. **Linting & SOPS**:
   - `ansible/ansible.cfg` configures `community.sops.sops` with `vars_stage = inventory`.
   - When running `ansible-lint` without decrypting inventory secrets, set `ANSIBLE_VARS_SOPS_PLUGIN_STAGE=task` (handled automatically by `just ans::lint`).

### Formatting (`.editorconfig`)
- Default indentation: **2 spaces**, LF line endings, UTF-8, trim trailing whitespace, final newline.
- Markdown (`*.md`): 2 spaces, `trim_trailing_whitespace = false`.
- Justfiles (`*.just`, `.justfile`): **4 spaces**.

## Git & Commit Conventions

- Use **Conventional Commits without scope** and with an emoji right after the colon: `type: <emoji> subject`
  - Example: `feat: ✨ add k3s role and kubeconfig fetch command`
  - Breaking changes: `type!: <emoji> subject` with a `BREAKING CHANGE:` footer.
  - Subject: imperative mood, lowercase after the emoji, no trailing period, max ~72 characters.
  - Use this exact type-to-emoji mapping:

    | Type | Emoji | Example |
    | :--- | :--- | :--- |
    | `feat` | ✨ | `feat: ✨ add k3s role and kubeconfig fetch command` |
    | `fix` | 🐛 | `fix: 🐛 handle missing kubeconfig path` |
    | `refactor` | ♻️ | `refactor: ♻️ rename ansible just module to ans` |
    | `perf` | ⚡ | `perf: ⚡ enable ssh pipelining in ansible` |
    | `test` | ✅ | `test: ✅ verify k3s systemd unit in molecule` |
    | `docs` | 📝 | `docs: 📝 add AGENTS.md reference guide` |
    | `build` | 📦 | `build: 📦 bump ansible to 11.0.0` |
    | `ci` | 👷 | `ci: 👷 add molecule test workflow` |
    | `chore` | 🔧 | `chore: 🔧 configure sops rules and editor settings` |
    | `revert` | ⏪ | `revert: ⏪ revert k3s role changes` |

- Keep one logical change per commit. Never commit or push unless explicitly requested.

## Testing & Verification Requirements

Before considering any Ansible or infrastructure change complete:
1. Run `just ans::lint` and ensure zero `ansible-lint` warnings or errors.
2. Update `ansible/molecule/default/converge.yml` and `ansible/molecule/default/verify.yml` to cover new roles, tasks, or configuration files.
3. Ensure tasks are idempotent (Molecule runs an `idempotence` step after `converge`).
4. Run `just ans::test` (or target affected platforms via `just ans::test <platform>`) and report actual results.

## Security & Secrets Rules

- **NEVER** read, print, log, or commit `age.key`, `kubeconfig`, `.decrypted~*`, or any unencrypted secret files.
- **NEVER** commit plaintext secrets. All secrets in `ansible/inventory/host_vars/*.sops.yml` and `k8s/**/*.sops.yaml` must be encrypted with SOPS using the rules in `.sops.yaml`.
- Notice if any `.decrypted~*` temporary file exists in the working tree: do not read or stage it, and warn the user so it can be cleaned up safely.
- **Infisical & SOPS Coexistence**: `k8s/infra/settings.sops.yaml` is retained for cluster-level post-build substitutions (`${SECRET_DOMAIN}`). Dynamic application runtime secrets are managed via Infisical Cloud and synchronized into Kubernetes Secrets using the Infisical Secrets Operator (`k8s/security/infisical-operator/`).


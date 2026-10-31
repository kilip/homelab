# App Role ZeroTier Task Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add ZeroTier (`zerotier-one`) installation, service lifecycle management, and network joining capabilities to the Ansible `app` role (`ansible/roles/app`), and store the local network ID in an encrypted SOPS inventory file.

**Architecture:** Extend the `app` role with `tasks/zerotier.yml` supporting Debian/Ubuntu (official APT repo + keyring) and Arch Linux/CachyOS (native pacman package). Use `app_zerotier` and `app_zerotier_start_service` flags for safe testing in Molecule containers. Add automated joining for `app_zerotier_networks` using `zerotier-cli`. Create `ansible/inventory/group_vars/all.sops.yaml` (and symlink `ansible/inventory/host_vars/all.sops.yaml`) containing the SOPS-encrypted ZeroTier network ID (`<zerotier-network-id>`).

**Tech Stack:** Ansible 2.16+, ZeroTier (`zerotier-one`), SOPS + Age, Molecule (Docker driver), Just.

**Spec:** Direct user request to add ZeroTier install & join network tasks to `@app`, reading network ID from the local machine (`<zerotier-network-id>`) and saving to `@ansible/inventory/host_vars/all.sops.yaml`.

## Global Constraints

- **FQCN Everywhere**: Always use Fully Qualified Collection Names (e.g. `ansible.builtin.apt`, `ansible.builtin.systemd_service`, `community.general.pacman`).
- **Secrets Security**: NEVER print, log, or commit plaintext secrets. Encrypt `all.sops.yaml` with SOPS using `.sops.yaml` Age creation rule.
- **Container-Safe Testing**: Service start and CLI join tasks must be guarded with `app_zerotier_start_service` and `not ansible_check_mode` so Molecule can test package installation without requiring privileged kernel `tun` / systemd.
- **Idempotency & Clean Removal**: When `app_zerotier: false`, stop/disable service, remove packages, and clean up repository files.

## Review Focus

- Architecture & OS differences: Debian/Ubuntu uses official APT repo with `/etc/apt/keyrings/zerotier.asc` while Archlinux uses native `extra/zerotier-one`.
- Safe joining: `zerotier-cli join` should only execute if `app_zerotier_start_service: true` and the network is not already joined.
- SOPS variable resolution: Ansible loads `group_vars/all.sops.yaml` for all hosts, while symlink `host_vars/all.sops.yaml` satisfies user path request.
- Linting: Zero warnings/errors from `just ans::lint`.
- Molecule test verification: Verify packages and files exist in `verify.yml` across ubuntu, debian, and cachyos.

---

### Task 1: Add ZeroTier defaults and verification assertions in role `app`

**Files:**
- Modify: `ansible/roles/app/defaults/main.yml`
- Modify: `ansible/roles/app/tasks/verify.yml`
- Modify: `ansible/roles/app/handlers/main.yml`

- [ ] **Step 1: Add ZeroTier role defaults**
Add to `ansible/roles/app/defaults/main.yml`:
```yaml
app_zerotier: false
app_zerotier_start_service: true
app_zerotier_service: zerotier-one
app_zerotier_packages_debian:
  - zerotier-one
app_zerotier_packages_archlinux:
  - zerotier-one
app_zerotier_packages: []
app_zerotier_networks: []
```

- [ ] **Step 2: Add validation assertions to `verify.yml`**
Add type validation assertions for `app_zerotier*` variables in `ansible/roles/app/tasks/verify.yml`:
- `app_zerotier is boolean`
- `app_zerotier_start_service is boolean`
- `app_zerotier_service is string`
- `app_zerotier_packages is sequence`
- `app_zerotier_packages_debian is sequence`
- `app_zerotier_packages_archlinux is sequence`
- `app_zerotier_networks is sequence`

- [ ] **Step 3: Add `Restart zerotier-one` handler**
Add handler in `ansible/roles/app/handlers/main.yml`:
```yaml
- name: Restart zerotier-one
  ansible.builtin.systemd_service:
    name: "{{ app_zerotier_service }}"
    state: restarted
  when:
    - app_zerotier_start_service | bool
    - not ansible_check_mode
```

- [ ] **Step 4: Verify syntax and linting**
Run `just ans::lint` to ensure role syntax and variable checks pass.

---

### Task 2: Implement ZeroTier tasks in `ansible/roles/app/tasks/zerotier.yml`

**Files:**
- Create: `ansible/roles/app/tasks/zerotier.yml`
- Modify: `ansible/roles/app/tasks/main.yml`

- [ ] **Step 1: Create `tasks/zerotier.yml`**
Implement installation, repository setup, service management, and network joining:
- Debian/Ubuntu:
  - Ensure prerequisites (`ca-certificates`, `curl`, `gnupg`)
  - Ensure `/etc/apt/keyrings` exists
  - Download official GPG key to `/etc/apt/keyrings/zerotier.asc`
  - Configure APT source `/etc/apt/sources.list.d/zerotier.list`
  - Update APT cache if repo changed
  - Install packages (`zerotier-one`)
- Arch Linux / CachyOS:
  - Install packages via `community.general.pacman`
- Service management:
  - Enable and start `zerotier-one` via `ansible.builtin.systemd_service` when `app_zerotier_start_service | bool and not ansible_check_mode`
- Network joining:
  - Query current joined networks via `zerotier-cli listnetworks`
  - Join networks in `app_zerotier_networks` when `app_zerotier_start_service | bool and not ansible_check_mode` and item not already joined
- Uninstall lifecycle (when `not (app_zerotier | bool)`):
  - Stop and disable `zerotier-one` service
  - Remove packages via `apt` (with `purge: true`) or `pacman`
  - Remove `/etc/apt/sources.list.d/zerotier.list` and `/etc/apt/keyrings/zerotier.asc` on Debian/Ubuntu

- [ ] **Step 2: Include `zerotier.yml` in `tasks/main.yml`**
Add task include in `ansible/roles/app/tasks/main.yml`:
```yaml
- name: Manage zerotier
  ansible.builtin.include_tasks:
    file: "zerotier.yml"
```

- [ ] **Step 3: Run linter**
Run `just ans::lint` to verify FQCN and task structure.

---

### Task 3: Create SOPS encrypted inventory file with network ID

**Files:**
- Create: `ansible/inventory/group_vars/all.sops.yaml`
- Create (symlink): `ansible/inventory/host_vars/all.sops.yaml -> ../group_vars/all.sops.yaml`

- [ ] **Step 1: Encrypt and write `all.sops.yaml`**
Content to encrypt:
```yaml
app_zerotier: true
app_zerotier_networks:
  - "<zerotier-network-id>"
```
Encrypt using `sops --filename-override ansible/inventory/group_vars/all.sops.yaml --encrypt` and save directly to `ansible/inventory/group_vars/all.sops.yaml`.

- [ ] **Step 2: Create symlink in `host_vars`**
Create symlink `ansible/inventory/host_vars/all.sops.yaml -> ../group_vars/all.sops.yaml`.

- [ ] **Step 3: Verify Ansible SOPS decryption across hosts**
Run `cd ansible && mise exec -- ansible-inventory -i inventory/hosts.yml --host hera` to confirm `app_zerotier: true` and `app_zerotier_networks: ["<zerotier-network-id>"]` are decrypted successfully.

---

### Task 4: Update Documentation and Molecule Scenarios

**Files:**
- Modify: `ansible/roles/app/README.md`
- Modify: `ansible/molecule/default/molecule.yml`
- Modify: `ansible/molecule/default/converge.yml`
- Modify: `ansible/molecule/default/verify.yml`

- [ ] **Step 1: Document ZeroTier in `ansible/roles/app/README.md`**
Add section for ZeroTier describing variables, Debian/Ubuntu & Arch Linux behavior, network joining, and uninstall lifecycle.

- [ ] **Step 2: Update `molecule.yml`**
Add `app_zerotier_start_service: false` to `inventory.group_vars.all` in `ansible/molecule/default/molecule.yml`.

- [ ] **Step 3: Update `converge.yml` and `verify.yml`**
- In `converge.yml`, enable `app_zerotier: true` to test installation and configuration.
- In `verify.yml`, assert that ZeroTier package is installed and `/etc/apt/sources.list.d/zerotier.list` exists on Debian/Ubuntu, and service unit exists.

---

### Task 5: Run Full Verification & Molecule Tests

**Files:**
- Test execution only

- [ ] **Step 1: Run Ansible lint**
Execute `just ans::lint` and verify 0 errors/warnings.

- [ ] **Step 2: Run Molecule converge and verify**
Execute `just ans::converge ubuntu` and `just ans::verify ubuntu` (and debian / cachyos).

- [ ] **Step 3: Cleanup Molecule containers**
Execute `just ans::destroy`.

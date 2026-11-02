# Zeus Chezmoi Dotfiles Setup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish a fresh public GitHub repository `kilip/dotfiles`, clean local state, and implement idempotent `chezmoi` installation and repository initialization tasks in the `zeus` Ansible role.

**Architecture:** A dedicated `tasks/chezmoi.yml` task file in `ansible/roles/zeus` handles pacman package installation for `chezmoi` and runs `chezmoi init` for `zeus_user`. The Molecule test environment disables git initialization via `zeus_chezmoi_init: false` to keep container testing hermetic while verifying package presence.

**Tech Stack:** Ansible (pacman, stat, command modules), chezmoi, GitHub CLI (`gh`), Molecule, CachyOS / Arch Linux.

**Spec:** `docs/superpowers/specs/2026-11-02-zeus-chezmoi-setup-design.md`

## Global Constraints

- Target workstation is Archlinux-based (`CachyOS`).
- Package manager is `community.general.pacman`.
- Role variable prefix is `zeus_chezmoi_`.
- Non-root workstation user is `zeus_user` (default: `"{{ ansible_user }}"`).
- All Ansible tasks must be container-safe: guarded by boolean flags (`zeus_chezmoi_init: false` in Molecule).
- All commits follow AGENTS.md Conventional Commits: `type: <emoji> subject`.

## Review Focus

- GitHub redirect collision: `kilip/dotfiles` previously redirected to `kilip/arch.dotfiles`. Creating a new repo explicitly must detach/claim `kilip/dotfiles` cleanly.
- Non-root execution: `chezmoi init` must run as `zeus_user` rather than `root` to avoid creating root-owned files in `/home/<user>/.local/share/chezmoi`.
- Idempotency: `chezmoi init` must not re-run or error if `~/.local/share/chezmoi` already exists.
- Container isolation: Molecule verification must pass without internet git-clone or SSH authentication dependencies.
- Lint compliance: `ansible-lint` must report 0 warnings or errors with FQCN everywhere.

---

### Task 1: GitHub Repository Creation & Local State Cleanup

**Files:**
- Modify: Local directory `/home/toni/.local/share/chezmoi` (remove old files)
- External: GitHub repository `kilip/dotfiles`

**Interfaces:**
- Consumes: `gh` CLI authenticated as `kilip`
- Produces: Empty public repository `https://github.com/kilip/dotfiles`

- [ ] **Step 1: Check and clean local chezmoi state**

Remove `/home/toni/.local/share/chezmoi` if it exists and still points to the old archived repository.

Command:
```bash
if [ -d "/home/toni/.local/share/chezmoi" ]; then
    rm -rf /home/toni/.local/share/chezmoi
fi
```

- [ ] **Step 2: Create new blank public repository on GitHub**

Create `kilip/dotfiles` with `gh repo create`.

Command:
```bash
gh repo create kilip/dotfiles --public --description "Dotfiles managed by chezmoi"
```

- [ ] **Step 3: Verify repository creation and remote accessibility**

Verify that `kilip/dotfiles` exists, is public, and is not archived.

Command:
```bash
gh repo view kilip/dotfiles --json name,isArchived,isPrivate,url
```
Expected: `{"isArchived":false,"isPrivate":false,"name":"dotfiles","url":"https://github.com/kilip/dotfiles"}`

---

### Task 2: Ansible Role Configuration & Chezmoi Tasks

**Files:**
- Create: `ansible/roles/zeus/tasks/chezmoi.yml`
- Modify: `ansible/roles/zeus/defaults/main.yml`
- Modify: `ansible/roles/zeus/tasks/verify.yml`
- Modify: `ansible/roles/zeus/tasks/main.yml`
- Modify: `ansible/roles/zeus/README.md`

**Interfaces:**
- Consumes: `zeus_chezmoi_enabled`, `zeus_chezmoi_repo`, `zeus_chezmoi_init`, `zeus_user`
- Produces: `chezmoi` package installed, `~/.local/share/chezmoi` initialized for `zeus_user`

- [ ] **Step 1: Define default variables in `ansible/roles/zeus/defaults/main.yml`**

Add defaults:
```yaml
# Chezmoi dotfiles management
zeus_chezmoi_enabled: true
zeus_chezmoi_repo: "git@github.com:kilip/dotfiles.git"
zeus_chezmoi_init: true
```

- [ ] **Step 2: Add assertions to `ansible/roles/zeus/tasks/verify.yml`**

Assert that `zeus_chezmoi_enabled` is boolean, `zeus_chezmoi_init` is boolean, and `zeus_chezmoi_repo` is a non-empty string when enabled.

- [ ] **Step 3: Implement `ansible/roles/zeus/tasks/chezmoi.yml`**

Tasks:
1. `ansible.builtin.package` or `community.general.pacman`: ensure `chezmoi` package is present.
2. `ansible.builtin.stat`: check if `~{{ zeus_user }}/.local/share/chezmoi` exists.
3. `ansible.builtin.command`: run `chezmoi init {{ zeus_chezmoi_repo }}` as `zeus_user` (`become: true`, `become_user: "{{ zeus_user }}"`) when `zeus_chezmoi_init | bool` and directory does not exist.

- [ ] **Step 4: Import `chezmoi.yml` in `ansible/roles/zeus/tasks/main.yml`**

```yaml
- name: Manage chezmoi dotfiles
  ansible.builtin.import_tasks: chezmoi.yml
  when:
    - zeus_enabled | bool
    - zeus_chezmoi_enabled | bool
```

- [ ] **Step 5: Update `ansible/roles/zeus/README.md`**

Document `zeus_chezmoi_enabled`, `zeus_chezmoi_repo`, and `zeus_chezmoi_init`.

- [ ] **Step 6: Commit role changes**

```bash
git add ansible/roles/zeus/
git commit -m "feat: ✨ add chezmoi dotfiles management to zeus role"
```

---

### Task 3: Molecule Configuration and Test Verification

**Files:**
- Modify: `ansible/molecule/default/molecule.yml`
- Modify: `ansible/molecule/default/verify.yml`

**Interfaces:**
- Consumes: `ansible/roles/zeus`
- Produces: Passing Molecule test on `cachyos` platform and zero lint errors

- [ ] **Step 1: Update `molecule.yml` with group variable override**

In `ansible/molecule/default/molecule.yml` under `provisioner.inventory.group_vars.workstations`:
```yaml
zeus_chezmoi_init: false
```

- [ ] **Step 2: Add chezmoi package verification to `molecule/default/verify.yml`**

Add check in `Verify zeus role installation and configuration`:
```yaml
- name: Verify chezmoi binary exists and is executable
  ansible.builtin.stat:
    path: /usr/bin/chezmoi
  register: chezmoi_bin_stat
  failed_when:
    - not chezmoi_bin_stat.stat.exists
    - chezmoi_bin_stat.stat.mode != '0755'
```

- [ ] **Step 3: Run `ansible-lint`**

Run: `just ans::lint`
Expected: 0 warnings, 0 errors.

- [ ] **Step 4: Run Molecule test on `cachyos`**

Run: `just ans::test cachyos`
Expected: PASS (all stages: syntax, converge, idempotence, verify, destroy).

- [ ] **Step 5: Commit Molecule test updates**

```bash
git add ansible/molecule/default/molecule.yml ansible/molecule/default/verify.yml
git commit -m "test: ✅ add chezmoi verification to molecule suite"
```

---

### Task 4: Provision Workstation Zeus & Verify Live Setup

**Files:**
- Verify: Live host `zeus` (`~/.local/share/chezmoi`)

**Interfaces:**
- Consumes: `just zeus` playbook runner
- Produces: `chezmoi` initialized on Zeus pointing to `git@github.com:kilip/dotfiles.git`

- [ ] **Step 1: Run Ansible playbook against Zeus**

Run: `just zeus`
Expected: Successful run without failures.

- [ ] **Step 2: Verify local chezmoi status on Zeus**

Run: `chezmoi status` and check git remote in `~/.local/share/chezmoi`.
Expected: Git remote points to `git@github.com:kilip/dotfiles.git`.

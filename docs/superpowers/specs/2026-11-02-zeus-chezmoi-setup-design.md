# Zeus Chezmoi Dotfiles Setup Design

## Intent & The Why
Configure dotfiles management for the Zeus workstation (`CachyOS`) using `chezmoi`. A fresh, empty public GitHub repository (`kilip/dotfiles`) will be established from scratch to replace the previous archived dotfiles repo, avoiding legacy Ubuntu-specific configurations.

## Goals
- Create a new public GitHub repository `kilip/dotfiles` from scratch using `gh` CLI.
- Clean up existing local state in `~/.local/share/chezmoi` on Zeus.
- Add an idempotent Ansible task in `ansible/roles/zeus` to install `chezmoi` via `pacman` and initialize `chezmoi init` pointing to `git@github.com:kilip/dotfiles.git` (or HTTPS) for `zeus_user`.
- Ensure role variables are properly verified in `tasks/verify.yml` and tested in Molecule.

## Non-Goals & Anti-Goals
- **Non-Goal**: Importing or migrating legacy configs from `kilip/arch.dotfiles` or old Ubuntu dotfiles.
- **Anti-Goal**: Running `chezmoi apply` automatically on empty/unreviewed repos, which could overwrite existing user files unintentionally.

## Constraints
- Target workstation is Archlinux-based (`CachyOS`).
- Package manager is `pacman` (`community.general.pacman`).
- User target is `zeus_user` (defaults to `ansible_user`).
- Molecule testing runs in Docker containers without SSH keys; chezmoi git initialization during Molecule testing must be container-safe (guarded by boolean flags like `zeus_chezmoi_init`).

## Approaches Considered
1. **Approach 1: Modular Task `tasks/chezmoi.yml` in role `zeus` (Selected)**
   - Structure: `ansible/roles/zeus/tasks/chezmoi.yml`, imported from `tasks/main.yml`.
   - Variables in `defaults/main.yml`:
     - `zeus_chezmoi_enabled: true`
     - `zeus_chezmoi_repo: "git@github.com:kilip/dotfiles.git"`
     - `zeus_chezmoi_init: true`
   - Trade-offs: Declarative, consistent with Olympus role standards (`deepcool.yml`), idempotent, tested in Molecule.
2. **Approach 2: One-off Justfile recipe or shell script**
   - Trade-offs: Bypasses Ansible IaC, not automated when re-provisioning workstations. Rejected.

## Decided Specifications
- **GitHub Repository**: `kilip/dotfiles` (public, created via `gh repo create kilip/dotfiles --public`).
- **Local State**: Remove old `~/.local/share/chezmoi` directory on Zeus.
- **Ansible Role**:
  - `ansible/roles/zeus/defaults/main.yml`: Add `zeus_chezmoi_*` defaults (`zeus_user: "{{ ansible_user }}"`).
  - `ansible/roles/zeus/tasks/verify.yml`: Add assertions for `zeus_chezmoi_*`.
  - `ansible/roles/zeus/tasks/chezmoi.yml`: Install package `chezmoi`, check destination, run `chezmoi init` if destination missing.
  - `ansible/roles/zeus/tasks/main.yml`: Import `chezmoi.yml` when `zeus_chezmoi_enabled`.
  - Molecule tests updated to verify `chezmoi` package installation while skipping network git init in container (`zeus_chezmoi_init: false`).

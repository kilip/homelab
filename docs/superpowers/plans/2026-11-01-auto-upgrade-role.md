# Auto Upgrade Role Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create an Ansible role `auto_upgrade` that configures systemd timers, upgrade runner scripts, and Telegram status notifications across all homelab nodes (Debian/Ubuntu servers and CachyOS workstation).

**Architecture:** A new Ansible role `auto_upgrade` deployed across all hosts. It provisions an upgrade script `/usr/local/bin/auto-upgrade.sh` that detects OS package manager (`apt` or `pacman`), executes the upgrade, checks for reboot requirements, and sends formatted notifications to Telegram via bot API. Systemd service (`auto-upgrade.service`) and timer (`auto-upgrade.timer`) units manage execution schedules, with `Persistent=true` and `After=network-online.target` ensuring reliability on workstations.

**Tech Stack:** Ansible (FQCN), Systemd Service & Timer, Bash, Telegram Bot API, SOPS + Age.

**Spec:** User requirements:
1. Server nodes (`hera`, `eros`): Auto upgrade every Monday at 01:00 (`OnCalendar=Mon *-*-* 01:00:00`).
2. Workstation node (`zeus`): Auto upgrade every Monday on startup/catch-up (`OnCalendar=Mon *-*-* 00:00:00` with `Persistent=true` and network dependency).
3. Telegram notification on execution status using bot `<telegram-bot-token>` and chat ID `<telegram-chat-id>`.

## Global Constraints

- Always use Ansible FQCN (`ansible.builtin.*`, `community.general.*`).
- Prefix all role variables with `auto_upgrade_`.
- Validate required variables upfront in `tasks/verify.yml` with `ansible.builtin.assert`.
- Guard systemd service/timer activation with `auto_upgrade_start_timer: true` (default `true`, overridden to `false` in Molecule container test environments).
- `ansible-lint` (`mise exec -- just ans::lint`) must pass cleanly.
- Never commit plaintext secrets into unencrypted files.

## Review Focus

1. **Missing Telegram Token/Chat ID**: If token or chat ID is empty/not configured, the upgrade script should still run the upgrade successfully and skip the Telegram call without throwing a fatal script error.
2. **Network Offline on Workstation Boot**: If `zeus` boots and starts the timer, `auto-upgrade.service` must wait for `network-online.target` so `pacman` doesn't fail immediately due to DNS/network unavailability.
3. **Pacman Lock Conflict on Arch/CachyOS**: If another pacman instance is running or lock file is stale, handle or report failure cleanly rather than hanging indefinitely.
4. **Debian Non-Interactive Mode**: Ensure `DEBIAN_FRONTEND=noninteractive` and `-y` are passed to `apt-get` to prevent hung interactive prompts during system upgrades.
5. **Molecule Container Compatibility**: Systemd unit enabling/starting must not execute inside Docker containers when `auto_upgrade_start_timer: false`.

---

### Task 1: Create Role Skeleton and Defaults

**Files:**
- Create: `ansible/roles/auto_upgrade/defaults/main.yml`
- Create: `ansible/roles/auto_upgrade/tasks/verify.yml`
- Create: `ansible/roles/auto_upgrade/meta/main.yml`

**Interfaces:**
- Produces: `auto_upgrade_enabled`, `auto_upgrade_start_timer`, `auto_upgrade_calendar`, `auto_upgrade_persistent`, `auto_upgrade_script_path`, `auto_upgrade_telegram_bot_token`, `auto_upgrade_telegram_chat_id`

- [ ] **Step 1: Define default variables in `ansible/roles/auto_upgrade/defaults/main.yml`**
  Set defaults with node-group awareness:
  - `auto_upgrade_enabled: true`
  - `auto_upgrade_start_timer: true`
  - `auto_upgrade_script_path: "/usr/local/bin/auto-upgrade.sh"`
  - `auto_upgrade_calendar: "{{ 'Mon *-*-* 00:00:00' if (inventory_hostname in groups['workstations'] | default([])) else 'Mon *-*-* 01:00:00' }}"`
  - `auto_upgrade_persistent: true`
  - `auto_upgrade_telegram_bot_token: ""`
  - `auto_upgrade_telegram_chat_id: ""`
  - `auto_upgrade_reboot: false`

- [ ] **Step 2: Define assertions in `ansible/roles/auto_upgrade/tasks/verify.yml`**
  Validate types and required variables using `ansible.builtin.assert`.

- [ ] **Step 3: Define role metadata in `ansible/roles/auto_upgrade/meta/main.yml`**
  Add author and platform metadata.

---

### Task 2: Create Auto-Upgrade Shell Script Template

**Files:**
- Create: `ansible/roles/auto_upgrade/templates/auto-upgrade.sh.j2`

**Interfaces:**
- Consumes: `auto_upgrade_telegram_bot_token`, `auto_upgrade_telegram_chat_id`, `auto_upgrade_reboot`

- [ ] **Step 1: Write template `ansible/roles/auto_upgrade/templates/auto-upgrade.sh.j2`**
  - Script must be bash with error handling.
  - Helper function `send_telegram()` using `curl` to `https://api.telegram.org/bot<TOKEN>/sendMessage`.
  - Supports Debian family (`apt-get update`, `apt-get dist-upgrade -y`, check `/var/run/reboot-required`).
  - Supports Archlinux family (`pacman -Syu --noconfirm`, check kernel version vs running kernel).
  - Sends Markdown-formatted status to Telegram with hostname, time taken, packages upgraded, and reboot status.

---

### Task 3: Create Systemd Service and Timer Templates

**Files:**
- Create: `ansible/roles/auto_upgrade/templates/auto-upgrade.service.j2`
- Create: `ansible/roles/auto_upgrade/templates/auto-upgrade.timer.j2`

**Interfaces:**
- Consumes: `auto_upgrade_script_path`, `auto_upgrade_calendar`, `auto_upgrade_persistent`

- [ ] **Step 1: Template `auto-upgrade.service.j2`**
  - `Type=oneshot`
  - `After=network-online.target`
  - `Wants=network-online.target`
  - `ExecStart={{ auto_upgrade_script_path }}`

- [ ] **Step 2: Template `auto-upgrade.timer.j2`**
  - `[Timer]`
  - `OnCalendar={{ auto_upgrade_calendar }}`
  - `Persistent={{ auto_upgrade_persistent | lower }}`
  - `RandomizedDelaySec=60`
  - `[Install]`
  - `WantedBy=timers.target`

---

### Task 4: Implement Role Tasks and Handlers

**Files:**
- Create: `ansible/roles/auto_upgrade/tasks/main.yml`
- Create: `ansible/roles/auto_upgrade/handlers/main.yml`

**Interfaces:**
- Consumes: templates from Tasks 2 and 3

- [ ] **Step 1: Define `ansible/roles/auto_upgrade/handlers/main.yml`**
  - Handler `systemd daemon reload` via `ansible.builtin.systemd_service: daemon_reload: true`
  - Handler `restart auto-upgrade timer` via `ansible.builtin.systemd_service: name: auto-upgrade.timer, state: restarted`

- [ ] **Step 2: Define `ansible/roles/auto_upgrade/tasks/main.yml`**
  - Import `tasks/verify.yml`
  - Install dependencies (`curl` if missing)
  - Deploy `/usr/local/bin/auto-upgrade.sh` with mode `0750` owner `root` group `root`
  - Deploy `/etc/systemd/system/auto-upgrade.service` with mode `0644`
  - Deploy `/etc/systemd/system/auto-upgrade.timer` with mode `0644` (notifies `systemd daemon reload`)
  - Manage systemd timer unit via `ansible.builtin.systemd_service` when `auto_upgrade_start_timer` is true

---

### Task 5: Encrypt Telegram Credentials and Wire Role to Playbook

**Files:**
- Modify: `ansible/inventory/group_vars/all.sops.yaml`
- Modify: `ansible/site.yml`

- [ ] **Step 1: Add Telegram token & chat_id to `ansible/inventory/group_vars/all.sops.yaml`**
  Use `sops` to securely encrypt:
  `auto_upgrade_telegram_bot_token: "<telegram-bot-token>"`
  `auto_upgrade_telegram_chat_id: "<telegram-chat-id>"`

- [ ] **Step 2: Add `auto_upgrade` role to `ansible/site.yml` under `hosts: all`**

---

### Task 6: Molecule Testing and Lint Verification

**Files:**
- Modify: `ansible/molecule/default/molecule.yml`
- Modify: `ansible/molecule/default/converge.yml`
- Modify: `ansible/molecule/default/verify.yml`
- Modify: `ansible/roles/common/defaults/main.yml` (fix pre-existing prefix lint issues if necessary)

- [ ] **Step 1: Update `ansible/molecule/default/molecule.yml`**
  Set `auto_upgrade_start_timer: false` in `group_vars: all`.

- [ ] **Step 2: Update `ansible/molecule/default/converge.yml`**
  Include `auto_upgrade` role.

- [ ] **Step 3: Update `ansible/molecule/default/verify.yml`**
  Verify `/usr/local/bin/auto-upgrade.sh`, `/etc/systemd/system/auto-upgrade.service`, and `/etc/systemd/system/auto-upgrade.timer` exist with correct permissions and expected content.

- [ ] **Step 4: Run `mise exec -- just ans::lint`**
  Ensure zero errors and zero warnings.

# Gemini Project Context: Homelab

## Project Overview
This repository contains the infrastructure-as-code (IaC) for a homelab environment, managed using **Ansible**. It automates the deployment and configuration of various services and applications across multiple nodes.

### Main Technologies
- **Ansible**: Primary configuration management and deployment tool.
- **Docker**: Containerization for most applications, managed via `geerlingguy.docker` role and `community.docker` collection.
- **SOPS**: Used for secret management, with files encrypted and decrypted on-the-fly via `community.sops`.
- **Taskfile**: Used for task orchestration and providing easy-to-use commands for common operations.
- **Molecule**: For testing and validating Ansible roles.
- **Python**: Used for library modules (`pihole.py`, `gpg_key.py`) and dependencies.

### Architecture
The project is organized into modular Ansible roles:
- **`core`**: Base configurations like Docker, Squid, Traefik, and Cloudflare Tunnels.
- **`apps`**: Application-specific tasks (e.g., Mosquitto, Authentik, Home Assistant, Trillium, Zabbix).
- **`storage`**: Storage-related services like Minio, Postgres, and Redis.
- **`node`**: Host-level configurations (SSH, GPG, Pass, Chezmoi).
- **`tools`**: Utility tools like Duplicati, Portainer, and Semaphore.

The main entry point is `main.yml`, which includes all roles and applies them to all hosts defined in `inventory/hosts.ini`.

---

## Building and Running

The project uses `Taskfile` to simplify common operations.

### Key Commands
- **`task deps`**: Installs project dependencies (pip requirements, Ansible galaxy collections/roles).
- **`task play`**: Runs the main playbook (`main.yml`) to converge the homelab.
  - Usage: `task play host=<host_name> tags=<tags> skip=<skip_tags> check=1`
- **`task check`**: Performs a dry run (check mode) of the main playbook.
  - Usage: `task check tags=<tags>` (e.g., `task check tags=mysql`)
- **`task ping`**: Pings all hosts in the inventory to check connectivity.
- **`task converge`**: Runs Molecule to test and validate roles.

> **Note:** To enable an application on a specific host, add the host to the relevant group in `inventory/hosts.ini` (e.g., adding a host under `[mysql]` will enable the MySQL role for that host). Application configurations in `defaults/main.yml` must remain `false` by default, and secrets/activation should be managed via encrypted `.sops.yaml` files.

### Prerequisites
- Ansible and `task` installed.
- Access to the `age.key` for SOPS decryption (typically retrieved from `pass hl/age-key`).
- Python virtual environment recommended.

---

## Development Conventions

### Secret Management
- All sensitive information (API keys, passwords, private keys) MUST be stored in `.sops.yaml` encrypted files.
- These are typically located in `inventory/group_vars/`, `inventory/host_vars/`, or `files/`.
- Ensure `age.key` is available before running playbooks.

### Role Structure
- Follow standard Ansible role structure (`defaults/`, `tasks/`, `handlers/`, `vars/`, `templates/`).
- Use `ansible.builtin.include_tasks` in `main.yml` of roles to keep them modular and allow filtering by tags.

### Naming and Style
- Use descriptive names for tasks.
- Adhere to YAML best practices (consistent indentation, clear structure).
- Use `ansible.builtin` prefix for all built-in modules to be explicit.

### Testing
- New roles or major changes to existing ones should be validated using **Molecule** (`molecule converge`).
- Linting is performed via `.ansible-lint`.

---

## Key Files
- `main.yml`: The primary Ansible playbook.
- `inventory/hosts.ini`: Defines the hosts and groups in the homelab.
- `Taskfile.yaml`: Defines common development and deployment tasks.
- `requirements.yml`: Lists external Ansible roles and collections.
- `inventory/group_vars/*.sops.yaml`: Encrypted secrets for various services.
- `library/*.py`: Custom Ansible modules for specific tasks (Pi-hole, GPG).

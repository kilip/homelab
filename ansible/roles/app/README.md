# Ansible Role: `app`

Deploy and manage host application services and containerized workloads across Olympus homelab nodes.

## Table of Contents

- [Requirements](#requirements)
- [Supported Platforms](#supported-platforms)
- [Architecture & Lifecycle](#architecture--lifecycle)
- [Applications & Components](#applications--components)
  - [Docker Engine (`app_docker`)](#docker-engine-app_docker)
  - [Mosquitto MQTT Broker (`app_mosquitto`)](#mosquitto-mqtt-broker-app_mosquitto)
  - [RustFS Object Storage (`app_rustfs`)](#rustfs-object-storage-app_rustfs)
  - [Prometheus Node Exporter (`app_node_exporter`)](#prometheus-node-exporter-app_node_exporter)
- [Example Playbook](#example-playbook)
- [License](#license)
- [Author Information](#author-information)

## Requirements

- Ansible 2.16 or higher.
- Elevated privileges (`become: true`) on target nodes.
- Python Docker SDK on target nodes (`python3-docker` or `python-docker`, installed automatically by the Docker component).

## Supported Platforms

- Ubuntu (all supported LTS releases)
- Debian (`trixie`)
- ArchLinux / CachyOS

## Architecture & Lifecycle

The `app` role provides a modular, containerized deployment pattern for host services:

1. **Dependency on Docker**: Containerized services (`mosquitto`, `rustfs`) require the container runtime. An assertion validates that `app_docker: true` when enabling any container service (`app_mosquitto: true` or `app_rustfs: true`).
2. **Container-Safe Testing**: All systemd service starts and container operations are guarded by `*_start_service` flags (`app_docker_start_service`, `app_mosquitto_start_service`, `app_rustfs_start_service`, `app_node_exporter_start_service`). In containerized test runners (e.g. Molecule), setting these to `false` allows verifying package installation, directory creation, permissions, and templating without requiring privileged Docker-in-Docker daemons.
3. **Idempotency & Clean Removal**: Setting any component flag to `false` triggers its respective uninstall routine, stopping and removing containers, disabling services, and cleaning up persistent data according to configured retention policies.

---

## Applications & Components

### Docker Engine (`app_docker`)

Installs and manages the host Docker CE container engine, official repository keys, daemon configuration (`/etc/docker/daemon.json`), and system user memberships.

#### Docker Variables

| Variable | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `app_docker` | Boolean | `false` | Enable Docker CE installation and management. Set to `false` to uninstall Docker packages, repository files, and daemon configurations. |
| `app_docker_start_service` | Boolean | `true` | Enable and start `docker.socket` and `docker.service` systemd units. Set to `false` in unprivileged container environments. |
| `app_docker_users` | List[String] | `["{{ ansible_user }}"]` | Host users added to the `docker` system group. |
| `app_docker_daemon_config` | Dict | See below | Daemon options rendered to `/etc/docker/daemon.json`. |
| `app_docker_packages` | List[String] | `[]` | Explicit package override list (uses distro defaults when empty). |
| `app_docker_packages_debian` | List[String] | `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, `docker-compose-plugin`, `python3-docker` | Default Docker packages for Debian and Ubuntu. |
| `app_docker_packages_archlinux` | List[String] | `docker`, `docker-buildx`, `docker-compose`, `python-docker` | Default Docker packages for Arch Linux and CachyOS. |

Default `app_docker_daemon_config`:

```yaml
app_docker_daemon_config:
  log-driver: "json-file"
  log-opts:
    max-size: "50m"
    max-file: "3"
  live-restore: true
```

#### Docker Uninstall Lifecycle

When `app_docker: false`:
- Stops and disables `docker.service` and `docker.socket`.
- Purges Docker packages across Debian/Ubuntu or Arch Linux.
- Removes APT repository (`/etc/apt/sources.list.d/docker.list`) and keyrings (`/etc/apt/keyrings/docker.asc`).
- Removes `/etc/docker/daemon.json`.

---

### Mosquitto MQTT Broker (`app_mosquitto`)

Deploys the lightweight Eclipse Mosquitto MQTT message broker as a Docker container. Supports persistent storage, custom listener ports, anonymous connection toggles, and user authentication with PBKDF2-SHA512 hashed passwords.

#### Mosquitto Storage & Directory Layout

- **Base Directory**: `{{ app_mosquitto_dir }}` (`/srv/mosquitto`)
- **Configuration**: `{{ app_mosquitto_config_dir }}` (`/srv/mosquitto/config`) -> mounted read-only (`:ro`) to `/mosquitto/config`
- **Data Persistence**: `{{ app_mosquitto_data_dir }}` (`/srv/mosquitto/data`) -> mounted read-write (`:rw`) to `/mosquitto/data`
- **Logs**: `{{ app_mosquitto_log_dir }}` (`/srv/mosquitto/log`) -> mounted read-write (`:rw`) to `/mosquitto/log`
- **Permissions**: Ownership set to UID `1883` and GID `1883` (Mosquitto container user).

#### Mosquitto Authentication & Password Hashing

Mosquitto 2.x requires hashed passwords in the `passwd` file. The role includes a custom Ansible filter plugin (`mosquitto_passwd`) that deterministically generates PBKDF2-SHA512 password hashes:

```yaml
app_mosquitto_allow_anonymous: false
app_mosquitto_users:
  - username: homeassistant
    password: "{{ vault_mosquitto_hass_password }}"
  - username: zigbee2mqtt
    password: "{{ vault_mosquitto_z2m_password }}"
```

#### Mosquitto Variables

| Variable | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `app_mosquitto` | Boolean | `false` | Enable Mosquitto deployment. |
| `app_mosquitto_container_name` | String | `mosquitto` | Docker container name. |
| `app_mosquitto_image` | String | `eclipse-mosquitto:2` | Container image tag. |
| `app_mosquitto_start_service` | Boolean | `true` | Start container (set to `false` in unprivileged container tests). |
| `app_mosquitto_dir` | String | `/srv/mosquitto` | Base directory on host. |
| `app_mosquitto_config_dir` | String | `{{ app_mosquitto_dir }}/config` | Configuration directory. |
| `app_mosquitto_data_dir` | String | `{{ app_mosquitto_dir }}/data` | Database/persistence storage directory. |
| `app_mosquitto_log_dir` | String | `{{ app_mosquitto_dir }}/log` | Log storage directory. |
| `app_mosquitto_port` | Integer | `1883` | Published host listener port. |
| `app_mosquitto_container_port` | Integer | `1883` | Container internal port. |
| `app_mosquitto_bind_address` | String | `0.0.0.0` | Host IP address to bind (empty string binds to all interfaces). |
| `app_mosquitto_allow_anonymous` | Boolean | `false` | Allow anonymous connections without credentials. |
| `app_mosquitto_persistence` | Boolean | `true` | Enable persistence database saving messages and subscriptions. |
| `app_mosquitto_users` | List[Dict] | `[]` | List of `{username: str, password: str}` dicts. |
| `app_mosquitto_uid` | String | `1883` | Host file ownership UID for Mosquitto. |
| `app_mosquitto_gid` | String | `1883` | Host file ownership GID for Mosquitto. |
| `app_mosquitto_service` | String | `mosquitto` | Name of legacy host systemd service stopped/disabled if present. |

#### Mosquitto Uninstall Lifecycle

When `app_mosquitto: false`:
- Stops and removes the Docker container `{{ app_mosquitto_container_name }}`.
- Deletes the base persistent directory `{{ app_mosquitto_dir }}` (`/srv/mosquitto`).

---

### RustFS Object Storage (`app_rustfs`)

Deploys RustFS, a lightweight, high-performance S3-compatible distributed object storage engine written in Rust. Exposes both S3 API and the built-in Web Management Console.

#### RustFS Storage & Directory Layout

- **Base Directory**: `{{ app_rustfs_dir }}` (`/srv/rustfs`)
- **Data Persistence**: `{{ app_rustfs_data_dir }}` (`/srv/rustfs/data`) -> mounted read-write (`:rw`) to `/data`
- **Permissions**: Ownership set to UID `10001` and GID `10001` (RustFS container user).

#### RustFS Network & Ports

| Service | Host Port | Container Port | Default Binding |
| :--- | :--- | :--- | :--- |
| **S3 API** | `app_rustfs_port` (`9000`) | `app_rustfs_container_port` (`9000`) | `0.0.0.0:9000` |
| **Web Console** | `app_rustfs_console_port` (`9001`) | `app_rustfs_container_console_port` (`9001`) | `0.0.0.0:9001` |

#### RustFS Variables

| Variable | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `app_rustfs` | Boolean | `false` | Enable RustFS deployment. |
| `app_rustfs_container_name` | String | `rustfs` | Docker container name. |
| `app_rustfs_image` | String | `rustfs/rustfs:1.0.1` | Container image tag. |
| `app_rustfs_start_service` | Boolean | `true` | Start container (set to `false` in unprivileged container tests). |
| `app_rustfs_dir` | String | `/srv/rustfs` | Base directory on host. |
| `app_rustfs_data_dir` | String | `{{ app_rustfs_dir }}/data` | Object storage data directory on host. |
| `app_rustfs_port` | Integer | `9000` | Published S3 API host port. |
| `app_rustfs_container_port` | Integer | `9000` | Internal S3 API port. |
| `app_rustfs_console_port` | Integer | `9001` | Published Web Console host port. |
| `app_rustfs_container_console_port` | Integer | `9001` | Internal Web Console port. |
| `app_rustfs_bind_address` | String | `0.0.0.0` | Host IP address to bind. |
| `app_rustfs_access_key` | String | `rustfsadmin` | Admin access key for S3 API and Console. |
| `app_rustfs_secret_key` | String | `rustfsadmin` | Admin secret key for S3 API and Console. |
| `app_rustfs_uid` | String | `10001` | Host file ownership UID for RustFS. |
| `app_rustfs_gid` | String | `10001` | Host file ownership GID for RustFS. |
| `app_rustfs_purge_data` | Boolean | `false` | Purge persistent storage (`/srv/rustfs`) when `app_rustfs: false`. Set to `false` to preserve data across uninstallations. |

#### RustFS Uninstall Lifecycle

When `app_rustfs: false`:
- Stops and removes the Docker container `{{ app_rustfs_container_name }}`.
- Storage directory `{{ app_rustfs_dir }}` is retained unless `app_rustfs_purge_data: true`.

---

### Prometheus Node Exporter (`app_node_exporter`)

Installs and configures the Prometheus Node Exporter system metrics collector as a native host systemd service via distro package managers (`apt` on Debian/Ubuntu, `pacman` on CachyOS/Arch Linux).

#### Node Exporter Variables

| Variable | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `app_node_exporter` | Boolean | `false` | Enable Prometheus Node Exporter installation and management. Set to `false` to stop service and uninstall packages. |
| `app_node_exporter_start_service` | Boolean | `true` | Enable and start `prometheus-node-exporter` systemd service. Set to `false` in unprivileged container environments. |
| `app_node_exporter_service` | String | `prometheus-node-exporter` | Systemd service name. |
| `app_node_exporter_port` | Integer | `9100` | Exporter HTTP metrics listener port. |
| `app_node_exporter_bind_address` | String | `0.0.0.0` | IP address to bind metrics listener. |
| `app_node_exporter_extra_flags` | List[String] | `[]` | List of extra command-line flags passed to the exporter. |
| `app_node_exporter_packages` | List[String] | `[]` | Explicit package override list (uses distro defaults when empty). |
| `app_node_exporter_packages_debian` | List[String] | `["prometheus-node-exporter"]` | Default packages for Debian and Ubuntu. |
| `app_node_exporter_packages_archlinux` | List[String] | `["prometheus-node-exporter"]` | Default packages for Arch Linux and CachyOS. |

#### Node Exporter Uninstall Lifecycle

When `app_node_exporter: false`:
- Stops and disables `prometheus-node-exporter` systemd service.
- Purges/removes packages across Debian/Ubuntu or Arch Linux.
- Removes configuration file (`/etc/default/prometheus-node-exporter` or `/etc/conf.d/prometheus-node-exporter`).

---

## Example Playbook

```yaml
---
- hosts: servers
  become: true
  roles:
    - role: app
      vars:
        # Enable Docker runtime
        app_docker: true
        app_docker_users:
          - toni

        # Deploy Mosquitto MQTT Broker
        app_mosquitto: true
        app_mosquitto_port: 1883
        app_mosquitto_allow_anonymous: false
        app_mosquitto_users:
          - username: sensor_node
            password: "{{ vault_mosquitto_sensor_password }}"
          - username: homeassistant
            password: "{{ vault_mosquitto_hass_password }}"

        # Deploy RustFS Object Storage
        app_rustfs: true
        app_rustfs_port: 9000
        app_rustfs_console_port: 9001
        app_rustfs_access_key: "admin"
        app_rustfs_secret_key: "{{ vault_rustfs_secret_key }}"
        app_rustfs_purge_data: false
```

## Dependencies

None.

## License

MIT

## Author Information

Anthonius (@Olympus)

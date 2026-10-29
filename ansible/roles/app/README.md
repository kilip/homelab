# Ansible Role: `app`

Deploy and manage host application services and utilities (e.g., Mosquitto MQTT broker) across Olympus homelab nodes.

## Requirements

- Ansible 2.16 or higher.
- Elevated privileges (`become: true`) on target nodes.

## Supported Platforms

- Ubuntu (all supported releases)
- Debian (`bookworm`)
- ArchLinux / CachyOS

## Role Variables

Variables available in `defaults/main.yml`:

| Variable | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `app_mosquitto` | Boolean | `false` | Enable Mosquitto installation and configuration. When `false`, executes uninstall block (stops service, removes package, and purges config/data). |
| `app_mosquitto_packages` | List | `["mosquitto"]` | Packages to install for Mosquitto. |
| `app_mosquitto_service` | String | `mosquitto` | Systemd service unit name. |
| `app_mosquitto_start_service` | Boolean | `true` | Start and enable service (set to `false` in unprivileged container/test environments). |
| `app_mosquitto_config_dir` | String | `/etc/mosquitto` | Base configuration directory. |
| `app_mosquitto_data_dir` | String | `/srv/mosquitto` | Persistence and data storage directory. |
| `app_mosquitto_port` | Integer | `1883` | MQTT listener port. |
| `app_mosquitto_bind_address` | String | `0.0.0.0` | IP address for MQTT listener to bind. |
| `app_mosquitto_allow_anonymous` | Boolean | `false` | Allow anonymous client connections without authentication. |
| `app_mosquitto_persistence` | Boolean | `true` | Enable persistent storage for retained messages and subscriptions. |
| `app_mosquitto_users` | List[Dict] | `[]` | List of user dictionaries (`username`, `password`) provisioned in `passwd` file via `mosquitto_passwd`. |

### Example User Provisioning

```yaml
app_mosquitto_users:
  - username: homeassistant
    password: "{{ vault_mosquitto_hass_password }}"
  - username: zigbee2mqtt
    password: "{{ vault_mosquitto_z2m_password }}"
```

## Dependencies

None.

## Example Playbook

```yaml
---
- hosts: servers
  become: true
  roles:
    - role: app
      vars:
        app_mosquitto: true
        app_mosquitto_port: 1883
        app_mosquitto_allow_anonymous: false
        app_mosquitto_users:
          - username: sensor_node
            password: "supersecretpassword"
```

## License

MIT

## Author Information

Anthonius (@Olympus)

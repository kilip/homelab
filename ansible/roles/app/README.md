# Ansible Role: `app`

Deploy and manage host application services and utilities (e.g., Mosquitto MQTT broker) across Olympus homelab nodes.

## Requirements

- Ansible 2.16 or higher.
- Elevated privileges (`become: true`) on target nodes.

## Supported Platforms

- Ubuntu (all supported releases)
- Debian (`trixie`)
- ArchLinux / CachyOS

## Role Variables

Variables available in `defaults/main.yml`:

| Variable | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `app_mosquitto` | Boolean | `false` | Enable Mosquitto Docker container deployment. When `false`, executes uninstall block (stops container and purges persistent storage). |
| `app_mosquitto_container_name` | String | `mosquitto` | Name of the Mosquitto Docker container. |
| `app_mosquitto_image` | String | `eclipse-mosquitto:2` | Docker container image for Mosquitto. |
| `app_mosquitto_start_service` | Boolean | `true` | Start container (set to `false` in unprivileged container/test environments). |
| `app_mosquitto_dir` | String | `/srv/mosquitto` | Base persistent storage directory on host. |
| `app_mosquitto_config_dir` | String | `{{ app_mosquitto_dir }}/config` | Configuration directory on host. |
| `app_mosquitto_data_dir` | String | `{{ app_mosquitto_dir }}/data` | Persistence and data storage directory on host. |
| `app_mosquitto_log_dir` | String | `{{ app_mosquitto_dir }}/log` | Log storage directory on host. |
| `app_mosquitto_port` | Integer | `1883` | Host MQTT listener port mapped to container. |
| `app_mosquitto_container_port` | Integer | `1883` | Internal MQTT listener port inside container. |
| `app_mosquitto_bind_address` | String | `0.0.0.0` | Host IP address for MQTT listener to bind. |
| `app_mosquitto_allow_anonymous` | Boolean | `false` | Allow anonymous client connections without authentication. |
| `app_mosquitto_persistence` | Boolean | `true` | Enable persistent storage for retained messages and subscriptions. |
| `app_mosquitto_users` | List[Dict] | `[]` | List of user dictionaries (`username`, `password`) provisioned in `passwd` file via PBKDF2-SHA512 hashing. |
| `app_mosquitto_uid` | String | `1883` | Numeric UID of mosquitto container user for directory ownership. |
| `app_mosquitto_gid` | String | `1883` | Numeric GID of mosquitto container user for directory ownership. |

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

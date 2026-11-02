# Ansible Role: `zeus`

Customization, package provisioning, environment setup, and hardware display daemon for the **Zeus** workstation (`CachyOS` / `Archlinux`).

## Table of Contents

- [Requirements](#requirements)
- [Supported Platforms](#supported-platforms)
- [Role Variables](#role-variables)
  - [General Variables](#general-variables)
  - [Chezmoi Dotfiles Management (`zeus_chezmoi`)](#chezmoi-dotfiles-management-zeus_chezmoi)
  - [DeepCool Digital Display (`zeus_deepcool`)](#deepcool-digital-display-zeus_deepcool)
- [Hardware Integration](#hardware-integration)
- [Example Playbook](#example-playbook)
- [License](#license)
- [Author Information](#author-information)

## Requirements

- Ansible 2.16 or higher.
- Elevated privileges (`become: true`) on target node.
- Target host must run an Arch Linux derivative (such as CachyOS).

## Supported Platforms

- CachyOS / Arch Linux (`os_family: Archlinux`)

## Role Variables

Defined in `defaults/main.yml`:

### General Variables

| Variable | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `zeus_enabled` | Boolean | `true` | Master toggle to enable or disable execution of the role. |
| `zeus_user` | String | `{{ ansible_user }}` | Primary workstation user account. |
| `zeus_packages` | List[String] | `[]` | List of packages to install via `pacman`. |

### Chezmoi Dotfiles Management (`zeus_chezmoi`)

Manages user dotfiles initialization using [chezmoi](https://www.chezmoi.io/).

| Variable | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `zeus_chezmoi_enabled` | Boolean | `true` | Enable chezmoi package installation and initialization. |
| `zeus_chezmoi_repo` | String | `git@github.com:kilip/dotfiles.git` | Git repository URL to clone dotfiles from. |
| `zeus_chezmoi_init` | Boolean | `true` | Run `chezmoi init` for `zeus_user` if `~/.local/share/chezmoi` is missing. Set to `false` in testing environments without git/SSH credentials. |

### DeepCool Digital Display (`zeus_deepcool`)

Integrates [Nortank12/deepcool-digital-linux](https://github.com/Nortank12/deepcool-digital-linux) to drive the real-time temperature and CPU utilization status screen on DeepCool AK400/AK500/AK620 Digital coolers (USB ID `3633:0001`).

| Variable | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `zeus_deepcool_enabled` | Boolean | `true` | Enable DeepCool Digital display service and udev rules. Set to `false` to stop service and remove deployed files. |
| `zeus_deepcool_start_service` | Boolean | `true` | Enable and start `deepcool-digital.service` unit and trigger udev reloads. Set to `false` in unprivileged container test environments (e.g. Molecule). |
| `zeus_deepcool_version` | String | `v0.11.0-alpha` | Release tag for `deepcool-digital-linux` binary. |
| `zeus_deepcool_binary_url` | String | See `defaults/main.yml` | Download URL for the standalone release binary. |
| `zeus_deepcool_install_dir` | String | `/usr/local/bin` | Path where the executable binary is placed. |
| `zeus_deepcool_extra_args` | String | `""` | Optional command-line flags (e.g., `--update 1000`, `--fahrenheit`, `--mode`). |

## Hardware Integration

When `zeus_deepcool_enabled: true`:
- Deploys `/etc/udev/rules.d/99-deepcool-digital.rules` to allow userspace HID raw device access to `3633:0001` and Intel RAPL power stats.
- Downloads the standalone `deepcool-digital-linux` binary to `{{ zeus_deepcool_install_dir }}`.
- Deploys and manages the systemd service `/etc/systemd/system/deepcool-digital.service`.

When `zeus_deepcool_enabled: false`:
- Stops and disables `deepcool-digital.service`.
- Cleans up the systemd unit file, binary, and udev rules.

## Example Playbook

```yaml
---
- name: Configure Zeus workstation
  hosts: workstations
  become: true
  roles:
    - role: zeus
      vars:
        zeus_packages:
          - fastfetch
          - alacritty
        zeus_deepcool_enabled: true
        zeus_deepcool_extra_args: "--update 1000"
```

## License

MIT

## Author Information

Anthonius (@Olympus)

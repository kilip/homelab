# Olympus

This repository contains infrastructure-as-code (IaC) for homelab management using **Ansible**. This configuration covers service deployment automation, network management, and a secure tunneling system.

## 🏗️ Architecture & Technology

- **Ansible**: Primary configuration management and deployment tool.
- **Kubernetes**: Container orchestration engine for managing and scaling homelab applications and workloads.
- **Flux CD**: GitOps tool for continuous delivery and automatic Kubernetes cluster state reconciliation.
- **SOPS + Age**: Encrypted secrets management directly within the repository.
- **Cloudflare Tunnel**: Secure public access without opening router ports (Local Management).
- **just**: Command runner for orchestrating development and deployment tasks.
- **mise**: Polyglot tool version manager and environment control (replacing asdf).

## 🖥️ Hardware Infrastructure

- **⚡ Zeus** — Main Workstation & Compute Node ([Details](docs/nodes/zeus.md))
  - 🔲 **CPU**: Intel Core i5-12400 (6C/12T)
  - 🎮 **GPU**: NVIDIA GeForce GTX 1650 (4 GB)
  - 🧠 **RAM**: 32 GB DDR4
  - 💽 **Disk**: 500 GB NVMe SSD
  - 🐧 **OS**: CachyOS Linux
- **🏛️ Hera** — Primary Homelab Server (NUC) ([Details](docs/nodes/hera.md))
  - 💻 **Model**: Intel NUC 6CAYH
  - 🔲 **CPU**: Intel Celeron J3455 (4C/4T)
  - 🧠 **RAM**: 8 GB DDR3
  - 💽 **Disk**: 256 GB SSD
  - 🐧 **OS**: Ubuntu Server 26.04 LTS
- **🕊️ Eros** — Auxiliary / Lightweight Node ([Details](docs/nodes/eros.md))
  - 🍓 **Model**: Raspberry Pi 3 Model B+
  - 🔲 **CPU**: Broadcom BCM2837B0 (4C/4T @ 1.4 GHz)
  - 🧠 **RAM**: 1 GB LPDDR2
  - 💽 **Disk**: 64 GB MicroSD
  - 🐧 **OS**: Debian GNU/Linux 12 (bookworm) arm64
- **🛡️ Ares** — Network Gateway & Router ([Details](docs/nodes/ares.md))
  - 🌐 **Model**: MikroTik RouterBOARD RB2011iL
  - 🔲 **CPU**: Qualcomm Atheros AR9344 (600 MHz)
  - 🧠 **RAM**: 64 MB
  - ⚙️ **OS**: RouterOS v7
- **🌍 Gaia** — Controlled Access Point & Switch ([Details](docs/nodes/gaia.md))
  - 🌐 **Model**: MikroTik RouterBOARD RB951Ui-2HnD
  - 🔲 **CPU**: Qualcomm Atheros AR9344 (600 MHz)
  - 🧠 **RAM**: 128 MB
  - 📶 **Wi-Fi**: 2.4 GHz 802.11b/g/n (CAPsMAN)
  - ⚙️ **OS**: RouterOS v7
- **🌙 Leto** — Controlled Access Point & Switch ([Details](docs/nodes/leto.md))
  - 🌐 **Model**: MikroTik RouterBOARD RB941-2nD (hAP lite)
  - 🔲 **CPU**: Qualcomm Atheros QCA9531 (650 MHz)
  - 🧠 **RAM**: 32 MB
  - 📶 **Wi-Fi**: 2.4 GHz 802.11b/g/n (CAPsMAN)
  - ⚙️ **OS**: RouterOS v6

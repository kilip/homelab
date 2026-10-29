# Olympus

This repository contains infrastructure-as-code (IaC) for homelab management using **Ansible**. This configuration covers service deployment automation, network management, and a secure tunneling system.

## 🏗️ Architecture & Technology

Olympus leverages an automated Infrastructure-as-Code (IaC) and GitOps pipeline designed for minimal node footprint, declarative configuration, zero-trust security, and reproducibility.

- **Configuration Management**: **Ansible** for multi-OS node provisioning (`Ubuntu`, `Debian`, `Archlinux`/`CachyOS`) and initial host hardening.
- **Orchestration**: **K3s** (Kubernetes) lightweight container orchestration engine running on homelab server nodes.
- **GitOps Delivery**: **Flux CD** (v2) managing declarative continuous deployment, dependency graphs, and automatic state reconciliation.
- **Networking & Ingress**:
  - **MetalLB**: Layer 2 bare-metal load balancer providing internal cluster IP allocation.
  - **Traefik**: Edge ingress controller managing HTTP/HTTPS routing, secure middlewares, and TLS termination via **Cert-Manager** with Cloudflare DNS-01 validation.
  - **Cloudflare Tunnel & ExternalDNS**: Secure zero-trust public edge ingress and automated DNS record management without opening public firewall ports.
- **Database & Storage**:
  - **CloudNative-PG**: Declarative Kubernetes operator for high-availability PostgreSQL with automated failover and backups.
  - **ParadeDB**: Elasticsearch-alternative search engine built directly on PostgreSQL with BM25 indexing.
  - **Local Path Provisioner**: Lightweight host-based persistent volume management.
- **Observability & Logging**:
  - **New Relic**: SaaS-based observability collecting node metrics (`newrelic-infrastructure`), cluster state (`kube-state-metrics`), custom Prometheus endpoints (`nri-prometheus`), and real-time container logs (`newrelic-logging` via Fluent Bit) with an ultra-low cluster footprint (~185 MiB RAM).
- **Secrets Management**: **SOPS + Age** for end-to-end repository encryption, transparently decrypted at runtime by Ansible and Flux CD.
- **Developer Toolchain**:
  - **`just`**: Modular task runner (`.just/`) orchestrating cluster diagnostics, linting, and GitOps workflows.
  - **`mise`**: Polyglot runtime version manager ensuring pinned, deterministic CLI environments.
  - **`uv`**: Fast Python virtual environment and package manager.

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

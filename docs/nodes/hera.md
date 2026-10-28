# Hera (`hera`)

Technical specifications and network profile for node **Hera** in the Olympus homelab infrastructure.

---

## 1. Node Overview

| Property | Value |
| :--- | :--- |
| **Hostname** | `hera` |
| **Role** | Core Homelab Server, Container Host & Primary Database Node |
| **Chassis** | Intel NUC Mini PC (UCFF) |
| **Primary OS** | Ubuntu 26.04.1 LTS (Resolute Raccoon) x86_64 |
| **Kernel** | `7.0.0-38-generic` (PREEMPT_DYNAMIC) |

---

## 2. Hardware Specifications

### Processor (CPU)
- **Model**: Intel Celeron J3455 (Apollo Lake)
- **Cores / Threads**: 4 Cores / 4 Threads
- **Base / Boost Clock**: 1.50 GHz / 2.30 GHz
- **TDP**: 10 W
- **Cache**:
  - L1 Data: 96 KiB (4 x 24 KiB)
  - L1 Instruction: 128 KiB (4 x 32 KiB)
  - L2: 2 MiB (2 x 1 MiB)
- **Virtualization Support**: Intel VT-x (VMX enabled)

### Motherboard & Firmware
- **Model**: Intel NUC6CAYB (System: NUC6CAYH)
- **Form Factor**: Ultra-Compact Form Factor (UCFF 4"x4")
- **BIOS / Firmware Version**: `AYAPLCEL.86A.0052.2018.0627.1943` (Release Date: 2018-06-27)
- **Vendor**: Intel Corporation

### Memory (RAM)
- **Total Capacity**: 8 GiB (Configured as 2 x 4 GiB SODIMM)
- **Type**: DDR3 Synchronous SDRAM
- **Configured Speed**: 1600 MT/s @ 1.5V
- **Module Details**:
  - Channel A (DIMM 0): Samsung `M471B5173QH0-YK0` (4 GiB)
  - Channel B (DIMM 0): V-GeN `D3V4GS16B8R` (4 GiB)
- **Swap**: 4.0 GiB swap partition

### Graphics (GPU)
- **Integrated GPU**: Intel Apollo Lake GT1 [HD Graphics 500]
- **PCI Bus ID**: `0000:00:02.0`
- **Kernel Driver**: `i915`

### Storage
- **Primary Drive**: Samsung SSD 850 PRO 256GB
  - **Interface**: SATA 3.1 6.0 Gb/s
  - **Firmware**: `EXM02B6Q`
  - **Capacity**: 256 GB (238.5 GiB usable)
- **Partition Scheme & Mounts**:
  | Device | File System | Size | Mount Point | Description |
  | :--- | :--- | :--- | :--- | :--- |
  | `/dev/sda1` | vfat (FAT32) | 1.0 GiB | `/boot/efi` | UEFI ESP (EFI System Partition) |
  | `/dev/sda2` | ext4 | 2.0 GiB | `/boot` | Linux kernel & initramfs boot images |
  | `/dev/sda3` | LVM2 (PV) | 235.4 GiB | - | LVM physical volume for root volume group |
  | `/dev/mapper/ubuntu--vg-ubuntu--lv` | ext4 | 235.4 GiB | `/` | Primary root filesystem (LVM LV) |

---

## 3. Network Interfaces

| Interface | Device / Chipset | Type | Description |
| :--- | :--- | :--- | :--- |
| `enp3s0` | Realtek RTL8111/8168/8211/8411 Gigabit Ethernet | Physical (RJ45) | Primary wired LAN connection |
| `wlp2s0` | Intel Dual Band Wireless-AC 3168NGW [Stone Peak] | Physical (M.2) | Secondary WiFi connection |
| `ztdiyrelhn` | ZeroTier One Virtual NIC | Overlay VPN | Mesh overlay VPN (`olympus`) |
| `tailscale0` | Tailscale Virtual TUN | Overlay VPN | Point-to-point mesh VPN adapter |
| `docker0` | Docker Bridge | Virtual Bridge | Container runtime default bridge |

### ZeroTier Integration
- **Network Name**: `olympus`
- **Client Version**: `1.16.2`

---

## 4. Software Environment & Homelab Services

### Operating System & Shell
- **Distribution**: Ubuntu 26.04.1 LTS (Resolute Raccoon)
- **Default Shell**: Zsh `5.9` (Oh My Zsh)

### Container Runtime
- **Docker CE Engine**: `29.9.2`
  - **containerd**: `v2.4.2`
  - **runc**: `1.5.2`

### Active Homelab Stack (Docker Containers)
- **Reverse Proxy & Edge Ingress**:
  - `traefik` (`v3.7.14`) — Edge routing, SSL termination, dynamic reverse proxy
  - `tunnel` / `pkrbt-tunnel` (`cloudflare/cloudflared:2026.10.0`) — Secure ingress via Cloudflare Tunnels
- **Smart Home & Automation**:
  - `hass` (`linuxserver/homeassistant:2026.10.0`) — Home automation hub
  - `mosquitto` — MQTT broker for IoT sensor data
- **Databases & In-Memory Store**:
  - `postgres` (`postgis/postgis:18-3.6-alpine`) — Relational database with PostGIS spatial support
  - `mysql` (`mysql:8.4.9`) — Relational database
  - `redis` (`redis:8.10.2-alpine`) — In-memory caching and session broker
- **Storage, Streaming & Backups**:
  - `minio` (`RELEASE.2025-09-07T16-13-09Z`) — S3-compatible distributed object storage
  - `rustfs` (`1.0.1`) — High-performance distributed file storage
  - `kafka` (`apache/kafka:4.3.1`) — Event streaming and message queuing
  - `duplicati` — Automated offsite backup service
- **Monitoring & Management**:
  - `portainer` (`portainer/portainer-ee:2.45.2`) — Web management UI for Docker
  - `librenms` (`26.4.1`) — Network management & SNMP monitoring
  - `newrelic-infra` — Infrastructure monitoring agent
  - `squid` — HTTP caching web proxy

### AI & Local Models
- **Runtime**: Ollama `0.21.0`
- **Models**: `qwen2.5:1.5b`

---

## 5. Connected USB & Peripheral Hardware

- **Bluetooth**: Intel Corp. Wireless-AC 3168 Bluetooth — `8087:0aa7`
- **USB Controller**: Intel Apollo Lake xHCI Host Controller

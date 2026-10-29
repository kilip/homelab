# Eros (`eros`)

Technical specifications and network profile for node **Eros** in the Olympus homelab infrastructure.

---

## 1. Node Overview

| Property | Value |
| :--- | :--- |
| **Hostname** | `eros` |
| **Role** | Auxiliary Edge Server, Local DNS Resolver & Network Boot Node |
| **Chassis** | Raspberry Pi 3 Model B Plus Rev 1.3 (Single Board Computer) |
| **Primary OS** | Debian GNU/Linux 13 (trixie) / Raspberry Pi OS 64-bit |
| **Kernel** | `6.12.34+rpt-rpi-v8` (aarch64) |

---

## 2. Hardware Specifications

### Processor (CPU / SoC)
- **SoC**: Broadcom BCM2837B0
- **CPU**: Quad-core ARM Cortex-A53 (ARMv8-A 64-bit)
- **Cores / Threads**: 4 Cores / 4 Threads
- **Base / Max Clock**: 600 MHz / 1400 MHz (1.4 GHz)
- **Architecture**: `aarch64`
- **Cache**:
  - L1 Data: 128 KiB (4 x 32 KiB)
  - L1 Instruction: 128 KiB (4 x 32 KiB)
  - L2: 512 KiB shared

### Memory (RAM)
- **Total Capacity**: 1 GiB LPDDR2 SDRAM (906 MiB addressable)
- **Swap**: 200 MiB configured swap space

### Graphics (GPU)
- **Integrated GPU**: Broadcom VideoCore IV @ 400 MHz / 300 MHz

### Storage
- **Primary Drive**: 64 GB MicroSD Card (SanDisk / High-Endurance Class 10 / UHS-I)
- **Partition Scheme & Mounts**:
  | Device | File System | Size | Mount Point | Description |
  | :--- | :--- | :--- | :--- | :--- |
  | `/dev/mmcblk0p1` | vfat (FAT32) | 512 MiB | `/boot/firmware` | Raspberry Pi boot firmware & kernel blobs |
  | `/dev/mmcblk0p2` | ext4 | 59.0 GiB | `/` | Primary root filesystem |

---

## 3. Network Interfaces

| Interface | Device / Chipset | Type | Description |
| :--- | :--- | :--- | :--- |
| `enxb827eb...` | Microchip LAN7515 (Gigabit over USB 2.0, ~300 Mbps) | Physical (RJ45) | Primary wired LAN connection |
| `wlan0` | Cypress CYW43455 (2.4 GHz / 5 GHz 802.11ac Wi-Fi) | Physical (Wireless) | Integrated dual-band wireless (disabled / standby) |
| `ztdiyrelhn` | ZeroTier One Virtual NIC | Overlay VPN | Mesh overlay VPN (`olympus`) |
| `docker0` | Docker Bridge | Virtual Bridge | Container runtime default bridge |

### ZeroTier Integration
- **Network Name**: `olympus`
- **Client Version**: `1.16.1`

---

## 4. Software Environment & Homelab Services

### Operating System & Shell
- **Distribution**: Debian GNU/Linux 13 (trixie) / Raspberry Pi OS arm64
- **Default Shell**: Fish `3.6.0+`

### Container Runtime
- **Docker CE Engine**: `29.4.0`
  - **containerd**: `v2.2.3`
  - **runc**: `1.3.5`

### Active Homelab Stack (Docker Containers)
- **DNS & Ad-Blocking**:
  - `pihole` (`pihole/pihole:2025.07.1`) — Primary / redundant homelab DNS resolver and network-wide ad blocker
  - `dockerdns` (`ghcr.io/kilip/docker-dns:v1.0.0`) — Internal container name resolution service
- **Network Boot Services**:
  - `netbootxyz` (`netbootxyz/netbootxyz:latest`) — iPXE / TFTP / HTTP network boot server for automated node provisioning
- **Infrastructure Management & Monitoring**:
  - `portainer_agent` (`portainer/agent:2.31.3`) — Edge agent for Portainer cluster management
  - `prometheus-node-exporter` (Systemd) — System metrics exporter for homelab Prometheus

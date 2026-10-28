# Zeus (`zeus`)

Technical specifications and network profile for node **Zeus** in the Olympus homelab infrastructure.

---

## 1. Node Overview

| Property | Value |
| :--- | :--- |
| **Hostname** | `zeus` |
| **Role** | Main Workstation, Compute Node & IaC Control Plane |
| **Chassis** | Desktop Tower |
| **Primary OS** | CachyOS Linux x86_64 (Arch Linux derivative) |
| **Kernel** | `7.3.0-4-cachyos` (PREEMPT_DYNAMIC) |

---

## 2. Hardware Specifications

### Processor (CPU)
- **Model**: Intel Core i5-12400 (12th Gen Alder Lake-S)
- **Cores / Threads**: 6 Cores (6P / 0E) / 12 Threads
- **Base / Boost Clock**: 2.50 GHz / 4.40 GHz
- **Cache**:
  - L1 Data: 288 KiB (6 x 48 KiB)
  - L1 Instruction: 192 KiB (6 x 32 KiB)
  - L2: 7.5 MiB (6 x 1.25 MiB)
  - L3: 18 MiB (shared)
- **Virtualization Support**: Intel VT-x (VMX enabled)
- **CPU Cooler**: DeepCool AK400 DIGITAL (integrated temperature/usage display)

### Motherboard & Firmware
- **Model**: ASUS TUF GAMING B760M-E D4
- **Form Factor**: Micro-ATX
- **Chipset**: Intel B760 Express
- **BIOS / Firmware Version**: `0401` (Release Date: 2023-02-16)
- **Vendor**: American Megatrends Inc. (AMI) / ASUSTeK COMPUTER INC.

### Memory (RAM)
- **Total Capacity**: 32 GiB (Configured as 4 x 8 GiB DIMMs)
- **Type**: DDR4 Synchronous SDRAM
- **Configured Speed**: 3200 MT/s @ 1.20V
- **Manufacturer**: Kingston (Kingston FURY Beast)
- **Part Number**: `KF3200C16D4/8GX` (4 matching modules in Channels A/B)
- **Swap / ZRAM**: 31.08 GiB compressed RAM swap (`/dev/zram0`)

### Graphics (GPU)
- **Discrete GPU**: NVIDIA GeForce GTX 1650
- **Architecture**: TU116 (Turing)
- **VRAM**: 4096 MiB (4 GiB) GDDR6
- **PCI Bus ID**: `0000:01:00.0`
- **NVIDIA Driver**: `615.78.08` (Proprietary)
- **CUDA Runtime / Version**: 13.4
- **Display Setup**: Triple monitor setup (3x LG Full HD 1920x1080 @ 60 Hz)

### Storage
- **Primary Drive**: Samsung SSD 980 500GB (`MZ-V8V500BW`)
  - **Interface**: M.2 PCIe Gen 3.0 x4 / NVMe 1.4
  - **Firmware**: `2B4QFXO7`
  - **Capacity**: 500.1 GB
- **Partition Scheme & Mounts**:
  | Device | File System | Size | Mount Point | Description |
  | :--- | :--- | :--- | :--- | :--- |
  | `/dev/nvme0n1p1` | vfat (FAT32) | 2.0 GiB | `/boot` | UEFI ESP (EFI System Partition) |
  | `/dev/nvme0n1p2` | Btrfs | 463.8 GiB | `/` | Root filesystem (subvolume `@`) |
  | `/dev/nvme0n1p2` | Btrfs | - | `/home` | Subvolume `@home` |
  | `/dev/nvme0n1p2` | Btrfs | - | `/root` | Subvolume `@root` |
  | `/dev/nvme0n1p2` | Btrfs | - | `/srv` | Subvolume `@srv` |
  | `/dev/nvme0n1p2` | Btrfs | - | `/var/cache` | Subvolume `@cache` |
  | `/dev/nvme0n1p2` | Btrfs | - | `/var/tmp` | Subvolume `@tmp` |
  | `/dev/nvme0n1p2` | Btrfs | - | `/var/log` | Subvolume `@log` |

---

## 3. Network Interfaces

| Interface | Device / Chipset | Type | Description |
| :--- | :--- | :--- | :--- |
| `eno1` (alt: `enp3s0`) | Realtek RTL8125 2.5GbE | Physical (RJ45) | Primary wired LAN connection |
| `wlan0` | Realtek RTL8188GU 802.11n | USB Wireless | Secondary WiFi interface |
| `ztdiyrelhn` | ZeroTier One Virtual NIC | Overlay VPN | Mesh overlay VPN (`olympus`) |
| `docker0` | Docker Bridge | Virtual Bridge | Container runtime default bridge |

### ZeroTier Integration
- **Network Name**: `olympus`
- **Client Version**: `1.16.2`

---

## 4. Software Environment & Homelab Tooling

### Operating System & Window Manager
- **Distribution**: CachyOS (Rolling release, performance-optimized Arch derivative)
- **Window Manager**: Hyprland `0.56.2` (Wayland)
- **Display Server**: Wayland with Xwayland support
- **Default Shell**: Bash `5.3.20`

### Container Runtime
- **Docker CE Engine**: `29.9.2`
  - **containerd**: `v2.4.2`
  - **runc**: `1.5.2`

### Infrastructure & Management CLI Stack (`mise` managed)
- **IaC & Secrets**:
  - `sops` (`3.13.3`) & `age` (`1.3.2`)
  - `ansible`
  - `just` task runner
- **Kubernetes & GitOps**:
  - `kubectl` (`1.37.1`)
  - `kustomize` (`5.8.3`)
  - `flux2` (`2.9.6`)
  - `helm` (`4.3.1`) & `helmfile` (`1.8.2`)
  - `kubeconform` (`0.8.0`)
- **Networking & Access**:
  - `cloudflared` (`2026.10.3`) for Cloudflare Tunnels
- **Developer Utilities**:
  - `uv` (`0.13.5`), `node` (`24.22.1`), `gh` (`2.103.2`), `yq` (`4.54.1`), `jq` (`1.8.2`), `gum` (`2.0.2`), `lefthook` (`2.2.2`), `zizmor` (`1.31.1`), `topf` (`0.6.2`)

---

## 5. Connected USB & Peripheral Hardware

- **Keyboard**: JosefAdamcik Sofle (Split ergonomic mechanical keyboard) — `fc32:0287`
- **Mouse**: Speedy Industrial Supplies USB Gaming Mouse — `1017:900a`
- **Display Cooler**: DeepCool AK400-DIGITAL USB controller — `3633:0001`
- **Lighting**: ASUSTek Computer, Inc. AURA LED Controller — `0b05:19af`
- **USB Expansion**: ASMedia ASM1074 USB 3.0 SuperSpeed & High-Speed Hubs

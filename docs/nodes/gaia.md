# Gaia (`gaia`)

Technical specifications, switching architecture, and wireless configuration for node **Gaia** (formerly `Hades`) in the Olympus homelab infrastructure.

---

## 1. Node Overview

| Property | Value |
| :--- | :--- |
| **Hostname / Identity** | `Gaia` |
| **Role** | Controlled Access Point (CAP) & 5-Port Fast Ethernet Switch |
| **Chassis** | Desktop Plastic Router Enclosure |
| **Platform** | MikroTik RouterBOARD |
| **Architecture** | `mipsbe` |
| **Primary OS** | MikroTik RouterOS v7.22.1 (stable) |
| **RouterBOOT Firmware** | `7.12.1` |
| **License Level** | Level 4 (`L4`) |

---

## 2. Hardware Specifications

### Processor (CPU)
- **Model**: Qualcomm Atheros AR9344 (MIPS 74Kc V4.12)
- **Cores / Threads**: 1 Core / 1 Thread
- **Clock Speed**: 600 MHz
- **Instruction Set**: MIPS32 Release 2

### Board & Platform
- **Model**: MikroTik RB951Ui-2HnD
- **Architecture**: `mipsbe`
- **Firmware Type**: `ar9344`

### Memory & Storage
- **System Memory (RAM)**: 128.0 MiB DDR SDRAM
- **Storage**: 128.0 MiB Onboard NAND Flash Storage

### Power & PoE
- **PoE In**: Passive PoE supported on `ether1` (8V – 30V DC)
- **PoE Out**: Passive PoE supported on `ether5` (same voltage as unit input, max current 500 mA)

---

## 3. Switching Architecture & Physical Interfaces

### Switch Chip & Hardware Offloading
- **Switch Chip**: Qualcomm Atheros AR8227
- **Bridge**: Single hardware-offloaded bridge combining all 5 physical Fast Ethernet ports with Rapid Spanning Tree Protocol (RSTP).

### Port Mapping

| Port | Switch Chip | Speed | Mode / Role | Description |
| :--- | :--- | :--- | :--- | :--- |
| `ether1` | Atheros AR8227 | 100 Mbps | Bridge Member | Uplink trunk to core router (**Ares**) with PoE In support |
| `ether2` | Atheros AR8227 | 100 Mbps | Bridge Member | Fast Ethernet LAN port |
| `ether3` | Atheros AR8227 | 100 Mbps | Bridge Member | Active Fast Ethernet LAN link |
| `ether4` | Atheros AR8227 | 100 Mbps | Bridge Member | Fast Ethernet LAN port |
| `ether5` | Atheros AR8227 | 100 Mbps | Bridge Member | Fast Ethernet LAN port with Passive PoE Out support |

---

## 4. Wireless Architecture & CAPsMAN Operation

Gaia operates as a **Controlled Access Point (CAP)**, fully managed by the centralized CAPsMAN controller hosted on core router [Ares](ares.md).

### Radio Specifications
- **Integrated Wireless Chip**: Qualcomm Atheros AR9300 / AR9344 integrated radio
- **Frequency Band**: 2.4 GHz (802.11b/g/n)
- **Channel Width**: 20 MHz
- **Antenna Design**: Integrated 2x2 MIMO PIF antennas (maximum gain: 2.5 dBi)
- **Transmit Power**: Up to 30 dBm (1000 mW)

### CAPsMAN Forwarding & Virtual APs
- **Control Interface**: CAP managed over the local management bridge by CAPsMAN.
- **Forwarding Mode**: `CAPsMAN forwarding` (wireless frames are encapsulated and forwarded directly to the core router controller for centralized traffic isolation and VLAN processing).
- **Broadcast Profiles**:
  - **Primary LAN Wi-Fi**: Dual-provisioned network for primary client connectivity.
  - **IoT & Smart Home Network**: Dedicated segregated 2.4 GHz network provisioned for IoT devices and smart home appliances.

---

## 5. Network Services & Management

### Management Services
- **WinBox**: Port `8291` (native MikroTik administration GUI)
- **SSH**: Port `22` (remote shell access)
- **WebFig (HTTP)**: Port `80` (RouterOS web configuration)
- **Telnet**: Port `23`
- **RouterOS API**: Port `8728` (plain API for automation)
- **SNMP**: Port `161/udp` (LibreNMS monitoring integration)

# Ares (`ares`)

Technical specifications, routing architecture, and network profile for node **Ares** in the Olympus homelab infrastructure.

---

## 1. Node Overview

| Property | Value |
| :--- | :--- |
| **Hostname** | `Ares` |
| **Role** | Core Network Gateway, Router & CAPsMAN Wireless Controller |
| **Chassis** | 1U Desktop / Rackmount Router Chassis |
| **Platform** | MikroTik RouterBOARD |
| **Architecture** | `mipsbe` |
| **Primary OS** | MikroTik RouterOS v7.25 |
| **License Level** | Level 4 (`L4`) |

---

## 2. Hardware Specifications

### Processor (CPU)
- **Model**: Qualcomm Atheros AR9344 (MIPS 74Kc V4.12)
- **Cores / Threads**: 1 Core / 1 Thread
- **Clock Speed**: 600 MHz
- **Instruction Set**: MIPS32 Release 2

### Board & Firmware
- **Model**: MikroTik RB2011iL
- **RouterBOOT Firmware Version**: `6.49.7` (Upgrade target available: `7.25`)
- **Firmware Type**: `ar9344`

### Memory & Storage
- **System Memory (RAM)**: 64.0 MiB DDR SDRAM
- **Storage**: 128.0 MiB Onboard NAND Flash Storage

### Switching Architecture
- **Switch 1 (Gigabit)**: Qualcomm Atheros AR8327 (Handles 5x 10/100/1000 Mbps ports with hardware switching and offload)
- **Switch 2 (Fast Ethernet)**: Qualcomm Atheros AR8227 (Handles 5x 10/100 Mbps ports with hardware switching)
- **Power over Ethernet (PoE)**:
  - **PoE In**: Passive PoE supported on `ether1` (8V - 28V DC)
  - **PoE Out**: Passive PoE supported on `ether10` (up to 500 mA output)

---

## 3. Network Architecture & Interfaces

### Physical Ethernet Ports

| Port | Switch Chip | Speed | Mode / Role | Description |
| :--- | :--- | :--- | :--- | :--- |
| `ether1` | Atheros AR8327 | 1 Gbps | Bridge Member (`br-local`) | Uplink / LAN trunk port with PoE In support |
| `ether2` | Atheros AR8327 | 1 Gbps | Bridge Member (`br-local`) | Active Gigabit LAN link to node **Zeus** |
| `ether3` | Atheros AR8327 | 1 Gbps | Bridge Member (`br-local`) | Gigabit LAN link |
| `ether4` | Atheros AR8327 | 1 Gbps | Bridge Member (`br-local`) | Active Gigabit LAN link to node **Hera** |
| `ether5` | Atheros AR8327 | 1 Gbps | Bridge Member (`br-local`) | Gigabit LAN link |
| `ether6` | Atheros AR8227 | 100 Mbps | Bridge Member (`br-wan`) | Dedicated WAN uplink to upstream ISP ONT / Modem |
| `ether7` | Atheros AR8227 | 100 Mbps | Bridge Member (`br-local`) | Fast Ethernet LAN port |
| `ether8` | Atheros AR8227 | 100 Mbps | Bridge Member (`br-local`) | Active Fast Ethernet LAN link |
| `ether9` | Atheros AR8227 | 100 Mbps | Bridge Member (`br-local`) | Fast Ethernet LAN port |
| `ether10` | Atheros AR8227 | 100 Mbps | Bridge Member (`br-local`) | Fast Ethernet LAN port with PoE Out capability |

### Logical Bridges
- **`br-local`**: Primary internal LAN bridge combining all LAN switch ports and CAPsMAN virtual wireless interfaces. Protocol mode: RSTP (Rapid Spanning Tree Protocol) with hardware offload enabled.
- **`br-wan`**: Dedicated WAN bridge isolating ISP ingress traffic on `ether6` from the internal network segments.

---

## 4. Wireless Architecture & CAPsMAN Controller

Ares serves as the centralized **CAPsMAN (Controlled Access Point system Manager)** controller for the premises, orchestrating wireless configuration across remote dual-band access points.

### Wireless Profiles & Network Segmentation
- **Primary LAN Wi-Fi**: High-throughput wireless network for workstations and daily client devices.
- **IoT & Smart Home Network**: Dedicated segregated network for smart home appliances and sensors (hidden broadcast).
- **Guest Network**: Isolated guest segment preventing access to private homelab nodes.
- **Infrastructure / Auxiliary Wi-Fi**: Dedicated profile for internal infrastructure components (hidden broadcast).

---

## 5. Network Services & Security Policies

### Routing & Ingress / Egress
- **NAT**: Outbound masquerade dynamically applied on WAN bridge (`br-wan`).
- **DHCP Services**: Internal DHCP server managing client leases on `br-local`.
- **DNS Forwarding**: Local caching DNS resolver forwarding queries to upstream local DNS sinkhole on node `eros` with public fallback resolvers.

### Management Services
- **WinBox**: Port `8291` (native MikroTik GUI client)
- **SSH**: Port `22` (restricted key-based management)
- **WebFig (HTTP/HTTPS)**: Port `80` / `443` (web administration interface with SSL)
- **RouterOS API**: Port `8728` (plain) / `8443` (API-SSL) for automation scripts and IaC integrations

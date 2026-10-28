# Leto (`leto`)

Technical specifications, switching architecture, and wireless configuration for node **Leto** (formerly `Venus`) in the Olympus homelab infrastructure.

---

## 1. Node Overview

| Property | Value |
| :--- | :--- |
| **Hostname / Identity** | `Leto` |
| **Role** | Controlled Access Point (CAP) & Fast Ethernet Switch |
| **Chassis** | Desktop Compact Plastic Enclosure |
| **Platform** | MikroTik RouterBOARD |
| **Architecture** | `smips` |
| **Primary OS** | MikroTik RouterOS v6.49.8 (stable) |
| **RouterBOOT Firmware** | `6.49.8` |
| **License Level** | Level 4 (`L4`) |

---

## 2. Hardware Specifications

### Processor (CPU)
- **Model**: Qualcomm Atheros QCA9531 (MIPS 24Kc V7.4)
- **Cores / Threads**: 1 Core / 1 Thread
- **Clock Speed**: 650 MHz
- **Instruction Set**: MIPS32 Release 2

### Board & Platform
- **Model**: MikroTik RB941-2nD (hAP lite r3)
- **Architecture**: `smips`
- **Firmware Type**: `qca9531L`

### Memory & Storage
- **System Memory (RAM)**: 32.0 MiB RAM
- **Storage**: 16.0 MiB SPI Flash Storage

### Power
- **Input**: 5V DC via MicroUSB power supply
- **PoE**: None (standard USB-powered hAP lite unit)

---

## 3. Switching Architecture & Physical Interfaces

### Switch Chip & Physical Ports
- **Switch Chip**: Qualcomm Atheros AR8227
- **Physical Ports**: 4x 10/100 Fast Ethernet (RJ45) ports

### Port Mapping

| Port | Switch Chip | Speed | Mode / Role | Description |
| :--- | :--- | :--- | :--- | :--- |
| `ether1` | Atheros AR8227 | 100 Mbps | Fast Ethernet | Standalone LAN port |
| `ether2` | Atheros AR8227 | 100 Mbps | Fast Ethernet | Standalone LAN port |
| `ether3` | Atheros AR8227 | 100 Mbps | Fast Ethernet | Standalone LAN port |
| `ether4` | Atheros AR8227 | 100 Mbps | Uplink / DHCP Client | Uplink link to homelab core switch / router (**Ares**) |

---

## 4. Wireless Architecture & CAPsMAN Operation

Leto operates as a **Controlled Access Point (CAP)**, centrally orchestrated by the CAPsMAN controller hosted on core router [Ares](ares.md).

### Radio Specifications
- **Integrated Wireless Chip**: Qualcomm Atheros AR9300 / QCA9531 integrated radio
- **Frequency Band**: 2.4 GHz (802.11b/g/n)
- **Channel Width**: 20 MHz
- **Antenna Design**: Integrated 2x2 MIMO omnidirectional antennas (maximum gain: 1.5 dBi)
- **Transmit Power**: Up to 22 dBm

### CAPsMAN Forwarding & Virtual APs
- **Forwarding Mode**: `CAPsMAN forwarding` (all layer-2 wireless frames are encapsulated and forwarded directly to the core router controller for centralized VLAN assignment and traffic filtering).
- **Discovery**: Dynamic discovery over the local uplink network interface.
- **Broadcast Profiles**:
  - **Primary LAN Wi-Fi**: Provisioned for primary end-user device connectivity.
  - **IoT & Smart Home Network**: Dedicated segregated virtual access point for IoT smart devices and peripheral hardware.

---

## 5. Network Services & Management

### Management Services
- **WinBox**: Port `8291` (native MikroTik administration GUI)
- **SSH**: Port `22` (remote shell access)
- **WebFig (HTTP)**: Port `80` (RouterOS web configuration)
- **Telnet**: Port `23`
- **RouterOS API**: Port `8728` (RouterOS API for automation)

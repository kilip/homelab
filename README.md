# Homelab IaC

Repositori ini berisi infrastruktur-as-code (IaC) untuk manajemen homelab menggunakan **Ansible**. Konfigurasi ini mencakup otomatisasi deployment layanan, manajemen jaringan, dan sistem tunnel yang aman.

## 🏗️ Arsitektur & Teknologi
- **Ansible**: Alat utama manajemen konfigurasi dan deployment.
- **Docker**: Containerization untuk hampir semua aplikasi.
- **SOPS + Age**: Manajemen file rahasia (secrets) secara terenkripsi di dalam repositori.
- **Cloudflare Tunnel**: Akses publik yang aman tanpa perlu buka port router (Manajemen Lokal).
- **Taskfile**: Orkestrasi perintah pengembangan dan deployment.

## 🔒 Manajemen Secrets (SOPS)
Semua variabel sensitif disimpan dalam file `.sops.yaml` yang dienkripsi menggunakan **Age**.
- Kunci publik tercatat di `.sops.yaml` root.
- Kunci privat (`age.key`) harus tersedia di lingkungan lokal agar Ansible dapat melakukan dekripsi saat runtime.

## 🌐 Cloudflare Tunnel (Managed Locally)
Tunnel dikelola sepenuhnya melalui repositori ini (**Local Management Mode**). Konfigurasi ingress didefinisikan di `inventory/group_vars/tunnel.sops.yaml`.

### Daftar Ingress Saat Ini:
| Public Hostname | Internal Service | Deskripsi |
| :--- | :--- | :--- |
| `home.itstoni.com` | `http://homarr:7575` | Homarr Dashboard |
| `hestia.itstoni.com` | `http://hass:8123` | Home Assistant |
| `sm.itstoni.com` | `http://semaphore:3000` | Ansible Semaphore |
| `zb.itstoni.com` | `http://zabbix-dashboard:8080` | Zabbix Monitoring |
| `lb.itstoni.com` | `http://librenms:8000` | LibreNMS |
| `pg.itstoni.com` | `tcp://postgres:5432` | Postgres Database (TCP) |

## 🚀 Cara Menjalankan

### Persiapan
1. Pastikan virtual environment aktif:
   ```bash
   source .venv/bin/activate
   ```
2. Pastikan `age.key` sudah terkonfigurasi untuk dekripsi SOPS.

### Deployment
Gunakan `task` untuk menjalankan playbook:
- **Deploy Semua**: `task play`
- **Deploy Berdasarkan Tag**: `task play tags=tunnel`
- **Cek Perubahan (Dry Run)**: `task check tags=tunnel`

## 📁 Struktur Folder
- `roles/core/`: Layanan dasar (Docker, Cloudflare Tunnel, Squid, Traefik).
- `roles/apps/`: Aplikasi spesifik (Home Assistant, Zabbix, Homarr, dll).
- `roles/storage/`: Database dan sistem penyimpanan (Postgres, MySQL, Redis, Minio).
- `inventory/group_vars/`: Variabel konfigurasi terenkripsi per grup layanan.

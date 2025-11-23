# ITS Secure Network Challenge - Kelompok 6

> **Implementasi Arsitektur Keamanan Berbasis Zona (Zone-Based Security) dengan Segmentasi Fisik & Manajemen Trafik Adaptif.**

Proyek ini mendemonstrasikan desain dan implementasi pertahanan jaringan untuk Departemen Teknologi Informasi ITS menggunakan filosofi **Zero Trust** dan **Physical Segmentation**.

## Anggota Tim (Kelompok 6)
1. **Angga Firmansyah** - 5027241062
2. **Ahmad Rafi Fadhillah Dwiputra** - 5027241068
3. **Fika Arka Nuriyah** - 5027241071
4. **Dimas Muhammad Putra** - 5027241076

---

## Arsitektur & Topologi

Sistem ini meninggalkan model jaringan datar (*flat network*) dan beralih ke topologi **Hub-and-Spoke** dengan isolasi perangkat keras.

### Komponen Utama
* **Core Security:** 1x MikroTik RouterOS (Firewall Pusat, QoS, Routing).
* **Zone Routers:** 4x MikroTik Router (Guest, Student, Admin, Academic) untuk isolasi *fault domain*.
* **Edge Router:** 1x MikroTik sebagai gerbang NAT ke Internet.
* **End-Points:** 6x Debian Linux Hosts (Simulasi Client & Server).

### Klasifikasi Zona
| Zona | Router | Subnet | Trust Level | Kebijakan Utama |
| :--- | :--- | :--- | :--- | :--- |
| **ADMIN** | ADMR | `10.20.40.0/24` | ✅ High | Akses penuh (*Full Access*) untuk maintenance. Prioritas QoS Tertinggi. |
| **AKADEMIK** | AcademicR | `10.20.20.0/24` | 🟡 Medium | Server Akademik. Mendapat garansi bandwidth (*Limit-at*) dan proteksi ketat. |
| **RISET (IoT)** | AcademicR | `10.20.30.0/24` | 🟡 Medium | Zona eksperimen. Dibatasi jumlah koneksi (*Connection Limit*) untuk cegah Botnet. |
| **MAHASISWA** | StudentR | `10.20.10.0/24` | 🟠 Low | Akses Internet bebas. Akses ke Server Akademik dibatasi hanya HTTPS/HTTP. |
| **GUEST** | GuestR | `10.20.50.0/24` | 🔴 Untrusted | Isolasi Total. Hanya boleh Web/DNS ke Internet. Dilarang Ping ke lokal. |

---

## Fitur Keamanan (Security Features)

Sistem ini menerapkan pertahanan berlapis (*Defense in Depth*) yang mencakup:

### 1. Hardened Firewall (MikroTik Core)
* **Port Scan Detection (PSD):** Secara otomatis mendeteksi aktivitas *scanning* (Nmap) dan memblokir IP penyerang selama 15 menit.
* **IoT Containment:** Membatasi perangkat di zona Riset maksimal **32 koneksi simultan** untuk mencegah serangan DDoS/Botnet.
* **ICMP Policy:** Ping dibatasi (*Rate Limit 5pps*) dan hanya diizinkan ke arah Internet. Guest dilarang ping ke Admin.
* **Input Protection:** Akses manajemen router (SSH/Winbox) dikunci hanya untuk IP Admin.

### 2. Anti-DDoS (RAW Filtering)
* Menggunakan tabel RAW `prerouting` untuk membuang paket **IP Bogon/Spoofing** dan serangan **TCP SYN Flood** sebelum membebani CPU router.

### 3. Manajemen Bandwidth (QoS Sultan)
Menggunakan *Simple Queue* dengan prioritas bertingkat:
* **Priority 1:** Server Akademik (Garansi 50 Mbps).
* **Priority 2:** Admin.
* **Priority 8:** Guest (Dibatasi Max 10 Mbps).

### 4. Local Isolation Patch
* Implementasi *Firewall Filter* lokal pada **AcademicR** untuk memblokir akses langsung dari IoT ke Server Akademik yang berada dalam satu router fisik.

---

## 📂 Konfigurasi Sistem

Seluruh skrip konfigurasi tersedia di folder `Config/`.

### A. Router Configuration
Gunakan skrip `.sh` berikut untuk mengonfigurasi router di GNS3:
* **Core:** `Config/MikrotikFW.sh` (Script Utama: Firewall, NAT, QoS, Routing).
* **Edge:** `Config/Router/EdgeR.sh` (NAT, DHCP Client).
* **Zones:** `Config/Router/GuestR.sh`, `StudentR.sh`, `ADMR.sh`, `AcademicR.sh`.

### B. Host Configuration (Debian Linux)
Konfigurasi IP statis dilakukan pada file `/etc/network/interfaces` di setiap node Debian.

| Hostname | Peran | IP Address | Gateway | Script Config |
| :--- | :--- | :--- | :--- | :--- |
| **Debian-1** | Guest PC | `10.20.50.2` | `10.20.50.1` | `Config/Hosts/GstVPC.sh` |
| **Debian-2** | Mahasiswa 1 | `10.20.10.2` | `10.20.10.1` | `Config/Hosts/MhsVPC1.sh` |
| **Debian-3** | Mahasiswa 2 | `10.20.10.6` | `10.20.10.1` | `Config/Hosts/MhsVPC2.sh` |
| **Debian-4** | Admin PC | `10.20.40.2` | `10.20.40.1` | `Config/Hosts/AdmVPC.sh` |
| **Debian-5** | Server Akademik | `10.20.20.2` | `10.20.20.1` | `Config/Hosts/AkdVPC.sh` |
| **Debian-6** | Riset IoT | `10.20.30.2` | `10.20.30.1` | `Config/Hosts/RstVPC.sh` |

**Cara Setup Host:**
1.  Login ke Debian
2.  Edit config: `sudo nano /etc/network/interfaces`.
3.  Masukkan konfigurasi sesuai file script terkait.
4.  Restart hosts: `sudo reboot`.
5.  Jika ingin menginstall/update: `sudo su` untuk masuk ke `root`.
---

## Panduan Testing

Sebelum melakukan demo, pastikan *tools* berikut sudah terinstall di Debian:
* **Server:** `apt install apache2` (Web Server).
* **Attacker (Guest/Riset):** `apt install nmap hping3 curl lynx`.
* **Client (Mhs/Admin):** `apt install curl lynx mtr-tiny`.

### Skenario Pengujian

1.  **Uji Isolasi Zona:**
    * Dari Guest: `ping 10.20.40.2` (Admin).
    * **Hasil:** *Timeout* (Diblokir Firewall).

2.  **Uji Akses Layanan:**
    * Dari Mahasiswa: `curl http://10.20.20.2`.
    * **Hasil:** Menampilkan HTML Server Akademik.

3.  **Uji Port Scan Detection (PSD):**
    * Dari Guest: `nmap -Pn -p 1-100 10.20.40.2`.
    * **Hasil:** IP Guest masuk ke *Address List* "port_scanners" di MikroTik dan koneksi internet diputus selama 15 menit.

4.  **Uji QoS & IoT Containment:**
    * Dari Riset (IoT): `hping3 -S --flood -p 80 10.20.20.2`.
    * **Hasil:** Koneksi dibatasi/didrop oleh firewall rule "LIMIT IOT Connections".

---


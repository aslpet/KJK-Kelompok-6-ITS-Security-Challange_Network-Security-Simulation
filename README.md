# ITS Secure Network Challenge - Kelompok 6

> **Implementasi Arsitektur Keamanan Berbasis Zona (Zone-Based Security) dengan Segmentasi Fisik, Mitigasi DDoS, & Manajemen Trafik Adaptif.**

Proyek ini mendemonstrasikan desain dan implementasi pertahanan jaringan "Hardened" untuk Departemen Teknologi Informasi ITS menggunakan filosofi **Zero Trust** dan **Physical Segmentation**.

## Anggota Tim
1. **Angga Firmansyah** - 5027241062
2. **Ahmad Rafi Fadhillah Dwiputra** - 5027241068
3. **Fika Arka Nuriyah** - 5027241071
4. **Dimas Muhammad Putra** - 5027241076

---

## Arsitektur & Topologi

Kami meninggalkan model jaringan datar (*flat network*) dan beralih ke topologi **Hub-and-Spoke** dengan isolasi perangkat keras untuk mencegah kegagalan sistemik.

### Komponen Infrastruktur
* **Core Security:** 1x MikroTik RouterOS sebagai Firewall Pusat, Traffic Shaper (QoS), dan Detektor Serangan.
* **Zone Routers:** 4x MikroTik Router (Guest, Student, Admin, Academic) untuk isolasi *fault domain*.
* **Edge Router:** 1x MikroTik sebagai gerbang NAT ke Internet dengan IP DHCP Client.
* **End-Points:** 6x Host **Debian Linux** untuk simulasi layanan nyata (Web Server, Attack Tool).

### Peta Zona & Kebijakan
| Zona | Router | Subnet | Trust Level | Kebijakan Utama |
| :--- | :--- | :--- | :--- | :--- |
| **ADMIN** | ADMR | `10.20.40.0/24` | ✅ High | Akses penuh (*God Mode*) ke seluruh jaringan & router. Prioritas Bandwidth Tinggi. |
| **AKADEMIK** | AcademicR | `10.20.20.0/24` | 🟡 Medium | Server Akademik. Mendapat garansi bandwidth (*Limit-at 50M*) dan proteksi akses (Hanya HTTP/S). |
| **RISET (IoT)** | AcademicR | `10.20.30.0/24` | 🟡 Medium | Zona eksperimen. Dibatasi jumlah koneksi (*Max 32 Connection*) untuk cegah Botnet. |
| **MAHASISWA** | StudentR | `10.20.10.0/24` | 🟠 Low | Akses Internet bebas. Akses ke Server Akademik dibatasi hanya Web (HTTP/S). Ping diblokir. |
| **GUEST** | GuestR | `10.20.50.0/24` | 🔴 Untrusted | Isolasi Total. Hanya boleh Web/DNS ke Internet. Dilarang keras Ping ke jaringan lokal. |

---

## Fitur Keamanan Unggulan (Hardened)

Sistem ini menerapkan pertahanan berlapis (*Defense in Depth*) yang telah teruji:

### 1. Active Defense (Deteksi Serangan)
* **Port Scan Detection (PSD):** MikroTik secara otomatis mendeteksi pola *scanning* (Nmap) dan memblokir IP penyerang selama **15 menit** (masuk *Address List* `port_scanners`).
* **IoT Containment:** Membatasi perangkat di zona Riset maksimal **32 koneksi TCP simultan**. Jika lebih (indikasi Botnet/DDoS), paket langsung di-DROP.

### 2. Anti-DDoS & Spoofing (RAW Table)
* Menggunakan tabel RAW `prerouting` untuk membuang paket **IP Bogon/Spoofing** dan serangan **TCP SYN Flood** di gerbang terdepan sebelum membebani CPU router.

### 3. Local Isolation Patch (Blind Spot Fix)
* Implementasi *Firewall Filter* lokal pada **AcademicR** untuk memblokir akses langsung dari IoT ke Server Akademik yang berada dalam satu router fisik, menutup celah keamanan internal.

### 4. Manajemen Bandwidth (QoS Sultan)
Menggunakan *Simple Queue* dengan prioritas bertingkat untuk menjamin *Service Availability*:
* **Priority 1 (Critical):** Server Akademik (Garansi 50 Mbps).
* **Priority 2 (High):** Admin (Max 100 Mbps).
* **Priority 8 (Low):** Guest (Dibatasi Max 10 Mbps).

---

## Panduan Konfigurasi

Seluruh skrip konfigurasi tersedia di folder `Config/`.

### A. Router Configuration (MikroTik)
Gunakan skrip `.sh` berikut via Terminal/Winbox:
1.  **Core Firewall (Wajib):** `Config/MikrotikFW.sh`
    * *Fitur:* Firewall Filter, NAT, RAW, QoS, MSS Clamping.
2.  **Router Zona:**
    * `Config/Router/AcademicR.sh` (Penting: Ada rule blokir lokal IoT).
    * `EdgeR.sh`, `GuestR.sh`, `StudentR.sh`, `ADMR.sh` (Routing dasar).

### B. Host Configuration (Debian Linux)
Edit file `/etc/network/interfaces` pada setiap node Debian dengan konfigurasi IP Statis berikut:

| Hostname | Peran | IP Address | Gateway | Script Referensi |
| :--- | :--- | :--- | :--- | :--- |
| **Debian-1** | Guest PC | `10.20.50.2` | `10.20.50.1` | `Config/Hosts/GstVPC.sh` |
| **Debian-2** | Mhs 1 | `10.20.10.2` | `10.20.10.1` | `Config/Hosts/MhsVPC1.sh` |
| **Debian-3** | Mhs 2 | `10.20.10.6` | `10.20.10.1` | `Config/Hosts/MhsVPC2.sh` |
| **Debian-4** | Admin | `10.20.40.2` | `10.20.40.1` | `Config/Hosts/AdmVPC.sh` |
| **Debian-5** | Server | `10.20.20.2` | `10.20.20.1` | `Config/Hosts/AkdVPC.sh` |
| **Debian-6** | Riset IoT | `10.20.30.2` | `10.20.30.1` | `Config/Hosts/RstVPC.sh` |

> **Catatan:** Pastikan nama interface di Debian sesuai (biasanya `eth0`, `ens3`, atau `enp2s0`).

---

## Skenario Pengujian (Testing Guide)

Pastikan *tools* berikut sudah terinstall di Debian sebelum demo:
`apt install apache2 nmap hping3 curl lynx mtr-tiny`

### 1. Uji Isolasi Zona (Segmentation)
* **Aksi:** Dari Guest, ping ke Admin (`ping 10.20.40.2`).
* **Hasil:** `Request Timed Out`.
* **Analisis:** Firewall Core memblokir akses lintas zona ilegal.

### 2. Uji Pertahanan Aktif (PSD)
* **Aksi:** Dari Guest, scan Admin (`nmap -Pn -p 1-100 10.20.40.2`).
* **Hasil:** IP Guest masuk *Blacklist* di MikroTik dan internet mati total selama 15 menit.

### 3. Uji IoT Containment (DDoS Mitigasi)
* **Aksi:** Dari Riset IoT, flood ke internet (`hping3 -S --flood -p 80 8.8.8.8`).
* **Hasil:** Trafik dibatasi oleh rule firewall `LIMIT IOT Connections`. Server aman.

### 4. Uji QoS (Bandwidth Stress Test)
* **Aksi:** Guest melakukan download besar/flood.
* **Hasil:** Bandwidth Guest mentok merah di 10 Mbps.
* **Verifikasi:** Admin/Server tetap bisa akses internet dengan lancar (Priority 1 & 2).

---
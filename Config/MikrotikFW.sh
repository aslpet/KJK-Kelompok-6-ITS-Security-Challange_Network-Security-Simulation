# --- SCRIPT START MIKROTIK TENGAH ---
/system identity set name=Core-Firewall

# 1. Konfigurasi IP Address
# ether1 ke Edge (Tetap)
/ip address add address=192.168.0.2/30 interface=ether1 comment="To Edge"
# ether2 ke GUEST (Ubah dr script lama)
/ip address add address=192.168.50.1/30 interface=ether2 comment="To Guest"
# ether3 ke STUDENT (Ubah dr script lama)
/ip address add address=192.168.10.1/30 interface=ether3 comment="To Student"
# ether4 ke ADMIN (Ubah dr script lama)
/ip address add address=192.168.40.1/30 interface=ether4 comment="To Admin"
# ether5 ke ACADEMIC (Asumsi sisa port)
/ip address add address=192.168.20.1/30 interface=ether5 comment="To Academic"

# 2. Routing (Gatewaynya tetap sama, cuma beda jalur fisik)
/ip route add dst-address=0.0.0.0/0 gateway=192.168.0.1
/ip route add dst-address=10.20.10.0/24 gateway=192.168.10.2
/ip route add dst-address=10.20.40.0/24 gateway=192.168.40.2
/ip route add dst-address=10.20.20.0/24 gateway=192.168.20.2
/ip route add dst-address=10.20.30.0/24 gateway=192.168.20.2
/ip route add dst-address=10.20.50.0/24 gateway=192.168.50.2

# 3. NAT
/ip firewall nat add chain=srcnat out-interface=ether1 action=masquerade

# --- SCRIPT END MIKROTIK TENGAH ---

# ========================================================
# MIKROTIK HARDENED FIREWALL - FINAL REVISION
# Fitur: Zone-Based, Isolation (Guest No Ping Admin), PSD
# ========================================================

# 1. Bersihkan Rule Lama
/ip firewall filter remove [find]

# 2. Cek configuration
/ip firewall filter print

# ========================================================
# MIKROTIK ULTIMATE SECURITY & QoS - WEEK 11 FINAL
# Fitur: RAW Anti-DDoS, Port Scan Detect, IoT Limit, QoS Sultan
# ========================================================

# 1. BERSIH-BERSIH (Hapus Konfig Lama biar gak bentrok)
/ip firewall filter remove [find]
/ip firewall nat remove [find]
/ip firewall raw remove [find]
/ip firewall address-list remove [find]
/queue simple remove [find]

# 2. CEK KONFIGURASI
/ip firewall filter print
/ip firewall nat print
/ip firewall raw print
/queue simple print

# --------------------------------------------------------
# BAGIAN A: RAW FILTERING (Garda Terdepan Anti-DDoS)
# --------------------------------------------------------
# Membuang sampah sebelum masuk CPU. Hemat Resource.

# 1. Blokir IP Bogon/Spoofing dari arah Internet (ether1)
# (IP Private tidak boleh muncul dari Internet)
/ip firewall raw add chain=prerouting in-interface=ether1 src-address=10.0.0.0/8 action=drop comment="DROP Bogon 10.x from WAN"
/ip firewall raw add chain=prerouting in-interface=ether1 src-address=172.16.0.0/12 action=drop comment="DROP Bogon 172.16.x from WAN"
/ip firewall raw add chain=prerouting in-interface=ether1 src-address=192.168.0.0/16 action=drop comment="DROP Bogon 192.168.x from WAN"

# 2. Blokir Serangan TCP SYN Flood
/ip firewall raw add chain=prerouting protocol=tcp tcp-flags=syn limit=400,5:packet action=accept comment="Accept Normal TCP SYN"
/ip firewall raw add chain=prerouting protocol=tcp tcp-flags=syn action=drop comment="DROP TCP SYN Flood"

# --------------------------------------------------------
# BAGIAN B: NAT (Wajib ada biar bisa internetan)
# --------------------------------------------------------
/ip firewall nat add chain=srcnat out-interface=ether1 action=masquerade comment="NAT Internet"

# --------------------------------------------------------
# BAGIAN C: FIREWALL FILTER (Logika Keamanan Utama)
# --------------------------------------------------------

# --- 1. PORT SCAN DETECTION (PSD) ---
# Deteksi Nmap/Scanner. Hukuman: Blacklist 15 Menit.
/ip firewall filter add chain=forward protocol=tcp psd=21,3s,3,1 action=add-src-to-address-list address-list="port_scanners" address-list-timeout=15m comment="DETECT PORT SCAN"
# Drop pelaku scan
/ip firewall filter add chain=forward src-address-list="port_scanners" action=drop comment="DROP PORT SCANNERS"
/ip firewall filter add chain=input src-address-list="port_scanners" action=drop comment="DROP PORT SCANNERS INPUT"

# --- 2. IOT CONTAINMENT (Anti-Botnet Riset) ---
# Jika 1 alat IoT (di subnet Riset) membuka > 32 koneksi sekaligus = DROP.
/ip firewall filter add chain=forward src-address=10.20.30.0/24 protocol=tcp connection-limit=32,32 action=drop comment="LIMIT IOT Connections (Anti-Botnet)"

# --- 3. BASIC TRAFFIC CONTROL ---
# Accept Established & Related
/ip firewall filter add chain=input action=accept connection-state=established,related comment="Accept Established Input"
/ip firewall filter add chain=forward action=accept connection-state=established,related comment="Accept Established Forward"
# Drop Invalid
/ip firewall filter add chain=input action=drop connection-state=invalid comment="Drop Invalid Input"
/ip firewall filter add chain=forward action=drop connection-state=invalid comment="Drop Invalid Forward"

# --- 4. ICMP (PING) POLICY ---
# Admin: Bebas Ping kemana saja
/ip firewall filter add chain=forward protocol=icmp in-interface=ether4 action=accept comment="Admin Ping ALL"
# User Lain: Cuma boleh Ping ke Internet (ether1). Ping ke Admin/Lokal = MATI.
/ip firewall filter add chain=forward protocol=icmp out-interface=ether1 limit=5,5:packet action=accept comment="User Ping Internet Only"
# Ping ke Gateway (Input) dibolehkan
/ip firewall filter add chain=input protocol=icmp limit=5,5:packet action=accept comment="Allow Ping to Gateway"

# --- 5. INPUT CHAIN (Proteksi Router) ---
# Admin: Boleh Login
/ip firewall filter add chain=input in-interface=ether4 action=accept comment="Admin Access to Router"
# Drop sisanya
/ip firewall filter add chain=input action=drop comment="DROP ALL INPUT"

# --- 6. FORWARD CHAIN (Akses Antar Zona) ---

# > ADMIN ZONE (High Trust)
/ip firewall filter add chain=forward action=accept in-interface=ether4 comment="Admin Full Access"

# > STUDENT ZONE (Low Trust)
/ip firewall filter add chain=forward action=accept protocol=tcp in-interface=ether3 out-interface=ether5 dst-port=443 comment="Student to Academic HTTPS"
/ip firewall filter add chain=forward action=accept protocol=tcp in-interface=ether3 out-interface=ether1 dst-port=80,443 comment="Student Internet Web"
# DNS (UDP & TCP)
/ip firewall filter add chain=forward action=accept protocol=udp in-interface=ether3 out-interface=ether1 dst-port=53 comment="Student Internet DNS"
/ip firewall filter add chain=forward action=accept protocol=tcp in-interface=ether3 out-interface=ether1 dst-port=53 comment="Student Internet DNS TCP"

# > GUEST ZONE (Untrusted)
/ip firewall filter add chain=forward action=accept protocol=tcp in-interface=ether2 out-interface=ether1 dst-port=80,443 comment="Guest Internet Web"
/ip firewall filter add chain=forward action=accept protocol=udp in-interface=ether2 out-interface=ether1 dst-port=53 comment="Guest Internet DNS"

# > ACADEMIC & RISET ZONE (Medium Trust)
/ip firewall filter add chain=forward action=accept protocol=tcp in-interface=ether5 out-interface=ether1 dst-port=443 comment="Riset IoT HTTPS"
/ip firewall filter add chain=forward action=accept protocol=udp in-interface=ether5 out-interface=ether1 dst-port=123 comment="Riset NTP"
/ip firewall filter add chain=forward action=accept in-interface=ether5 out-interface=ether5 comment="Intra-Academic"

# --- 7. SAFETY NET (DROP ALL) ---
/ip firewall filter add chain=forward action=drop log=yes log-prefix="BLOCKED:" comment="DROP ALL FORWARD"

# --------------------------------------------------------
# BAGIAN D: QoS / BANDWIDTH MANAGEMENT
# --------------------------------------------------------
# Skenario: Total Bandwidth Internet = 100 Mbps
# Priority: 1 (Tertinggi) s/d 8 (Terendah)

# 1. AKADEMIK (Server Utama)
# Priority 1. Max Speed Full 100M. Dijamin (Limit-at) 50M tidak akan diganggu gugat.
/queue simple add name="1_Academic_Server" target=10.20.20.0/24 max-limit=100M/100M limit-at=50M/50M priority=1/1 comment="Server Critical Priority"

# 2. ADMIN
# Priority 2. Speed Full 100M. Tidak ada garansi khusus tapi prioritas tinggi.
/queue simple add name="2_Admin_VIP" target=10.20.40.0/24 max-limit=100M/100M priority=2/2 comment="Admin VIP"

# 3. MAHASISWA
# Priority 5. Speed lumayan 50 Mbps.
/queue simple add name="3_Student_Std" target=10.20.10.0/24 max-limit=50M/50M priority=5/5 comment="Student Standard"

# 4. RISET IOT
# Priority 7. Upload dicekik 2Mbps biar gak dipake DDoS. Download lega 20Mbps.
/queue simple add name="4_Riset_IoT" target=10.20.30.0/24 max-limit=20M/2M priority=7/7 comment="IoT Upload Limit"

# 5. GUEST
# Priority 8 (Terendah). Speed 10 Mbps (Udah baik banget ini).
# Kalau jaringan penuh, ini yang pertama kali lemot.
/queue simple add name="5_Guest_Public" target=10.20.50.0/24 max-limit=10M/10M priority=8/8 comment="Guest Limit"
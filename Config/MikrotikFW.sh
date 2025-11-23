# ========================================================
# MIKROTIK CORE FIREWALL - FINAL GOLD VERSION
# ========================================================

# 1. BERSIH-BERSIH
# ----------------
# Resets the firewall configuration to a clean state to avoid conflicts with existing rules.
/ip firewall filter remove [find]
/ip firewall nat remove [find]
/ip firewall raw remove [find]
/ip firewall mangle remove [find]
/ip firewall address-list remove [find]
/queue simple remove [find]
/ip address remove [find]
/ip route remove [find]

# 2. SET IDENTITY & OPTIMASI GNS3
# -------------------------------
# Sets the router's hostname for identification.
/system identity set name=MikrotikFirewall

# OPTIMIZATION: TCP MSS CLAMPING
# Adjusts the Maximum Segment Size (MSS) for TCP connections.
# This is crucial in GNS3/VPN environments to prevent packet fragmentation issues
# that cause websites to hang or load partially (e.g., white screens).
/ip firewall mangle add chain=forward protocol=tcp tcp-flags=syn action=change-mss new-mss=clamp-to-pmtu comment="Fix Web Loading Issues"

# 3. KONFIGURASI IP ADDRESS (Gateway Zona)
# ----------------------------------------
# Assigns IP addresses to each interface, making this router the default gateway for connected zones.
/ip address add address=192.168.0.2/30 interface=ether1 comment="Uplink-Edge"
/ip address add address=192.168.50.1/30 interface=ether2 comment="Gateway-Guest"
/ip address add address=192.168.10.1/30 interface=ether3 comment="Gateway-Student"
/ip address add address=192.168.40.1/30 interface=ether4 comment="Gateway-Admin"
/ip address add address=192.168.20.1/30 interface=ether5 comment="Gateway-Academic"

# 4. ROUTING
# ----------
# Static routing table definition.
# 1. Default Route: Sends all unknown traffic (0.0.0.0/0) to the Edge Router (Internet).
/ip route add dst-address=0.0.0.0/0 gateway=192.168.0.1

# 2. Return Routes: Tells the router how to reach specific internal subnets
# located behind other downstream routers (Zone Routers).
/ip route add dst-address=10.20.10.0/24 gateway=192.168.10.2 comment="To Student LAN"
/ip route add dst-address=10.20.40.0/24 gateway=192.168.40.2 comment="To Admin LAN"
/ip route add dst-address=10.20.20.0/24 gateway=192.168.20.2 comment="To Academic LAN"
/ip route add dst-address=10.20.30.0/24 gateway=192.168.20.2 comment="To Riset LAN"
/ip route add dst-address=10.20.50.0/24 gateway=192.168.50.2 comment="To Guest LAN"

# 5. NAT INTERNET
# ---------------
# Enables Source NAT (Masquerade) on the WAN interface (ether1).
# Allows internal private IP addresses to access the internet by "hiding" behind the router's public IP.
/ip firewall nat add chain=srcnat out-interface=ether1 action=masquerade comment="NAT Internet"

# 6. RAW FILTERING (Anti-DDoS & Spoofing)
# ---------------------------------------
# The RAW table processes packets BEFORE connection tracking, saving CPU resources during attacks.

# Anti-Spoofing (Bogon Filtering):
# Drops packets coming FROM the internet (ether1) that claim to have private source IPs.
# These are invalid and often malicious (spoofing).
/ip firewall raw add chain=prerouting in-interface=ether1 src-address=10.0.0.0/8 action=drop comment="DROP Bogon 10.x"
/ip firewall raw add chain=prerouting in-interface=ether1 src-address=172.16.0.0/12 action=drop comment="DROP Bogon 172.16.x"
/ip firewall raw add chain=prerouting in-interface=ether1 src-address=192.168.0.0/16 action=drop comment="DROP Bogon 192.168.x"

# Anti-Flood (SYN Flood Protection):
# Protects against TCP SYN Flood attacks.
# 1. Allows normal SYN packets up to a limit (400/sec).
# 2. Drops excess SYN packets to prevent CPU exhaustion.
/ip firewall raw add chain=prerouting protocol=tcp tcp-flags=syn limit=400,5:packet action=accept comment="Accept Normal SYN"
/ip firewall raw add chain=prerouting protocol=tcp tcp-flags=syn action=drop comment="DROP SYN Flood"

# 7. FIREWALL FILTER (Security Policy)
# ------------------------------------

# --- A. DETEKSI & PROTEKSI DINI ---

# Port Scan Detection (PSD):
# Uses MikroTik's PSD feature to detect port scanning behavior (e.g., Nmap).
# If detected, adds the source IP to the "port_scanners" address list for 15 minutes.
/ip firewall filter add chain=forward protocol=tcp psd=21,3s,3,1 action=add-src-to-address-list address-list="port_scanners" address-list-timeout=15m comment="DETECT PORT SCAN"

# Drop Scanners:
# Drops ALL traffic from IPs listed in "port_scanners".
# Applies to traffic passing through (forward) and traffic to the router itself (input).
/ip firewall filter add chain=forward src-address-list="port_scanners" action=drop comment="DROP PORT SCANNERS"
/ip firewall filter add chain=input src-address-list="port_scanners" action=drop comment="DROP PORT SCANNERS INPUT"

# IoT Containment (Anti-Botnet):
# Limits hosts in the Riset IoT subnet (10.20.30.0/24) to 32 concurrent TCP connections.
# Prevents compromised IoT devices from launching massive DDoS attacks.
/ip firewall filter add chain=forward src-address=10.20.30.0/24 protocol=tcp connection-limit=32,32 action=drop comment="LIMIT IOT Connections"

# --- B. BASIC CONNECTION TRACKING ---

# Accept Established/Related:
# Standard stateful firewall rule. Allows packets that are part of an already permitted connection.
# Highly efficient as it bypasses subsequent rule checks for active streams.
/ip firewall filter add chain=input action=accept connection-state=established,related
/ip firewall filter add chain=forward action=accept connection-state=established,related

# Drop Invalid:
# Drops packets with invalid headers or state, which are useless or malicious.
/ip firewall filter add chain=input action=drop connection-state=invalid
/ip firewall filter add chain=forward action=drop connection-state=invalid

# --- C. ICMP (PING) POLICY ---

# Admin Ping:
# Grants Admin network full permission to ping anywhere for troubleshooting.
/ip firewall filter add chain=forward protocol=icmp in-interface=ether4 action=accept comment="Admin Ping ALL"

# User Ping (Restricted):
# Allows Users (Guest/Student) to ping ONLY the Internet (out-interface=ether1).
# Rate limited to 5 packets/sec to prevent ping floods.
# IMPORTANT: Implicitly BLOCKS pinging internal networks (Admin/Server).
/ip firewall filter add chain=forward protocol=icmp out-interface=ether1 limit=5,5:packet action=accept comment="User Ping Internet Only"

# Ping Gateway:
# Allows pinging the router's own interface to verify connectivity.
/ip firewall filter add chain=input protocol=icmp limit=5,5:packet action=accept comment="Ping to Gateway"

# --- D. INPUT CHAIN (Proteksi Router) ---

# Admin Access:
# Allows ONLY the Admin network (ether4) to access router services (SSH, Winbox, Webfig).
/ip firewall filter add chain=input in-interface=ether4 action=accept comment="Admin Access Router"

# Input Safety Net:
# Drops all other traffic trying to reach the router itself (prevents brute force from Guest/Student).
/ip firewall filter add chain=input action=drop comment="DROP ALL INPUT"

# --- E. FORWARD CHAIN (Akses Antar Zona) ---

# 1. ADMIN (High Trust):
# Grants Admin full access to all networks (Internet, Student, Guest, Academic).
/ip firewall filter add chain=forward action=accept in-interface=ether4 comment="Admin Full Access"

# 2. STUDENT (Low Trust):
# - Allows HTTPS (TCP 443) access to the Academic Server.
# - Allows Web (HTTP/HTTPS) and DNS access to the Internet.
/ip firewall filter add chain=forward action=accept protocol=tcp in-interface=ether3 out-interface=ether5 dst-port=443 comment="Student to Academic HTTPS"
/ip firewall filter add chain=forward action=accept protocol=tcp in-interface=ether3 out-interface=ether1 dst-port=80,443 comment="Student Internet Web"
/ip firewall filter add chain=forward action=accept protocol=udp in-interface=ether3 out-interface=ether1 dst-port=53 comment="Student DNS"
/ip firewall filter add chain=forward action=accept protocol=tcp in-interface=ether3 out-interface=ether1 dst-port=53 comment="Student DNS TCP"

# 3. GUEST (Untrusted):
# Strict isolation. ONLY allows Web browsing and DNS resolution to the Internet.
# No access to internal servers or other clients.
/ip firewall filter add chain=forward action=accept protocol=tcp in-interface=ether2 out-interface=ether1 dst-port=80,443 comment="Guest Web"
/ip firewall filter add chain=forward action=accept protocol=udp in-interface=ether2 out-interface=ether1 dst-port=53 comment="Guest DNS"

# 4. ACADEMIC & RISET (Medium Trust):
# - Allows Servers/IoT devices to update/connect to cloud via HTTP/HTTPS.
# - Allows DNS queries (essential for updates like apt-get).
# - Allows NTP (Time Sync).
# - Allows intra-zone communication (e.g., IoT device talking to local Server).
/ip firewall filter add chain=forward action=accept protocol=tcp in-interface=ether5 out-interface=ether1 dst-port=80,443 comment="Server Update & IoT Cloud"
/ip firewall filter add chain=forward action=accept protocol=udp in-interface=ether5 out-interface=ether1 dst-port=53 comment="Server DNS"
/ip firewall filter add chain=forward action=accept protocol=udp in-interface=ether5 out-interface=ether1 dst-port=123 comment="NTP Sync"
/ip firewall filter add chain=forward action=accept in-interface=ether5 out-interface=ether5 comment="Intra-Academic"

# --- F. SAFETY NET ---
# Drop All Forward:
# The final "catch-all" rule.
# Drops ANY packet that did not match the rules above.
# Logs the dropped packet with prefix "BLOCKED:" for auditing.
/ip firewall filter add chain=forward action=drop log=yes log-prefix="BLOCKED:" comment="DROP ALL FORWARD"

# 8. QoS (BANDWIDTH MANAGEMENT)
# -----------------------------
# Simple Queues to prioritize traffic based on user role.

# Priority 1 (Critical): Academic Server gets dedicated/guaranteed bandwidth.
/queue simple add name="1_Academic_Server" target=10.20.20.0/24 max-limit=100M/100M limit-at=50M/50M priority=1/1

# Priority 2 (High): Admin gets high availability.
/queue simple add name="2_Admin_VIP" target=10.20.40.0/24 max-limit=100M/100M priority=2/2

# Priority 5 (Standard): Students get standard access.
/queue simple add name="3_Student_Std" target=10.20.10.0/24 max-limit=50M/50M priority=5/5

# Priority 7 (Restricted): IoT devices have restricted upload to prevent DDoS participation.
/queue simple add name="4_Riset_IoT" target=10.20.30.0/24 max-limit=20M/2M priority=7/7

# Priority 8 (Low): Guests get lowest priority, bandwidth is throttled first during congestion.
/queue simple add name="5_Guest_Public" target=10.20.50.0/24 max-limit=10M/10M priority=8/8
# --- SCRIPT START AcademicR ---
/system identity set name=AcademicR

# IP Uplink ke Firewall
/ip address add address=192.168.20.2/30 interface=ether1

# IP Downlink 1 (Akademik)
/ip address add address=10.20.20.1/24 interface=ether2

# IP Downlink 2 (Riset & IoT)
/ip address add address=10.20.30.1/24 interface=ether2

# Default Route
/ip route add dst-address=0.0.0.0/0 gateway=192.168.20.1

/ip firewall filter add chain=forward src-address=10.20.30.0/24 dst-address=10.20.20.0/24 action=drop comment="BLOCK IoT to Academic Server (Local Isolation)"

# 1. Izinkan DNS dari Zona Akademik (Wajib supaya bisa resolve domain)
/ip firewall filter add chain=forward action=accept protocol=udp in-interface=ether5 out-interface=ether1 dst-port=53 place-before=20 comment="Academic DNS"

# 2. Izinkan HTTP & HTTPS dari Zona Akademik ke Internet (Untuk apt-get update)
/ip firewall filter add chain=forward action=accept protocol=tcp in-interface=ether5 out-interface=ether1 dst-port=80,443 place-before=20 comment="Academic Server Update"
# --- SCRIPT END AcademicR ---
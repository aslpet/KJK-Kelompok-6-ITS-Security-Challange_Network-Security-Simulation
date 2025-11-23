# --- SCRIPT FINAL ACADEMICR ---
/system identity set name=AcademicR

# 1. IP Address
/ip address add address=192.168.20.2/30 interface=ether1
/ip address add address=10.20.20.1/24 interface=ether2 comment="LAN Akademik"
/ip address add address=10.20.30.1/24 interface=ether2 comment="LAN Riset IoT"

# 2. Default Route
/ip route add dst-address=0.0.0.0/0 gateway=192.168.20.1

# 3. LOCAL FIREWALL (Blind Spot Fix)
# Blokir IoT ke Server agar tidak bisa serang langsung
/ip firewall filter add chain=forward src-address=10.20.30.0/24 dst-address=10.20.20.0/24 action=drop comment="BLOCK IoT to Server (Local)"
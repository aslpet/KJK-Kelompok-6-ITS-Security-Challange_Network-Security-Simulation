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
# --- SCRIPT END AcademicR ---
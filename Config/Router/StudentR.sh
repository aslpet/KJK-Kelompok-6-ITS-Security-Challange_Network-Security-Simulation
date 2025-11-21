# --- SCRIPT START StudentR ---
/system identity set name=StudentR

# IP Uplink ke Firewall
/ip address add address=192.168.10.2/30 interface=ether1

# IP Downlink ke LAN
/ip address add address=10.20.10.1/24 interface=ether2

# Default Route (Semua trafik lempar ke Firewall)
/ip route add dst-address=0.0.0.0/0 gateway=192.168.10.1
# --- SCRIPT END StudentR ---
# --- SCRIPT START ADMR ---
/system identity set name=ADMR

# IP Uplink ke Firewall
/ip address add address=192.168.40.2/30 interface=ether1

# IP Downlink ke LAN
/ip address add address=10.20.40.1/24 interface=ether2

# Default Route
/ip route add dst-address=0.0.0.0/0 gateway=192.168.40.1
# --- SCRIPT END ADMR ---
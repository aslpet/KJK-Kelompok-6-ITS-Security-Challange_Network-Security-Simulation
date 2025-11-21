# --- SCRIPT START GuestR ---
/system identity set name=GuestR

# IP Uplink ke Firewall
/ip address add address=192.168.50.2/30 interface=ether1

# IP Downlink ke LAN
/ip address add address=10.20.50.1/24 interface=ether2

# Default Route
/ip route add dst-address=0.0.0.0/0 gateway=192.168.50.1
# --- SCRIPT END GuestR ---
# --- SCRIPT FINAL EDGER ---
/system identity set name=EdgeR

# 1. WAN (DHCP dari Cloud)
/ip dhcp-client add interface=ether1 disabled=no
/ip address add address=192.168.122.2/24 interface=ether1 comment="WAN-to-NAT"

# 2. LAN (Ke Firewall)
/ip address add address=192.168.0.1/30 interface=ether2

# 3. NAT & Routing
/ip firewall nat add chain=srcnat out-interface=ether1 action=masquerade
/ip route add dst-address=10.20.0.0/16 gateway=192.168.0.2
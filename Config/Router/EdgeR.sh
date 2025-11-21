# --- SCRIPT START EDGER ---
/system identity set name=EdgeR

# 1. Minta IP dari Internet GNS3
/ip dhcp-client add interface=ether1 disabled=no
/ip address add address=192.168.122.2/24 interface=ether1 comment="WAN-to-NAT"

# 2. Set IP ke arah Firewall Internal
/ip address add address=192.168.0.1/30 interface=ether2

# 3. NAT (Supaya jaringan di bawah bisa akses internet)
/ip firewall nat add chain=srcnat out-interface=ether1 action=masquerade

# 4. Static Route (Agar EdgeR tau subnet kampus 10.20.x.x ada di mana)
/ip route add dst-address=10.20.0.0/16 gateway=192.168.0.2
# --- SCRIPT END EDGER ---

test:
/ip address print
should show:
#ether1 = 192.168.122.2/24
#ether2 = 10.20.0.2/30

/ip route print
should show:
#0.0.0.0/0 → 192.168.122.1

ping 192.168.122.1 → REPLY ✓


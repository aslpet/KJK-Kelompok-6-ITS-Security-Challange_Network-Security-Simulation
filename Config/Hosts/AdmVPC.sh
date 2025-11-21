# ========================================================
# IP address AdmVPC
# ========================================================
# IP: 10.20.40.2
# Gateway: 10.20.40.1
# ========================================================

# /etc/network/interfaces
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address 10.20.40.2
    netmask 255.255.255.0
    gateway 10.20.40.1
    dns-nameservers 8.8.8.8
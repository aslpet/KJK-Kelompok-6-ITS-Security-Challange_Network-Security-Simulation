# ========================================================
# IP address RstVPC
# ========================================================
# IP: 10.20.30.2
# Gateway: 10.20.30.1
# ========================================================

# /etc/network/interfaces
auto lo
iface lo inet loopback

auto enp2s0
iface enp2s0 inet static
    address 10.20.30.2
    netmask 255.255.255.0
    gateway 10.20.30.1
    dns-nameservers 8.8.8.8
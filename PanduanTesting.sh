Monitoring Mikrotik Firewall
=================================
This document provides instructions on how to monitor the Mikrotik Firewall using various tools and techniques. 
Monitoring is essential to ensure the firewall is functioning correctly and to identify any potential security threats.

1. Accessing the Mikrotik Firewall
---------------------------------
/log print follow where topics~"firewall"

This command allows you to view real-time logs related to firewall activities. 
You can monitor dropped packets, accepted connections, and other firewall events.

2. SKENARIO 1: UJI KONEKTIVITAS & ISOLASI (Zone-Based Security)
---------------------------------
Tujuan: Membuktikan bahwa "Siapa Boleh ke Mana" berjalan sesuai aturan.

1. Testing Guest (Si Terisolasi)
Aksi: Buka Console GstVPC.

Perintah 1 (Cek Internet): ping 8.8.8.8
Hasil: Reply. (Sukses Internetan).

Perintah 2 (Cek ke Admin): ping 10.20.40.2
Hasil: Timeout / Destination Unreachable. (Sukses Diblokir).

Penjelasan: Guest mencoba masuk ke jaringan Admin tapi diblokir oleh Firewall Rule "Drop All".

2. Testing Mahasiswa (Si Terbatas)
Aksi: Buka Console MhsVPC.

Perintah 1 (Cek ke Server Akademik): ping 10.20.20.2
Hasil: Timeout.

Penjelasan: Ini BENAR. Mahasiswa hanya diizinkan akses Web (TCP Port 80/443), bukan Ping (ICMP). Firewall bekerja membedakan protokol.

3. Testing Admin (Si Super User)
Aksi: Buka Console AdmVPC.

Perintah: ping 10.20.50.2 (Ping ke Guest).
Hasil: Reply.

Penjelasan: Admin memiliki aturan "Full Access" sehingga bisa menembus ke mana saja untuk maintenance.

3. SKENARIO 2: UJI QoS & PERFORMA (Bandwidth Management)
---------------------------------
Tujuan: Membuktikan bahwa Server Akademik tetap ngebut meskipun jaringan macet, dan Guest dibatasi.

1. Cek Limit Bandwidth Guest
Aksi: Buka Console GstVPC.

Perintah: Lakukan ping dengan paket besar terus menerus (Simulasi Download). ping 8.8.8.8 -l 20000 -t
Observasi: Buka Winbox/Terminal Mikrotik, ketik /queue simple print stats.

Hasil: Lihat pada antrian 5_Guest_Public. Trafik akan mentok di angka 1 Mbps (warna merah di Winbox). Latency ping di VPCS mungkin naik tinggi.

2. Cek Prioritas Akademik (Sultan)
Aksi: Saat Guest sedang "Download" (Ping besar tadi), buka Console AdmVPC atau AkdVPC.

Perintah: ping 8.8.8.8
Hasil: Reply Lancar & Stabil.

Penjelasan: Karena Akademik/Admin punya Priority 1 & 2, paket mereka menyalip antrian Guest (Priority 8). Server Akademik dijamin bandwidth 50Mbps.

4. SKENARIO 3: UJI KEAMANAN AKTIF (Port Scan Detection)
---------------------------------
Tujuan: Membuktikan sistem pertahanan adaptif (otomatis mem-blacklist penyerang).
Karena VPCS tidak bisa Nmap, kita simulasi dengan melihat konfigurasi dan log.

1. Aktifkan Monitoring Log
Aksi: Di Terminal Mikrotik, ketik: /log print follow.

2. Simulasi Serangan (Penjelasan Lisan)
Penjelasan: "Misalkan ada penyerang dari IP..."
Tunjukkan Bukti Konfigurasi: Ketik /ip firewall address-list print.
Penjelasan: "IP Penyerang akan otomatis muncul di sini dengan nama port_scanners dan akses internetnya mati total selama 15 menit."

5. SKENARIO 4: UJI IOT CONTAINMENT (Anti-Botnet)
Tujuan: Membuktikan bahwa alat IoT yang kena virus tidak akan menghancurkan jaringan.

1. Cek Rule Pembatas
Aksi: Di Terminal Mikrotik, ketik /ip firewall filter print where comment~"IOT".
Hasil: Muncul rule connection-limit=32,32.

2. Simulasi (Penjelasan Logika)
Penjelasan: "Di zona Riset (10.20.30.0/24), jika ada satu perangkat IoT yang tiba-tiba membuka lebih dari 32 koneksi (tanda-tanda virus botnet melakukan DDoS), paket ke-33 dan seterusnya akan langsung di-DROP oleh router. Ini menjaga jaringan kampus tetap aman dari serangan internal."

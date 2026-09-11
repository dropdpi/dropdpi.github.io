#!/bin/bash
echo "[*] Устанавливаем зависимости и AmneziaWG..."
sudo apt update && sudo apt install -y docker.io docker-compose-v2 qrencode wireguard-tools curl

mkdir -p ~/amneziawg/config
cd ~/amneziawg

# Создаем базовый docker-compose.yml
cat <<EOF > docker-compose.yml
services:
  amneziawg:
    image: ghcr.io/ayastrebov/docker-amneziawg:latest
    container_name: amneziawg
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun:/dev/net/tun
    ports:
      - "51820:51820/udp"
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
      - SERVERURL=$(curl -s4 ifconfig.me)
      - SERVERPORT=51820
      - PEERS=5
      - I1=dropdpi.ink
    volumes:
      - ./config:/config
    sysctls:
      - net.ipv4.ip_forward=1
    restart: unless-stopped
EOF

sudo docker compose up -d
echo "[+] Сервер запущен!"

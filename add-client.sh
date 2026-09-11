#!/bin/bash
if [ -z "$1" ]; then
    echo "Использование: ./add-client.sh <имя_клиента>"
    exit 1
fi

CLIENT_NAME="$1"
CONF_DIR="$HOME/amneziawg/config/wg_confs"
WG_CONF="$CONF_DIR/wg0.conf"
CLIENT_DIR="$HOME/amneziawg/config/$CLIENT_NAME"

mkdir -p "$CLIENT_DIR"

# Генерируем ключи клиента
CLIENT_PRIV=$(wg genkey)
CLIENT_PUB=$(echo "$CLIENT_PRIV" | wg pubkey)
PSK=$(wg genpsk)

# Ищем следующий свободный IP
LAST_IP=$(grep -oE '10\.13\.13\.[0-9]+' "$WG_CONF" | awk -F. '{print $NF}' | sort -n | tail -1)
NEXT_IP=$((LAST_IP + 1))
CLIENT_IP="10.13.13.$NEXT_IP"

# Правильно достаем публичный ключ сервера из его приватного
SERVER_PRIV=$(grep -oP 'PrivateKey\s*=\s*\K.*' "$WG_CONF" | head -1)
SERVER_PUB=$(echo "$SERVER_PRIV" | wg pubkey)
ENDPOINT="$(curl -s4 ifconfig.me):51820"

# Дописываем пир в wg0.conf
cat <<EOF >> "$WG_CONF"

[Peer]
# $CLIENT_NAME
PublicKey = $CLIENT_PUB
PresharedKey = $PSK
AllowedIPs = $CLIENT_IP/32
EOF

# Парсим параметры обфускации
JC=$(grep "Jc" "$WG_CONF" | head -1)
JMIN=$(grep "Jmin" "$WG_CONF" | head -1)
JMAX=$(grep "Jmax" "$WG_CONF" | head -1)
S1=$(grep "S1" "$WG_CONF" | head -1)
S2=$(grep "S2" "$WG_CONF" | head -1)
S3=$(grep "S3" "$WG_CONF" | head -1)
S4=$(grep "S4" "$WG_CONF" | head -1)
H1=$(grep "H1" "$WG_CONF" | head -1)
H2=$(grep "H2" "$WG_CONF" | head -1)
H3=$(grep "H3" "$WG_CONF" | head -1)
H4=$(grep "H4" "$WG_CONF" | head -1)
I1_LINE=$(grep "I1" "$WG_CONF" | head -1)

# Создаем файл конфига для клиента
cat <<EOF > "$CLIENT_DIR/$CLIENT_NAME.conf"
[Interface]
Address = $CLIENT_IP/32
PrivateKey = $CLIENT_PRIV
DNS = 10.13.13.1
$JC
$JMIN
$JMAX
$S1
$S2
$S3
$S4
$H1
$H2
$H3
$H4
$I1_LINE

[Peer]
PublicKey = $SERVER_PUB
PresharedKey = $PSK
Endpoint = $ENDPOINT
AllowedIPs = 0.0.0.0/0, ::/0
EOF

# Мягко обновляем интерфейс без перезапуска всего контейнера
sudo docker exec amneziawg bash -c "awg syncconf wg0 <(awg-quick strip wg0)" >/dev/null 2>&1

echo "[+] Клиент '$CLIENT_NAME' создан! Сканируй QR-код:"
qrencode -t ansiutf8 < "$CLIENT_DIR/$CLIENT_NAME.conf"

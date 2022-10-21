# linode/wireguardreg-one-click.sh by linode
# id: 401706
# description: WireGuard One-Click
# defined fields: name-port-label-port-example-51820-default-51820-name-privateip-label-tunnel-ip-example-1000124-172160124-1921681124-etc-default-1001124-name-peerpubkey-label-wireguard-public-key-client-default-name-privateip_client-label-tunnel-ip-client-example-1000224-172160224-1921681224-etc-default-1001224-name-endpoint-label-endpoint-ip-client-default
# images: ['linode/debian11']
# stats: Used By: 297 + AllTime: 6501
#!/bin/bash

# <UDF name="port" Label="Port" example="51820" default="51820" />
# <UDF name="privateip" Label="Tunnel IP" example="10.0.0.1/24, 172.16.0.1/24, 192.168.1.1/24, etc" Default="10.0.1.1/24" />
# <UDF name="peerpubkey" Label="WireGuard Public Key (Client)" default="" />
# <UDF name="privateip_client" Label="Tunnel IP (Client)" example="10.0.0.2/24, 172.16.0.2/24, 192.168.1.2/24 etc" Default="10.0.1.2/24" />
# <UDF name="endpoint" Label="Endpoint IP (Client)" default="" />

source <ssinclude StackScriptID="401712">

exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1
set -o pipefail

### Set hostname, Apt configuration and update/upgrade

set_hostname
apt_setup_update

apt install wireguard wireguard-tools linux-headers-$(uname -r) -y

if [[ "$PORT" != "51820" ]]; then
  PORT="$PORT"
fi

# Wireguard

wg genkey | tee ~/wg-private.key | wg pubkey > ~/wg-public.key

PRIVATEKEY=`cat ~/wg-private.key`

cat <<END >/etc/wireguard/wg0.conf
[Interface]
PrivateKey = $PRIVATEKEY
Address = $PRIVATEIP
ListenPort = $PORT
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; \
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE; \
ip6tables -A FORWARD -i wg0 -j ACCEPT; \
ip6tables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; \
iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE; \
ip6tables -D FORWARD -i wg0 -j ACCEPT; \
ip6tables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
SaveConfig = true
[Peer]
PublicKey = $PEERPUBKEY
AllowedIPs = $PRIVATEIP_CLIENT
Endpoint = $ENDPOINT:$PORT
END

### Enable Port Forwarding
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sysctl -p /etc/sysctl.conf
sysctl --system

### Services

wg-quick up wg0
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0
wg show
ufw_install
ufw allow "$PORT"/udp
ufw enable

systemctl restart wg-quick@wg0

stackscript_cleanup
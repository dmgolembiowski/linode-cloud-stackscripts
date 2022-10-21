# linode/wireguard-ca.sh by agracie
# id: 348742
# description: 
# defined fields: name-pubkey-label-ssh-key-default-name-port-label-port-example-51820-default-51820-name-privateip-label-tunnel-ip-example-1000124-172160124-1921681124-etc-default-1921682124-name-peerpubkey-label-public-key-client-default-name-privateip_client-label-tunnel-ip-client-example-1000224-172160224-1921681224-etc-default-1921682224-name-endpoint-label-client-endpoint-ip-default
# images: ['linode/debian9']
# stats: Used By: 0 + AllTime: 96
#!/bin/bash

# <UDF name="pubkey" Label="SSH Key" default="" />
# <UDF name="port" Label="Port" example="51820" default="51820" />
# <UDF name="privateip" Label="Tunnel IP" example="10.0.0.1/24, 172.16.0.1/24, 192.168.1.1/24 etc" Default="192.168.2.1/24" />
# <UDF name="peerpubkey" Label="Public Key (Client)" default="" />
# <UDF name="privateip_client" Label="Tunnel IP (Client)" example="10.0.0.2/24, 172.16.0.2/24, 192.168.1.2/24 etc" Default="192.168.2.2/24" />
# <UDF name="endpoint" Label="Client Endpoint IP" default="" />

source <ssinclude StackScriptID="401712">

exec 1> >(tee -a "/var/log/stackscript.log") 2>&1

### Set hostname, Apt configuration and update/upgrade

set_hostname

echo "deb http://deb.debian.org/debian/ unstable main" > \
/etc/apt/sources.list.d/unstable-wireguard.list

printf 'Package: *\nPin: release a=unstable\nPin-Priority: 150\n' > \
/etc/apt/preferences.d/limit-unstable

apt_setup_update
if [[ "$PUBKEY" != "" ]]; then
  add_pubkey
fi

if [[ "$PORT" != "51820" ]]; then
  PORT="$PORT"
fi

apt-get install wireguard -y

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

### Services

wg-quick up wg0
systemctl enable wg-quick@wg0
wg show
ufw_install
ufw allow "$PORT"/udp
ufw allow "$PORT"/tcp
ufw enable

stackscript_cleanup
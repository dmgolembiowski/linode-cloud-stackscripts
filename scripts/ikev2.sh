# linode/ikev2.sh by bobuser
# id: 823029
# description: Creates IKEv2 server.
# defined fields: name-udf_cert_name-label-set-name-for-vpn-certificate-example-vpn-usa-name-udf_vpn_username-label-set-username-for-vpn-connection-name-udf_vpn_password-label-set-password-for-vpn-connection-name-udf_request_id-label-set-request_id-for-callback-name-udf_callback_url-label-set-callback-url-to-send-certificate
# images: ['linode/ubuntu20.04']
# stats: Used By: 0 + AllTime: 110
#!/bin/bash

# User defined variables
# <UDF name="udf_cert_name" label="Set name for VPN certificate" example="VPN USA" />
# <UDF name="udf_vpn_username" label="Set username for VPN connection" />
# <UDF name="udf_vpn_password" label="Set password for VPN connection" />
# <UDF name="udf_request_id" label="Set request_id for callback" />
# <UDF name="udf_callback_url" label="Set callback url to send certificate" />

apt update

mkdir -p /opt/vpnfiles

SERVER_IP=$(ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)

CERT_NAME="$UDF_CERT_NAME"

VPN_USERNAME="$UDF_VPN_USERNAME"
VPN_PASSWORD="$UDF_VPN_PASSWORD"

REQUEST_ID="$UDF_REQUEST_ID"
CALLBACK_URL="$UDF_CALLBACK_URL"

# DEV_INTERFACE=$(ip route show default | awk '/default/ {print $5}')
DEV_INTERFACE="eth0"

# ipsec.conf
cat >/opt/vpnfiles/ipsec.conf <<EOF
config setup
    charondebug="ike 1, knl 1, cfg 0"
    uniqueids=no

conn ikev2-vpn
    auto=add
    compress=no
    type=tunnel
    keyexchange=ikev2
    fragmentation=yes
    forceencaps=yes
    dpdaction=clear
    dpddelay=300s
    rekey=no
    left=%any
    leftid=$SERVER_IP
    leftcert=server-cert.pem
    leftsendcert=always
    leftsubnet=0.0.0.0/0
    right=%any
    rightid=%any
    rightauth=eap-mschapv2
    rightsourceip=10.10.10.0/24
    rightdns=8.8.8.8,8.8.4.4
    rightsendcert=never
    eap_identity=%identity
    ike=chacha20poly1305-sha512-curve25519-prfsha512,aes256gcm16-sha384-prfsha384-ecp384,aes256-sha1-modp1024,aes128-sha1-modp1024,3des-sha1-modp1024!
    esp=chacha20poly1305-sha512,aes256gcm16-ecp384,aes256-sha256,aes256-sha1,3des-sha1!
EOF


# ipsec.secrets
cat >/opt/vpnfiles/ipsec.secrets <<EOF
: RSA "server-key.pem"
$VPN_USERNAME : EAP "$VPN_PASSWORD"
EOF

# ufw.before.rules.1
cat >/opt/vpnfiles/ufw.before.rules.1 <<EOF
*nat
-A POSTROUTING -s 10.10.10.0/24 -o $DEV_INTERFACE -m policy --pol ipsec --dir out -j ACCEPT
-A POSTROUTING -s 10.10.10.0/24 -o $DEV_INTERFACE -j MASQUERADE
COMMIT

*mangle
-A FORWARD --match policy --pol ipsec --dir in -s 10.10.10.0/24 -o $DEV_INTERFACE -p tcp -m tcp --tcp-flags SYN,RST SYN -m tcpmss --mss 1361:1536 -j TCPMSS --set-mss 1360
COMMIT
EOF

# ufw.before.rules.2
cat >/opt/vpnfiles/ufw.before.rules.2 <<EOF
-A ufw-before-forward --match policy --pol ipsec --dir in --proto esp -s 10.10.10.0/24 -j ACCEPT
-A ufw-before-forward --match policy --pol ipsec --dir out --proto esp -d 10.10.10.0/24 -j ACCEPT
EOF

# ufw.sysctl.conf
cat >/opt/vpnfiles/ufw.sysctl.conf <<EOF
net/ipv4/ip_forward=1

net/ipv4/conf/all/accept_redirects=0
net/ipv4/conf/all/send_redirects=0

net/ipv4/ip_no_pmtu_disc=1
EOF

# Step1
groupadd ubuntu
useradd ubuntu -d /home/ubuntu -g ubuntu -m -s /bin/false

apt install -y strongswan strongswan-pki libcharon-extra-plugins libcharon-extauth-plugins libstrongswan-extra-plugins ufw

# Step2
mkdir -p /home/ubuntu/pki/{cacerts,certs,private}
chmod 700 /home/ubuntu/pki
pki --gen --type rsa --size 4096 --outform pem > /home/ubuntu/pki/private/ca-key.pem
pki --self --ca --lifetime 3650 --in /home/ubuntu/pki/private/ca-key.pem --type rsa --dn "CN=$CERT_NAME" --outform pem > /home/ubuntu/pki/cacerts/ca-cert.pem

# Step3
pki --gen --type rsa --size 4096 --outform pem > /home/ubuntu/pki/private/server-key.pem
pki --pub --in /home/ubuntu/pki/private/server-key.pem --type rsa | pki --issue --lifetime 1825 --cacert /home/ubuntu/pki/cacerts/ca-cert.pem --cakey /home/ubuntu/pki/private/ca-key.pem --dn "CN=$SERVER_IP" --san $SERVER_IP --flag serverAuth --flag ikeIntermediate --outform pem >  /home/ubuntu/pki/certs/server-cert.pem
cp -r /home/ubuntu/pki/* /etc/ipsec.d/

chown -R ubuntu:ubuntu /home/ubuntu

# Step4
mv /etc/ipsec.conf{,.original}
cp /opt/vpnfiles/ipsec.conf /etc/ipsec.conf

# Step5
cp /opt/vpnfiles/ipsec.secrets /etc/ipsec.secrets
systemctl restart strongswan-starter

# Step6
# Put content of file /opt/vpnfiles/ufw.before.rules.1 to /etc/ufw/before.rules
# before "*filter"
cp /etc/ufw/before.rules /etc/ufw/before.rules.original

RULES1=$(cat /opt/vpnfiles/ufw.before.rules.1)
CONTENT1=$(awk -v f="$RULES1" '/*filter/{print f; print; next}1' /etc/ufw/before.rules)
echo "$CONTENT1" > /etc/ufw/before.rules

# Put content of file /opt/vpnfiles/ufw.before.rules.2 to /etc/ufw/before.rules
# after ":ufw-not-local - [0:0]"
RULES2=$(cat /opt/vpnfiles/ufw.before.rules.2)
CONTENT2=$(awk -v f="$RULES2" '/:ufw-not-local - \[0:0\]/{print; print f; next}1' /etc/ufw/before.rules)
echo "$CONTENT2" > /etc/ufw/before.rules

ufw allow OpenSSH
ufw --force enable
ufw allow 500,4500/udp

# Step7
PART1=$(cat /opt/vpnfiles/ufw.sysctl.conf)
PART2=$(cat /etc/ufw/sysctl.conf)

echo "$PART1" > /etc/ufw/sysctl.conf
echo "$PART2" >> /etc/ufw/sysctl.conf

ufw disable
ufw --force enable


# Send certificate to callback url

apt install -y python3-venv
pip3 install requests

cat >/home/ubuntu/temp.py <<EOF
import requests
import time

pth = "/home/ubuntu/pki/cacerts/ca-cert.pem"
cert_data = open(pth, "r").read()

url = "$CALLBACK_URL"
headers = {"content-type": "application/json"}


d = {
    "request_id": "$REQUEST_ID",
    "certificate": cert_data
}

# Send certificate to callback url: make 50 attempts
for i in range(50):
    r = requests.post(url, json=d, headers=headers)

    if r.status_code == 204:
        break

    time.sleep(5)

EOF

python3 /home/ubuntu/temp.py
rm /home/ubuntu/temp.py

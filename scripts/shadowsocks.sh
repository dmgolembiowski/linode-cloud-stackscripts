# linode/shadowsocks.sh by burgess
# id: 316709
# description: Debian 9 shadowsocks python bbr.
# defined fields: 
# images: ['linode/debian9']
# stats: Used By: 0 + AllTime: 95
#!/bin/bash

apt-get update
apt-get install -y -qq net-tools curl
curl 'https://raw.githubusercontent.com/shadowsocks/stackscript/master/stackscript.sh?v=4' > /tmp/ss.sh && bash /tmp/ss.sh && rm /tmp/ss.sh

sed -i 's/EVP_CIPHER_CTX_cleanup/EVP_CIPHER_CTX_reset/g' /usr/local/lib/python2.7/dist-packages/shadowsocks/crypto/openssl.py

echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p

supervisorctl restart shadowsocks
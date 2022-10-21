# linode/shadowsocks-libev-with-bbr-on-debian10.sh by linodejs
# id: 420011
# description: shadowsocks-libev with bbr on debian10.
# defined fields: name-shadowsp-label-server-port-example-1568-default-1568-name-shadowlp-label-server-local-port-example-1080-default-1080-name-shadowpw-label-shadowsocks-password-example-114225xx-name-shadowmd-label-shadowsocks-method-example-aes-256-cfb-default-aes-256-cfb-name-shadowto-label-shadowsocks-timeout-example-180
# images: ['linode/debian10']
# stats: Used By: 1 + AllTime: 114
#!/bin/bash
##

#Define some values;
#<UDF name="shadowsp" Label="Server Port" example="1568" default="1568" />
#<UDF name="shadowlp" Label="Server local port" example="1080" default="1080"/>
#<UDF name="shadowpw" Label="Shadowsocks Password" example="114225xx" />
#<UDF name="shadowmd" Label="Shadowsocks method" example="aes-256-cfb" default="aes-256-cfb" />
#<UDF name="shadowto" Label="Shadowsocks timeout" example="180" example="180" />
SHADOWIP=` ip addr show eth0 | grep 'inet ' | cut -f 1 -d '/' | awk '{print $2}' | sed -n '1,1p'`
#SHADOWPD=`dd if=/dev/urandom bs=32 count=1 | md5sum | cut -c-32`
#SHADOWSP=`seq 1083 4567 |  shuf -n 1`
#SHADOWLP=`seq 1083 4567 |  shuf -n 1`
#-----Update system-----
apt-get update && apt-get upgrade

more /etc/debian_version
#Open BBR:
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sudo sysctl -p



#Install shadowsocks
apt install shadowsocks-libev  -y
systemctl enable shadowsocks-libev

#write the config file of shadowsocks
cat <<END >/etc/shadowsocks-libev/config.json
{
"server":"0.0.0.0",
"server_port":"$SHADOWSP",
"local_address": "$SHADOWLIP",
"local_port":"1080",
"password":"$SHADOWPD",
"timeout":"$SHADOWTO",
"method":"$SHADOWMD"
}
END

#Start shadowsocks 
/etc/init.d/shadowsocks-libev stop
/etc/init.d/shadowsocks-libev start
/etc/init.d/shadowsocks-libev force-reload




# linode/install-pptpd.sh by georgecyriac989
# id: 128399
# description: Open vpn installation script
# defined fields: 
# images: ['linode/ubuntu16.04lts', 'linode/ubuntu17.10']
# stats: Used By: 3 + AllTime: 88
#!/bin/bash
apt-get -o Acquire::ForceIPv4=true update
apt-get upgrade
apt-get dist-upgrade
apt-get install net-tools -y #for installing ifconfig
apt-get install pptpd -y
#to resolve issue module load error use this command:      dpkg --configure -a
dpkg --configure -a
echo 'tom pptpd tompassword *' > /etc/ppp/chap-secrets  #creating the default user
IP="$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')"
echo "localip ${IP} " >> /etc/pptpd.conf
echo "remoteip 10.0.0.100-200" >> /etc/pptpd.conf
echo "ms-dns 8.8.8.8" >> /etc/ppp/pptpd-options 
echo "ms-dns 8.8.4.4" >> /etc/ppp/pptpd-options 
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf 
sysctl -p
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE && iptables-save
iptables --table nat --append POSTROUTING --out-interface ppp0 -j MASQUERADE
iptables -I INPUT -s 10.0.0.0/8 -i ppp0 -j ACCEPT
iptables --append FORWARD --in-interface eth0 -j ACCEPT
iptables-save
systemctl enable pptpd
service pptpd restart
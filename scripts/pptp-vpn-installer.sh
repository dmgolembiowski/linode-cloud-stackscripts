# linode/pptp-vpn-installer.sh by embl
# id: 6346
# description: Installs an easy-to-use PPTP VPN solution on your box. See: http://drewsymo.com/networking/vpn/install-ptpp/
# defined fields: name-vpn_user-label-enter-your-vpn-username-default-myuser-example-vpn-user-name-vpn_pass-label-enter-the-password-of-vpn-user-default-sudoninja-example-wackytubeman23x-name-vpn_local-label-enter-the-local-ip-address-of-your-server-default-19216801-texample-10001-name-vpn_remote-label-enter-the-local-ip-address-of-your-home-device-or-range-default-19216801-example-1921680151-200
# images: ['linode/centos6.232bit', 'linode/centos6.2']
# stats: Used By: 0 + AllTime: 88
#!/bin/bash -x

#
# drewsymo/VPN
#
# Installs a PPTP VPN-only system for CentOS
#
# @package VPN 2.0
# @since VPN 1.0
# @author Drew Morris
# @url http://drewsymo.com/networking/vpn/install-ptpp/
#

# Create UDF Options

## VPN Username
#<udf name="vpn_user" label="Enter your VPN Username"
#    default="myuser"
#    example="vpn-user">

## VPN Password
#<udf name="vpn_pass" label="Enter the Password of VPN User"
#    default="sudoninja"
#    example="wackytubeman23x">

## VPN Local IP
#<udf name="vpn_local" label="Enter the Local IP Address of your Server"
#    default="192.168.0.1"
#	example="10.0.0.1">

## VPN Remote IP
#<udf name="vpn_remote" label="Enter the Local IP Address of your Home Device (or range)"
#    default="192.168.0.1"
#    example="192.168.0.151-200">

(

VPN_IP=`curl ipv4.icanhazip.com>/dev/null 2>&1`

yum -y groupinstall "Development Tools"
rpm -Uvh http://poptop.sourceforge.net/yum/stable/rhel6/pptp-release-current.noarch.rpm
yum -y install policycoreutils policycoreutils
yum -y install ppp pptpd
yum -y update

echo "1" > /proc/sys/net/ipv4/ip_forward
sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/sysctl.conf

sysctl -p /etc/sysctl.conf

echo "localip $VPN_LOCAL" >> /etc/pptpd.conf # Local IP address of your VPN server
echo "remoteip $VPN_REMOTE" >> /etc/pptpd.conf # Scope for your home network

echo "ms-dns 8.8.8.8" >> /etc/ppp/options.pptpd # Google DNS Primary
echo "ms-dns 209.244.0.3" >> /etc/ppp/options.pptpd # Level3 Primary
echo "ms-dns 208.67.222.222" >> /etc/ppp/options.pptpd # OpenDNS Primary

echo "$VPN_USER pptpd $VPN_PASS *" >> /etc/ppp/chap-secrets

service iptables start
echo "iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE" >> /etc/rc.local
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
service iptables save
service iptables restart

service pptpd restart

echo -e '\E[37;44m'"\033[1m Installation Log: /var/log/vpn-installer.log \033[0m"
echo -e '\E[37;44m'"\033[1m You can now connect to your VPN via your external IP ($VPN_IP)\033[0m"

echo -e '\E[37;44m'"\033[1m Username: $VPN_USER\033[0m"
echo -e '\E[37;44m'"\033[1m Password: $VPN_PASS\033[0m"

) 2>&1 | tee /var/log/vpn-installer.log
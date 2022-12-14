# linode/easy-squid-proxy-script-password-auth.sh by spiraxcarts123
# id: 660293
# description: Simple script to use server as a proxy server - USERNAME/PASSWORD
# defined fields: 
# images: ['linode/ubuntu16.04lts']
# stats: Used By: 0 + AllTime: 2
#!/bin/bash

apt-get update

sleep 15

clear

apt-get install squid -y
apt-get install apache2-utils -y

rm -rf /etc/squid/squid.conf

touch /etc/squid/squid.conf

echo -e "
forwarded_for off
visible_hostname squid.server.commm

auth_param basic program /usr/lib/squid3/basic_ncsa_auth /etc/squid/squid_passwd
auth_param basic realm proxy
acl authenticated proxy_auth REQUIRED
http_access allow authenticated

# Choose the port you want. Below we set it to default 3128.
http_port 3128

request_header_access Allow allow all
request_header_access Authorization allow all
request_header_access WWW-Authenticate allow all
request_header_access Proxy-Authorization allow all
request_header_access Proxy-Authenticate allow all
request_header_access Cache-Control allow all
request_header_access Content-Encoding allow all
request_header_access Content-Length allow all
request_header_access Content-Type allow all
request_header_access Date allow all
request_header_access Expires allow all
request_header_access Host allow all
request_header_access If-Modified-Since allow all
request_header_access Last-Modified allow all
request_header_access Location allow all
request_header_access Pragma allow all
request_header_access Accept allow all
request_header_access Accept-Charset allow all
request_header_access Accept-Encoding allow all
request_header_access Accept-Language allow all
request_header_access Content-Language allow all
request_header_access Mime-Version allow all
request_header_access Retry-After allow all
request_header_access Title allow all
request_header_access Connection allow all
request_header_access Proxy-Connection allow all
request_header_access User-Agent allow all
request_header_access Cookie allow all
request_header_access All deny all" >> /etc/squid/squid.conf

htpasswd -b -c /etc/squid/squid_passwd username password

service squid restart

clear
change
htpasswd -b -c /etc/squid/squid_passwd username password
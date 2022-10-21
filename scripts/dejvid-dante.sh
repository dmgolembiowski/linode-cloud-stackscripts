# linode/dejvid-dante.sh by filipzmrdak
# id: 1020477
# description: Simple socks5 server
# defined fields: 
# images: ['linode/ubuntu20.04']
# stats: Used By: 0 + AllTime: 75
#!/bin/sh
apt update -y; apt install dante-server -y
rm /etc/danted.conf
echo 'logoutput: syslog' > /etc/danted.conf
echo 'user.privileged: root' >> /etc/danted.conf
echo 'user.unprivileged: nobody' >> /etc/danted.conf
echo '' >> /etc/danted.conf
echo 'internal: 0.0.0.0 port=1080' >> /etc/danted.conf
echo '' >> /etc/danted.conf
echo 'external: eth0' >> /etc/danted.conf
echo '' >> /etc/danted.conf
echo 'socksmethod: none' >> /etc/danted.conf
echo '' >> /etc/danted.conf
echo 'clientmethod: none' >> /etc/danted.conf
echo '' >> /etc/danted.conf
echo 'client pass {' >> /etc/danted.conf
echo '    from: 0.0.0.0/0 to: 0.0.0.0/0' >> /etc/danted.conf
echo '}' >> /etc/danted.conf
echo '' >> /etc/danted.conf
echo 'socks pass {' >> /etc/danted.conf
echo '    from: 0.0.0.0/0 to: 0.0.0.0/0' >> /etc/danted.conf
echo '}' >> /etc/danted.conf
systemctl restart danted.service
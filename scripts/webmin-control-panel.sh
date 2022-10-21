# linode/webmin-control-panel.sh by hmorris
# id: 106107
# description: Install takes about 10-15 minutes
please visit yourip:10000 to visit your webmin
You can watch the install via LISH

https://github.com/hmorris3293/Webmin-Control-Panel
# defined fields: name-ssuser-label-new-user-example-username-name-sspassword-label-new-user-password-example-password-name-hostname-label-hostname-example-examplehost
# images: ['linode/ubuntu16.04lts']
# stats: Used By: 1 + AllTime: 110
#!/bin/bash 
## 
#<UDF name="ssuser" Label="New user" example="username" />
#<UDF name="sspassword" Label="New user password" example="Password" />
#<UDF name="hostname" Label="Hostname" example="examplehost" />

# add sudo user
adduser $SSUSER --disabled-password --gecos "" && \
echo "$SSUSER:$SSPASSWORD" | chpasswd
adduser $SSUSER sudo

hostnamectl set-hostname $HOSTNAME
echo "127.0.0.1   $HOSTNAME" >> /etc/hosts

apt-get -o Acquire::ForceIPv4=true update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o DPkg::options::="--force-confdef" -o DPkg::options::="--force-confold"  install grub-pc
apt-get -o Acquire::ForceIPv4=true update -y

echo 'deb http://download.webmin.com/download/repository sarge contrib' | sudo tee -a /etc/apt/sources.list
echo 'deb http://webmin.mirror.somersettechsolutions.co.uk/repository sarge contrib' | sudo tee -a /etc/apt/sources.list

cd /tmp
wget http://www.webmin.com/jcameron-key.asc
apt-key add jcameron-key.asc -y
apt-get -o Acquire::ForceIPv4=true update -y
apt-get install webmin -y --allow-unauthenticated
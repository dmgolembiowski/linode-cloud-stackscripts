# linode/apostrophe-cms.sh by apostrophecms
# id: 239217
# description: Sets up a CentOS 7 server for Apostrophe CMS hosting. Your server will be ready to set up to receive deployments via [Stagecoach](https://github.com/punkave/stagecoach) and manage sites via [mechanic](https://github.com/punkave/mechanic).


# defined fields: name-password-label-a-password-for-the-non-root-user-nodeapps-used-for-deployment
# images: ['linode/centos7']
# stats: Used By: 7 + AllTime: 97
#!/bin/bash
#<UDF name="password" label="A password for the non-root user, nodeapps, used for deployment.">
# PASSWORD=

exec >/root/stackscript.log 2>&1

user=nodeapps

useradd $user -m -s /bin/bash

# This is safe because there are no other users on the system
# to try to spot this command line when running the stackscript
echo "$user:$PASSWORD" | chpasswd

echo "Configuring stagecoach to run your apps, see:"
echo "https://github.com/punkave/stagecoach"
echo

mkdir -p /opt &&
cd /opt &&
yum install -y git bzip2 &&
git clone https://github.com/punkave/stagecoach &&
mkdir -p /opt/stagecoach/apps &&
chown -R nodeapps.nodeapps /opt/stagecoach/apps &&
cp /opt/stagecoach/settings.example /opt/stagecoach/settings &&
chmod +x /etc/rc.d/rc.local &&
echo -e "cd /opt/stagecoach/bin\nbash sc-start-all\n" >> /etc/rc.d/rc.local &&

echo "Adding nginx via the official nginx.org repo"

rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm
yum install -y nginx
systemctl stop nginx.service

# Run as nodeapps, not nginx, so we can read the same files
# as the command line tasks
perl -pi -e 's/user\s+nginx/user nodeapps/g' /etc/nginx/nginx.conf
mkdir -p /var/lib/nginx
chown -R nodeapps.nodeapps /var/lib/nginx

# Kill default site
perl -pi -e 's/^/#/g' /etc/nginx/conf.d/default.conf

# Right now
systemctl start nginx.service
# On reboot
systemctl enable nginx.service

echo "Adding tools for compiling C++ nodejs extensions and processing images" &&
yum install -y gcc gcc-c++ automake autoconf libtool make ImageMagick &&
( curl -sL https://rpm.nodesource.com/setup_8.x | bash - ) &&
yum install -y nodejs &&
echo "Node installed" &&

echo "Installing MongoDB via the official mongodb repo" &&
cat > /etc/yum.repos.d/mongodb-org-3.4.repo <<EOM
[mongodb-org-3.4]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/7Server/mongodb-org/3.4/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-3.4.asc
EOM

yum install -y mongodb-org &&
echo "Installed MongoDB" &&

systemctl restart mongod.service
# Make sure mongod starts on each boot
systemctl enable mongod.service

echo "Installing 'forever' to restart node apps as needed"
npm install --unsafe-perm -g forever &&

echo "Installing 'mechanic' to manage nginx"
npm install --unsafe-perm -g mechanic

echo "Making sure mongodb stays up"

if [ -f /usr/lib/systemd/system/mongod.service ]; then
  echo "Setting up respawn for mongod"
  mkdir -p /etc/systemd/system/mongod.service.d && cat > /etc/systemd/system/mongod.service.d/restart-always.conf <<EOM
[Service]
Restart=always
RestartSec=5
EOM
  systemctl daemon-reload
fi

# Disable selinux and the firewall, this server is intended as a
# publicly accessible webserver

setenforce 0
# For next boot
perl -pi -e 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config

systemctl stop firewalld
systemctl disable firewalld

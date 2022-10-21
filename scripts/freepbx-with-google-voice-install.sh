# linode/freepbx-with-google-voice-install.sh by chrisrios88
# id: 326569
# description: Installs FreePBX along with Google Voice Support
# defined fields: 
# images: ['linode/centos7']
# stats: Used By: 1 + AllTime: 71
#!/bin/bash
###FreePBX with Google Voice Support Script###
###By: Chris Rios###
###Rev 2###

# This updates the packages on the system from the distribution repositories.
yum update -y
yum upgrade -y

# This section disables SELinux
setenforce 0
sed -i 's/\(^SELINUX=\).*/\SELINUX=disabled/' /etc/sysconfig/selinux
sed -i 's/\(^SELINUX=\).*/\SELINUX=disabled/' /etc/selinux/config

# Add Firewall Rules for HTTP
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --reload

# Install Development Tools

yum -y update
yum -y groupinstall core base "Development Tools"

# Add Asterisk User
adduser asterisk -m -c "Asterisk User"

# This section will install required FreePBX/Asterisk dependencies

yum -y install lynx tftp-server unixODBC mysql-connector-odbc mariadb-server mariadb \
  httpd ncurses-devel sendmail sendmail-cf sox newt-devel libxml2-devel libtiff-devel \
  audiofile-devel gtk2-devel subversion kernel-devel git crontabs cronie \
  cronie-anacron wget vim uuid-devel sqlite-devel net-tools gnutls-devel python-devel texinfo \
  libuuid-devel

# Install PHP 5.6 Repositories

rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm

# Install PHP 5.6w

yum -y remove php*
yum -y install php56w php56w-pdo php56w-mysql php56w-mbstring php56w-pear php56w-process php56w-xml php56w-opcache php56w-ldap php56w-intl php56w-soap

# Install nodeJS

curl -sL https://rpm.nodesource.com/setup_8.x | bash -
yum install -y nodejs

# Enable and start MariaDB

systemctl enable mariadb.service
systemctl start mariadb

# Lock down MySQL

# Make sure that NOBODY can access the server without a password
mysql -e "UPDATE mysql.user SET Password = PASSWORD('CHANGEME') WHERE User = 'root'"
# Kill the anonymous users
mysql -e "DROP USER ''@'localhost'"
# Because our hostname varies we'll use some Bash magic here.
mysql -e "DROP USER ''@'$(hostname)'"
# Kill off the demo database
mysql -e "DROP DATABASE test"
# Make our changes take effect
mysql -e "FLUSH PRIVILEGES"
# Any subsequent tries to run queries this way will get access denied because lack of usr/pwd param

# Enable and Start Apache

systemctl enable httpd.service
systemctl start httpd.service

# Install Legacy Pear Requirements

pear install Console_Getopt

# Install Google Voice Requirements 
cd /usr/src
wget https://github.com/meduketto/iksemel/archive/master.zip -O iksemel-master.zip
unzip iksemel-master.zip
rm -f iksemel-master.zip
cd iksemel-master
./autogen.sh
./configure
make
make install

# Download Asterisk Source

cd /usr/src
wget http://downloads.asterisk.org/pub/telephony/dahdi-linux-complete/dahdi-linux-complete-current.tar.gz
wget http://downloads.asterisk.org/pub/telephony/libpri/libpri-current.tar.gz
wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-14-current.tar.gz
wget -O jansson.tar.gz https://github.com/akheron/jansson/archive/v2.10.tar.gz

# Compile and Install Jansson

cd /usr/src
tar vxfz jansson.tar.gz
rm -f jansson.tar.gz
cd jansson-*
autoreconf -i
./configure --libdir=/usr/lib64
make
make install

# Compile and Install Asterisk

cd /usr/src
tar xvfz asterisk-14-current.tar.gz
rm -f asterisk-14-current.tar.gz
cd asterisk-*
contrib/scripts/install_prereq install
./configure --libdir=/usr/lib64 --with-pjproject-bundled
contrib/scripts/get_mp3_source.sh
make
make install
make config
ldconfig
chkconfig asterisk off

# Set Asterisk permissions

chown asterisk. /var/run/asterisk
chown -R asterisk. /etc/asterisk
chown -R asterisk. /var/{lib,log,spool}/asterisk
chown -R asterisk. /usr/lib64/asterisk
chown -R asterisk. /var/www/

# Add some things to Apache

sed -i 's/\(^upload_max_filesize = \).*/\120M/' /etc/php.ini
sed -i 's/^\(User\|Group\).*/\1 asterisk/' /etc/httpd/conf/httpd.conf
sed -i 's/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf
systemctl restart httpd.service

# Download and Install FreePBX

cd /usr/src
wget http://mirror.freepbx.org/modules/packages/freepbx/freepbx-14.0-latest.tgz
tar xfz freepbx-14.0-latest.tgz
rm -f freepbx-14.0-latest.tgz
cd freepbx
./start_asterisk start
./install -n --dbuser root --dbpass CHANGEME

# Download Motif Module for Google Voice

amportal a ma download https://github.com/FreePBX/motif/archive/master.zip

# Install Motif Module for Google Voice

amportal a ma install motif

# Install All Available Modules

amportal a ma installall

# Upgrade All Installed Modules

amportal a ma upgradeall

# Fix Unsigned Modules

amportal chown
amportal a ma refreshsignatures
amportal a reload

#BAM
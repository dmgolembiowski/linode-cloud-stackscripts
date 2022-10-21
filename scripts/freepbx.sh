# linode/freepbx.sh by ryanc08
# id: 85769
# description: La LA
# defined fields: name-hostname-label-fully-qualified-dns-name-secret-label-secret-for-mysql-and-ami
# images: ['linode/centos6.8']
# stats: Used By: 0 + AllTime: 75
#!/bin/bash
# <UDF NAME="hostname" LABEL="Fully Qualified DNS" />
# <UDF NAME="secret" LABEL="Secret for MySQL and AMI" />


yum -y update
yum -y install mysql-server httpd php-mysql php-gd php-pear-DB php-pear gcc autoconf make vsftpd gpg

touch /etc/yum.repos.d/centos-asterisk.repo
touch /etc/yum.repos.d/centos-digium.repo

echo "[asterisk-tested]" >> /etc/yum.repos.d/centos-asterisk.repo
echo "name=CentOS-\$releasever - Asterisk - Tested" >> /etc/yum.repos.d/centos-asterisk.repo
echo "baseurl=http://packages.asterisk.org/centos/\$releasever/tested/\$basearch/" >> /etc/yum.repos.d/centos-asterisk.repo
echo "enabled=0" >> /etc/yum.repos.d/centos-asterisk.repo
echo "gpgcheck=0" >> /etc/yum.repos.d/centos-asterisk.repo
echo "#gpgkey=http://packages.asterisk.org/RPM-GPG-KEY-Digium" >> /etc/yum.repos.d/centos-asterisk.repo
echo " " >> /etc/yum.repos.d/centos-asterisk.repo
echo "[asterisk-current]" >> /etc/yum.repos.d/centos-asterisk.repo
echo "name=CentOS-\$releasever - Asterisk - Current" >> /etc/yum.repos.d/centos-asterisk.repo
echo "baseurl=http://packages.asterisk.org/centos/\$releasever/current/\$basearch/" >> /etc/yum.repos.d/centos-asterisk.repo
echo "enabled=1" >> /etc/yum.repos.d/centos-asterisk.repo
echo "gpgcheck=0" >> /etc/yum.repos.d/centos-asterisk.repo
echo "#gpgkey=http://packages.asterisk.org/RPM-GPG-KEY-Digium" >> /etc/yum.repos.d/centos-asterisk.repo

echo "[digium-tested]" >> /etc/yum.repos.d/centos-digium.repo
echo "name=CentOS-\$releasever - Digium - Tested" >> /etc/yum.repos.d/centos-digium.repo
echo "baseurl=http://packages.digium.com/centos/\$releasever/tested/\$basearch/" >> /etc/yum.repos.d/centos-digium.repo
echo "enabled=0" >> /etc/yum.repos.d/centos-digium.repo
echo "gpgcheck=0" >> /etc/yum.repos.d/centos-digium.repo
echo "#gpgkey=http://packages.digium.com/RPM-GPG-KEY-Digium" >> /etc/yum.repos.d/centos-digium.repo
echo " " >> /etc/yum.repos.d/centos-digium.repo
echo "[digium-current]" >> /etc/yum.repos.d/centos-digium.repo
echo "name=CentOS-\$releasever - Digium - Current" >> /etc/yum.repos.d/centos-digium.repo
echo "baseurl=http://packages.digium.com/centos/\$releasever/current/\$basearch/" >> /etc/yum.repos.d/centos-digium.repo
echo "enabled=1" >> /etc/yum.repos.d/centos-digium.repo
echo "gpgcheck=0" >> /etc/yum.repos.d/centos-digium.repo
echo "#gpgkey=http://packages.digium.com/RPM-GPG-KEY-Digium" >> /etc/yum.repos.d/centos-digium.repo

yum -y install asterisk18 asterisk18-configs asterisk18-voicemail asterisk18-addons-mysql --skip-broken

cd /usr/src
wget http://downloads.sourceforge.net/project/lame/lame/3.98.4/lame-3.98.4.tar.gz
tar -xzf lame-3.98.4.tar.gz
cd lame-3.98.4
./configure
make && make install

/etc/init.d/httpd start
chkconfig httpd on

/etc/init.d/mysqld start
chkconfig mysqld on

mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'"
mysql -e "DELETE FROM mysql.user WHERE User=''"
mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host!='localhost'"
/usr/bin/mysqladmin -u root password $SECRET
/etc/init.d/mysqld restart

cd /usr/src
wget http://mirror.freepbx.org/freepbx-2.10.0.tar.gz
tar -xzf freepbx-2.10.0.tar.gz
cd freepbx-2.10.0

mysqladmin -u root -p$SECRET create asterisk
mysqladmin -u root -p$SECRET create asteriskcdrdb
mysql -u root -p$SECRET asterisk < SQL/newinstall.sql
mysql -u root -p$SECRET asteriskcdrdb < SQL/cdr_mysql_table.sql
mysql -u root -p$SECRET -e "GRANT ALL PRIVILEGES ON asteriskcdrdb.* TO asteriskuser@localhost IDENTIFIED BY '$SECRET'"
mysql -u root -p$SECRET -e "GRANT ALL PRIVILEGES ON asterisk.* TO asteriskuser@localhost IDENTIFIED BY '$SECRET'"
mysql -u root -p$SECRET -e "flush privileges"

mv /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.backup
sed '231s/.*/User asterisk/' /etc/httpd/conf/httpd.conf.backup > /etc/httpd/conf/httpd.conf
rm -rf /etc/httpd/conf/httpd.conf.backup
mv /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.backup
sed '232s/.*/Group asterisk/' /etc/httpd/conf/httpd.conf.backup > /etc/httpd/conf/httpd.conf

cd /etc
mv /etc/php.ini /etc/php.ini.backup
sed '582s/.*/upload_max_filesize = 8M/' /etc/php.ini.backup > /etc/php.ini
rm /etc/php.ini.backup

/etc/init.d/httpd restart

mv /usr/sbin/safe_asterisk /usr/sbin/safe_asterisk.temp
sed '5s/.*/#TTY=9/' /usr/sbin/safe_asterisk.temp > /usr/sbin/safe_asterisk
rm -rf /usr/sbin/safe_asterisk.temp
mv /usr/sbin/safe_asterisk /usr/sbin/safe_asterisk.temp
sed '6s/.*/CONSOLE=no/' /usr/sbin/safe_asterisk.temp > /usr/sbin/safe_asterisk
chmod 755 /usr/sbin/safe_asterisk
rm -rf /usr/sbin/safe_asterisk.temp


cd /usr/src/freepbx-2.10.0
./start_asterisk start
cp amportal.conf /etc/amportal.conf
./install_amp --username=asteriskuser --password=$SECRET

chown -R asterisk.asterisk /var/lib/asterisk/sounds/custom/
mv /etc/asterisk/sip_notify.conf /etc/asterisk/sip_notify.conf.OLD
rm -f /var/www/html/index.html
touch /var/www/html/index.html
chown asterisk.asterisk /var/www/html/index.html
cat "/usr/local/sbin/amportal start" >> /etc/rc.local

chown -R asterisk.asterisk /var/lib/php/session/
chown -R asterisk.asterisk /var/lib/asterisk/moh/

echo "HOSTNAME=$HOSTNAME" >> /etc/sysconfig/network
hostname "$HOSTNAME"


rm -rf /etc/asterisk/extensions.conf 
ln -s /var/www/html/admin/modules/core/etc/extensions.conf /etc/asterisk/extensions.conf
rm -rf /etc/asterisk/sip.conf
ln -s /var/www/html/admin/modules/core/etc/sip.conf /etc/asterisk/sip.conf
rm -rf /etc/asterisk/iax.conf
ln -s /var/www/html/admin/modules/core/etc/iax.conf /etc/asterisk/iax.conf
rm -rf /etc/asterisk/logger.conf
ln -s /var/www/html/admin/modules/core/etc/logger.conf /etc/asterisk/logger.conf
rm -rf /etc/asterisk/features.conf
ln -s /var/www/html/admin/modules/core/etc/features.conf /etc/asterisk/features.conf
rm -rf /etc/asterisk/ccss.conf
ln -s /var/www/html/admin/modules/campon/etc/ccss.conf /etc/asterisk/ccss.conf
chown -R asterisk.asterisk /etc/asterisk

echo "don't forget to lock down your pbx"
echo "alohatone: http://www.alohatone.com - call us , we can help 808-848-8888"
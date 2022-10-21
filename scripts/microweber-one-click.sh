# linode/microweber-one-click.sh by linode
# id: 1051714
# description: Microweber One-Click
# defined fields: 
# images: ['linode/ubuntu20.04']
# stats: Used By: 27 + AllTime: 153
#!/usr/bin/env bash
# https://github.com/microweber/microweber

set -e

MICROWEBER_INSTALLER_TAG="1.3.0"
WORKING_DIR="/var/www/html"
DOWNLOAD_URL='http://updater.microweberapi.com/builds/master/microweber.zip'

## REQUIRED IN EVERY MARKETPLACE SUBMISSION
# Add Logging to /var/log/stackscript.log for future troubleshooting
exec 1> >(tee -a "/var/log/stackscript.log") 2>&1

## 03-force-ssh-logout.sh
cat >>/etc/ssh/sshd_config <<EOM
Match User root
        ForceCommand echo "Please wait while we get your Microweber ready..."
EOM

systemctl restart ssh

add-apt-repository -y --remove ppa:mc3man/trusty-media
apt-get update -y
##echo "deb http://ppa.launchpad.net/chris-lea/libsodium/ubuntu trusty main" >> /etc/apt/sources.list;
##echo "deb-src http://ppa.launchpad.net/chris-lea/libsodium/ubuntu trusty main" >> /etc/apt/sources.list;
apt-get install -y libsodium-dev
apt install -y lsb-release ca-certificates apt-transport-https software-properties-common
add-apt-repository -y ppa:ondrej/php


# 00-update.sh
DEBIAN_FRONTEND=noninteractive apt-get update -qq >/dev/null
apt install -y apache2 libapache2-mod-php
apt install -y mysql-server
apt install -y php8.1-{bcmath,xml,fpm,mysql,iconv,xsl,zip,intl,ldap,gd,cli,dev,bz2,curl,exif,mbstring,pgsql,sqlite3,tokenizer,opcache,soap,cgi,common,imap,opcache}
apt install -y python3-certbot-apache software-properties-common unzip
apt install -y php-pear
pecl install -f libsodium
sed -i 's/;opcache.enable\s*=.*/opcache.enable=1/g' /etc/php/8.1/cli/php.ini

# 01-fs.sh
cat >/etc/apache2/sites-available/000-default.conf <<EOM
<VirtualHost *:80>
    <Directory /var/www/html>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOM

cat >/etc/update-motd.d/99-one-click <<EOM
#!/usr/bin/env bash
myip=\$(hostname -I | awk '{print\$1}')
cat <<EOF
********************************************************************************

Welcome to Linode's One-Click Microweber server!
To keep this server secure, the UFW firewall is enabled.
All ports are BLOCKED except 22 (SSH), 80 (HTTP), and 443 (HTTPS).
In a web browser, you can view:
 * The Microweber installer: http://\$myip/
On the server:
 * The default web root is located at /var/www/html
 * The MySQL root password is saved at /root/.mysql_password
 * Certbot is preinstalled, to configure HTTPS run:
   > certbot --apache -d example.com -d www.example.com
IMPORTANT:
 * After connecting to the server for the first time, immediately install
   Microweber at http://\$myip/
 * Secure your database by running:
   > mysql_secure_installation
For help and more information visit https://microweber.org
********************************************************************************
To delete this message of the day: rm -rf \$(readlink -f \${0})
EOF
EOM
chmod +x /etc/update-motd.d/99-one-click

cat >/etc/cron.d/microweber <<EOM
* * * * * www-data php /var/www/html/artisan schedule:run -C cron
EOM




# 10-php.sh
cat >/etc/php/8.1/apache2/conf.d/30-microweber.ini <<EOM
log_errors = On
upload_max_filesize = 1500M
post_max_size = 1500M
max_execution_time = 300
memory_limit = 5120M
extension=libsodium.so
opcache.enable=1
EOM

# 11-installer.sh
rm -rf "${WORKING_DIR}"/*
cd $WORKING_DIR
wget -q ${DOWNLOAD_URL} -O /tmp/microweber-latest.zip
unzip -qqo /tmp/microweber-latest.zip -d "${WORKING_DIR}"
touch "${WORKING_DIR}"/installer.lock
rm -f /tmp/microweber-latest.zip
cd $WORKING_DIR

# 12-apache.sh
chown -R www-data: /var/log/apache2
chown -R www-data: /etc/apache2
chown -R www-data: $WORKING_DIR

a2enmod rewrite

# 14-ufw-apache.sh
ufw limit ssh
ufw allow 'Apache Full'
ufw --force enable

# provision.sh
echo $(date -u) ": System provisioning started." >>/var/log/per-instance.log

MYSQL_ROOT_PASS=$(openssl rand -hex 16)
DEBIAN_SYS_MAINT_MYSQL_PASS=$(openssl rand -hex 16)

MICROWEBER_DB_HOST=localhost
MICROWEBER_DB_PORT=3306
MICROWEBER_DB_NAME=microweber
MICROWEBER_DB_USER=microweber
MICROWEBER_DB_PASS=$(openssl rand -hex 16)

cat >/root/.mysql_password <<EOM
MYSQL_ROOT_PASS="${MYSQL_ROOT_PASS}"
EOM

mysql -u root -e "CREATE DATABASE $MICROWEBER_DB_NAME;"
mysql -u root -e "CREATE USER '$MICROWEBER_DB_USER'@'$MICROWEBER_DB_HOST' IDENTIFIED BY '$MICROWEBER_DB_PASS';"
mysql -u root -e "GRANT ALL ON *.* TO '$MICROWEBER_DB_USER'@'$MICROWEBER_DB_HOST';"

mysqladmin -u root -h localhost password $MYSQL_ROOT_PASS

mysql -uroot -p${MYSQL_ROOT_PASS} \
    -e "ALTER USER 'debian-sys-maint'@'localhost' IDENTIFIED BY '$DEBIAN_SYS_MAINT_MYSQL_PASS';"

cat >>/etc/apache2/envvars <<EOM
export MICROWEBER_DB_HOST=${MICROWEBER_DB_HOST}
export MICROWEBER_DB_NAME=${MICROWEBER_DB_NAME}
export MICROWEBER_DB_USER=${MICROWEBER_DB_USER}
export MICROWEBER_DB_PASS=${MICROWEBER_DB_PASS}
export MICROWEBER_DB_PORT=${MICROWEBER_DB_PORT}
EOM

systemctl restart apache2

cat >/etc/mysql/debian.cnf <<EOM
# Automatically generated for Debian scripts. DO NOT TOUCH!
[client]
host     = localhost
user     = debian-sys-maint
password = ${DEBIAN_SYS_MAINT_MYSQL_PASS}
socket   = /var/run/mysqld/mysqld.sock
[mysql_upgrade]
host     = localhost
user     = debian-sys-maint
password = ${DEBIAN_SYS_MAINT_MYSQL_PASS}
socket   = /var/run/mysqld/mysqld.sock
EOM

sed -e '/Match User root/d' \
    -e '/.*ForceCommand.*Microweber.*/d' \
    -i /etc/ssh/sshd_config

systemctl restart ssh

rm -rf "${WORKING_DIR}"/installer.lock

echo $(date -u) ": System provisioning script is complete." >>/var/log/per-instance.log

echo "[OK] Microweber Installer $MICROWEBER_INSTALLER_TAG provisioned!"
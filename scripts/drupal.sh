# linode/drupal.sh by hmorris
# id: 95468
# description: 
# defined fields: name-drupal_admin-label-admin-username-name-drupal_password-label-admin-password-example-an0th3r_s3cure_p4ssw0rd-name-dbroot_password-label-database-root-password-name-db_password-label-database-user-password-name-email-label-e-mail-address-name-domain-label-domain-example-domain-for-your-linode-examplecom-default
# images: ['linode/debian9', 'linode/debian10']
# stats: Used By: 3 + AllTime: 70
#!/bin/bash

# <UDF name="drupal_admin" Label="Admin Username" />
# <UDF name="drupal_password" Label="Admin Password" example="an0th3r_s3cure_p4ssw0rd"/>
# <UDF name="dbroot_password" Label="Database Root Password" />
# <UDF name="db_password" Label="Database User Password" />
# <UDF name="email" Label="E-Mail Address" />
# <UDF name="domain" Label="Domain" example="Domain for your Linode: example.com" default="" />

source <ssinclude StackScriptID="401712">
# Set hostname, apt configuration and update/upgrade

exec 1> >(tee -a "/var/log/stackscript.log") 2>&1

set_hostname
apt_setup_update

if [[ "$DOMAIN" = "" ]]; then
  DOMAIN=`hostname`
else
  sed -i '/linode.com/ s/$/ $DOMAIN/' /etc/hosts
fi

# Install/configure UFW
ufw_install
ufw allow http
ufw allow https
ufw enable
fail2ban_install


# Install/configure MySQL
apt-get install mariadb-server -y
systemctl start mariadb
systemctl enable mariadb
mysql_root_preinstall
run_mysql_secure_installation

mysql -uroot -p"$DBROOT_PASSWORD" -e "CREATE DATABASE drupaldb"
mysql -uroot -p"$DBROOT_PASSWORD" -e "GRANT ALL ON drupaldb.* TO 'drupal'@'localhost' IDENTIFIED BY '$DB_PASSWORD'";
mysql -uroot -p"$DBROOT_PASSWORD" -e "FLUSH PRIVILEGES";

# Install & Configure Apache
apt-get install -y apache2
touch /var/log/apache2/drupal-error_log
touch /var/log/apache2/drupal-access_log
cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/drupal.conf
cat <<END > /etc/apache2/sites-available/drupal.conf
<VirtualHost *:80>
    DocumentRoot /var/www/drupal
    ServerName $DOMAIN
    ServerAlias www.$DOMAIN
    <Directory "/var/www/drupal/">
    Options FollowSymLinks
    AllowOverride All
    Order allow,deny
    allow from all
    RewriteEngine on
    RewriteBase /
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteCond %{REQUEST_URI} !=/favicon.ico
    RewriteRule ^ index.php [L]
</Directory>
    ErrorLog /var/log/apache2/drupal-error_log
    CustomLog /var/log/apache2/drupal-access_log common
</VirtualHost>
END
a2enmod rewrite
a2dissite 000-default.conf
a2ensite drupal.conf
sed -ie "s/KeepAlive Off/KeepAlive On/g" /etc/apache2/apache2.conf
systemctl restart apache2
systemctl enable apache2

# Install PHP
apt-get install php7.3 libapache2-mod-php7.3 php-mysql php-curl php-json php-cgi php-gd php-mbstring php-xml php-xmlrpc -y
CAT <<END > /etc/php/7.3/apache2/php.ini
error_reporting = E_COMPILE_ERROR|E_RECOVERABLE_ERROR|E_ERROR|E_CORE_ERROR
error_log = /var/log/php/error.log
max_input_time = 30
END
mkdir /var/log/php
chown www-data /var/log/php

# Install Drupal
rm -r /var/www/html
cd ~; wget -4 https://www.drupal.org/download-latest/tar.gz
tar -xf tar.gz -C /var/www/ && mv /var/www/drupal* /var/www/drupal
rm tar.gz

# Cleanup
rm /root/StackScript
echo "Installation complete!"

systemctl restart mysql
systemctl restart apache2
stackscript_cleanup
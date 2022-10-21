# linode/drupal-ca.sh by agracie
# id: 349175
# description: Installs Drush and Drupal and creates the site
# defined fields: name-pubkey-label-your-ssh-public-key-default-name-drupal_admin-label-drupal-admin-username-name-drupal_password-label-drupal-admin-password-example-an0th3r_s3cure_p4ssw0rd-name-email-label-email-for-your-drupal-account-name-domain-label-domain-example-domain-for-your-linode-examplecom-default
# images: ['linode/debian9']
# stats: Used By: 0 + AllTime: 73
#!/bin/bash

# Installs Drupal latest and drush

# <UDF name="pubkey" Label="Your SSH public key" default="" />
# <UDF name="drupal_admin" Label="Drupal admin username" />
# <UDF name="drupal_password" Label="Drupal admin password" example="an0th3r_s3cure_p4ssw0rd"/>
# <UDF name="email" Label="Email for your Drupal account" />
# <UDF name="domain" Label="Domain" example="Domain for your Linode: example.com" default="" />

source <ssinclude StackScriptID="349139">

# Set hostname, apt configuration and update/upgrade

exec 1> >(tee -a "/var/log/stackscript.log") 2>&1

set_hostname
apt_setup_update
if [[ "$PUBKEY" != "" ]]; then
  add_pubkey
fi

if [[ "$DOMAIN" = "" ]]; then
  DOMAIN=`hostname`
else
  sed -i '/linode.com/ s/$/ $DOMAIN/' /etc/hosts
fi

apt install haveged -y
DBROOT_PASSWORD=`head -c 32 /dev/random | base64`
# '/=+' are removed for the drush db-url command, they are reserved url characters.
DB_PASSWORD=`head -c 32 /dev/random | base64 | tr -d /=+`

# Install and configure UFW and Fail2ban

ufw_install
ufw allow http
ufw allow https
ufw enable
fail2ban_install

# Set MySQL root password and preform secure installation

mysql_root_preinstall
run_mysql_secure_installation

### Installations

#Install PHP

apt-get install php7.0 php7.0-cli php7.0-curl php7.0-mysql \
php7.0-mcrypt php-pear libapache2-mod-php7.0 php7.0-gd php7.0-common \
php7.0-xml php7.0-zip php-mbstring apache2 mysql-server git unzip sendmail -y

#Install Drush

curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
ln -s /usr/local/bin/composer /usr/bin/composer
git clone https://github.com/drush-ops/drush.git /usr/local/src/drush
cd /usr/local/src/drush
ln -s /usr/local/src/drush/drush /usr/bin/drush
composer install

### Configurations

### PHP

sed -i 's/memory_limit = -1/memory_limit = 512M/g' /etc/php/7.0/cli/php.ini
sed -i 's/;date.timezone =/date.timezone = UTC/g' /etc/php/7.0/cli/php.ini
sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/7.0/cli/php.ini
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 100M/g' /etc/php/7.0/cli/php.ini
sed -i 's/post_max_size = 8M/post_max_size = 100M/g' /etc/php/7.0/cli/php.ini

### MySQL

mysql -uroot -p"$DBROOT_PASSWORD" -e "CREATE DATABASE drupaldb"
mysql -uroot -p"$DBROOT_PASSWORD" -e "GRANT ALL ON drupaldb.* TO 'drupal'@'localhost' IDENTIFIED BY '$DB_PASSWORD'";
mysql -uroot -p"$DBROOT_PASSWORD" -e "FLUSH PRIVILEGES";

### Apache

# Configuration of virtualhost file

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

# Enable Keepalives

sed -ie "s/KeepAlive Off/KeepAlive On/g" /etc/apache2/apache2.conf

# Create log files

touch /var/log/apache2/drupal-error_log
touch /var/log/apache2/drupal-access_log

#Disable the default virtualhost and enable Drupal. Enable Rewrite for CleanUrls.

a2enmod rewrite
a2dissite 000-default.conf
a2ensite drupal.conf

#### Drupal

# Install

rm -r /var/www/html
cd ~; wget -4 https://www.drupal.org/download-latest/tar.gz
tar -xf tar.gz -C /var/www/ && mv /var/www/drupal* /var/www/drupal
rm tar.gz

# Create settings.php and make writable for install,
# Install will automatically set permissions upon completion.

mkdir /var/www/drupal/sites/default/files
chmod a+w /var/www/drupal/sites/default/files
cp /var/www/drupal/sites/default/default.settings.php /var/www/drupal/sites/default/settings.php
chmod a+w /var/www/drupal/sites/default/settings.php

# Create Site

cd /var/www/drupal

drush site-install \
--db-url="mysql://drupal:$DB_PASSWORD@localhost:3306/drupaldb" \
--account-name="$DRUPAL_ADMIN" \
--account-pass="$DRUPAL_PASSWORD" \
--account-mail="$EMAIL" \
--site-name="$DOMAIN" \
--site-mail="admin@$DOMAIN" -y

# Set trusted hosts -- this will show a warning in Drupal if it is not set.

IP=`hostname -i`
PARSED_IP="${IP//\./\\.}"
PARSED_DOMAIN="${DOMAIN//\./\\.}"

cat <<END >> /var/www/drupal/sites/default/settings.php
\$settings['trusted_host_patterns'] = array(
   '^$PARSED_DOMAIN$',
   '^www\.$PARSED_DOMAIN$',
   '^$PARSED_IP$',
 );
END

# Restart services

systemctl restart mysql
systemctl restart apache2
stackscript_cleanup
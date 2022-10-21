# linode/drupal-one-click.sh by linode
# id: 401698
# description: Drupal One-Click
# defined fields: name-soa_email_address-label-e-mail-address-example-your-email-address-name-dbroot_password-label-mysql-root-password-example-an0th3r_s3cure_p4ssw0rd-name-db_password-label-database-password-example-an0th3r_s3cure_p4ssw0rd-name-username-label-the-limited-sudo-user-to-be-created-for-the-linode-default-name-password-label-the-password-for-the-limited-sudo-user-example-an0th3r_s3cure_p4ssw0rd-default-name-pubkey-label-the-ssh-public-key-that-will-be-used-to-access-the-linode-default-name-disable_root-label-disable-root-access-over-ssh-oneof-yesno-default-no-name-token_password-label-your-linode-api-token-this-is-needed-to-create-your-wordpress-servers-dns-records-default-name-subdomain-label-subdomain-example-the-subdomain-for-the-dns-record-www-requires-domain-default-name-domain-label-domain-example-the-domain-for-the-dns-record-examplecom-requires-api-token-default
# images: ['linode/debian11']
# stats: Used By: 77 + AllTime: 1349
#!/usr/bin/env bash

## Drupal Settings
# <UDF name="soa_email_address" label="E-Mail Address" example="Your email address">
# <UDF name="dbroot_password" label="MySQL root Password" example="an0th3r_s3cure_p4ssw0rd">
# <UDF name="db_password" label="Database Password" example="an0th3r_s3cure_p4ssw0rd">

## Linode/SSH Security Settings
#<UDF name="username" label="The limited sudo user to be created for the Linode" default="">
#<UDF name="password" label="The password for the limited sudo user" example="an0th3r_s3cure_p4ssw0rd" default="">
#<UDF name="pubkey" label="The SSH Public Key that will be used to access the Linode" default="">
#<UDF name="disable_root" label="Disable root access over SSH?" oneOf="Yes,No" default="No">

## Domain Settings
#<UDF name="token_password" label="Your Linode API token. This is needed to create your WordPress server's DNS records" default="">
#<UDF name="subdomain" label="Subdomain" example="The subdomain for the DNS record: www (Requires Domain)" default="">
#<UDF name="domain" label="Domain" example="The domain for the DNS record: example.com (Requires API token)" default="">


## Enable logging
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1
set -o pipefail
## Import the Bash StackScript Library
source <ssinclude StackScriptID=1>

## Import the DNS/API Functions Library
source <ssinclude StackScriptID=632759>

## Import the OCA Helper Functions
source <ssinclude StackScriptID=401712>

## Run initial configuration tasks (DNS/SSH stuff, etc...)
source <ssinclude StackScriptID=666912>

# Set hostname, apt configuration and update/upgrade
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

# Install/configure UFW
ufw allow http
ufw allow https

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
touch /var/log/apache2/drupal-error_log /var/log/apache2/drupal-access_log
cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/drupal.conf
cat <<END > /etc/apache2/sites-available/drupal.conf
<VirtualHost *:80>
    DocumentRoot /var/www/drupal
    ServerName $FQDN
    ServerAlias www.$FQDN
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
apt-get install php libapache2-mod-php php-mysql php-curl php-json php-cgi php-gd php-mbstring php-xml php-xmlrpc -y
PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
cat <<END > /etc/php/$PHP_VERSION/apache2/php.ini
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

mkdir /var/www/drupal/sites/default/files
chmod a+w /var/www/drupal/sites/default/files
cp /var/www/drupal/sites/default/default.settings.php /var/www/drupal/sites/default/settings.php
chmod a+w /var/www/drupal/sites/default/settings.php
cat <<END >> /var/www/drupal/sites/default/settings.php
\$settings['trusted_host_patterns'] = [
  '^$FQDN\$',
];
END

# Cleanup
systemctl restart apache2
systemctl restart mysql

# SSL
apt install certbot python3-certbot-apache -y
certbot_ssl "$FQDN" "$SOA_EMAIL_ADDRESS" 'apache'

stackscript_cleanup
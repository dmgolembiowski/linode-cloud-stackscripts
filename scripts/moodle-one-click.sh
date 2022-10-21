# linode/moodle-one-click.sh by linode
# id: 869127
# description: Moodle One-Click
# defined fields: name-admin_password-label-moodle-admin-password-name-soa_email_address-label-moodle-admin-email-name-dbroot_password-label-mysql-root-password-name-db_password-label-moodle-database-user-password-name-token_password-label-your-linode-api-token-this-is-required-in-order-to-create-dns-records-default-name-subdomain-label-the-subdomain-for-the-linodes-dns-record-requires-api-token-default-name-domain-label-the-domain-for-the-linodes-dns-record-requires-api-token-default-name-username-label-the-username-for-the-linodes-adminssh-user-please-ensure-that-the-username-entered-does-not-contain-any-uppercase-characters-example-user1-name-password-label-the-password-for-the-linodes-adminssh-user-example-s3curepsw0rd-name-pubkey-label-the-ssh-public-key-used-to-securely-access-the-linode-via-ssh-default-name-disable_root-label-disable-root-access-over-ssh-oneof-yesno-default-no
# images: ['linode/ubuntu20.04']
# stats: Used By: 86 + AllTime: 678
#!/usr/bin/env bash

### UDF Variables
## Moodle settings
#<UDF name="admin_password" Label="Moodle Admin Password" />
#<UDF name="soa_email_address" Label="Moodle Admin Email" />
#<UDF name="dbroot_password" Label="MySQL Root Password" />
#<UDF name="db_password" Label="Moodle database User password" />

## Domain settings
#<UDF name="token_password" label="Your Linode API token. This is required in order to create DNS records." default="">
#<UDF name="subdomain" label="The subdomain for the Linode's DNS record (Requires API token)" default="">
#<UDF name="domain" label="The domain for the Linode's DNS record (Requires API token)" default="">

## Linode/SSH Security Settings 
#<UDF name="username" label="The username for the Linode's admin/SSH user (Please ensure that the username entered does not contain any uppercase characters)" example="user1">
#<UDF name="password" label="The password for the Linode's admin/SSH user" example="S3cuReP@s$w0rd">

## Linode/SSH Settings - Optional
#<UDF name="pubkey" label="The SSH Public Key used to securely access the Linode via SSH" default="">
#<UDF name="disable_root" label="Disable root access over SSH?" oneOf="Yes,No" default="No">
### Logging and other debugging helpers

# Enable logging for the StackScript
set -o pipefail
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

# Source the Linode Bash StackScript, API, and LinuxGSM Helper libraries
source <ssinclude StackScriptID=1>
source <ssinclude StackScriptID=632759>
source <ssinclude StackScriptID=401712>

# Source and run the New Linode Setup script for DNS/SSH configuration
source <ssinclude StackScriptID=666912>

# System Update
system_update

# Install dependencies 
apt install -y apache2 mysql-client mysql-server php libapache2-mod-php git graphviz aspell ghostscript clamav php7.4-pspell php7.4-curl php7.4-gd php7.4-intl php7.4-mysql php7.4-xml php7.4-xmlrpc php7.4-ldap php7.4-zip php7.4-soap php7.4-mbstring

# Firewall
ufw allow http 
ufw allow https

# Secure MySQL
run_mysql_secure_installation_ubuntu20

# Install Moodle
cd /var/www/html
git clone git://git.moodle.org/moodle.git
cd moodle
git branch --track MOODLE_39_STABLE origin/MOODLE_39_STABLE
git checkout MOODLE_39_STABLE

# Configure Moodle
mkdir /var/moodledata
chmod -R 777 /var/moodledata 
chmod -R 755 /var/www/html/moodle 

mysql -uroot -p"$DBROOT_PASSWORD" -e "CREATE DATABASE moodle DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -uroot -p"$DBROOT_PASSWORD" -e "CREATE USER 'moodle'@'localhost' IDENTIFIED BY '$DB_PASSWORD';";
mysql -uroot -p"$DBROOT_PASSWORD" -e "GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,CREATE TEMPORARY TABLES,DROP,INDEX,ALTER ON moodle.* TO 'moodle'@'localhost';"
mysql -uroot -p"$DBROOT_PASSWORD" -e "FLUSH PRIVILEGES";

cat <<END > /etc/apache2/sites-available/moodle.conf
<VirtualHost *:80>
     ServerAdmin admin@$FQDN
     DocumentRoot /var/www/html/moodle/
     ServerName $FQDN
     ServerAlias www.$FQDN 
     <Directory /var/www/html/moodle/>
        Options +FollowSymlinks
        AllowOverride All
        Require all granted
     </Directory>
     ErrorLog \${APACHE_LOG_DIR}/error.log
     CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
END

a2enmod rewrite
a2ensite moodle.conf
a2dissite 000-default.conf
service apache2 restart

apt install certbot python3-certbot-apache -y
certbot_ssl "$FQDN" "$SOA_EMAIL_ADDRESS" 'apache'

/usr/bin/php admin/cli/install.php --chmod=777 --lang=en_us --wwwroot=https://$FQDN --dataroot=/var/moodledata/ --dbtype=mysqli --dbhost=localhost --dbname=moodle --dbuser=moodle --dbpass=$DB_PASSWORD --dbport=3306 --dbsocket=1 --prefix=mdl_ --fullname=moodle --shortname=moodle --summary="Moodle: Powered By Linode Marketplace" --adminuser=moodle --adminpass="$ADMIN_PASSWORD" --adminemail=$SOA_EMAIL_ADDRESS --upgradekey= --non-interactive --agree-license

chown -R www-data:  /var/www/html/moodle

# Clean up
stackscript_cleanup
# linode/joomla-one-click.sh by linode
# id: 985372
# description: Joomla One-Click
# defined fields: name-soa_email_address-label-email-address-for-the-lets-encrypt-ssl-certificate-example-userdomaintld-name-dbroot_password-label-mysql-root-password-example-s3cur3_9a55w04d-name-dbuser_password-label-mysql-user-password-example-s3cur3_9a55w04d-name-username-label-the-limited-sudo-user-to-be-created-for-the-linode-default-name-password-label-the-password-for-the-limited-sudo-user-example-an0th3r_s3cure_p4ssw0rd-default-name-pubkey-label-the-ssh-public-key-that-will-be-used-to-access-the-linode-default-name-disable_root-label-disable-root-access-over-ssh-oneof-yesno-default-no-name-token_password-label-your-linode-api-token-this-is-needed-to-create-your-wordpress-servers-dns-records-default-name-subdomain-label-subdomain-example-the-subdomain-for-the-dns-record-www-requires-domain-default-name-domain-label-domain-example-the-domain-for-the-dns-record-examplecom-requires-api-token-default
# images: ['linode/ubuntu20.04']
# stats: Used By: 13 + AllTime: 138
#!/bin/bash
## Joomla Settings
#<UDF name="soa_email_address" label="Email address (for the Let's Encrypt SSL certificate)" example="user@domain.tld">
#<UDF name="dbroot_password" label="MySQL Root Password" example="s3cur3_9a55w04d">
#<UDF name="dbuser_password" Label="MySQL User Password" example="s3cur3_9a55w04d"/>

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
set -xo pipefail

# Source the Linode Bash StackScript, API, and OCA Helper libraries
source <ssinclude StackScriptID=1>
source <ssinclude StackScriptID=632759>
source <ssinclude StackScriptID=401712>

# Source and run the New Linode Setup script for DNS/SSH configuration
source <ssinclude StackScriptID=666912>

function lampjoomla {
    apt-get install apache2 mariadb-server php php-common libapache2-mod-php php-cli php-fpm php-mysql php-json php-opcache php-gmp php-curl php-intl php-mbstring php-xmlrpc php-gd php-xml php-zip -y
    PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
    cat <<END > /etc/php/$PHP_VERSION/apache2/php.ini
memory_limit = 512M
upload_max_filesize = 256M
post_max_size = 256M 
max_execution_time = 300
output_buffering = off
display_errors = off
upload_tmp_dir = "/var/www/html/joomla/tmp"
END
}

function databaseconf {
    run_mysql_secure_installation
    mysql -uroot -p$DBROOT_PASSWORD -e "CREATE DATABASE joomla_db;"
    mysql -uroot -p$DBROOT_PASSWORD -e "CREATE USER 'joomla'@'localhost' IDENTIFIED BY '$DBUSER_PASSWORD';"
    mysql -uroot -p$DBROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON joomla_db.* TO 'joomla'@'localhost';"
}

function apachejoomla {
    apt-get install wget unzip -y
    mkdir -p /var/www/html/joomla
    cd /tmp && wget https://downloads.joomla.org/cms/joomla4/4-1-0/Joomla_4-1-0-Stable-Full_Package.zip?format=zip
    unzip Joomla_4* -d /var/www/html/joomla
    chown -R www-data:www-data /var/www/html/joomla 
    chmod -R 755 /var/www/html/joomla
    cat <<END > /etc/apache2/sites-available/joomla.conf
<VirtualHost *:80>
     ServerAdmin $SOA_EMAIL_ADDRESS
      DocumentRoot /var/www/html/joomla
     ServerName $FQDN

     <Directory /var/www/html/joomla>
          Options FollowSymlinks
          AllowOverride All
          Require all granted
     </Directory>

     ErrorLog ${APACHE_LOG_DIR}/$FQDN_error.log
     CustomLog ${APACHE_LOG_DIR}/$FQDN_access.log combined

</VirtualHost>
END
    a2ensite joomla.conf
    a2enmod rewrite
    a2enmod php$PHP_VERSION
    a2dissite 000-default.conf
    systemctl restart apache2

    ufw allow http
    ufw allow https
}
function ssljoomla {
    apt install certbot python3-certbot-apache -y
    certbot_ssl "$FQDN" "$SOA_EMAIL_ADDRESS" 'apache'
}

function main {
    lampjoomla
    databaseconf
    apachejoomla
    ssljoomla
    stackscript_cleanup
}
# Execute script
main
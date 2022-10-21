# linode/lamp-one-click.sh by linode
# id: 401701
# description: LAMP One-Click
# defined fields: name-dbroot_password-label-database-root-password-example-s3cure_p4ssw0rd-name-soa_email_address-label-email-address-for-the-lets-encrypt-ssl-certificate-example-userdomaintld-name-username-label-the-limited-sudo-user-to-be-created-for-the-linode-default-name-password-label-the-password-for-the-limited-sudo-user-example-an0th3r_s3cure_p4ssw0rd-default-name-pubkey-label-the-ssh-public-key-that-will-be-used-to-access-the-linode-default-name-disable_root-label-disable-root-access-over-ssh-oneof-yesno-default-no-name-token_password-label-your-linode-api-token-this-is-needed-to-create-your-wordpress-servers-dns-records-default-name-subdomain-label-subdomain-example-the-subdomain-for-the-dns-record-www-requires-domain-default-name-domain-label-domain-example-the-domain-for-the-dns-record-examplecom-requires-api-token-default
# images: ['linode/debian10', 'linode/debian11', 'linode/ubuntu20.04']
# stats: Used By: 1073 + AllTime: 10206
#!/usr/bin/env bash

## LAMP Settings
#<UDF name="dbroot_password" label="Database Root Password" example="s3cure_p4ssw0rd">
#<UDF name="soa_email_address" label="Email address (for the Let's Encrypt SSL certificate)" example="user@domain.tld">

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
set -o pipefail
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

## Import the Bash StackScript Library
source <ssinclude StackScriptID=1>

## Import the DNS/API Functions Library
source <ssinclude StackScriptID=632759>

## Import the OCA Helper Functions
source <ssinclude StackScriptID=401712>

## Run initial configuration tasks (DNS/SSH stuff, etc...)
source <ssinclude StackScriptID=666912>

# Update system & set hostname & basic security
set_hostname
apt_setup_update
ufw_install
ufw allow http
ufw allow https
fail2ban_install

# Install all services
apt install -y apache2 php libapache2-mod-php php-mysql

# Secure MySQL/MariaDB install
if [ "${detected_distro[distro]}" = 'debian' ]; then  
apt install -y mariadb-server
run_mysql_secure_installation
elif [ "${detected_distro[distro]}" = 'ubuntu' ]; then
apt install -y mysql-server
run_mysql_secure_installation_ubuntu20
else 
echo "Setting this up for the future incase we add more distros"
fi

# Apache configuration
cat <<END > /etc/apache2/sites-available/$FQDN.conf
<VirtualHost *:80>
     ServerAdmin admin@$FQDN
     DocumentRoot /var/www/html/
     ServerName $FQDN
     ServerAlias www.$FQDN 
     <Directory /var/www/html/>
        Options +FollowSymlinks
        AllowOverride All
        Require all granted
     </Directory>
     ErrorLog \${APACHE_LOG_DIR}/error.log
     CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
END

a2enmod rewrite
a2ensite $FQDN.conf
a2dissite 000-default.conf
service apache2 restart

apt install certbot python3-certbot-apache -y
certbot_ssl "$FQDN" "$SOA_EMAIL_ADDRESS" 'apache'

# Stackscript cleanup
stackscript_cleanup
# linode/grav-one-click.sh by linode
# id: 970559
# description: Grav One-Click
# defined fields: name-soa_email_address-label-this-is-the-email-address-for-the-letsencrypt-ssl-certificate-example-userdomaintld-name-username-label-the-limited-sudo-user-to-be-created-for-the-linode-default-name-password-label-the-password-for-the-limited-sudo-user-example-an0th3r_s3cure_p4ssw0rd-default-name-pubkey-label-the-ssh-public-key-that-will-be-used-to-access-the-linode-default-name-disable_root-label-disable-root-access-over-ssh-oneof-yesno-default-no-name-token_password-label-your-linode-api-token-this-is-needed-to-create-your-wordpress-servers-dns-records-default-name-subdomain-label-subdomain-example-the-subdomain-for-the-dns-record-www-requires-domain-default-name-domain-label-domain-example-the-domain-for-the-dns-record-examplecom-requires-api-token-default
# images: ['linode/ubuntu20.04']
# stats: Used By: 29 + AllTime: 193
#!/usr/bin/env bash

## Grav Settings
#<UDF name="soa_email_address" label="This is the Email address for the LetsEncrypt SSL Certificate" example="user@domain.tld">

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

function grav {
    apt-get install -y apache2 php libapache2-mod-php php-mysql mysql-server composer php-curl php-common php-gd php-json php-mbstring php-xml php-zip
    run_mysql_secure_installation_ubuntu20
    cd /var/www/html
    git clone https://github.com/getgrav/grav.git
    cd grav
    chown www-data:www-data -R .
    su -l www-data -s /bin/bash -c "cd /var/www/html/grav && composer install --no-dev -o && bin/grav install && bin/gpm install admin"
    chown www-data:www-data -R .
}

function apache_conf {
    cat <<END > /etc/apache2/sites-available/grav.conf
<VirtualHost *:80>
ServerAdmin $SOA_EMAIL_ADDRESS
DocumentRoot /var/www/html/grav/
ServerName $FQDN
ServerAlias www.$FQDN
<Directory /var/www/html/grav/>
Options FollowSymLinks
AllowOverride All
Order allow,deny
allow from all
</Directory>
ErrorLog /var/log/apache2/$FQDN-error_log
CustomLog /var/log/apache2/$FQDN-access_log common
</VirtualHost>

END
    a2enmod rewrite
    a2ensite grav.conf
    a2dissite 000-default.conf
    service apache2 restart
}

function ssl {
    apt install certbot python3-certbot-apache -y
    certbot_ssl "$FQDN" "$SOA_EMAIL_ADDRESS" 'apache'
}
function firewall {
    ufw allow http
    ufw allow https
}

function main {
    firewall
    grav
    apache_conf
    ssl

}


# execute script
main
stackscript_cleanup
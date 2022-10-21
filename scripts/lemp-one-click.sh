# linode/lemp-one-click.sh by linode
# id: 606691
# description: LEMP Stack
# defined fields: name-dbroot_password-label-database-root-password-example-an0th3r_s3cure_p4ssw0rd-name-soa_email_address-label-email-address-for-the-lets-encrypt-ssl-certificate-example-userdomaintld-name-username-label-the-limited-sudo-user-to-be-created-for-the-linode-default-name-password-label-the-password-for-the-limited-sudo-user-example-an0th3r_s3cure_p4ssw0rd-default-name-pubkey-label-the-ssh-public-key-that-will-be-used-to-access-the-linode-default-name-disable_root-label-disable-root-access-over-ssh-oneof-yesno-default-no-name-token_password-label-your-linode-api-token-this-is-needed-to-create-your-wordpress-servers-dns-records-default-name-subdomain-label-subdomain-example-the-subdomain-for-the-dns-record-www-requires-domain-default-name-domain-label-domain-example-the-domain-for-the-dns-record-examplecom-requires-api-token-default
# images: ['linode/debian11', 'linode/ubuntu20.04']
# stats: Used By: 297 + AllTime: 3365
#!/usr/bin/env bash

## LEMP Settings
#<UDF name="dbroot_password" label="Database Root Password" example="an0th3r_s3cure_p4ssw0rd">
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

function lemp_install {
    apt install -y nginx php-fpm php-mysql
    PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
    sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/$PHP_VERSION/fpm/php.ini
    if [ "${detected_distro[distro]}" = 'debian' ]; then  
    apt install -y mariadb-server
    run_mysql_secure_installation
    elif [ "${detected_distro[distro]}" = 'ubuntu' ]; then
    apt install -y mysql-server
    run_mysql_secure_installation_ubuntu20
    else 
    echo "Distro not supported"
    fi
    cat <<END >/etc/nginx/sites-available/$FQDN
server {
    listen         80;
    listen         [::]:80;
    server_name    $FQDN www.$FQDN;
    root           /var/www/html/$FQDN/public_html;
    index          index.html;
    location / {
      try_files \$uri \$uri/ =404;
    }
    location ~* \.php$ {
      fastcgi_pass unix:/run/php/php$PHP_VERSION-fpm.sock;
      include         fastcgi_params;
      fastcgi_param   SCRIPT_FILENAME    \$document_root\$fastcgi_script_name;
      fastcgi_param   SCRIPT_NAME        \$fastcgi_script_name;
    }
}
END
    ln -s /etc/nginx/sites-available/$FQDN /etc/nginx/sites-enabled/
    unlink /etc/nginx/sites-enabled/default
    nginx -t
    systemctl reload nginx
    systemctl restart php$PHP_VERSION-fpm
    mkdir -p /var/www/html/$FQDN/public_html
    chown -R www-data:www-data /var/www/html/$FQDN/public_html
    cat <<END >/var/www/html/$FQDN/public_html/index.html
<!DOCTYPE html>
<html>
<head>
<style>
body {background-color: #32363B;}
h1   {color: #00B050;}
</style>
</head>
<body>
<h1>LEMP Stack: Powered by Linode Marketplace</h1>
</body>
</html>
END
}

function ssl_lemp {
apt install certbot python3-certbot-nginx -y
certbot_ssl "$FQDN" "$SOA_EMAIL_ADDRESS" 'nginx'
}

function lempfirewall {
  ufw allow http
  ufw allow https

}

function main {
lemp_install
lempfirewall 
ssl_lemp
}    

# Call Functions

ufw allow http
ufw allow https

main
stackscript_cleanup
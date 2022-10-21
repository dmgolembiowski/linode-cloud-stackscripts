# linode/uptime-kuma-one-click.sh by linode
# id: 970523
# description: Uptime Kuma One-Click
# defined fields: name-soa_email_address-label-email-address-for-the-lets-encrypt-ssl-certificate-example-userdomaintld-name-username-label-the-limited-sudo-user-to-be-created-for-the-linode-default-name-password-label-the-password-for-the-limited-sudo-user-example-an0th3r_s3cure_p4ssw0rd-default-name-pubkey-label-the-ssh-public-key-that-will-be-used-to-access-the-linode-default-name-disable_root-label-disable-root-access-over-ssh-oneof-yesno-default-no-name-token_password-label-your-linode-api-token-this-is-needed-to-create-your-wordpress-servers-dns-records-default-name-subdomain-label-subdomain-example-the-subdomain-for-the-dns-record-www-requires-domain-default-name-domain-label-domain-example-the-domain-for-the-dns-record-examplecom-requires-api-token-default
# images: ['linode/ubuntu20.04']
# stats: Used By: 82 + AllTime: 361
#!/bin/bash
## KUMA Settings
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
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1
set -o pipefail

# Source the Linode Bash StackScript, API, and OCA Helper libraries
source <ssinclude StackScriptID=1>
source <ssinclude StackScriptID=632759>
source <ssinclude StackScriptID=401712>

# Source and run the New Linode Setup script for DNS/SSH configuration
source <ssinclude StackScriptID=666912>

## Linode Docker OCA
source <ssinclude StackScriptID=607433>

function kumainstall {
docker volume create uptime-kuma
docker run -d --restart=always -p 3001:3001 -v uptime-kuma:/app/data --name uptime-kuma louislam/uptime-kuma:1
}

function nginxreverse {
    apt-get install nginx -y 
    cat <<END > /etc/nginx/sites-available/$FQDN
server  {
    listen 80;
    server_name    $FQDN;
    error_log /var/log/nginx/$FQDN.error;
    access_log /var/log/nginx/$FQDN.access;
    location / {
        proxy_pass         http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade \$http_upgrade;
        proxy_set_header   Connection "upgrade";
        proxy_set_header   Host \$host;
    }
}
END
    ln -s /etc/nginx/sites-available/$FQDN /etc/nginx/sites-enabled/
    unlink /etc/nginx/sites-enabled/default
    nginx -t
    systemctl reload nginx
    
}

function ssl_lemp {
apt install certbot python3-certbot-nginx -y
certbot_ssl "$FQDN" "$SOA_EMAIL_ADDRESS" 'nginx'
}

function firewall {
    ufw allow http
    ufw allow https
}

function main {
    kumainstall
    firewall
    nginxreverse
    ssl_lemp
}

# Execute script
main
stackscript_cleanup
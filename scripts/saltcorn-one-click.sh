# linode/saltcorn-one-click.sh by linode
# id: 971042
# description: Saltcorn One-Click
# defined fields: name-soa_email_address-label-email-address-for-letsencrypt-ssl-example-userdomaintld-name-username-label-the-limited-sudo-user-to-be-created-for-the-linode-default-name-password-label-the-password-for-the-limited-sudo-user-example-an0th3r_s3cure_p4ssw0rd-default-name-pubkey-label-the-ssh-public-key-that-will-be-used-to-access-the-linode-default-name-disable_root-label-disable-root-access-over-ssh-oneof-yesno-default-no-name-token_password-label-your-linode-api-token-this-is-needed-to-create-your-wordpress-servers-dns-records-default-name-subdomain-label-subdomain-example-the-subdomain-for-the-dns-record-www-requires-domain-default-name-domain-label-domain-example-the-domain-for-the-dns-record-examplecom-requires-api-token-default
# images: ['linode/debian11', 'linode/ubuntu20.04']
# stats: Used By: 6 + AllTime: 118
#!/bin/bash
## Saltcorn Settings
#<UDF name="soa_email_address" label="Email address for Letsencrypt SSL" example="user@domain.tld">

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

function saltcorninstall {
    wget -qO - https://deb.nodesource.com/setup_14.x | sudo bash -
    apt-get install -qqy nodejs
    npx saltcorn-install -y
    systemctl enable saltcorn
    systemctl stop saltcorn
    cat <<END > /lib/systemd/system/saltcorn.service
[Unit]
Description=saltcorn
Documentation=https://saltcorn.com
After=network.target

[Service]
Type=notify
WatchdogSec=5
User=saltcorn
WorkingDirectory=/home/saltcorn
ExecStart=/home/saltcorn/.local/bin/saltcorn serve -p 8080
Restart=always
Environment="NODE_ENV=production"

[Install]
WantedBy=multi-user.target
END
    systemctl daemon-reload
    systemctl start saltcorn
}

function firewallsaltcorn {
    ufw allow 22
    ufw allow 80
    ufw allow 443
}

function nginxreversesaltcorn {
    apt-get install nginx -y
    cat <<END > /etc/nginx/conf.d/saltcorn.conf
server {
    listen 80;
    server_name $FQDN $IP;

    location / {
        proxy_set_header   X-Forwarded-For \$remote_addr;
        proxy_set_header   Host \$http_host;
        proxy_pass         http://localhost:8080;
    }
}
END
    nginx -t
    unlink /etc/nginx/sites-enabled/default
    systemctl restart nginx
}

function ssl_saltcorn {
apt install certbot python3-certbot-nginx -y
certbot_ssl "$FQDN" "$SOA_EMAIL_ADDRESS" 'nginx'
}

function main {
    saltcorninstall
    nginxreversesaltcorn
    firewallsaltcorn
    ssl_saltcorn

}
# Execute
main 
stackscript_cleanup
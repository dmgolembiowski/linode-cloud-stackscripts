# linode/nodejs-one-click.sh by linode
# id: 970561
# description: NodeJS One-Click
# defined fields: name-soa_email_address-label-this-is-the-email-address-for-the-letsencrypt-ssl-certificate-example-userdomaintld-name-username-label-the-limited-sudo-user-to-be-created-for-the-linode-default-name-password-label-the-password-for-the-limited-sudo-user-example-an0th3r_s3cure_p4ssw0rd-default-name-pubkey-label-the-ssh-public-key-that-will-be-used-to-access-the-linode-default-name-disable_root-label-disable-root-access-over-ssh-oneof-yesno-default-no-name-token_password-label-your-linode-api-token-this-is-needed-to-create-your-wordpress-servers-dns-records-default-name-subdomain-label-subdomain-example-the-subdomain-for-the-dns-record-www-requires-domain-default-name-domain-label-domain-example-the-domain-for-the-dns-record-examplecom-requires-api-token-default
# images: ['linode/ubuntu20.04']
# stats: Used By: 146 + AllTime: 830
#!/usr/bin/env bash

## NodeJS Settings
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

function nodejs {
    if [ "${detected_distro[distro]}" = 'debian' ]; then  
    curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
    elif [ "${detected_distro[distro]}" = 'ubuntu' ]; then
    curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
    else 
    echo "Setting this up for the future incase we add more distros"
    fi
    apt-get install -y nodejs
 
    mkdir -p /opt/nodejs
    cat <<END > /opt/nodejs/hello.js
const http = require('http');

const hostname = 'localhost';
const port = 3000;

const server = http.createServer((req, res) => {
  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/plain');
  res.end('Hello World Powered By Linode Marketplace');
});

server.listen(port, hostname, () => {
  console.log(`Server running at http://localhost:3000/`);
});
END
}

function pm2nodejs {
    npm install pm2@latest -g --no-audit
    cd /opt/nodejs/
    pm2 start hello.js
    sleep 5
    pm2 startup systemd
    sleep 5
    pm2 save
}

function nginxnodejs {
    apt-get install nginx -y    
    cat <<END > /etc/nginx/sites-available/$FQDN
server {
    server_name    $FQDN www.$FQDN;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }

}
END
    ln -s /etc/nginx/sites-available/$FQDN /etc/nginx/sites-enabled/
    unlink /etc/nginx/sites-enabled/default
    nginx -t
    systemctl reload nginx
}

function sslnodejs {
    apt install certbot python3-certbot-nginx -y
    certbot_ssl "$FQDN" "$SOA_EMAIL_ADDRESS" 'nginx'
}

function firewallnodejs  {
    ufw allow http
    ufw allow https

}
function main {
    nodejs
    pm2nodejs
    firewallnodejs 
    nginxnodejs 
    sslnodejs 
}

# Execute Script
main
stackscript_cleanup
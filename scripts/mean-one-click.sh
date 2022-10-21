# linode/mean-one-click.sh by linode
# id: 611895
# description: MEAN One-Click
# defined fields: name-soa_email_address-label-email-address-for-ssl-certificate-name-username-label-the-limited-sudo-user-to-be-created-for-the-linode-default-name-password-label-the-password-for-the-limited-sudo-user-example-an0th3r_s3cure_p4ssw0rd-default-name-pubkey-label-the-ssh-public-key-that-will-be-used-to-access-the-linode-default-name-disable_root-label-disable-root-access-over-ssh-oneof-yesno-default-no-name-token_password-label-your-linode-api-token-this-is-needed-to-create-your-wordpress-servers-dns-records-default-name-subdomain-label-subdomain-example-the-subdomain-for-the-dns-record-www-requires-domain-default-name-domain-label-domain-example-the-domain-for-the-dns-record-examplecom-requires-api-token-default
# images: ['linode/ubuntu20.04']
# stats: Used By: 44 + AllTime: 578
#!/usr/bin/env bash

## MEAN Settings
#<UDF name="soa_email_address" label="Email address for SSL certificate">

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

function dependmean {
    apt-get install -y build-essential git fontconfig libpng-dev ruby ruby-dev wget gnupg
    gem install sass
}

function mongoinstall {
    cd && wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add -
    if [ "${detected_distro[distro]}" = 'debian' ]; then  
    echo "deb http://repo.mongodb.org/apt/debian buster/mongodb-org/5.0 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-5.0.list
    elif [ "${detected_distro[distro]}" = 'ubuntu' ]; then
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/5.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-5.0.list
    else 
    echo "Setting this up for the future incase we add more distros"
    fi
    apt-get update -y
    apt-get install -y mongodb-org
    systemctl enable mongod.service
    systemctl start mongod.service
}


function meaninstall {
    apt-get install -y curl software-properties-common
    curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
    apt-get install -y nodejs

    # MEAN APP CONFIGURATION
    cd && mkdir -p /opt/mean
    cd /opt/mean
    cat <<END >> package.json
{
"name" : "mean",
"version": "0.0.1"
}
END
    npm install express --save
    npm install angular
    cat <<END >> server.js
var express = require('express');
var app = express();
var port = 3000;
app.get('/', function(req, res) {
res.send('Hello World Powered By: Linode Marketplace');
});
app.listen(port, function(){
console.log("Listening at port: " + port);
})
END
    # Start App on reboot
    cd && npm install pm2 -g
    pm2 start --name="MEAN_APP" /opt/mean/server.js
    pm2 startup 
    pm2 save
}

function nginxmean {
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

function sslmean {
    apt install certbot python3-certbot-nginx -y
    certbot_ssl "$FQDN" "$SOA_EMAIL_ADDRESS" 'nginx'
}

function firewallmean  {
    ufw allow http
    ufw allow https
}

function main {
    dependmean
    firewallmean
    mongoinstall
    meaninstall
    nginxmean
    sslmean

}

# execute script
main
stackscript_cleanup
# linode/mongodb-one-click.sh by linode
# id: 609195
# description: MongoDB One-Click
# defined fields: name-db_password-label-mongo-password-name-mongoversion-label-mongo-version-oneof-50444240-default-50-name-username-label-the-limited-sudo-user-to-be-created-for-the-linode-default-name-password-label-the-password-for-the-limited-sudo-user-example-an0th3r_s3cure_p4ssw0rd-default-name-pubkey-label-the-ssh-public-key-that-will-be-used-to-access-the-linode-default-name-disable_root-label-disable-root-access-over-ssh-oneof-yesno-default-no-name-token_password-label-your-linode-api-token-this-is-needed-to-create-your-mongodb-servers-dns-records-default-name-subdomain-label-subdomain-example-the-subdomain-for-the-dns-record-www-requires-domain-default-name-domain-label-domain-example-the-domain-for-the-dns-record-examplecom-requires-api-token-default-name-soa_email_address-label-email-address-for-soa-record-default
# images: ['linode/debian11', 'linode/ubuntu20.04']
# stats: Used By: 118 + AllTime: 1376
#!/bin/bash
## Mongo Settings
#<UDF name="db_password" label="Mongo Password" />
#<UDF name="mongoversion" label="Mongo Version"  oneof="5.0,4.4,4.2,4.0"  default="5.0" />

## Linode/SSH Security Settings
#<UDF name="username" label="The limited sudo user to be created for the Linode" default="">
#<UDF name="password" label="The password for the limited sudo user" example="an0th3r_s3cure_p4ssw0rd" default="">
#<UDF name="pubkey" label="The SSH Public Key that will be used to access the Linode" default="">
#<UDF name="disable_root" label="Disable root access over SSH?" oneOf="Yes,No" default="No">

## Domain Settings
#<UDF name="token_password" label="Your Linode API token. This is needed to create your MongoDB server's DNS records" default="">
#<UDF name="subdomain" label="Subdomain" example="The subdomain for the DNS record: www (Requires Domain)" default="">
#<UDF name="domain" label="Domain" example="The domain for the DNS record: example.com (Requires API token)" default="">
#<UDF name="soa_email_address" Label="Email address for soa record" default=""/>

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

source <ssinclude StackScriptID="401712">
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

function mongoinstall {
    apt-get install -y wget gnupg
    if [ $MONGOVERSION == "5.0" ]; then
        wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add -
        echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/5.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-5.0.list
    elif [ $MONGOVERSION == "4.4" ]; then
        wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -
        echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
    elif [ $MONGOVERSION == "4.2" ]; then
        wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -
        echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list
    elif [ $MONGOVERSION == "4.0" ]; then
        wget -qO - https://www.mongodb.org/static/pgp/server-4.0.asc | sudo apt-key add -
        echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.0.list
    fi

    apt-get update -y
    apt-get install -y mongodb-org
    systemctl enable mongod.service
    systemctl start mongod.service
}

function createmongouser {
    echo "Creating Mongo User" & sleep 3
    mongo <<EOF
use admin
db.createUser({user: "admin", pwd: "${DB_PASSWORD}", roles:[{role: "userAdminAnyDatabase", db: "admin"}]})
EOF

}
function main {
    mongoinstall
    createmongouser 
}

main
stackscript_cleanup
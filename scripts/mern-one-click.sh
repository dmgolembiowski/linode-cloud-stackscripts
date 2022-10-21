# linode/mern-one-click.sh by linode
# id: 401702
# description: MERN One-Click
# defined fields: name-username-label-the-limited-sudo-user-to-be-created-for-the-linode-default-name-password-label-the-password-for-the-limited-sudo-user-example-an0th3r_s3cure_p4ssw0rd-default-name-pubkey-label-the-ssh-public-key-that-will-be-used-to-access-the-linode-default-name-disable_root-label-disable-root-access-over-ssh-oneof-yesno-default-no-name-token_password-label-your-linode-api-token-this-is-needed-to-create-your-wordpress-servers-dns-records-default-name-subdomain-label-subdomain-example-the-subdomain-for-the-dns-record-www-requires-domain-default-name-domain-label-domain-example-the-domain-for-the-dns-record-examplecom-requires-api-token-default
# images: ['linode/debian10', 'linode/debian11', 'linode/ubuntu20.04']
# stats: Used By: 74 + AllTime: 1202
#!/usr/bin/env bash

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
ufw allow 3000
fail2ban_install

# Set hostname, configure apt and perform update/upgrade
set_hostname
apt_setup_update

# Install dependencies
apt-get install -y build-essential git 

# Install Mongodb
apt-get install -y wget gnupg
wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add -
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

# Install NodeJS and NPM
apt-get install -y curl software-properties-common
if [ "${detected_distro[distro]}" = 'debian' ]; then  
curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
elif [ "${detected_distro[distro]}" = 'ubuntu' ]; then
curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
else 
echo "Setting this up for the future incase we add more distros"
fi
apt-get install -y nodejs

# Install ExpressJS
npm update -g
npm install --global express
npm link express
npm -g install create-react-app
cd /opt
create-react-app hello-world
npm i --package-lock-only
npm audit fix

# Start App on reboot
cat <<END > /lib/systemd/system/hello-world.service
[Unit]
Description=Hello World React Application Service
Requires=hello-world.service
After=hello-world.service

[Service]
Type=simple
User=root
RemainAfterExit=yes
Restart=on-failure
WorkingDirectory=/opt/hello-world
ExecStart=npm start --host 0.0.0.0 --port=3000

[Install]
WantedBy=multi-user.target
END

systemctl daemon-reload
systemctl start hello-world
systemctl enable hello-world

# Cleanup
stackscript_cleanup
# linode/pritunl-one-click.sh by linode
# id: 925722
# description: Pritunl One-Click
# defined fields: name-username-label-the-limited-sudo-user-to-be-created-for-the-linode-default-name-password-label-the-password-for-the-limited-sudo-user-example-an0th3r_s3cure_p4ssw0rd-default-name-pubkey-label-the-ssh-public-key-that-will-be-used-to-access-the-linode-default-name-disable_root-label-disable-root-access-over-ssh-oneof-yesno-default-no-name-token_password-label-your-linode-api-token-this-is-needed-to-create-your-wordpress-servers-dns-records-default-name-subdomain-label-subdomain-example-the-subdomain-for-the-dns-record-www-requires-domain-default-name-domain-label-domain-example-the-domain-for-the-dns-record-examplecom-requires-api-token-default-name-soa_email_address-label-email-address-for-the-soa-record-default
# images: ['linode/debian10', 'linode/ubuntu20.04']
# stats: Used By: 18 + AllTime: 314
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
#<UDF name="soa_email_address" label="Email address for the SOA record" default="">

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
ufw allow 443
ufw allow 80
fail2ban_install

# Mongo Install
apt-get install -y wget gnupg dirmngr 
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

# Pritunl
apt-key adv --keyserver hkp://keyserver.ubuntu.com --recv E162F504A20CDF15827F718D4B7C549A058F8B6B
apt-key adv --keyserver hkp://keyserver.ubuntu.com --recv 7568D9BB55FF9E5287D586017AE645C0CF8E292A
if [ "${detected_distro[distro]}" = 'debian' ]; then  
echo "deb http://repo.pritunl.com/stable/apt buster main" | tee /etc/apt/sources.list.d/pritunl.list
elif [ "${detected_distro[distro]}" = 'ubuntu' ]; then
echo "deb http://repo.pritunl.com/stable/apt focal main" | tee /etc/apt/sources.list.d/pritunl.list
else 
echo "Setting this up for the future incase we add more distros"
fi

apt update -y
apt install -y pritunl

systemctl enable pritunl.service
systemctl start pritunl.service

# Performance tune
echo "* hard nofile 64000" >> /etc/security/limits.conf
echo "* soft nofile 64000" >> /etc/security/limits.conf
echo "root hard nofile 64000" >> /etc/security/limits.conf
echo "root soft nofile 64000" >> /etc/security/limits.conf

# Cleanup
stackscript_cleanup
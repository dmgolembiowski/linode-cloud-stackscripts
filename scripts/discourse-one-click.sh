# linode/discourse-one-click.sh by linode
# id: 688891
# description: Discourse One-Click
# defined fields: name-token_password-label-your-linode-api-token-this-is-required-in-order-to-create-dns-records-default-name-subdomain-label-the-subdomain-for-the-linodes-dns-record-requires-api-token-default-name-domain-label-the-domain-for-the-linodes-dns-record-requires-api-token-default-name-soa_email_address-label-email-for-admin-account-and-lets-encrypt-certificate-default-name-smtp_address-label-smtp-address-default-name-smtp_email-label-smtp-username-default-name-smtp_password-label-password-for-smtp-user-default-name-username-label-the-limited-sudo-user-to-be-created-for-the-linode-default-name-password-label-the-password-for-the-limited-sudo-user-default-name-pubkey-label-the-ssh-public-key-that-will-be-used-to-access-the-linode-default-name-disable_root-label-disable-root-access-over-ssh-oneof-yesno-default-no
# images: ['linode/ubuntu20.04']
# stats: Used By: 63 + AllTime: 794
#!/bin/bash

## Discourse Settings

#<UDF name="token_password" label="Your Linode API token. This is required in order to create DNS records." default="">
#<UDF name="subdomain" label="The subdomain for the Linode's DNS record (Requires API token)" default="">
#<UDF name="domain" label="The domain for the Linode's DNS record (Requires API token)" default="">
#<UDF name="soa_email_address" label="Email for Admin Account and Lets Encrypt certificate" default="">
#<UDF name="smtp_address" label="SMTP Address" default="">
#<UDF name="smtp_email" label="SMTP Username" default="">
#<UDF name="smtp_password" label="Password for SMTP User" default="">

## Linode/SSH Security Settings
#<UDF name="username" label="The limited sudo user to be created for the Linode" default="">
#<UDF name="password" label="The password for the limited sudo user" default="">
#<UDF name="pubkey" label="The SSH Public Key that will be used to access the Linode" default="">
#<UDF name="disable_root" label="Disable root access over SSH?" oneOf="Yes,No" default="No">

# Source the Bash StackScript Library and the API functions for DNS
source <ssinclude StackScriptID=1>
source <ssinclude StackScriptID=632759>
source <ssinclude StackScriptID=401712>

# Source and run the New Linode Setup script for DNS/SSH configuration
# This also sets some useful variables, like $IP and $FQDN
source <ssinclude StackScriptID=666912>

exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1
set -xo pipefail

#Install dependencies needed for Discourse
apt install git apt-transport-https ca-certificates curl software-properties-common net-tools -y

#Clone Discourse Docker repo for install and management
git clone https://github.com/discourse/discourse_docker.git /var/discourse
#UFW Firewall Rules
ufw allow http
ufw allow https
ufw allow 25
ufw allow 465
ufw allow 587
ufw enable <<EOF
y
EOF

#Change directories to Discourse Repo, and run install script.
cd /var/discourse
./discourse-setup <<EOF

$FQDN
$SOA_EMAIL_ADDRESS
$SMTP_ADDRESS

$SMTP_EMAIL
$SMTP_PASSWORD
$SOA_EMAIL_ADDRESS 
EOF

stackscript_cleanup
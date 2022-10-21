# linode/rocketchat-one-click.sh by linode
# id: 912264
# description: Rocket.Chat One-Click
# defined fields: name-username-label-the-limited-sudo-user-to-be-created-for-the-linode-default-name-password-label-the-password-for-the-limited-sudo-user-example-an0th3r_s3cure_p4ssw0rd-default-name-pubkey-label-the-ssh-public-key-that-will-be-used-to-access-the-linode-default-name-disable_root-label-disable-root-access-over-ssh-oneof-yesno-default-no-name-token_password-label-your-linode-api-token-this-is-needed-to-create-your-wordpress-servers-dns-records-default-name-subdomain-label-subdomain-example-the-subdomain-for-the-dns-record-www-requires-domain-default-name-domain-label-domain-example-the-domain-for-the-dns-record-examplecom-requires-api-token-default-name-soa_email_address-label-email-address-for-the-soa-default
# images: ['linode/ubuntu20.04']
# stats: Used By: 86 + AllTime: 932
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
#<UDF name="soa_email_address" label="Email address for the SOA" default="">

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
ufw allow 3000
fail2ban_install

# Snapd & rocketchat install
apt install snapd -y
snap install rocketchat-server
snap info rocketchat-server

# Check DNS
check_dns_propagation "${FQDN}" "${IP}"
# SSL
snap set rocketchat-server siteurl=https://$FQDN
systemctl enable --now snap.rocketchat-server.rocketchat-caddy 
snap restart rocketchat-server

# Cleanup
stackscript_cleanup
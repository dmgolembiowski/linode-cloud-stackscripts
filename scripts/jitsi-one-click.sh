# linode/jitsi-one-click.sh by linode
# id: 662121
# description: Jitsi One-Click
# defined fields: name-soa_email_address-label-admin-email-for-the-jitsi-server-name-token_password-label-your-linode-api-token-this-is-required-in-order-to-create-dns-records-default-name-subdomain-label-the-subdomain-for-the-linodes-dns-record-requires-api-token-default-name-domain-label-the-domain-for-the-linodes-dns-record-requires-api-token-default-name-username-label-the-limited-sudo-user-to-be-created-for-the-linode-default-name-password-label-the-password-for-the-limited-sudo-user-default-name-pubkey-label-the-ssh-public-key-that-will-be-used-to-access-the-linode-default-name-disable_root-label-disable-root-access-over-ssh-oneof-yesno-default-no
# images: ['linode/ubuntu20.04', 'linode/ubuntu22.04']
# stats: Used By: 155 + AllTime: 3845
#!/bin/bash

## Jitsi Settings
#<UDF name="soa_email_address" label="Admin Email for the Jitsi server">

## Domain Settings
#<UDF name="token_password" label="Your Linode API token. This is required in order to create DNS records." default="">
#<UDF name="subdomain" label="The subdomain for the Linode's DNS record (Requires API token)" default="">
#<UDF name="domain" label="The domain for the Linode's DNS record (Requires API token)" default="">

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
set -o pipefail
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

# dependencies
apt install apt-transport-https gnupg2 curl wget -y
apt-add-repository universe
apt update -y

#Install Nginx
apt install -y nginx
systemctl start nginx
systemctl enable nginx

#Install Jitsi Meet
curl https://download.jitsi.org/jitsi-key.gpg.key | sudo sh -c 'gpg --dearmor > /usr/share/keyrings/jitsi-keyring.gpg'
echo 'deb [signed-by=/usr/share/keyrings/jitsi-keyring.gpg] https://download.jitsi.org stable/' | sudo tee /etc/apt/sources.list.d/jitsi-stable.list > /dev/null

# update all package sources
apt update -y
echo "jitsi-videobridge jitsi-videobridge/jvb-hostname string $FQDN" | debconf-set-selections
echo "jitsi-meet-web-config jitsi-meet/cert-choice select 'Generate a new self-signed certificate (You will later get a chance to obtain a Let's encrypt certificate)'" | debconf-set-selections
apt --option=Dpkg::Options::=--force-confold --option=Dpkg::options::=--force-unsafe-io --assume-yes --quiet install jitsi-meet -y

# Firewall
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 10000/udp
sudo ufw allow 22
sudo ufw allow 3478/udp
sudo ufw allow 5349/tcp
sudo ufw enable

# SSL 
check_dns_propagation "${FQDN}" "${IP}"
/usr/share/jitsi-meet/scripts/install-letsencrypt-cert.sh <<EOF
$SOA_EMAIL_ADDRESS
EOF

# Cleanup
stackscript_cleanup
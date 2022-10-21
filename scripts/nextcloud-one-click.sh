# linode/nextcloud-one-click.sh by linode
# id: 632758
# description: One Click App - Nextcloud
# defined fields: name-username-label-the-limited-sudo-user-to-be-created-for-the-linode-default-name-password-label-the-password-for-the-limited-sudo-user-default-name-pubkey-label-the-ssh-public-key-that-will-be-used-to-access-the-linode-default-name-disable_root-label-disable-root-access-over-ssh-oneof-yesno-default-no-name-token_password-label-your-linode-api-token-this-is-required-for-creating-dns-records-default-name-subdomain-label-the-subdomain-for-the-linodes-dns-record-requires-api-token-default-name-domain-label-the-domain-for-the-linodes-dns-record-requires-api-token-default-name-soa_email_address-label-soa-email-address-default
# images: ['linode/ubuntu22.04']
# stats: Used By: 986 + AllTime: 13007
#!/usr/bin/env bash

## Linode/SSH Security Settings
#<UDF name="username" label="The limited sudo user to be created for the Linode" default="">
#<UDF name="password" label="The password for the limited sudo user" default="">
#<UDF name="pubkey" label="The SSH Public Key that will be used to access the Linode" default="">
#<UDF name="disable_root" label="Disable root access over SSH?" oneOf="Yes,No" default="No">

## Domain Settings
#<UDF name="token_password" label="Your Linode API token. This is required for creating DNS records." default="">
#<UDF name="subdomain" label="The subdomain for the Linode's DNS record (Requires API token)" default="">
#<UDF name="domain" label="The domain for the Linode's DNS record (Requires API token)" default="">
#<UDF name="soa_email_address" label="SOA email address" default="">

## Enable logging
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1
set -xo pipefail

## Import the Bash StackScript Library
source <ssinclude StackScriptID=1>

## Import the DNS/API Functions Library
source <ssinclude StackScriptID=632759>

## Import the OCA Helper Functions
source <ssinclude StackScriptID=401712>

## Run initial configuration tasks (DNS/SSH stuff, etc...)
source <ssinclude StackScriptID=666912>

# Install docker
curl -fsSL get.docker.com | sudo sh

# Adjust permissions
sudo mkdir -p /mnt/ncdata
sudo chown -R 33:0 /mnt/ncdata

# Install Nextcloud
sudo docker run -d \
--name nextcloud-aio-mastercontainer \
--restart always \
-p 80:80 \
-p 8080:8080 \
-p 8443:8443 \
-e NEXTCLOUD_MOUNT=/mnt/ \
-e NEXTCLOUD_DATADIR=/mnt/ncdata \
--volume nextcloud_aio_mastercontainer:/mnt/docker-aio-config \
--volume /var/run/docker.sock:/var/run/docker.sock:ro \
nextcloud/all-in-one:latest

# Some Info
cat << EOF > /etc/motd
 #    #  ######  #    #   #####   ####   #        ####   #    #  #####
 ##   #  #        #  #      #    #    #  #       #    #  #    #  #    #
 # #  #  #####     ##       #    #       #       #    #  #    #  #    #
 #  # #  #         ##       #    #       #       #    #  #    #  #    #
 #   ##  #        #  #      #    #    #  #       #    #  #    #  #    #
 #    #  ######  #    #     #     ####   ######   ####    ####   #####
If you point a domain to this server ($(hostname -I | cut -f1 -d' ')), you can open the admin interface at https://yourdomain.com:8443
Otherwise you can open the admin interface at https://$(hostname -I | cut -f1 -d' '):8080
    
Further documentation is available here: https://github.com/nextcloud/all-in-one
EOF

# firewall
ufw allow 80
ufw allow 443
ufw allow 8080
ufw allow 8443
ufw allow 3478

stackscript_cleanup
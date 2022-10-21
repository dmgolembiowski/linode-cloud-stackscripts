# linode/harbor-one-click.sh by linode
# id: 912262
# description: Harbor One-Click
# defined fields: name-harbor_password-label-the-harbor-admin-password-name-harbor_db_password-label-the-harbor-database-password-name-soa_email_address-label-admin-email-for-the-harbor-server-name-token_password-label-your-linode-api-token-this-is-required-in-order-to-create-dns-records-default-name-subdomain-label-the-subdomain-for-the-linodes-dns-record-requires-api-token-default-name-domain-label-the-domain-for-the-linodes-dns-record-requires-api-token-default-name-username-label-the-limited-sudo-user-to-be-created-for-the-linode-default-name-password-label-the-password-for-the-limited-sudo-user-default-name-pubkey-label-the-ssh-public-key-that-will-be-used-to-access-the-linode-default-name-disable_root-label-disable-root-access-over-ssh-oneof-yesno-default-no
# images: ['linode/debian11', 'linode/ubuntu20.04']
# stats: Used By: 8 + AllTime: 132
#!/bin/bash

## Harbor Settings
#<UDF name="harbor_password" label="The Harbor admin password">
#<UDF name="harbor_db_password" label="The Harbor database password">
#<UDF name="soa_email_address" label="Admin Email for the Harbor server">

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

## Linode Docker OCA
source <ssinclude StackScriptID=607433>

# Logging
set -o pipefail
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

# Installation
ufw_install
ufw allow http
ufw allow https
mkdir -p /data/harbor
curl -s https://api.github.com/repos/goharbor/harbor/releases/latest | grep browser_download_url | cut -d '"' -f 4 | grep '\.tgz$' | wget -i -
tar xvzf harbor-offline-installer*.tgz
cd harbor
cp harbor.yml.tmpl harbor.yml

# SSL
apt install certbot -y
check_dns_propagation "${FQDN}" "${IP}"
certbot certonly --standalone -d $FQDN --preferred-challenges http --agree-tos -n -m $SOA_EMAIL_ADDRESS --keep-until-expiring
# Configure auto-renewal for the certificate
crontab -l > cron
echo "* 1 * * 1 /etc/certbot/certbot renew" >> cron
crontab cron
rm cron

cat <<END > harbor.yml
hostname: $FQDN
http:
  port: 80
https:
  port: 443
  certificate: /etc/letsencrypt/live/$FQDN/fullchain.pem
  private_key: /etc/letsencrypt/live/$FQDN/privkey.pem
harbor_admin_password: $HARBOR_PASSWORD
database:
  password: $HARBOR_DB_PASSWORD
  max_idle_conns: 50
  max_open_conns: 100
data_volume: /data/harbor/
clair:
  updaters_interval: 12
jobservice:
  max_job_workers: 10
notification:
  webhook_job_max_retry: 10
chart:
  absolute_url: disabled
log:
  level: info
  local:
    rotate_count: 50
    rotate_size: 200M
    location: /var/log/harbor
END

# Harbor install
./install.sh

# Configure service file
cat <<END > /etc/systemd/system/harbor.service
[Unit]
Description=Docker Compose Harbor Application Service
Requires=harbor.service
After=harbor.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
ExecReload=/usr/local/bin/docker-compose up -d
WorkingDirectory=/root/harbor/

[Install]
WantedBy=multi-user.target
END

# Enable harbor daemon
systemctl daemon-reload
systemctl enable harbor.service
systemctl start harbor.service

# Clean up
stackscript_cleanup
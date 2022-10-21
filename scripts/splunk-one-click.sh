# linode/splunk-one-click.sh by linode
# id: 869153
# description: Splunk One-Click
# defined fields: name-splunk_user-label-splunk-admin-user-name-splunk_password-label-splunk-admin-password-name-token_password-label-your-linode-api-token-this-is-required-in-order-to-create-dns-records-default-name-subdomain-label-the-subdomain-for-the-linodes-dns-record-requires-api-token-default-name-domain-label-the-domain-for-the-linodes-dns-record-requires-api-token-default-name-soa_email_address-label-admin-email-for-the-server-default-name-username-label-the-username-for-the-linodes-adminssh-user-please-ensure-that-the-username-entered-does-not-contain-any-uppercase-characters-example-user1-default-name-password-label-the-password-for-the-linodes-adminssh-user-example-s3curepsw0rd-default-name-pubkey-label-the-ssh-public-key-used-to-securely-access-the-linode-via-ssh-default-name-disable_root-label-disable-root-access-over-ssh-oneof-yesno-default-no
# images: ['linode/debian10', 'linode/ubuntu20.04']
# stats: Used By: 81 + AllTime: 396
#!/usr/bin/env bash

### UDF Variables

## Splunk settings
#<UDF name="splunk_user" Label="Splunk Admin User" />
#<UDF name="splunk_password" Label="Splunk Admin password" />

## Domain settings
#<UDF name="token_password" label="Your Linode API token. This is required in order to create DNS records." default="">
#<UDF name="subdomain" label="The subdomain for the Linode's DNS record (Requires API token)" default="">
#<UDF name="domain" label="The domain for the Linode's DNS record (Requires API token)" default="">
#<UDF name="soa_email_address" label="Admin Email for the server" default="">

## Linode/SSH Security Settings
#<UDF name="username" label="The username for the Linode's admin/SSH user (Please ensure that the username entered does not contain any uppercase characters)" example="user1" default="">
#<UDF name="password" label="The password for the Linode's admin/SSH user" example="S3cuReP@s$w0rd" default="">

## Linode/SSH Settings - Optional
#<UDF name="pubkey" label="The SSH Public Key used to securely access the Linode via SSH" default="">
#<UDF name="disable_root" label="Disable root access over SSH?" oneOf="Yes,No" default="No">

### Logging and other debugging helpers

# Enable logging for the StackScript
set -xo pipefail
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

# Source the Linode Bash StackScript, API, and OCA Helper libraries
source <ssinclude StackScriptID=1>
source <ssinclude StackScriptID=632759>
source <ssinclude StackScriptID=401712>

# Source and run the New Linode Setup script for DNS/SSH configuration
source <ssinclude StackScriptID=666912>

# Configure Splunk
wget https://download.splunk.com/products/splunk/releases/8.2.0/linux/splunk-8.2.0-e053ef3c985f-Linux-x86_64.tgz
wget 
tar zxvf splunk-8.2.0-e053ef3c985f-Linux-x86_64.tgz -C /opt/
useradd splunk --system --shell=/usr/sbin/nologin
chown -R splunk:splunk /opt/splunk

apt install -y expect
  SPLUNK_INSTALL=$(expect -c "
  set timeout 10
  spawn /opt/splunk/bin/splunk enable boot-start -user splunk -systemd-managed 1 --accept-license
  expect \"Please enter an administrator username:\"
  send \"$SPLUNK_USER\r\"
  expect \"Please enter a new password:\"
  send \"$SPLUNK_PASSWORD\r\"
  expect \"Please confirm new password:\"
  send \"$SPLUNK_PASSWORD\r\"
  expect eof
  ")

# Start daemon
systemctl start Splunkd
systemctl status Splunkd

# Firewall
ufw allow 22 
ufw allow 8000
ufw allow 8089
ufw allow 9997

# Clean up
stackscript_cleanup
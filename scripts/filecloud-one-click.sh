# linode/filecloud-one-click.sh by linode
# id: 691620
# description: FileCloud One-Click
# defined fields: name-token_password-label-your-linode-api-token-this-is-required-in-order-to-create-dns-records-default-name-subdomain-label-the-subdomain-for-the-linodes-dns-record-requires-api-token-default-name-domain-label-the-domain-for-the-linodes-dns-record-requires-api-token-default-name-soa_email_address-label-the-soa-email-for-the-linodes-dns-record-default-name-username-label-the-limited-sudo-user-to-be-created-for-the-linode-default-name-password-label-the-password-for-the-limited-sudo-user-example-an0th3r_s3cure_p4ssw0rd-default-name-pubkey-label-the-ssh-public-key-that-will-be-used-to-access-the-linode-default-name-disable_root-label-disable-root-access-over-ssh-oneof-yesno-default-no
# images: ['linode/ubuntu20.04']
# stats: Used By: 7 + AllTime: 387
#!/bin/bash 

## Domain Settings
#<UDF name="token_password" label="Your Linode API token. This is required in order to create DNS records." default="">
#<UDF name="subdomain" label="The subdomain for the Linode's DNS record (Requires API token)" default="">
#<UDF name="domain" label="The domain for the Linode's DNS record (Requires API token)" default="">
#<UDF name="soa_email_address" label="The SOA email for the Linode's DNS record" default="">

## Linode/SSH Security Settings
#<UDF name="username" label="The limited sudo user to be created for the Linode" default="">
#<UDF name="password" label="The password for the limited sudo user" example="an0th3r_s3cure_p4ssw0rd" default="">
#<UDF name="pubkey" label="The SSH Public Key that will be used to access the Linode" default="">
#<UDF name="disable_root" label="Disable root access over SSH?" oneOf="Yes,No" default="No">

# Source and run the New Linode Setup script for DNS configuration
# This also sets some useful variables, like $IP and $FQDN

source <ssinclude StackScriptID=666912>

# Source the Bash StackScript Library and the API functions for DNS
source <ssinclude StackScriptID=1>
source <ssinclude StackScriptID=632759>
source <ssinclude StackScriptID=401712>

# Add Logging to /var/log/stackscript.log for future troubleshooting
set pipefail -o
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1


# Download FileCloud silent installer script
curl -L -o /tmp/fc-silent.sh https://patch.codelathe.com/tonidocloud/live/installer/fc-silent.sh

# Remove lines to avoid upgrade of packages on Debian/Ubuntu
sed -i -e 's/apt-get upgrade/apt-get update/g' /tmp/fc-silent.sh

# Enable execute permission for the script
chmod +x /tmp/fc-silent.sh

# Allow traffic on ports 80 and 443
ufw allow 80
ufw allow 443


# Execute the installer script
bash /tmp/fc-silent.sh

if [[ "$SSL" == "Yes" ]]; then
    certbot_ssl "$FQDN" "$SOA_EMAIL_ADDRESS" 'apache'
fi

# Cleanup
stackscript_cleanup
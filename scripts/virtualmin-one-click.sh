# linode/virtualmin-one-click.sh by linode
# id: 662117
# description: Virtualmin One-Click
# defined fields: name-username-label-the-limited-sudo-user-to-be-created-for-the-linode-default-name-password-label-the-password-for-the-limited-sudo-user-default-name-pubkey-label-the-ssh-public-key-that-will-be-used-to-access-the-linode-default-name-pwless_sudo-label-enable-passwordless-sudo-access-for-the-limited-user-oneof-yesno-default-no-name-disable_root-label-disable-root-access-over-ssh-oneof-yesno-default-no-name-auto_updates-label-configure-automatic-security-updates-oneof-yesno-default-no-name-fail2ban-label-use-fail2ban-to-prevent-automated-instrusion-attempts-oneof-yesno-default-no-name-token_password-label-your-linode-api-token-this-is-needed-to-create-your-dns-records-default-name-subdomain-label-the-subdomain-for-your-server-default-name-domain-label-your-domain-default-name-soa_email_address-label-admin-email-for-the-server-default-name-mx-label-do-you-need-an-mx-record-for-this-domain-yes-if-sending-mail-from-this-linode-oneof-yesno-default-no-name-spf-label-do-you-need-an-spf-record-for-this-domain-yes-if-sending-mail-from-this-linode-oneof-yesno-default-no
# images: ['linode/debian10']
# stats: Used By: 129 + AllTime: 1685
#!/usr/bin/env bash

### UDF Variables for the StackScript

## Linode/SSH Security Settings
#<UDF name="username" label="The limited sudo user to be created for the Linode" default="">
#<UDF name="password" label="The password for the limited sudo user" default="">
#<UDF name="pubkey" label="The SSH Public Key that will be used to access the Linode" default="">
#<UDF name="pwless_sudo" label="Enable passwordless sudo access for the limited user?" oneOf="Yes,No" default="No">
#<UDF name="disable_root" label="Disable root access over SSH?" oneOf="Yes,No" default="No">
#<UDF name="auto_updates" label="Configure automatic security updates?" oneOf="Yes,No" default="No">
#<UDF name="fail2ban" label="Use fail2ban to prevent automated instrusion attempts?" oneOf="Yes,No" default="No">

## Domain Settings
#<UDF name="token_password" label="Your Linode API token. This is needed to create your DNS records" default="">
#<UDF name="subdomain" label="The subdomain for your server" default="">
#<UDF name="domain" label="Your domain" default="">
#<UDF name="soa_email_address" label="Admin Email for the server" default="">
#<UDF name="mx" label="Do you need an MX record for this domain? (Yes if sending mail from this Linode)" oneOf="Yes,No" default="No">
#<UDF name="spf" label="Do you need an SPF record for this domain? (Yes if sending mail from this Linode)" oneOf="Yes,No" default="No">

# Enable logging for the StackScript
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

IFS=$'\n\t'

## Import the Bash StackScript and API/DNS Libraries
source <ssinclude StackScriptID=1>
source <ssinclude StackScriptID=632759>

# Import the OCA Helper Functions
source <ssinclude StackScriptID=401712>

function install_virtualmin {
    if [ $(cat /etc/os-release | grep -i 'ubuntu' )]; then
        if [ ! $(cat /etc/os-release | grep -i 'lts') ]; then
            printf "Virtualmin only works with LTS versions of Ubuntu\n"
            exit 1;
        fi
    else
        curl -O http://software.virtualmin.com/gpl/scripts/install.sh && {
            chmod +x install.sh
            ./install.sh
        }
    fi
}

## Run initial configuration tasks (DNS/SSH stuff, etc...)
source <ssinclude StackScriptID=666912>

## Configure firewall and install Fail2Ban
ufw_install
ufw allow http
ufw allow https
ufw allow 10000
fail2ban_install

# Install Webmin and Virtualmin
source <ssinclude StackScriptID=662116>
install_virtualmin

# Disable SSL so that everything works
sed -i 's/^ssl=1/ssl=0/g' /etc/webmin/miniserv.conf

# Restart Webmin
systemctl restart webmin

# Clean up
stackscript_cleanup
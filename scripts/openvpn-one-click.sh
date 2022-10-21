# linode/openvpn-one-click.sh by linode
# id: 401719
# description: OpenVPN OCA Debian 11 & ubuntu 20
# defined fields: name-username-label-the-limited-sudo-user-to-be-created-for-the-linode-default-name-password-label-the-password-for-the-limited-sudo-user-default-name-pubkey-label-the-ssh-public-key-that-will-be-used-to-access-the-linode-default-name-disable_root-label-disable-root-access-over-ssh-oneof-yesno-default-no-name-token_password-label-your-linode-api-token-this-is-required-for-creating-dns-records-default-name-subdomain-label-the-subdomain-for-the-linodes-dns-record-requires-api-token-default-name-domain-label-the-domain-for-the-linodes-dns-record-requires-api-token-default-name-soa_email_address-label-admin-email-for-the-server-default
# images: ['linode/debian11', 'linode/ubuntu20.04']
# stats: Used By: 1768 + AllTime: 28040
#!/bin/bash
## Linode/SSH Security Settings
#<UDF name="username" label="The limited sudo user to be created for the Linode" default="">
#<UDF name="password" label="The password for the limited sudo user" default="">
#<UDF name="pubkey" label="The SSH Public Key that will be used to access the Linode" default="">
#<UDF name="disable_root" label="Disable root access over SSH?" oneOf="Yes,No" default="No">

## Domain Settings
#<UDF name="token_password" label="Your Linode API token. This is required for creating DNS records." default="">
#<UDF name="subdomain" label="The subdomain for the Linode's DNS record (Requires API token)" default="">
#<UDF name="domain" label="The domain for the Linode's DNS record (Requires API token)" default="">
#<UDF name="soa_email_address" label="Admin Email for the server" default="">

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

## Install OpenVPN dependencies
apt update && apt -y install ca-certificates wget net-tools gnupg
if [ "${detected_distro[distro]}" = 'debian' ]; then  
wget -qO - https://as-repository.openvpn.net/as-repo-public.gpg | apt-key add -
echo "deb http://as-repository.openvpn.net/as/debian bullseye main">/etc/apt/sources.list.d/openvpn-as-repo.list
elif [ "${detected_distro[distro]}" = 'ubuntu' ]; then
wget -qO - https://as-repository.openvpn.net/as-repo-public.gpg | apt-key add -
echo "deb http://as-repository.openvpn.net/as/debian focal main">/etc/apt/sources.list.d/openvpn-as-repo.list
else 
echo "Distro Not Supported"
fi

## Apt Update & Install OpenVPN
apt update -y && apt -y install openvpn-as

# UFW install
ufw_install
ufw allow 1194/udp
sed -ie "s/DEFAULT_FORWARD_POLICY=\"DROP\"/DEFAULT_FORWARD_POLICY=\"ACCEPT\"/g" /etc/default/ufw

# Cleanup
stackscript_cleanup

# Adding to display default password as last line in LISH console
sleep 3
cat /usr/local/openvpn_as/init.log | grep 'To login'; echo "(password can be changed on Admin UI)"
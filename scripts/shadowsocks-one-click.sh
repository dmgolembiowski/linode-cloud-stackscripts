# linode/shadowsocks-one-click.sh by linode
# id: 604068
# description: Shadowsocks One-Click
# defined fields: name-shadowpassword-label-shadowsocks-password-example-password-name-username-label-the-limited-sudo-user-to-be-created-for-the-linode-default-name-password-label-the-password-for-the-limited-sudo-user-example-an0th3r_s3cure_p4ssw0rd-default-name-pubkey-label-the-ssh-public-key-that-will-be-used-to-access-the-linode-default-name-disable_root-label-disable-root-access-over-ssh-oneof-yesno-default-no-name-token_password-label-your-linode-api-token-this-is-needed-to-create-your-linodes-dns-records-default-name-subdomain-label-subdomain-example-the-subdomain-for-the-dns-record-www-requires-domain-default-name-domain-label-domain-example-the-domain-for-the-dns-record-examplecom-requires-api-token-default-name-soa_email_address-label-email-address-for-soa-recorf-default
# images: ['linode/ubuntu20.04']
# stats: Used By: 133 + AllTime: 5625
#!/usr/bin/env bash

#<UDF name="shadowpassword" Label="Shadowsocks Password" example="Password" />

## Linode/SSH Security Settings
#<UDF name="username" label="The limited sudo user to be created for the Linode" default="">
#<UDF name="password" label="The password for the limited sudo user" example="an0th3r_s3cure_p4ssw0rd" default="">
#<UDF name="pubkey" label="The SSH Public Key that will be used to access the Linode" default="">
#<UDF name="disable_root" label="Disable root access over SSH?" oneOf="Yes,No" default="No">

## Domain Settings
#<UDF name="token_password" label="Your Linode API token. This is needed to create your Linode's DNS records" default="">
#<UDF name="subdomain" label="Subdomain" example="The subdomain for the DNS record: www (Requires Domain)" default="">
#<UDF name="domain" label="Domain" example="The domain for the DNS record: example.com (Requires API token)" default="">
#<UDF name="soa_email_address" label="Email address for SOA Recorf" default="">

## Enable logging
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1
set -o pipefail
## Import the Bash StackScript Library
source <ssinclude StackScriptID=1>

## Import the DNS/API Functions Library
source <ssinclude StackScriptID=632759>

## Import the OCA Helper Functions
source <ssinclude StackScriptID=401712>

## Run initial configuration tasks (DNS/SSH stuff, etc...)
source <ssinclude StackScriptID=666912>

# Install & configure shadowsocks
function install_shadowsocks {
    apt-get install shadowsocks-libev -y
    cat <<END >/etc/shadowsocks-libev/config.json
{
"server":"$IP",
"server_port":8000,
"local_port":1080,
"password":"$SHADOWPASSWORD",
"timeout":60,
"method":"aes-256-gcm"
}
END
    systemctl start shadowsocks-libev
    systemctl enable shadowsocks-libev
    systemctl restart shadowsocks-libev
}

function shadowsocks_firewall {
    ufw allow 8000
}

function main {
    install_shadowsocks
    shadowsocks_firewall
    stackscript_cleanup
}

# Execute function
main
# linode/pi-hole-one-click.sh by linode
# id: 970522
# description: Pi-hole One-Click
# defined fields: name-pihole_password-label-pihole-user-password-name-username-label-the-limited-sudo-user-to-be-created-for-the-linode-default-name-password-label-the-password-for-the-limited-sudo-user-example-an0th3r_s3cure_p4ssw0rd-default-name-pubkey-label-the-ssh-public-key-that-will-be-used-to-access-the-linode-default-name-disable_root-label-disable-root-access-over-ssh-oneof-yesno-default-no-name-token_password-label-your-linode-api-token-this-is-needed-to-create-your-wordpress-servers-dns-records-default-name-subdomain-label-subdomain-example-the-subdomain-for-the-dns-record-www-requires-domain-default-name-domain-label-domain-example-the-domain-for-the-dns-record-examplecom-requires-api-token-default-name-soa_email_address-label-this-is-the-email-address-for-the-soa-record-default
# images: ['linode/ubuntu20.04']
# stats: Used By: 199 + AllTime: 1672
#!/usr/bin/env bash

## PIHOLE Settings
#<UDF name="pihole_password" label="PIHOLE USER Password">

## Linode/SSH Security Settings
#<UDF name="username" label="The limited sudo user to be created for the Linode" default="">
#<UDF name="password" label="The password for the limited sudo user" example="an0th3r_s3cure_p4ssw0rd" default="">
#<UDF name="pubkey" label="The SSH Public Key that will be used to access the Linode" default="">
#<UDF name="disable_root" label="Disable root access over SSH?" oneOf="Yes,No" default="No">

## Domain Settings
#<UDF name="token_password" label="Your Linode API token. This is needed to create your WordPress server's DNS records" default="">
#<UDF name="subdomain" label="Subdomain" example="The subdomain for the DNS record: www (Requires Domain)" default="">
#<UDF name="domain" label="Domain" example="The domain for the DNS record: example.com (Requires API token)" default="">
#<UDF name="soa_email_address" label="This is the Email address for the SOA record" default="">

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

IPV4=$(ip a | awk '/inet / {print $2}'| sed -n '2 p')
IPV6=$(ip -6 a | grep inet6 | awk '/global/{print $2}' | cut -d/ -f1)
GENPIHOLEPASSWD=$(echo -n $PIHOLE_PASSWORD | sha256sum | awk '{printf "%s",$1 }' | sha256sum)
PIHOLE_PASSWD=${GENPIHOLEPASSWD:0:-1}

function firewall {
    ufw allow 80
    ufw allow 53
    ufw allow 67
    ufw allow 547
    ufw allow 4711
}

function config_pihole {
    mkdir -p /etc/pihole
    cat <<END > /etc/pihole/setupVars.conf
PIHOLE_INTERFACE=eth0
IPV4_ADDRESS=$IPV4
IPV6_ADDRESS=$IPV6
PIHOLE_DNS_1=8.8.8.8
PIHOLE_DNS_2=8.8.4.4
QUERY_LOGGING=true
INSTALL_WEB_SERVER=true
INSTALL_WEB_INTERFACE=true
LIGHTTPD_ENABLED=true
CACHE_SIZE=10000
DNS_FQDN_REQUIRED=true
DNS_BOGUS_PRIV=true
DNSMASQ_LISTENING=local
WEBPASSWORD=$PIHOLE_PASSWD
BLOCKING_ENABLED=true
END

curl -L https://install.pi-hole.net | bash /dev/stdin --unattended
}

function main {
    config_pihole
    firewall
}

# Execute script
apt_setup_update
main
stackscript_cleanup
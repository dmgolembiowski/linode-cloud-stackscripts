# linode/unifi-network-application-one-click.sh by linode
# id: 1051711
# description: UniFi Network Application One-Click
# defined fields: name-soa_email_address-label-email-address-for-the-lets-encrypt-ssl-certificate-example-userdomaintld-name-username-label-the-limited-sudo-user-to-be-created-for-the-linode-default-name-password-label-the-password-for-the-limited-sudo-user-example-an0th3r_s3cure_p4ssw0rd-default-name-pubkey-label-the-ssh-public-key-that-will-be-used-to-access-the-linode-default-name-disable_root-label-disable-root-access-over-ssh-oneof-yesno-default-no-name-token_password-label-your-linode-api-token-this-is-needed-to-create-your-linodes-dns-records-default-name-subdomain-label-subdomain-example-the-subdomain-for-the-dns-record-www-requires-domain-default-name-domain-label-domain-example-the-domain-for-the-dns-record-examplecom-requires-api-token-default
# images: ['linode/debian9']
# stats: Used By: 12 + AllTime: 119
#!/bin/bash
#
# Script to install UniFi Controller on Linode
# <UDF name="soa_email_address" label="Email address (for the Let's Encrypt SSL certificate)" example="user@domain.tld">
## Linode/SSH Security Settings
#<UDF name="username" label="The limited sudo user to be created for the Linode." default="">
#<UDF name="password" label="The password for the limited sudo user" example="an0th3r_s3cure_p4ssw0rd" default="">
#<UDF name="pubkey" label="The SSH Public Key that will be used to access the Linode" default="">
#<UDF name="disable_root" label="Disable root access over SSH?" oneOf="Yes,No" default="No">
## Domain Settings
#<UDF name="token_password" label="Your Linode API token. This is needed to create your Linode's DNS records" default="">
#<UDF name="subdomain" label="Subdomain" example="The subdomain for the DNS record: www (Requires Domain)" default="">
#<UDF name="domain" label="Domain" example="The domain for the DNS record: example.com (Requires API token)" default="">
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

## Register default rDNS
export DEFAULT_RDNS=$(dnsdomainname -A | awk '{print $1}')

#set absolute domain if any, otherwise use localhost
if [[ $DOMAIN = "" ]]; then
  readonly ABS_DOMAIN="$DEFAULT_RDNS"
elif [[ $SUBDOMAIN = "" ]]; then
  readonly ABS_DOMAIN="$DOMAIN"
else
  readonly ABS_DOMAIN="$SUBDOMAIN.$DOMAIN"
fi

create_a_record $SUBDOMAIN $IP $DOMAIN

## install depends
export DEBIAN_FRONTEND=noninteractive
apt-get install apt-transport-https ca-certificates wget dirmngr gpg software-properties-common multiarch-support libcommons-daemon-java jsvc -y
# install mongodb req libssl1
wget http://security.debian.org/debian-security/pool/updates/main/o/openssl/libssl1.0.0_1.0.1t-1+deb8u12_amd64.deb
dpkg -i libssl1.0.0_1.0.1t-1+deb8u12_amd64.deb
# install mongodb-3.4
wget -qO - https://www.mongodb.org/static/pgp/server-3.4.asc |  apt-key add -
echo "deb http://repo.mongodb.org/apt/debian jessie/mongodb-org/3.4 main" | tee /etc/apt/sources.list.d/mongodb-org-3.4.list
apt update && apt upgrade -y
apt install mongodb-org -y
# install Java 8
wget -qO - https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | sudo apt-key add -
add-apt-repository --yes https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/
apt update && apt install adoptopenjdk-8-hotspot -y
# install latest UniFi Controller
echo 'deb https://www.ui.com/downloads/unifi/debian stable ubiquiti' | sudo tee /etc/apt/sources.list.d/100-ubnt-unifi.list
sudo wget -O /etc/apt/trusted.gpg.d/unifi-repo.gpg https://dl.ui.com/unifi/unifi-repo.gpg
apt update && apt install unifi -yq

## install nginx reverse-proxy
apt install nginx -y
#configure nginx reverse proxy
rm /etc/nginx/sites-enabled/default
touch /etc/nginx/sites-available/reverse-proxy.conf
cat <<END > /etc/nginx/sites-available/reverse-proxy.conf
server {
        listen 80;
        listen [::]:80;
        server_name ${ABS_DOMAIN};

        access_log /var/log/nginx/reverse-access.log;
        error_log /var/log/nginx/reverse-error.log;

        location / {
                    proxy_pass https://localhost:8443;
  }
}
END
ln -s /etc/nginx/sites-available/reverse-proxy.conf /etc/nginx/sites-enabled/reverse-proxy.conf

#enable and start nginx
systemctl enable nginx
systemctl restart nginx

## UFW rules
ufw allow http
ufw allow https
ufw enable

sleep 60

## install SSL certs. required
apt install python3-certbot-nginx -y
certbot run --non-interactive --nginx --agree-tos --redirect -d ${ABS_DOMAIN} -m ${SOA_EMAIL_ADDRESS} -w /var/www/html/

## add some details
cat << EOF > /etc/motd
###################

 The installation is now complete, and you can access the UniFi Network Controller GUI from https://${ABS_DOMAIN}
 We recommend using the GUI to complete your configurations of the service

###################
EOF
stackscript_cleanup
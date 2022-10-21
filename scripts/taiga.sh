# linode/taiga.sh by 633a
# id: 619952
# description: Try Taiga! Docs: https://taigaio.github.io/taiga-doc/dist/setup-alternatives.html#_introduction. 
This script installs fork of https://github.com/taigaio/taiga-scripts
- Ubuntu 20.04
- Optional import sample projects
- Enable/disable public registraton
- Encryption with letsencrypt.org (certbot) - only when rebuilding as domain needs to be resolving at the time of certificate request.
# defined fields: name-taiga_front_user-label-taiga-front-end-user-example-admin-name-taiga_front_password-label-taiga-front-end-password-example-password-name-taiga_front_email-label-taiga-front-end-user-email-example-exampledomaincom-name-taiga_password-label-taiga-linux-user-password-example-password-name-taiga_hostname-label-host-name-default-localhost-name-taiga_domain-label-ip-address-will-be-used-if-no-domain-name-is-provided-default-name-taiga_sample_data-label-import-sample-projects-oneof-truefalse-default-true-example-import-sample-projects-and-data-name-taiga_public_register_enabled-label-public-registation-enabled-oneof-truefalse-default-true-example-enable-anyone-to-register-name-taiga_encrypt-label-use-encryption-only-works-on-rebuild-requires-fqdn-oneof-truefalse-default-false-example-install-certbot-and-install-ssl-certificate-from-letsencryptorg-name-taiga_ssl_email-label-ssl-renewal-notice-email-lets-encrypt-use-example-exampledomaincom-default
# images: ['linode/ubuntu20.04']
# stats: Used By: 0 + AllTime: 90
#!/bin/bash
#<UDF name="TAIGA_FRONT_USER" Label="Taiga front end user" example="admin" />
#<UDF name="TAIGA_FRONT_PASSWORD" Label="Taiga front end password" example="password" />
#<UDF name="TAIGA_FRONT_EMAIL" Label="Taiga front end user email" example="example@domain.com" />
#<UDF name="TAIGA_PASSWORD" Label="Taiga linux user password" example="password" />
#<UDF name="TAIGA_HOSTNAME" Label="Host name" default="localhost" />
#<UDF name="TAIGA_DOMAIN" label="Fully qualified domain name" default="" Label="IP address will be used if no domain name is provided." />
#<UDF name="TAIGA_SAMPLE_DATA" label="Import Sample Projects" oneof="True,False" default="True" example="Import sample projects and data." />
#<UDF name="TAIGA_PUBLIC_REGISTER_ENABLED" label="Public Registation Enabled" oneof="True,False" default="True" example="Enable anyone to register." />
#<UDF name="TAIGA_ENCRYPT" label="Use Encryption (Only works on rebuild - requires FQDN) " oneof="True,False" default="False" example="Install Certbot and install SSL certificate from letsencrypt.org" />
#<UDF name="TAIGA_SSL_EMAIL" Label="SSL Renewal notice email (Let's Encrypt use)" example="example@domain.com" default="" />

# Install net tools to have 'ifconfig' available
apt update && apt install net-tools

# Create a user named taiga, and give it root permissions
adduser taiga --disabled-password --gecos "" && \
echo "taiga:$TAIGA_PASSWORD" | chpasswd
echo 'taiga ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/taiga

cd /home/taiga

# Copy public keys if as was added in stack Script
mkdir /home/taiga/.ssh
cp /root/.ssh/authorized_keys /home/taiga/.ssh/authorized_keys
chown -R taiga:taiga /home/taiga/.setup/data.sh /home/taiga/.ssh

# Create config variables for taiga-scripts
IP_ADDRESS=$(/sbin/ifconfig eth0 | awk '/inet / { print $2 }' | sed 's/addr://')

if [ "$TAIGA_DOMAIN" == "" ] ; then
      TAIGA_DOMAIN="$IP_ADDRESS"
fi

if [ "$TAIGA_ENCRYPT" == "True" ] ; then
      TAIGA_SCHEME="https"
      TAIGA_EVENTS_SCHEME="wss"
else
      TAIGA_SCHEME="http"
      TAIGA_EVENTS_SCHEME="ws"
fi

mkdir -p /home/taiga/.setup
cat <<EOF >/home/taiga/.setup/data.sh
#!/bin/bash
TAIGA_FRONT_USER="$TAIGA_FRONT_USER"
TAIGA_FRONT_PASSWORD="$TAIGA_FRONT_PASSWORD"
TAIGA_FRONT_EMAIL="$TAIGA_FRONT_EMAIL"
TAIGA_HOSTNAME="$TAIGA_HOSTNAME"
TAIGA_DOMAIN="$TAIGA_DOMAIN"
TAIGA_SAMPLE_DATA="$TAIGA_SAMPLE_DATA"
TAIGA_PUBLIC_REGISTER_ENABLED="$TAIGA_PUBLIC_REGISTER_ENABLED"
TAIGA_ENCRYPT="$TAIGA_ENCRYPT"
TAIGA_SCHEME="$TAIGA_SCHEME"
TAIGA_EVENTS_SCHEME="$TAIGA_EVENTS_SCHEME"
TAIGA_SSL_EMAIL="$TAIGA_SSL_EMAIL"
IP_ADDRESS="$IP_ADDRESS"
SECRET_KEY=$(< /dev/urandom tr -dc A-Za-z | head -c48)
EVENTS_PASS=$(< /dev/urandom tr -dc A-Za-z0-9 | head -c16)
TAIGA_PUBLIC_REGISTER_ENABLED_FRONT=$(echo "$TAIGA_PUBLIC_REGISTER_ENABLED" | awk '{print tolower($0)}')

EOF

# Download the code as taiga user

sudo -i -u taiga  bash <<EOF
git clone https://github.com/dev633a/taiga-scripts.git
cd /home/taiga/taiga-scripts
./setup-server.sh
EOF

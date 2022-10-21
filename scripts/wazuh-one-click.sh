# linode/wazuh-one-click.sh by linode
# id: 913276
# description: Wazuh One-Click
# defined fields: name-soa_email_address-label-email-address-for-the-lets-encrypt-ssl-certificate-example-userdomaintld-name-username-label-the-limited-sudo-user-to-be-created-for-the-linode-default-name-password-label-the-password-for-the-limited-sudo-user-example-an0th3r_s3cure_p4ssw0rd-default-name-pubkey-label-the-ssh-public-key-that-will-be-used-to-access-the-linode-default-name-disable_root-label-disable-root-access-over-ssh-oneof-yesno-default-no-name-token_password-label-your-linode-api-token-this-is-needed-to-create-your-wordpress-servers-dns-records-default-name-subdomain-label-subdomain-example-the-subdomain-for-the-dns-record-www-requires-domain-default-name-domain-label-domain-example-the-domain-for-the-dns-record-examplecom-requires-api-token-default
# images: ['linode/ubuntu20.04']
# stats: Used By: 67 + AllTime: 821
#!/usr/bin/env bash

# #<UDF name="soa_email_address" label="Email address (for the Let's Encrypt SSL certificate)" example="user@domain.tld">

## Linode/SSH Security Settings
#<UDF name="username" label="The limited sudo user to be created for the Linode" default="">
#<UDF name="password" label="The password for the limited sudo user" example="an0th3r_s3cure_p4ssw0rd" default="">
#<UDF name="pubkey" label="The SSH Public Key that will be used to access the Linode" default="">
#<UDF name="disable_root" label="Disable root access over SSH?" oneOf="Yes,No" default="No">

## Domain Settings 
#<UDF name="token_password" label="Your Linode API token. This is needed to create your WordPress server's DNS records" default="">
#<UDF name="subdomain" label="Subdomain" example="The subdomain for the DNS record: www (Requires Domain)" default="">
#<UDF name="domain" label="Domain" example="The domain for the DNS record: example.com (Requires API token)" default="">

## Enable logging
set -xo pipefail
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1
## Import the Bash StackScript Library
source <ssinclude StackScriptID=1>
## Import the DNS/API Functions Library
source <ssinclude StackScriptID=632759>
## Import the OCA Helper Functions
source <ssinclude StackScriptID=401712>
## Run initial configuration tasks (DNS/SSH stuff, etc...)
source <ssinclude StackScriptID=666912>

# UFW https://documentation.wazuh.com/current/getting-started/architecture.html
ufw allow 1514
ufw allow 1515
ufw allow 1516
ufw allow 514
ufw allow 55000
ufw allow 443
ufw allow 80
ufw allow 9200
ufw allow 9300

# Prereqs & Wazuh Install
apt install -y curl apt-transport-https unzip wget libcap2-bin software-properties-common lsb-release gnupg2 default-jre
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | sudo apt-key add -
echo "deb https://packages.wazuh.com/4.x/apt/ stable main" | sudo tee /etc/apt/sources.list.d/wazuh.list
apt_setup_update
apt install -y wazuh-manager

systemctl daemon-reload
systemctl enable --now wazuh-manager

# Elastic
apt install -y elasticsearch-oss opendistroforelasticsearch
curl -so /etc/elasticsearch/elasticsearch.yml https://packages.wazuh.com/resources/4.2/open-distro/elasticsearch/7.x/elasticsearch_all_in_one.yml

curl -so /usr/share/elasticsearch/plugins/opendistro_security/securityconfig/roles.yml https://packages.wazuh.com/resources/4.2/open-distro/elasticsearch/roles/roles.yml
curl -so /usr/share/elasticsearch/plugins/opendistro_security/securityconfig/roles_mapping.yml https://packages.wazuh.com/resources/4.2/open-distro/elasticsearch/roles/roles_mapping.yml
curl -so /usr/share/elasticsearch/plugins/opendistro_security/securityconfig/internal_users.yml https://packages.wazuh.com/resources/4.2/open-distro/elasticsearch/roles/internal_users.yml

rm -f /etc/elasticsearch/{esnode-key.pem,esnode.pem,kirk-key.pem,kirk.pem,root-ca.pem}

curl -so ~/wazuh-cert-tool.sh https://packages.wazuh.com/resources/4.2/open-distro/tools/certificate-utility/wazuh-cert-tool.sh
curl -so ~/instances.yml https://packages.wazuh.com/resources/4.2/open-distro/tools/certificate-utility/instances_aio.yml
bash ~/wazuh-cert-tool.sh
mkdir /etc/elasticsearch/certs/
mv ~/certs/elasticsearch* /etc/elasticsearch/certs/
mv ~/certs/admin* /etc/elasticsearch/certs/
cp ~/certs/root-ca* /etc/elasticsearch/certs/

systemctl daemon-reload
systemctl enable elasticsearch
systemctl start elasticsearch

export JAVA_HOME=/usr/share/elasticsearch/jdk/ && /usr/share/elasticsearch/plugins/opendistro_security/tools/securityadmin.sh -cd /usr/share/elasticsearch/plugins/opendistro_security/securityconfig/ -nhnv -cacert /etc/elasticsearch/certs/root-ca.pem -cert /etc/elasticsearch/certs/admin.pem -key /etc/elasticsearch/certs/admin-key.pem

# FOR TESTING
curl -XGET https://localhost:9200 -u admin:admin -k

# Filebeat
apt install -y filebeat
curl -so /etc/filebeat/filebeat.yml https://packages.wazuh.com/resources/4.2/open-distro/filebeat/7.x/filebeat_all_in_one.yml
curl -so /etc/filebeat/wazuh-template.json https://raw.githubusercontent.com/wazuh/wazuh/4.2/extensions/elasticsearch/7.x/wazuh-template.json
chmod go+r /etc/filebeat/wazuh-template.json
curl -s https://packages.wazuh.com/4.x/filebeat/wazuh-filebeat-0.1.tar.gz | tar -xvz -C /usr/share/filebeat/module

mkdir /etc/filebeat/certs
cp ~/certs/root-ca.pem /etc/filebeat/certs/
mv ~/certs/filebeat* /etc/filebeat/certs/

systemctl daemon-reload
systemctl enable filebeat
systemctl start filebeat

# TESTING
filebeat test output

# Kibana
apt install -y opendistroforelasticsearch-kibana
curl -so /etc/kibana/kibana.yml https://packages.wazuh.com/resources/4.2/open-distro/kibana/7.x/kibana_all_in_one.yml
mkdir /usr/share/kibana/data
chown -R kibana:kibana /usr/share/kibana/data

cd /usr/share/kibana
sudo -u kibana /usr/share/kibana/bin/kibana-plugin install https://packages.wazuh.com/4.x/ui/kibana/wazuh_kibana-4.2.2_7.10.2-1.zip
mkdir /etc/kibana/certs
cp ~/certs/root-ca.pem /etc/kibana/certs/
mv ~/certs/kibana* /etc/kibana/certs/
chown kibana:kibana /etc/kibana/certs/*

setcap 'cap_net_bind_service=+ep' /usr/share/kibana/node/bin/node

systemctl daemon-reload
systemctl enable kibana
systemctl start kibana

# Get Passwords
cd && curl -so wazuh-passwords-tool.sh https://packages.wazuh.com/resources/4.2/open-distro/tools/wazuh-passwords-tool.sh
#bash wazuh-passwords-tool.sh -a > .wazuh_creds.txt

# NGINX
apt install git nginx certbot python3-certbot-nginx -y

mkdir -p /var/www/certs/.well-known
chown -R www-data:www-data /var/www/certs/
cat <<EOF > /etc/nginx/sites-available/$FQDN
server {
    listen 80;
    listen [::]:80;
    server_name $FQDN;
    root /var/www/certs;
    location / {
        try_files \$uri \$uri/ =404;
    }
# allow .well-known
    location ^~ /.well-known {
      allow all;
      auth_basic off;
      alias /var/www/certs/.well-known;
    }
}
EOF
ln -s /etc/nginx/sites-available/$FQDN /etc/nginx/sites-enabled/$FQDN
unlink /etc/nginx/sites-enabled/default
systemctl restart nginx

# SSL Certbot
certbot certonly --agree-tos --webroot --webroot-path=/var/www/certs -d $FQDN -m $SOA_EMAIL_ADDRESS

# Set Variables
export KIBANA_FULL=/etc/kibana/certs/fullchain.pem
export KIBANA_PRIVKEY=/etc/kibana/certs/privkey.pem
export FULLCHAIN=/etc/letsencrypt/live/$FQDN/fullchain.pem
export PRIVKEY=/etc/letsencrypt/live/$FQDN/privkey.pem

# Place certificates in /etc/kibana/kibana.yml
cat $FULLCHAIN > $KIBANA_FULL
cat $PRIVKEY > $KIBANA_PRIVKEY

# Update kibana config to point to letsencrypt certs
sed -i -e "s/kibana-key.pem/privkey.pem/" /etc/kibana/kibana.yml
sed -i -e "s/kibana.pem/fullchain.pem/" /etc/kibana/kibana.yml

# Restart Kibana
service kibana restart

# Create Cert renewal cron script
cat <<END >/root/certbot-kibana-renewal.sh
#!/bin/bash
#
# Script to handle Certbot renewal & Kibana

# Debug
# set -xo pipefail

export KIBANA_FULL=/etc/kibana/certs/fullchain.pem
export KIBANA_PRIVKEY=/etc/kibana/certs/privkey.pem
export FULLCHAIN=/etc/letsencrypt/live/$FQDN/fullchain.pem
export PRIVKEY=/etc/letsencrypt/live/$FQDN/privkey.pem

certbot renew

cat \$FULLCHAIN > \$KIBANA_FULL
cat \$PRIVKEY > \$KIBANA_PRIVKEY

service kibana restart
END

chmod +x /root/certbot-kibana-renewal.sh

# Setup Cron
crontab -l > cron
echo "* 1 * * 1 bash /root/certbot-kibana-renewal.sh" >> cron
crontab cron
rm cron

# Cleanup
stackscript_cleanup
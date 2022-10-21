# linode/gitea-one-click.sh by linode
# id: 688911
# description: Gitea One-Click
# defined fields: name-dbroot_password-label-mysql-root-password-name-db_password-label-gitea-database-password-name-username-label-the-limited-sudo-user-to-be-created-for-the-linode-default-name-password-label-the-password-for-the-limited-sudo-user-default-name-pubkey-label-the-ssh-public-key-that-will-be-used-to-access-the-linode-default-name-pwless_sudo-label-enable-passwordless-sudo-access-for-the-limited-user-oneof-yesno-default-no-name-disable_root-label-disable-root-access-over-ssh-oneof-yesno-default-no-name-auto_updates-label-configure-automatic-security-updates-oneof-yesno-default-no-name-fail2ban-label-use-fail2ban-to-prevent-automated-instrusion-attempts-oneof-yesno-default-no-name-token_password-label-your-linode-api-token-this-is-needed-to-create-your-dns-records-default-name-subdomain-label-the-subdomain-for-your-server-domain-required-default-name-domain-label-your-domain-api-token-required-default-name-soa_email_address-label-soa-email-for-your-domain-required-for-new-domains-default-name-mx-label-do-you-need-an-mx-record-for-this-domain-yes-if-sending-mail-from-this-linode-oneof-yesno-default-no-name-spf-label-do-you-need-an-spf-record-for-this-domain-yes-if-sending-mail-from-this-linode-oneof-yesno-default-no-name-ssl-label-would-you-like-to-use-a-free-lets-encrypt-ssl-certificate-for-your-domain-oneof-yesno-default-no-name-email_address-label-admin-email-for-lets-encrypt-certificate-default
# images: ['linode/debian10']
# stats: Used By: 72 + AllTime: 667
#! /bin/bash

## Database Settings
#<UDF name="dbroot_password" Label="MySQL root Password" />
#<UDF name="db_password" Label="gitea Database Password" />

## User and SSH Security
#<UDF name="username" label="The limited sudo user to be created for the Linode" default="">
#<UDF name="password" label="The password for the limited sudo user" default="">
#<UDF name="pubkey" label="The SSH Public Key that will be used to access the Linode" default="">
#<UDF name="pwless_sudo" label="Enable passwordless sudo access for the limited user?" oneOf="Yes,No" default="No">
#<UDF name="disable_root" label="Disable root access over SSH?" oneOf="Yes,No" default="No">
#<UDF name="auto_updates" label="Configure automatic security updates?" oneOf="Yes,No" default="No">
#<UDF name="fail2ban" label="Use fail2ban to prevent automated instrusion attempts?" oneOf="Yes,No" default="No">

## Domain Settings
#<UDF name="token_password" label="Your Linode API token. This is needed to create your DNS records." default="">
#<UDF name="subdomain" label="The subdomain for your server (Domain required)" default="">
#<UDF name="domain" label="Your domain (API Token required)" default="">
#<UDF name="soa_email_address" label="SOA Email for your domain (Required for new domains)" default="">
#<UDF name="mx" label="Do you need an MX record for this domain? (Yes if sending mail from this Linode)" oneOf="Yes,No" default="No">
#<UDF name="spf" label="Do you need an SPF record for this domain? (Yes if sending mail from this Linode)" oneOf="Yes,No" default="No">
#<UDF name="ssl" label="Would you like to use a free Let's Encrypt SSL certificate for your domain?" oneOf="Yes,No" default="No">
#<UDF name="email_address" label="Admin Email for Let's Encrypt certificate" default="">

source <ssinclude StackScriptID="1">
source <ssinclude StackScriptID="401712">
source <ssinclude StackScriptID="632759">
source <ssinclude StackScriptID="666912">

exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

#assigns var for IP address
readonly ip=$(hostname -I | awk '{print$1}')

#intall git
apt install -y git

#install nginx
apt install -y nginx

#install mysql and secure
mysql_root_preinstall
apt-get install -y mariadb-server
systemctl start mariadb
systemctl enable mariadb
run_mysql_secure_installation

#create mysql db and user
mysql -u root --password="$DBROOT_PASSWORD" -e "CREATE DATABASE gitea;"
mysql -u root --password="$DBROOT_PASSWORD" -e "CREATE USER 'gitea'@'localhost' IDENTIFIED BY '$(printf '%q' "$DB_PASSWORD")';"
mysql -u root --password="$DBROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON gitea.* TO 'gitea'@'localhost' WITH GRANT OPTION;"
mysql -u root --password="$DBROOT_PASSWORD" -e "FLUSH PRIVILEGES;"

#create user for gitea
adduser --system --disabled-password --group --shell /bin/bash --gecos 'Git Version Control' --home /home/git git

#create directories for gitea
mkdir -p /var/lib/gitea/{custom,data,log}
chown -R git:git /var/lib/gitea/
chmod -R 750 /var/lib/gitea/
mkdir /etc/gitea
chown root:git /etc/gitea
chmod 770 /etc/gitea

#pull down gitea binary
wget -O gitea https://dl.gitea.io/gitea/1.13.0/gitea-1.13.0-linux-amd64
chmod +x gitea

#validate gpg
apt install gnupg -y
gpg --keyserver keys.openpgp.org --recv 7C9E68152594688862D62AF62D9AE806EC1592E2
gpg --verify gitea-1.13.0-linux-amd64.asc gitea-1.13.0-linux-amd64

#copy gitea to global location
cp gitea /usr/local/bin/gitea

#download systemd file from gitea
wget https://raw.githubusercontent.com/go-gitea/gitea/master/contrib/systemd/gitea.service -P /etc/systemd/system/

#add requires mysql to the systemd file
sed -i 's/#Requires=mariadb.service/Requires=mariadb.service/' /etc/systemd/system/gitea.service

#start gitea as systemd service
systemctl daemon-reload
systemctl start gitea
systemctl enable gitea

#configures ufw rules before nginx
systemctl start ufw
ufw allow http
ufw allow https
ufw enable

#set absolute domain if any, otherwise use localhost
if [[ $DOMAIN = "" ]]; then
  readonly ABS_DOMAIN=localhost
elif [[ $SUBDOMAIN = "" ]]; then
  readonly ABS_DOMAIN="$DOMAIN"
else
  readonly ABS_DOMAIN="$SUBDOMAIN.$DOMAIN"
fi

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
                    proxy_pass http://localhost:3000;
  }
}
END
ln -s /etc/nginx/sites-available/reverse-proxy.conf /etc/nginx/sites-enabled/reverse-proxy.conf

#enable and start nginx
systemctl enable nginx
systemctl restart nginx

sleep 60

#sets certbot ssl
if [[ $SSL = "Yes" ]]; then
  check_dns_propagation ${ABS_DOMAIN} ${ip}
  apt install python3-certbot-nginx -y
  certbot run --non-interactive --nginx --agree-tos --redirect -d ${ABS_DOMAIN} -m ${EMAIL_ADDRESS} -w /var/www/html/
fi

stackscript_cleanup
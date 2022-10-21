# linode/mysqlmariadb-one-click.sh by linode
# id: 607026
# description: MySql One Click
# defined fields: name-database-label-would-you-like-to-install-mysql-or-mariadb-oneof-mysqlmariadb-name-dbroot_password-label-mysql-root-password-example-s3cur3_9a55w04d-name-dbuser-label-mysql-user-example-user1-name-dbuser_password-label-mysql-user-password-example-s3cur3_9a55w04d-name-database_name-label-create-database-example-testdb-name-username-label-the-limited-sudo-user-to-be-created-for-the-linode-default-name-password-label-the-password-for-the-limited-sudo-user-example-an0th3r_s3cure_p4ssw0rd-default-name-pubkey-label-the-ssh-public-key-that-will-be-used-to-access-the-linode-default-name-disable_root-label-disable-root-access-over-ssh-oneof-yesno-default-no-name-token_password-label-your-linode-api-token-this-is-needed-to-create-your-wordpress-servers-dns-records-default-name-subdomain-label-subdomain-example-the-subdomain-for-the-dns-record-www-requires-domain-default-name-domain-label-domain-example-the-domain-for-the-dns-record-examplecom-requires-api-token-default
# images: ['linode/ubuntu20.04']
# stats: Used By: 309 + AllTime: 3421
#!/usr/bin/env bash

## MySQL Settings
#<UDF name="database" label="Would you like to install MySQL or MariaDB?" oneOf="MySQL,MariaDB">
#<UDF name="dbroot_password" label="MySQL Root Password" example="s3cur3_9a55w04d">
#<UDF name="dbuser" Label="MySQL User" example="user1" />
#<UDF name="dbuser_password" Label="MySQL User Password" example="s3cur3_9a55w04d"/>
#<UDF name="database_name" Label="Create Database" example="testdb" />

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

# Update system & set hostname & basic security
set_hostname
apt_setup_update
ufw_install
ufw allow 3306
fail2ban_install

# Set hostname, configure apt and perform update/upgrade
set_hostname
apt_setup_update

if [[ "$DATABASE" == "MySQL" ]]; then
    # Install/configure MySQL
    apt install -y mysql-server
    # Secure MySQL install
    run_mysql_secure_installation_ubuntu20  
else 
    # Install/configure MySQL
    apt install -y mariadb-server
    # Secure MySQL install
    run_mysql_secure_installation
fi

mysql -uroot -p$DBROOT_PASSWORD -e "create database $DATABASE_NAME;"
mysql -uroot -p$DBROOT_PASSWORD -e "CREATE USER '$DBUSER' IDENTIFIED BY '$DBUSER_PASSWORD';"
mysql -uroot -p$DBROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON $DATABASE_NAME.* TO '$DBUSER'@'%' WITH GRANT OPTION;"

# Cleanup
stackscript_cleanup
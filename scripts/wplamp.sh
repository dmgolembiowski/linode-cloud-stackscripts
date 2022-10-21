# linode/wplamp.sh by flowcom
# id: 5645
# description: Standard WP Site with Apache, MySql and PHP on Ubuntu LTS-Server.
# defined fields: name-host_name-label-servers-hostname-default-servername-name-host_account-label-the-account-that-manage-the-server-instead-of-root-default-www-name-host_password-label-strong-password-name-host_ssh_key-label-the-hos-account-public-ssh-key-name-service_account-label-name-of-service-user-default-service-name-service_password-label-password-for-service-user-name-service_email-label-service-account-email-name-web_domain-label-domain-of-the-wordpress-site-default-mydomainorg
# images: [None]
# stats: Used By: 0 + AllTime: 70
#!/bin/bash
# stackscript: WPLAMP
# Create a WPLamp-stack for WordPress at Ubuntu 12.04 LTS.
# author: Andreas Ek <andreas at flowcom.se>
# To better understand what this stackscript does please go to http://repo.flowcom.se/flowcom/wplamp

# <UDF name="host_name" Label="Server's hostname" default="ServerName" />
# <UDF name="host_account" Label="The account that manage the server instead of root" default="www" />
# <UDF name="host_password" Label="Strong password" />
# <UDF name="host_ssh_key" Label="The hos account public ssh key" />

# <UDF name="service_account" Label="Name of service user" default="service" />
# <UDF name="service_password" Label="Password for service user" />
# <UDF name="service_email" Label="Service account email" />
# <UDF name="web_domain" Label="domain of the Wordpress site" default="mydomain.org" />

exec > /tmp/install_server.log

echo "Install Mercurial to clone down bash scripts..." 1>&2
apt-get -y install mercurial

echo "Cloning Flowcom WPLAMP to tmp folder" 1>&2
cd /tmp
hg clone http://code.flowcom.se/public/wplamp

echo "Running WPLAMP installer" 1>&2
wplamp/install_server.sh
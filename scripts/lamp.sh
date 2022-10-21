# linode/lamp.sh by caceyjones
# id: 12124
# description: Ubuntu/Debian LAMP
# defined fields: name-db_password-label-mysql-root-password-name-db_name-label-create-database-default-example-optionally-create-this-database-name-db_user-label-create-mysql-user-default-example-optionally-create-this-user-name-db_user_password-label-mysql-users-password-default-example-users-password
# images: ['linode/debian7', 'linode/debian8', 'linode/ubuntu14.04lts', 'linode/ubuntu14.10', 'linode/ubuntu15.04']
# stats: Used By: 8 + AllTime: 102
#!/bin/bash
# <UDF name="db_password" Label="MySQL root Password" />
# <UDF name="db_name" Label="Create Database" default="" example="Optionally create this database" />
# <UDF name="db_user" Label="Create MySQL User" default="" example="Optionally create this user" />
# <UDF name="db_user_password" Label="MySQL User's Password" default="" example="User's password" />

#Update system

apt-get update
apt-get upgrade -y


source <ssinclude StackScriptID="1">

system_update
postfix_install_loopback_only
mysql_install "$DB_PASSWORD" && mysql_tune 40
mysql_create_database "$DB_PASSWORD" "$DB_NAME"
mysql_create_user "$DB_PASSWORD" "$DB_USER" "$DB_USER_PASSWORD"
mysql_grant_user "$DB_PASSWORD" "$DB_USER" "$DB_NAME"
php_install_with_apache && php_tune
apache_install && apache_tune 40 && apache_virtualhost_from_rdns
goodstuff
restartServices
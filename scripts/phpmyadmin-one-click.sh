# linode/phpmyadmin-one-click.sh by linode
# id: 609018
# description: phpMyAdmin One-Click
# defined fields: name-db_user-label-phpmyadminmysql-admin-user-example-admin-name-dbuser_password-label-phpmyadminmysql-admin-password-name-dbroot_password-label-mysql-root-password
# images: ['linode/debian11']
# stats: Used By: 97 + AllTime: 1465
#!/bin/bash
#<UDF name="db_user" Label="phpMyAdmin/MySQL Admin User" example="admin" />
#<UDF name="dbuser_password" Label="phpMyAdmin/MySQL Admin Password" />
#<UDF name="dbroot_password" Label="MySQL root Password" />

source <ssinclude StackScriptID="401712">
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

# Set hostname
set_hostname

# Update system
apt_setup_update

# Install/configure MySQL, Add Admin User
apt-get install -y mariadb-server
systemctl enable mariadb --now
run_mysql_secure_installation
mysql -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DBUSER_PASSWORD'"
mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO '$DB_USER'@'localhost' WITH GRANT OPTION"
mysql -u root -e "FLUSH PRIVILEGES"

# Install PHP
echo 'phpmyadmin phpmyadmin/dbconfig-install boolean true' | debconf-set-selections
echo 'phpmyadmin phpmyadmin/mysql/admin-pass password $DBROOT_PASSWORD' | debconf-set-selections
echo 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2' | debconf-set-selections
apt-get install -y phpmyadmin libapache2-mod-php7.4

# Configure ufw
ufw_install
ufw allow http
ufw reload

# Cleanup
stackscript_cleanup